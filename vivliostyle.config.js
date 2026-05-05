// @ts-check
import { defineConfig, VFM } from "@vivliostyle/cli";

export default defineConfig({
  title: "vivliostyle-preview-in-container",
  author: "u1f992",
  language: "ja",
  theme: "./theme",
  entry: ["public/vivliostyle-preview-in-container.md"],
  vfm: {
    footnote: "gcpm",
  },
  // Qiitaの記事としてはtitleがh1相当
  documentProcessor: (opts, meta) =>
    VFM(opts, meta).use(() => (node) => {
      const tree = /** @type {import("hast").Root} */ (node);
      const html = tree.children.find(
        (n) => n.type === "element" && n.tagName === "html",
      );
      if (html?.type !== "element") return;
      const head = html.children.find(
        (n) => n.type === "element" && n.tagName === "head",
      );
      const body = html.children.find(
        (n) => n.type === "element" && n.tagName === "body",
      );
      if (head?.type !== "element" || body?.type !== "element") return;
      const title = head.children.find(
        (n) => n.type === "element" && n.tagName === "title",
      );
      if (title?.type !== "element") return;
      body.children = [
        {
          type: "element",
          tagName: "section",
          properties: { className: ["level1"] },
          children: [
            {
              type: "element",
              tagName: "h1",
              properties: {},
              children: title.children,
            },
            ...body.children,
          ],
        },
      ];
    }),
});
