import { expect, Page } from "@playwright/test";
import getPort from "get-port";

import {
  matchLine,
  testTemplate,
  urlRegex,
  withoutHmrPortError,
} from "./utils";

const test = testTemplate("basic-lambda");

test("typecheck", async ({ $ }) => {
  await $(`npm run typecheck`);
});

test("dev", async ({ page, $ }) => {
  const port = await getPort();
  const dev = $(`npm run dev -- --port ${String(port)}`);

  const url = await matchLine(dev.stdout, urlRegex.viteDev);
  await workflow({ page, url });
  expect(withoutHmrPortError(dev.buffer.stderr)).toBe("");
});

test("build", async ({ $ }) => {
  await $(`npm run build`);
});

async function workflow({ page, url }: { page: Page; url: string }) {
  await page.goto(url);
  await expect(page).toHaveTitle(/New React Router App/);
  await page.getByRole("link", { name: "React Router Docs" }).waitFor();
  await page.getByRole("link", { name: "Join Discord" }).waitFor();
  expect(page.errors).toStrictEqual([]);
}
