import { createRequestHandler } from "react-router-lambda-adapter";
// @ts-ignore
import * as build from "virtual:react-router/server-build";

export const handler = createRequestHandler({
  build,
  getLoadContext: async () => ({}),
});
