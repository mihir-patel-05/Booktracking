# PageFlow deployment on AWS EC2 with GitHub Actions

This runbook replaces AWS Amplify Hosting with a single EC2 deployment for the
PageFlow Next.js web application. It is written for:

- GitHub repository: **mihir-patel-05/Booktracking**
- Current deployment branch: **codex/pageflow-web**
- Application directory: **web/**
- Runtime: **Node.js 22**
- Database and authentication: **Supabase**
- Recommended AWS Region: **Canada Central (ca-central-1)**, matching the current
  Supabase project

The target pipeline is:

~~~text
Pull request or push
        |
        v
GitHub Actions: npm ci -> lint -> unit tests -> WebKit tests -> build
        |
        v
GitHub OIDC -> short-lived AWS role (no AWS access-key secrets)
        |
        v
Private versioned S3 deployment artifact
        |
        v
AWS Systems Manager Run Command
        |
        v
EC2 release directory -> atomic symlink -> systemd -> Node.js
        |
        v
Nginx -> HTTPS -> PageFlow
~~~

## Important operating assumptions

This first EC2 design uses one instance. It is appropriate for a private preview
and an initial low-traffic release, but it is a single point of failure. A later
high-availability version should put at least two instances in an Auto Scaling
group behind an Application Load Balancer.

The database must remain in Supabase. Do not install Postgres, store uploaded
data, or store application state on the EC2 filesystem. Only application
releases and logs live on the instance.

Do not create an inbound SSH rule. Administration and deployments use AWS
Systems Manager. AWS documents Systems Manager Run Command as a secure remote
management and automation mechanism for EC2 managed nodes:
[AWS Systems Manager Run Command](https://docs.aws.amazon.com/systems-manager/latest/userguide/run-command.html).

## Values to collect

Choose these values before starting and substitute them throughout this guide.

| Name | Example |
| --- | --- |
| AWS region | ca-central-1 |
| AWS account ID | 123456789012 |
| EC2 instance ID | i-0123456789abcdef0 |
| Deployment bucket | pageflow-deployments-123456789012-ca-central-1 |
| GitHub deploy role | PageFlowGitHubDeployRole |
| EC2 instance role | PageFlowEC2Role |
| Production hostname | pageflow.example.com |
| Supabase URL | https://shjvfdbzefejhyjhlvqw.supabase.co |

Bucket names are globally unique. Include the AWS account ID in the name.

## Phase 1: prepare the Next.js production bundle

Next.js standalone output produces a much smaller runtime bundle and avoids
running npm install on the EC2 instance for every deployment.

Edit web/next.config.ts and add output: "standalone" to nextConfig:

~~~ts
const nextConfig: NextConfig = {
  output: "standalone",
  poweredByHeader: false,
  // Keep the existing images and headers configuration.
};
~~~

Do not remove the existing CSP, HSTS, authenticated cache-control, image, or
permissions-policy configuration.

Verify locally:

~~~bash
cd web
npm ci
npm run lint
npm test
npm run build
test -f .next/standalone/server.js
~~~

The EC2 instance must use x86_64 because the default GitHub-hosted Linux runner
builds native Node dependencies for x86_64. Do not select an Arm/Graviton EC2
instance unless the GitHub build runner is also changed to Arm.

## Phase 2: create the private deployment bucket

In AWS Console:

1. Open **S3** in ca-central-1.
2. Create a bucket named with the value selected above.
3. Keep **Block all public access** enabled.
4. Enable bucket versioning.
5. Enable default server-side encryption with SSE-S3 or SSE-KMS.
6. Create a lifecycle rule that expires artifacts under releases/ after 30 days.

Add this bucket policy after replacing BUCKET_NAME. It refuses non-TLS access:

~~~json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Sid": "DenyInsecureTransport",
      "Effect": "Deny",
      "Principal": "*",
      "Action": "s3:*",
      "Resource": [
        "arn:aws:s3:::BUCKET_NAME",
        "arn:aws:s3:::BUCKET_NAME/*"
      ],
      "Condition": {
        "Bool": {
          "aws:SecureTransport": "false"
        }
      }
    }
  ]
}
~~~

## Phase 3: create the EC2 instance role

In **IAM → Roles → Create role**:

1. Select **AWS service**.
2. Select **EC2**.
3. Name the role **PageFlowEC2Role**.
4. Attach the AWS-managed policy **AmazonSSMManagedInstanceCore**.
5. Add the following inline policy, replacing BUCKET_NAME:

~~~json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Sid": "ReadDeploymentArtifacts",
      "Effect": "Allow",
      "Action": [
        "s3:GetObject"
      ],
      "Resource": "arn:aws:s3:::BUCKET_NAME/releases/*"
    }
  ]
}
~~~

The instance does not need permission to upload artifacts or modify the bucket.
AWS documents the required Systems Manager instance permissions here:
[Configure instance permissions](https://docs.aws.amazon.com/systems-manager/latest/userguide/setup-instance-permissions.html).

## Phase 4: create the EC2 security group

Create a security group named **pageflow-web** with these inbound rules:

| Type | Port | Source |
| --- | ---: | --- |
| HTTP | 80 | 0.0.0.0/0 and ::/0 |
| HTTPS | 443 | 0.0.0.0/0 and ::/0 |

Do not add port 22. Keep port 3000 closed to the internet; Nginx reaches it over
127.0.0.1.

Security groups are the instance firewall and must explicitly allow required
inbound traffic:
[Amazon EC2 security groups](https://docs.aws.amazon.com/AWSEC2/latest/UserGuide/ec2-security-groups.html).

For the first deployment, the default outbound allow rule is acceptable. Later,
restrict outbound traffic only after confirming DNS, HTTPS, package downloads,
Supabase, Google Books, and AWS API access.

## Phase 5: launch EC2

In **EC2 → Instances → Launch instance**:

1. Name: **pageflow-web-production**.
2. AMI: **Ubuntu Server 24.04 LTS, x86_64**.
3. Instance type: **t3.small minimum**; **t3.medium recommended**.
4. Key pair: choose **Proceed without a key pair** because access uses SSM.
5. Network: a public subnet with automatic public IPv4 enabled.
6. Security group: select **pageflow-web**.
7. Storage: at least 20 GiB gp3, encrypted, delete on termination enabled.
8. Advanced details → IAM instance profile: **PageFlowEC2Role**.
9. Advanced details → Metadata version: **V2 only**.
10. Add tags:
    - Name = pageflow-web-production
    - Application = PageFlow
    - Environment = production

AWS supports requiring IMDSv2 so requests without a session token fail:
[EC2 instance metadata options](https://docs.aws.amazon.com/AWSEC2/latest/UserGuide/configuring-instance-metadata-service.html).

Allocate an Elastic IP and associate it with the instance. Record the address.
AWS charges for public IPv4 addresses, so delete the address if this deployment
is retired.

## Phase 6: confirm Systems Manager access

Wait several minutes after launch, then open:

**Systems Manager → Fleet Manager → Managed nodes**

The instance should appear as online. If it does not:

1. Confirm PageFlowEC2Role is attached.
2. Confirm AmazonSSMManagedInstanceCore is attached to the role.
3. Confirm the instance has outbound HTTPS access.
4. Confirm the SSM Agent is running.

Open **EC2 → Instance → Connect → Session Manager → Connect**. This opens a
shell without SSH.

## Phase 7: bootstrap the instance

Run these commands in Session Manager. Review each block before running it.

### Install operating-system packages

~~~bash
sudo apt-get update
sudo apt-get upgrade -y
sudo apt-get install -y ca-certificates curl gnupg nginx awscli jq
~~~

Install Node.js 22 from the NodeSource Debian repository. Download the setup
script first so the download must succeed before it is executed:

~~~bash
curl -fsSL https://deb.nodesource.com/setup_22.x -o /tmp/nodesource_setup.sh
sudo -E bash /tmp/nodesource_setup.sh
sudo apt-get install -y nodejs
rm /tmp/nodesource_setup.sh
~~~

NodeSource currently supports Node.js 22 on Ubuntu 24.04. Verify the installed
major version and executable path. The commands above follow the
[NodeSource Node.js 22 installation instructions](https://github.com/nodesource/distributions/blob/master/DEV_README.md#using-ubuntu-nodejs-22):

~~~bash
node --version
npm --version
~~~

The Node major version must be 22. Ensure the executable is available at
/usr/bin/node or update the systemd service below to its actual absolute path:

~~~bash
command -v node
~~~

### Create the application user and directories

~~~bash
sudo useradd --system --home /opt/pageflow --shell /usr/sbin/nologin pageflow
sudo install -d -o pageflow -g pageflow /opt/pageflow/releases
sudo install -d -o root -g pageflow -m 0750 /etc/pageflow
~~~

### Create the runtime environment file

Create /etc/pageflow/pageflow.env:

~~~dotenv
NODE_ENV=production
PORT=3000
HOSTNAME=127.0.0.1
NEXT_PUBLIC_SUPABASE_URL=https://shjvfdbzefejhyjhlvqw.supabase.co
NEXT_PUBLIC_SUPABASE_PUBLISHABLE_KEY=REPLACE_WITH_PUBLISHABLE_KEY
NEXT_PUBLIC_SITE_URL=https://pageflow.example.com
NEXT_PUBLIC_TURNSTILE_SITE_KEY=REPLACE_WITH_TURNSTILE_SITE_KEY
GOOGLE_BOOKS_API_KEY=REPLACE_WITH_SERVER_RESTRICTED_KEY
~~~

Set its permissions:

~~~bash
sudo chown root:pageflow /etc/pageflow/pageflow.env
sudo chmod 0640 /etc/pageflow/pageflow.env
~~~

The Supabase publishable key and Turnstile site key are intended for browser
use. The Google Books key is server-only in this application; restrict it in
Google Cloud to the Books API and, if practical, to this server. Never place a
service-role key, Supabase secret key, Google OAuth client secret, database
password, or AWS access key in this file.

### Create the systemd service

Create /etc/systemd/system/pageflow.service:

~~~ini
[Unit]
Description=PageFlow Next.js web application
After=network-online.target
Wants=network-online.target

[Service]
Type=simple
User=pageflow
Group=pageflow
WorkingDirectory=/opt/pageflow/current
EnvironmentFile=/etc/pageflow/pageflow.env
ExecStart=/usr/bin/node server.js
Restart=always
RestartSec=5
TimeoutStopSec=20
KillSignal=SIGTERM
NoNewPrivileges=true
PrivateTmp=true
ProtectHome=true
ProtectSystem=full
ReadWritePaths=/opt/pageflow

[Install]
WantedBy=multi-user.target
~~~

Then reload systemd:

~~~bash
sudo systemctl daemon-reload
sudo systemctl enable pageflow
~~~

The first start will fail until the initial release is deployed. That is
expected.

### Create the atomic deployment script

Create /usr/local/bin/pageflow-deploy:

~~~bash
#!/usr/bin/env bash
set -Eeuo pipefail

RELEASE_SHA="$1"
ARTIFACT_URI="$2"
APP_ROOT="/opt/pageflow"
RELEASE_DIR="$APP_ROOT/releases/$RELEASE_SHA"
ARCHIVE="/tmp/pageflow-$RELEASE_SHA.tar.gz"
PREVIOUS_RELEASE=""

if [[ ! "$RELEASE_SHA" =~ ^[0-9a-f]{40}$ ]]; then
  echo "Invalid commit SHA" >&2
  exit 2
fi

if [[ "$ARTIFACT_URI" != s3://*/releases/*/pageflow.tar.gz ]]; then
  echo "Unexpected artifact URI" >&2
  exit 2
fi

if [[ -L "$APP_ROOT/current" ]]; then
  PREVIOUS_RELEASE="$(readlink -f "$APP_ROOT/current")"
fi

rm -f "$ARCHIVE"
rm -rf "$RELEASE_DIR"
install -d -o pageflow -g pageflow "$RELEASE_DIR"

aws s3 cp "$ARTIFACT_URI" "$ARCHIVE" --only-show-errors
tar -xzf "$ARCHIVE" -C "$RELEASE_DIR"
chown -R pageflow:pageflow "$RELEASE_DIR"

ln -sfn "$RELEASE_DIR" "$APP_ROOT/current.next"
mv -Tf "$APP_ROOT/current.next" "$APP_ROOT/current"

systemctl restart pageflow
sleep 5

if ! curl --fail --silent --show-error --max-time 10 \
  http://127.0.0.1:3000/login >/dev/null; then
  echo "Health check failed; rolling back" >&2
  if [[ -n "$PREVIOUS_RELEASE" && -d "$PREVIOUS_RELEASE" ]]; then
    ln -sfn "$PREVIOUS_RELEASE" "$APP_ROOT/current.next"
    mv -Tf "$APP_ROOT/current.next" "$APP_ROOT/current"
    systemctl restart pageflow
  fi
  exit 1
fi

rm -f "$ARCHIVE"
echo "Deployed $RELEASE_SHA"
~~~

Set ownership and executable permissions:

~~~bash
sudo chown root:root /usr/local/bin/pageflow-deploy
sudo chmod 0755 /usr/local/bin/pageflow-deploy
~~~

## Phase 8: configure Nginx

Create /etc/nginx/sites-available/pageflow:

~~~nginx
server {
    listen 80;
    listen [::]:80;
    server_name pageflow.example.com;

    client_max_body_size 2m;

    location / {
        proxy_pass http://127.0.0.1:3000;
        proxy_http_version 1.1;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
        proxy_set_header Upgrade $http_upgrade;
        proxy_set_header Connection "upgrade";
        proxy_read_timeout 60s;
    }
}
~~~

Replace pageflow.example.com with the real hostname, then enable the site:

~~~bash
sudo ln -s /etc/nginx/sites-available/pageflow /etc/nginx/sites-enabled/pageflow
sudo rm -f /etc/nginx/sites-enabled/default
sudo nginx -t
sudo systemctl reload nginx
~~~

## Phase 9: create DNS and HTTPS

Create an A record for the hostname pointing to the Elastic IP. Wait for DNS to
resolve:

~~~bash
dig +short pageflow.example.com
~~~

Install Certbot and obtain a certificate:

~~~bash
sudo apt-get install -y certbot python3-certbot-nginx
sudo certbot --nginx -d pageflow.example.com --redirect
sudo certbot renew --dry-run
~~~

Do not enable the production Google or Supabase redirect URLs until HTTPS works.

## Phase 10: configure GitHub OIDC in AWS

GitHub OIDC gives Actions short-lived AWS credentials. Do not create an IAM user
or store AWS_ACCESS_KEY_ID and AWS_SECRET_ACCESS_KEY in GitHub.

GitHub documents the provider URL, audience, token permission, and trust-policy
conditions here:
[GitHub OIDC with AWS](https://docs.github.com/en/actions/how-tos/secure-your-work/security-harden-deployments/oidc-in-aws).

### Add the GitHub identity provider

In **IAM → Identity providers → Add provider**:

- Provider type: OpenID Connect
- Provider URL: https://token.actions.githubusercontent.com
- Audience: sts.amazonaws.com

### Create the GitHub deployment role

Create **PageFlowGitHubDeployRole** and set this trust policy. Replace
AWS_ACCOUNT_ID:

~~~json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "Federated": "arn:aws:iam::AWS_ACCOUNT_ID:oidc-provider/token.actions.githubusercontent.com"
      },
      "Action": "sts:AssumeRoleWithWebIdentity",
      "Condition": {
        "StringEquals": {
          "token.actions.githubusercontent.com:aud": "sts.amazonaws.com",
          "token.actions.githubusercontent.com:sub": "repo:mihir-patel-05/Booktracking:ref:refs/heads/codex/pageflow-web"
        }
      }
    }
  ]
}
~~~

This permits deployments only from codex/pageflow-web. When production moves to
main, replace the branch in the trust policy and workflow together.

GitHub repositories created after July 15, 2026, or repositories that opt into
immutable OIDC subjects can include immutable owner and repository IDs in the
sub claim. If AWS rejects the conventional subject, follow GitHub's current OIDC
reference and use the exact immutable subject for this repository.

Attach this permissions policy after replacing AWS_ACCOUNT_ID, REGION,
INSTANCE_ID, and BUCKET_NAME:

~~~json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Sid": "UploadRelease",
      "Effect": "Allow",
      "Action": [
        "s3:PutObject"
      ],
      "Resource": "arn:aws:s3:::BUCKET_NAME/releases/*"
    },
    {
      "Sid": "RunDeployment",
      "Effect": "Allow",
      "Action": [
        "ssm:SendCommand"
      ],
      "Resource": [
        "arn:aws:ssm:REGION::document/AWS-RunShellScript",
        "arn:aws:ec2:REGION:AWS_ACCOUNT_ID:instance/INSTANCE_ID"
      ]
    },
    {
      "Sid": "ReadDeploymentResult",
      "Effect": "Allow",
      "Action": [
        "ssm:GetCommandInvocation",
        "ssm:ListCommandInvocations"
      ],
      "Resource": "*"
    }
  ]
}
~~~

## Phase 11: create GitHub repository variables

In GitHub open:

**Booktracking → Settings → Secrets and variables → Actions → Variables**

Create:

| Variable | Value |
| --- | --- |
| AWS_REGION | ca-central-1 |
| AWS_ACCOUNT_ID | the 12-digit AWS account ID |
| AWS_DEPLOY_ROLE_ARN | arn:aws:iam::ACCOUNT_ID:role/PageFlowGitHubDeployRole |
| EC2_INSTANCE_ID | the EC2 instance ID |
| DEPLOY_BUCKET | the private deployment bucket |
| SITE_URL | https://pageflow.example.com |
| NEXT_PUBLIC_SUPABASE_URL | https://shjvfdbzefejhyjhlvqw.supabase.co |
| NEXT_PUBLIC_SUPABASE_PUBLISHABLE_KEY | the modern Supabase publishable key |
| NEXT_PUBLIC_TURNSTILE_SITE_KEY | the public Turnstile site key |

These values are identifiers or browser-public configuration. Do not add a
Google secret, Supabase secret/service-role key, database password, or permanent
AWS credential.

## Phase 12: add the CI workflow

Create .github/workflows/web-ci.yml:

~~~yaml
name: Web CI

on:
  pull_request:
    paths:
      - "web/**"
      - ".github/workflows/web-ci.yml"
  push:
    branches:
      - codex/pageflow-web
    paths:
      - "web/**"
      - ".github/workflows/web-ci.yml"

permissions:
  contents: read

concurrency:
  group: web-ci-${{ github.ref }}
  cancel-in-progress: true

jobs:
  test:
    runs-on: ubuntu-24.04
    timeout-minutes: 30
    defaults:
      run:
        working-directory: web

    steps:
      - name: Check out repository
        uses: actions/checkout@v7
        with:
          persist-credentials: false

      - name: Set up Node.js
        uses: actions/setup-node@v7
        with:
          node-version: 22
          cache: npm
          cache-dependency-path: web/package-lock.json

      - name: Install dependencies
        run: npm ci

      - name: Lint
        run: npm run lint

      - name: Unit tests
        run: npm test

      - name: Install WebKit
        run: npx playwright install --with-deps webkit

      - name: Browser acceptance tests
        run: npm run test:e2e

      - name: Production build
        run: npm run build
~~~

GitHub's current official examples use actions/checkout@v7 and
actions/setup-node@v7. Before public launch, pin all actions to reviewed full
commit SHAs and configure Dependabot to propose action updates.

## Phase 13: add the EC2 deployment workflow

Create .github/workflows/web-deploy-ec2.yml:

~~~yaml
name: Deploy web to EC2

on:
  workflow_dispatch:
  push:
    branches:
      - codex/pageflow-web
    paths:
      - "web/**"
      - ".github/workflows/web-deploy-ec2.yml"

permissions:
  contents: read
  id-token: write

concurrency:
  group: pageflow-production
  cancel-in-progress: false

jobs:
  build-and-deploy:
    runs-on: ubuntu-24.04
    timeout-minutes: 35
    env:
      AWS_REGION: ${{ vars.AWS_REGION }}
      DEPLOY_BUCKET: ${{ vars.DEPLOY_BUCKET }}
      NEXT_PUBLIC_SUPABASE_URL: ${{ vars.NEXT_PUBLIC_SUPABASE_URL }}
      NEXT_PUBLIC_SUPABASE_PUBLISHABLE_KEY: ${{ vars.NEXT_PUBLIC_SUPABASE_PUBLISHABLE_KEY }}
      NEXT_PUBLIC_SITE_URL: ${{ vars.SITE_URL }}
      NEXT_PUBLIC_TURNSTILE_SITE_KEY: ${{ vars.NEXT_PUBLIC_TURNSTILE_SITE_KEY }}

    steps:
      - name: Check out repository
        uses: actions/checkout@v7
        with:
          persist-credentials: false

      - name: Set up Node.js
        uses: actions/setup-node@v7
        with:
          node-version: 22
          cache: npm
          cache-dependency-path: web/package-lock.json

      - name: Install dependencies
        working-directory: web
        run: npm ci

      - name: Lint
        working-directory: web
        run: npm run lint

      - name: Unit tests
        working-directory: web
        run: npm test

      - name: Install WebKit
        working-directory: web
        run: npx playwright install --with-deps webkit

      - name: Browser acceptance tests
        working-directory: web
        run: npm run test:e2e

      - name: Build standalone application
        working-directory: web
        run: npm run build

      - name: Package release
        working-directory: web
        run: |
          set -Eeuo pipefail
          rm -rf release
          mkdir -p release/.next/static
          cp -a .next/standalone/. release/
          cp -a .next/static/. release/.next/static/
          if [[ -d public ]]; then cp -a public release/public; fi
          tar -C release -czf "../pageflow-${GITHUB_SHA}.tar.gz" .

      - name: Configure short-lived AWS credentials
        uses: aws-actions/configure-aws-credentials@v6.2.3
        with:
          role-to-assume: ${{ vars.AWS_DEPLOY_ROLE_ARN }}
          role-session-name: pageflow-${{ github.run_id }}
          aws-region: ${{ vars.AWS_REGION }}
          allowed-account-ids: ${{ vars.AWS_ACCOUNT_ID }}

      - name: Upload immutable release
        run: |
          set -Eeuo pipefail
          ARTIFACT_URI="s3://$DEPLOY_BUCKET/releases/$GITHUB_SHA/pageflow.tar.gz"
          aws s3 cp "pageflow-$GITHUB_SHA.tar.gz" "$ARTIFACT_URI" --only-show-errors
          echo "ARTIFACT_URI=$ARTIFACT_URI" >> "$GITHUB_ENV"

      - name: Deploy through Systems Manager
        env:
          INSTANCE_ID: ${{ vars.EC2_INSTANCE_ID }}
        run: |
          set -Eeuo pipefail
          COMMAND_ID="$(aws ssm send-command \
            --document-name AWS-RunShellScript \
            --instance-ids "$INSTANCE_ID" \
            --comment "Deploy PageFlow $GITHUB_SHA" \
            --parameters "commands=[\"sudo /usr/local/bin/pageflow-deploy '$GITHUB_SHA' '$ARTIFACT_URI'\"]" \
            --query "Command.CommandId" \
            --output text)"

          if ! aws ssm wait command-executed \
              --command-id "$COMMAND_ID" \
              --instance-id "$INSTANCE_ID"; then
            aws ssm get-command-invocation \
              --command-id "$COMMAND_ID" \
              --instance-id "$INSTANCE_ID" \
              --query '{Status:Status,Output:StandardOutputContent,Error:StandardErrorContent}'
            exit 1
          fi

          aws ssm get-command-invocation \
            --command-id "$COMMAND_ID" \
            --instance-id "$INSTANCE_ID" \
            --query '{Status:Status,Output:StandardOutputContent,Error:StandardErrorContent}'

      - name: Public HTTPS smoke test
        env:
          SITE_URL: ${{ vars.SITE_URL }}
        run: curl --fail --show-error --silent --max-time 20 "$SITE_URL/login" >/dev/null
~~~

The workflow intentionally does not use pull_request_target and never deploys
untrusted pull-request code.

## Phase 14: make the first deployment

1. Commit the standalone setting and both workflow files.
2. Push to codex/pageflow-web.
3. Open GitHub → Actions → Web CI and confirm every job passes.
4. Open GitHub → Actions → Deploy web to EC2.
5. Choose **Run workflow** for the first deployment.
6. Confirm the S3 artifact exists under releases/COMMIT_SHA/.
7. Confirm the Systems Manager command reports Success.
8. Confirm the application service:

~~~bash
sudo systemctl status pageflow --no-pager
sudo journalctl -u pageflow -n 100 --no-pager
curl -I http://127.0.0.1:3000/login
curl -I https://pageflow.example.com/login
~~~

## Phase 15: update Supabase, Google OAuth, and Turnstile

After the production HTTPS URL works:

### Supabase

In **Authentication → URL Configuration**:

- Site URL: https://pageflow.example.com
- Redirect allowlist: https://pageflow.example.com/auth/callback

Keep localhost only if local development still requires it.

### Google Cloud

In the PageFlow OAuth web client:

- Authorized JavaScript origin: https://pageflow.example.com
- Google authorized redirect URI remains:
  https://shjvfdbzefejhyjhlvqw.supabase.co/auth/v1/callback

Do not replace the Supabase callback with the PageFlow callback.

### Cloudflare Turnstile

Add pageflow.example.com to the Turnstile widget's allowed hostnames. Keep the
Turnstile secret in Supabase Auth's CAPTCHA configuration; do not put it in the
browser bundle, GitHub variables, or the EC2 environment file. Only the public
site key belongs in NEXT_PUBLIC_TURNSTILE_SITE_KEY.

### Amazon SES

No EC2 email credential is required. Supabase Auth continues to send email
through the custom SMTP configuration already configured in Supabase.

## Rollback

List releases:

~~~bash
sudo find /opt/pageflow/releases -mindepth 1 -maxdepth 1 -type d -printf '%f\n'
readlink -f /opt/pageflow/current
~~~

Switch to a known-good release:

~~~bash
GOOD_SHA=REPLACE_WITH_KNOWN_GOOD_COMMIT
sudo ln -sfn "/opt/pageflow/releases/$GOOD_SHA" /opt/pageflow/current.next
sudo mv -Tf /opt/pageflow/current.next /opt/pageflow/current
sudo systemctl restart pageflow
curl --fail http://127.0.0.1:3000/login >/dev/null
~~~

Do not delete the previous release until the new release has passed the local
and public smoke tests.

## Troubleshooting

### GitHub OIDC says Not authorized to perform AssumeRoleWithWebIdentity

- Confirm id-token: write is present.
- Confirm the role ARN and AWS account are correct.
- Confirm the trust policy branch exactly matches codex/pageflow-web.
- If a GitHub Environment is added, the subject changes to
  repo:mihir-patel-05/Booktracking:environment:ENVIRONMENT_NAME.
- Check whether immutable owner/repository IDs are required for the OIDC subject.

### The EC2 instance does not appear in Systems Manager

- Confirm the instance profile is attached.
- Confirm AmazonSSMManagedInstanceCore is attached.
- Confirm SSM Agent is active.
- Confirm outbound TCP 443 and DNS work.
- Confirm the instance and Systems Manager console are in the same region.

### systemd reports node not found

Run command -v node and update ExecStart in pageflow.service to that absolute
path. Then run:

~~~bash
sudo systemctl daemon-reload
sudo systemctl restart pageflow
~~~

### Next.js starts but returns configuration errors

Confirm both NEXT_PUBLIC_SUPABASE values existed during the GitHub build and in
/etc/pageflow/pageflow.env. NEXT_PUBLIC values are compiled into browser code
during next build.

### Nginx returns 502

~~~bash
sudo systemctl status pageflow --no-pager
sudo journalctl -u pageflow -n 200 --no-pager
sudo tail -n 200 /var/log/nginx/error.log
curl -v http://127.0.0.1:3000/login
~~~

### Deployment fails after switching the symlink

The deployment script automatically returns to the previous release if the
local login-page health check fails. Inspect the Systems Manager command output
and the systemd journal before retrying.

## Production hardening checklist

- [ ] EC2 requires IMDSv2.
- [ ] No inbound SSH rule exists.
- [ ] Only ports 80 and 443 are public.
- [ ] S3 Block Public Access and versioning are enabled.
- [ ] GitHub uses OIDC, not permanent AWS keys.
- [ ] OIDC trust is restricted to this repository and deployment branch.
- [ ] GitHub Actions are pinned to reviewed commit SHAs.
- [ ] GitHub production environment has required reviewers.
- [ ] Automatic Ubuntu security updates are enabled and monitored.
- [ ] CloudWatch alarms cover CPU, disk, status checks, and application errors.
- [ ] AWS Budgets alerts are enabled.
- [ ] EC2 and EBS are backed up with AWS Backup or scheduled AMIs.
- [ ] Supabase security and performance advisors remain clean.
- [ ] Google OAuth, email verification, password recovery, and deletion are
      tested on the HTTPS domain.
- [ ] A rollback has been performed successfully at least once.

## Recommended next infrastructure upgrade

Before PageFlow becomes business-critical:

1. Build an immutable AMI instead of modifying a long-lived instance.
2. Run at least two instances in an Auto Scaling group.
3. Terminate TLS at an Application Load Balancer with an ACM certificate.
4. Add target-group health checks and rolling deployments.
5. Add AWS WAF and centralized CloudWatch logs if the risk and traffic justify
   the additional cost.

EC2 means the operating system, packages, Node runtime, Nginx, TLS renewal,
monitoring, scaling, and incident response are now PageFlow's responsibility.
Keep the managed Supabase database and Auth architecture unchanged.
