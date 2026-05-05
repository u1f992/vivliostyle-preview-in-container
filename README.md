## メモ

[Qiita CLI](https://github.com/increments/qiita-cli)は、アカウントごとに1リポジトリで管理するという思想のようだ（`npx qiita preview`実行時に既存の記事の原稿が`public/`にダウンロードされる）。このリポジトリでは1記事のために1リポジトリを切りたい。

- 原稿名はリポジトリ名と同一とする。GitHubでリポジトリ名は一意だから、この規則なら将来的に別のリポジトリで同じことをする際にファイル名が競合することはないはず。
- [public/.gitignore](./public/.gitignore)で、このリポジトリの原稿以外を無視する。
