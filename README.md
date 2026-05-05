## プレビュー／ビルド

`npm run`をDockerコマンドのショートハンドとして利用しています。Docker内で都度`npm ci`を実行しLinux用のnode_modulesを構築するため、ホストでは`npm ci`を行わないでください。通常の`vivliostyle preview`とは異なり、ホスト側のブラウザを閉じてもプレビューは終了しません。Ctrl+Cで終了してください。

```shellsession
$ npm run preview  # http://localhost:14500/vnc.html?resize=remote&autoconnect=true
$ npm run build
```

これらは単なるショートハンドであり実際にはNode.jsを使用していないので、直接Dockerコマンドを実行する運用なら、ホスト側にはNode.jsのインストールすら不要です。

```shellsession
$ docker run --rm --volume .:/workdir --workdir /workdir --user root --entrypoint bash --tty ghcr.io/vivliostyle/cli:10.5.0 scripts/build.sh
$ docker run --rm --volume .:/workdir --workdir /workdir --user root --entrypoint bash --tty --interactive --publish 14500:14500 ghcr.io/vivliostyle/cli:10.5.0 scripts/preview.sh
```

## メモ

プレビュー起動にはかなり時間がかかる。先にコンテナイメージをビルドしておく運用にすればよいのだが、共同作業者がコンテナイメージの管理を行えるか定かでない場合を考慮し、コマンド一発であることを重視している。

---

ビルドには`--tty`は不要だが、つけないとメッセージの色が消えてプレビューと不揃いになり見栄えがよくない。

---

クロスプラットフォームのタスクランナーの選定は難しい。Vivliostyleを使おうとする人ならNode.jsは入っているだろう。

---

[Qiita CLI](https://github.com/increments/qiita-cli)は、アカウントごとに1リポジトリで管理するという思想のようだ（`npx qiita preview`実行時に既存の記事の原稿が`public/`にダウンロードされる）。このリポジトリでは1記事のために1リポジトリを切りたい。

- 原稿名はリポジトリ名と同一とする。GitHubでリポジトリ名は一意だから、この規則なら将来的に別のリポジトリで同じことをする際にファイル名が競合することはないはず。
- [public/.gitignore](./public/.gitignore)で、このリポジトリの原稿以外を無視する。
