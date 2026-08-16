import { defineConfig } from "@playwright/test";

const viewports = [
  { name: "iphone-375", viewport: { width: 375, height: 812 }, browserName: "webkit" as const },
  { name: "iphone-390", viewport: { width: 390, height: 844 }, browserName: "webkit" as const },
  { name: "iphone-430", viewport: { width: 430, height: 932 }, browserName: "webkit" as const },
  { name: "macbook-1280", viewport: { width: 1280, height: 800 }, browserName: "webkit" as const },
  { name: "macbook-1440", viewport: { width: 1440, height: 900 }, browserName: "webkit" as const },
];

export default defineConfig({
  testDir: "./e2e",
  outputDir: "./output/playwright/results",
  reporter: [["list"], ["html", { outputFolder: "output/playwright/report", open: "never" }]],
  use: { baseURL: "http://127.0.0.1:3100", trace: "retain-on-failure", screenshot: "only-on-failure" },
  projects: viewports.map(({ name, ...use }) => ({ name, use })),
  webServer: { command: "npm run dev -- --hostname 127.0.0.1 --port 3100", url: "http://127.0.0.1:3100", reuseExistingServer: !process.env.CI, timeout: 120_000 },
});
