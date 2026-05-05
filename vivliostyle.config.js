// @ts-check
import { defineConfig } from "@vivliostyle/cli";

export default defineConfig({
  title: "vivliostyle-preview-in-container",
  author: "u1f992",
  language: "ja",
  theme: "./theme",
  entry: ["public/manuscript.md"],
  vfm: {
    footnote: "gcpm",
  },
});
