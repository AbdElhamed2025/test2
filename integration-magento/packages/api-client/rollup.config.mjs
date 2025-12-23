import {
  generateBaseConfig,
  generateServerConfig,
} from "@vue-storefront/rollup-config";
import { createRequire } from "node:module";

const require = createRequire(import.meta.url);
const package_ = require("./package.json");

export default [generateBaseConfig(package_), generateServerConfig(package_)];
