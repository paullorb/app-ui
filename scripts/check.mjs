import { readFile } from "node:fs/promises";

const files = [
  "styles/tokens.css",
  "styles/base.css",
  "styles/primitives.css",
];
const forbidden = [
  "--muk-",
  ".event-",
  ".login-",
  ".checkin-",
  ".staffing-",
];

for (const file of files) {
  const source = await readFile(new URL(`../${file}`, import.meta.url), "utf8");
  for (const marker of forbidden) {
    if (source.includes(marker)) {
      throw new Error(`${file} contains product-specific marker ${marker}`);
    }
  }
}

const primitives = await readFile(
  new URL("../styles/primitives.css", import.meta.url),
  "utf8",
);
for (const selector of [".ui-panel", ".ui-surface", ".ui-button", ".ui-pill"]) {
  if (!primitives.includes(selector)) {
    throw new Error(`missing shared primitive ${selector}`);
  }
}

console.log("Shared UI boundary is product-neutral.");
