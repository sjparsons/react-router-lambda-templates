import * as fsp from "node:fs/promises";

await fsp.rename("build/server/index.js", "build/server/index.mjs");
