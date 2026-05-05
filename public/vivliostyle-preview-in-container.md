---
title: vivliostyle-preview-in-container
tags:
  - ''
private: false
updated_at: ''
id: null
organization_url_name: null
slide: false
ignorePublish: true
---

Vivliostyleの組版処理はクライアントサイドJavaScriptであり、Webブラウザを動作させるOSの影響を受けます。実際に以下のような差が発生すると報告されています。これらは個別にはChromiumのバグやフォントファイルの不具合と言えるものですが、Webブラウザの組版処理にOSごとの分岐が存在することが伝われば十分です。

> Chromiumブラウザの場合、テキストのレンダリングがOSによって異なり、特にLinux環境では、テキストノードの境界ごとに幅がわずかに増加する現象があります。 — [vivliostyle/vivliostyle.js#1590](https://github.com/vivliostyle/vivliostyle.js/issues/1590)

> `OS/2.fsSelection`の[`USE_TYPO_METRICS`](https://learn.microsoft.com/en-us/typography/opentype/spec/os2#fsselection)ビット（bit 7）が立っているフォントは全プラットフォームが`sTypo*`を使用しますが、立っていない場合のフォールバック先がプラットフォームごとに分かれます。 — [Webページで一部フォントの位置がOS依存になる問題に対処する #CSS - Qiita](https://qiita.com/u1f992/items/2cfaa722072276f20452)

したがって、共同作業者の環境を統一することが現実的でない場合に全員の手元で同じPDFを出力するには、Vivliostyleやブラウザのバージョン固定では不十分です。また一人で制作する場合にも、将来再度作業する際に元と同じ環境を用意できるとは限りません。同人誌ならともかく、商業出版物のようなシビアな用途で組版の再現性を確保するためには、少なくともビルドにはコンテナを用いる必要があります[^hardware][^resources]。

[^hardware]: 素朴に考えれば組版に関わる処理はコンテナで固定できるユーザー空間に収まるはずですが、理論上はカーネルやCPUアーキテクチャによる差異があるかもしれません。厳密な回答としては、すべてのハードウェアをソフトウェアエミュレーションして固定する必要があります。ここではそこまでは考えていません。

[^resources]: 「すべてのリソースをリポジトリにコピーして、リモートリソースを参照しない」などは再現性以前の問題です。なおここには再配布が可能なフォント≒オープンソースのフォントだけが使用できるという前提があります。GitHubなどソースコードを公開するためのプラットフォーム上で、オープンソースの組版ソフトを用いて制作するなら、当然リソースもオープンソースに寄せなければ歪みが発生するというのが予てからの筆者の主張です。

ところで、Vivliostyleにはライブプレビュー機能があります。DevToolsでCSSの効果をインタラクティブに確認しながらスタイルを作成したり、ページに内容を収めるために文章や図版の調整を探ることが可能であり、これはTeX系では弱いVivliostyleの利点のひとつです。

しかしビルドにコンテナを用いる場合、プレビューもコンテナ内のブラウザの出力を確認したいということになります。これは少し面倒です。ホストがLinuxだけならX11転送でよいのですが、MacではXQuartzなどのセットアップが必要です[^wslg][^complexity]。そこで、ホスト側からWebページとしてコンテナ内のブラウザを確認できるセットアップを考案し、直近の制作に投入しました。

[^wslg]: 十分新しいWindowsではWSLgがうまくやります。Dockerの導入の前提としてセットアップされているはずなので、VcXsrvなどは不要です。意外にもMacより簡単に済みそうです。

[^complexity]: Dockerを導入している時点で十分複雑であり、Xサーバーのインストールが今さら何だという異論はあると思います。

https://github.com/u1f992/vivliostyle-preview-in-container
