const { test, expect } = require("@playwright/test");

async function prepare(page) {
  await page.addInitScript(() => {
    window.entranceEvents = [];
    for (const type of ["preloader:reveal", "preloader:complete"]) {
      document.addEventListener(type, () => window.entranceEvents.push(type));
    }
    const original = HTMLCanvasElement.prototype.getContext;
    HTMLCanvasElement.prototype.getContext = function (kind, options) {
      return original.call(this, kind, kind === "webgl" ? { ...options, failIfMajorPerformanceCaveat: false } : options);
    };
  });
}

async function checkCanvas(page, budget) {
  const metrics = await page.evaluate(() => {
    const canvas = document.querySelector("canvas.paper-burn");
    if (!canvas) return null;
    const box = canvas.getBoundingClientRect();
    return { width: canvas.width, height: canvas.height, cssWidth: box.width, cssHeight: box.height };
  });
  expect(metrics).not.toBeNull();
  expect(metrics.width * metrics.height).toBeLessThanOrEqual(budget);
  expect(Math.abs(metrics.width / metrics.height - metrics.cssWidth / metrics.cssHeight)).toBeLessThan(0.015);
  return metrics;
}

const screens = [
  { name: "small phone", width: 320, height: 568, scale: 2, touch: true },
  { name: "phone", width: 390, height: 844, scale: 3, touch: true },
  { name: "small phone landscape", width: 568, height: 320, scale: 2, touch: true },
  { name: "phone landscape", width: 844, height: 390, scale: 3, touch: true },
  { name: "tablet", width: 768, height: 1024, scale: 2, touch: true },
  { name: "tablet landscape", width: 1024, height: 768, scale: 2, touch: true },
  { name: "desktop", width: 1440, height: 900, scale: 1, touch: false },
  { name: "large desktop", width: 1920, height: 1080, scale: 2, touch: false },
];

for (const screen of screens) {
  test.describe(screen.name, () => {
    test.use({ viewport: { width: screen.width, height: screen.height }, deviceScaleFactor: screen.scale, isMobile: screen.touch, hasTouch: screen.touch });

    test("a fresh slow visit burns and reveals the hero", async ({ page }) => {
      await prepare(page);
      const errors = [];
      page.on("pageerror", error => errors.push(error.message));
      // The entrance must work with no cached scripts and a late portrait at every breakpoint.
      await page.route(/\/assets\/.*\.js(?:\?.*)?$/, route => route.abort());
      let release;
      const held = new Promise(resolve => { release = resolve; });
      await page.route(/\/media\//, async route => {
        await held;
        await route.continue();
      });
      await page.goto("/", { waitUntil: "commit" });
      await expect(page.locator(".preloader")).toBeVisible();
      await expect(page.locator('[data-preloader-target="count"]')).toHaveAttribute("data-value", "99", { timeout: 5000 });
      const layout = await page.evaluate(() => {
        const count = document.querySelector('[data-preloader-target="count"]').getBoundingClientRect();
        const portrait = document.querySelector(".hero-portrait").getBoundingClientRect();
        return {
          fits: count.left >= 0 && count.right <= innerWidth && count.top >= 0 && count.bottom <= innerHeight,
          noOverflow: document.documentElement.scrollWidth <= innerWidth,
          faceVisible: portrait.top + portrait.height * 0.22 < innerHeight,
        };
      });
      expect(layout).toEqual({ fits: true, noOverflow: true, faceVisible: true });
      release();
      await expect(page.locator(".preloader")).toHaveClass(/is-burning/);
      await expect(page.locator(".preloader")).not.toHaveClass(/is-wiping/);
      await checkCanvas(page, screen.touch ? 400_000 : 1_000_000);
      await expect.poll(() => page.locator(".hero-char").first().evaluate(element => element.getAnimations().length)).toBeGreaterThan(0);
      await page.screenshot({ path: `test-results/entrance-${screen.width}x${screen.height}.png` });
      await expect(page.locator(".preloader")).toHaveCount(0, { timeout: 8000 });
      expect(await page.evaluate(() => window.entranceEvents)).toEqual(["preloader:reveal", "preloader:complete"]);
      expect(errors).toEqual([]);
    });
  });
}

for (const [start, end] of [
  [{ width: 390, height: 844 }, { width: 844, height: 390 }],
  [{ width: 1024, height: 768 }, { width: 768, height: 1024 }],
]) {
  test.describe(`rotation from ${start.width}x${start.height}`, () => {
    test.use({ viewport: start, deviceScaleFactor: 3, isMobile: true, hasTouch: true });
    test("resizes the active burn without a wipe or duplicate reveal", async ({ page }) => {
      await prepare(page);
      await page.goto("/", { waitUntil: "domcontentloaded" });
      await expect(page.locator(".preloader")).toHaveClass(/is-burning/);
      const before = await checkCanvas(page, 400_000);
      await page.setViewportSize(end);
      await expect.poll(() => page.evaluate(previousWidth => {
        const canvas = document.querySelector("canvas.paper-burn");
        return Boolean(canvas && canvas.width !== previousWidth);
      }, before.width)).toBe(true);
      await checkCanvas(page, 400_000);
      await expect(page.locator(".preloader")).toHaveClass(/is-burning/);
      await expect(page.locator(".preloader")).not.toHaveClass(/is-wiping/);
      await expect(page.locator(".preloader")).toHaveCount(0, { timeout: 8000 });
      expect(await page.evaluate(() => window.entranceEvents)).toEqual(["preloader:reveal", "preloader:complete"]);
      expect(await page.evaluate(() => document.documentElement.scrollWidth <= innerWidth)).toBe(true);
    });
  });
}
