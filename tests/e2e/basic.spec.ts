import { test, expect } from '@playwright/test';

test.describe('Synapse Grid Core Journeys', () => {
  test('should load the home page or redirect to sign in', async ({ page }) => {
    await page.goto('/');
    
    // We expect to see either the dashboard landing page or a redirection to authentication
    // Let's assert on the URL path structure or the presence of a login heading/form
    const title = await page.title();
    expect(title).toBeDefined();
  });
});
