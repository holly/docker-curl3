# CLAUDE.md

このファイルは、このリポジトリで作業するときにClaude Code（claude.ai/code）にガイダンスを提供します。

## プロジェクト概要

**docker-curl3** は、Dockerマルチステージビルドを使用してHTTP/3対応のcurlをビルドするプロジェクトです。curl + OpenSSL（QUIC）、ngtcp2、nghttp2、nghttp3を最小限のランタイムイメージにコンパイルします。

## テックスタック

- **ビルド**: Docker、Dockerfile、autoconf、bash
- **コア依存**: OpenSSL（QUIC対応）、ngtcp2、nghttp2、nghttp3
- **プロトコル**: HTTP/3、HTTP/2、HTTP/1.1、FTP
- **追加機能**: brotli圧縮、zlib、HSTS、AltSvc、Unixソケット

## クイックスタート

```bash
./build.sh              # Dockerイメージをビルド
./run.sh --version      # コンテナからcurlを実行
./curl https://...      # シンボリックリンク経由のショートカット
```

## アーキテクチャと開発ガイド

### ビルド設計
@import .claude/rules/dockerfile.md

### コマンドリファレンス
@import .claude/commands/build.md
@import .claude/commands/run.md
@import .claude/commands/test-http3.md

### 開発手順
@import .claude/skills/update-dependencies/SKILL.md
@import .claude/skills/configure-curl/SKILL.md
@import .claude/skills/debug-builds/SKILL.md

## 最近の作業

ngtcp2によるHTTP/3サポート追加（コミット26709f9）。
