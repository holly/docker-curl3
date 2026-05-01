---
name: プロジェクト依存関係を更新する
description: OpenSSL、ngtcp2、nghttp2、nghttp3のバージョン更新手順
---

# スキル: プロジェクト依存関係を更新する

依存ライブラリ（OpenSSL、ngtcp2など）をバージョンアップする手順。

## 更新対象

各ライブラリは `git clone` で最新版をダウンロードされます：

- **OpenSSL** (Dockerfile行11): QUIC対応が必須
- **ngtcp2** (Dockerfile行31): QUIC実装
- **nghttp2/nghttp3**: HTTP/2、HTTP/3サポート

## 更新手順

### ステップ1: 対象ライブラリの位置確認

Dockerfile内で、更新したいライブラリの `git clone` 行を特定します：

```dockerfile
# OpenSSL (行11)
git clone --depth 1 https://github.com/openssl/openssl

# ngtcp2 (行31)
git clone --depth 1 https://github.com/ngtcp2/ngtcp2

# curl (行61)
git clone https://github.com/curl/curl
```

### ステップ2: Dockerfileを編集

クローンするリポジトリまたはブランチを変更：

```dockerfile
# ブランチを指定（デフォルトはmain/master）
git clone --branch release-3.1 --depth 1 https://github.com/openssl/openssl

# または特定タグをチェックアウト後
git clone https://github.com/openssl/openssl && cd openssl && git checkout openssl-3.1.0
```

### ステップ3: リビルド

```bash
./build.sh
```

Docker は自動的に：
1. 変更されたステージ以降を再ビルド
2. 依存ステージ（下流）は影響を受ける（キャッシュ無効化）
3. 前のステージ（上流）はキャッシュから再利用

例：OpenSSL更新 → ngtcp2_builder、curl_builder、executor が再ビルド

### ステップ4: 検証

```bash
# バージョン確認
./run.sh --version

# 詳細な依存関係確認
./run.sh -v https://example.com 2>&1 | grep -i "openssl\|http"
```

## トラブルシューティング

**Configure エラー**: 新しいバージョンがオプションをサポートしていないことがあります。
- Dockerfileの configure オプションを確認
- 新バージョンのドキュメントでサポートされているフラグを確認
- 不要なフラグを削除または調整

**ビルド失敗**: 依存関係のバージョン不一致
- ngtcp2 は OpenSSL の QUIC サポートに依存
- OpenSSL バージョンアップ後は ngtcp2 もテスト
- 古い ngtcp2 は新しい OpenSSL と互換性がないことがあります

**キャッシュ関連**: 想定外のキャッシュ動作
```bash
docker build --no-cache -t $USER/curl3:latest .
```

## 推奨事項

- 複数ライブラリを同時に更新する場合は、下流ステージ（curl）からさかのぼって更新
- テスト対応サーバへの接続確認を毎回実施（.claude/commands/test-http3.md 参照）
- QUIC対応のため、OpenSSL は最新版保持を推奨
