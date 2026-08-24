import { expect, test } from "@playwright/test";

test("landing and authentication remain usable at the target viewport", async ({ page }) => {
  await page.goto("/");
  await expect(page.getByRole("heading", { name: /keep the account/i })).toBeVisible();
  await page.getByRole("link", { name: /open an account/i }).first().click();
  await expect(page).toHaveURL(/\/signup$/);
  await expect(page.getByRole("button", { name: /create account/i })).toBeVisible();
  await expect(page.getByRole("button", { name: /continue with google/i })).toBeVisible();
  await expect(page.locator("body")).not.toHaveCSS("overflow-x", "scroll");
});

test("protected pages redirect to authentication without configuration", async ({ page }) => {
  await page.goto("/app");
  await expect(page).toHaveURL(/\/login\?error=configuration/);
  await expect(page.getByRole("heading", { name: /^sign in$/i })).toBeVisible();
});

test("the reading diary is behind authentication too", async ({ page }) => {
  await page.goto("/app/calendar?month=2026-08");
  await expect(page).toHaveURL(/\/login\?error=configuration/);
});
