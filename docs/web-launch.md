# PageFlow web launch runbook

PageFlow web is an iPhone-first Next.js 15 application in `web/`. MacBook browsers receive the secondary wide layout. The Swift projects remain legacy references and are not part of the web build.

## Data architecture

The legacy native checkout uses SwiftData for local persistence and Firebase Firestore/Auth for remote data. The web application does not read or migrate either system. It uses a fresh Supabase project for all authentication and persistent application data.

The committed Supabase migrations create `profiles`, `books`, `reading_sessions`, `session_notes`, `quotes`, `reading_plans`, `streak_freezes`, and `user_stats`. Every exposed table has RLS, explicit authenticated grants, anonymous revocation, and ownership predicates. Composite foreign keys prevent a record from referencing another user's book or session. `finalize_reading_session` is a security-invoker RPC that calculates XP and refreshes streak/stat caches in the database.

## Local verification

Requirements: Node 22, npm, Docker Desktop, and Supabase CLI.

```sh
supabase start
supabase test db
cd web
cp .env.example .env.local
npm ci
npm test
npm run lint
npm run build
npm run test:e2e
```

Regenerate database types after any schema change:

```sh
supabase gen types typescript --local --schema public
```

Replace `web/src/lib/database.types.ts` with that output and run the full suite. Browser artifacts stay under `web/output/playwright/` and are ignored by Git.

## Create and connect Supabase

1. Create a new project named exactly `PageFlow` in `us-east-2`. Do not paste its database password or secret/service-role key into chat or frontend configuration.
2. Confirm the project reference through the connected Supabase plugin before any mutation.
3. Inspect tables, migrations, extensions, Auth settings, API URL, and active publishable keys read-only.
4. Apply each file in `supabase/migrations/` once, in timestamp order, using the migration API. Do not replay a migration under a different name.
5. Deploy `supabase/functions/delete-account/index.ts` with JWT verification enabled.
6. Generate types from the remote project and compare them with `web/src/lib/database.types.ts`.
7. Run both Supabase security and performance advisors. Resolve actionable findings before connecting a public deployment.

Use separate Supabase projects for preview/non-production and production. Repeat the migration and advisor sequence for each project; never point a preview branch at production data.

## Configure Supabase Auth

In Supabase Auth:

- Require verified email signup and a 12-character password with uppercase, lowercase, number, and symbol.
- Enable secure password changes and disable anonymous sign-in.
- Enable Google with a web OAuth client. Google’s authorized redirect URI is `https://<project-ref>.supabase.co/auth/v1/callback`.
- Set the production Site URL to the final HTTPS domain. Add the Amplify preview and production URLs ending in `/auth/callback` to allowed redirect URLs.
- Enable Cloudflare Turnstile and set its secret in Supabase. Put only the matching public site key in Amplify.
- Configure Amazon SES custom SMTP in `us-east-2` with a verified sender/domain. Use the SES SMTP credential, not an AWS access key, and complete SES production-access approval before launch.
- Customize verification and recovery templates, then exercise both links on iPhone Safari.

`supabase/config.toml` mirrors the local password and verification policy; it does not automatically change hosted Auth settings.

## AWS Amplify Hosting

1. Connect the GitHub repository to AWS Amplify and select `codex/pageflow-web` for the preview deployment.
2. Amplify reads the root `amplify.yml`, installs Node 22, runs `npm ci`, unit tests, and the production build with `web/` as the monorepo app root.
3. Configure these environment variables per Amplify branch:

   - `NEXT_PUBLIC_SUPABASE_URL`
   - `NEXT_PUBLIC_SUPABASE_PUBLISHABLE_KEY`
   - `NEXT_PUBLIC_SITE_URL`
   - `NEXT_PUBLIC_TURNSTILE_SITE_KEY`
   - `GOOGLE_BOOKS_API_KEY` (optional, server-side)

4. Never add a Supabase secret/service-role key, database password, SES secret, or OAuth client secret to Amplify’s public app environment.
5. Attach the production custom domain, require HTTPS, and update Supabase and Google redirect allowlists to the exact final URLs.
6. Keep preview branch variables connected to the non-production Supabase project.

The application sends CSP, HSTS, nosniff, referrer, and permissions-policy headers. Authenticated pages, Auth callbacks, and JSON exports use private no-store caching.

## Launch acceptance

- Validate signup verification, Google OAuth, failed login, recovery, password change, cookie refresh, redirects, logout, export, and permanent deletion.
- Run the RLS test suite with two users and rerun both Supabase advisors.
- Exercise library CRUD/search, progress, timer pause/refresh/resume/early completion, journal restoration and all optional combinations, notes, quotes, PNG sharing, XP, streaks/freezes, and deletion-driven stat recalculation.
- Run WebKit at 375×812, 390×844, and 430×932, then verify the same flows on a real iPhone in Safari. Run secondary checks at 1280×800 and 1440×900.
- Confirm browser-closed push delivery and full offline synchronization remain disabled for this release.

## Current remote status

At implementation time, the connected Supabase account did not contain a project named `PageFlow`; only unrelated projects were visible. No remote database was modified. Remote migration, Edge Function deployment, hosted Auth/SMTP/OAuth configuration, generated remote types, and advisor remediation must wait until `PageFlow` appears through the connector.
