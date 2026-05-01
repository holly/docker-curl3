---
name: Dockerfile マルチステージビルド規約
description: HTTP/3対応curlのDockerビルドパイプライン設計
paths: ["Dockerfile"]
---

# Dockerfile マルチステージビルド規約

## 4段階ビルドプロセス

このプロジェクトは依存関係を段階的にビルドし、最終的な実行イメージを最小化します。

### ステージ1: openssl_builder
- OpenSSLをソースからビルド
- QUIC対応が必須（ngtcp2のために）
- プリフィックス: `/usr/local/openssl`
- 出力: libssl.so、libcrypto.so

### ステージ2: ngtcp2_builder
- OpenSSLに依存（COPY経由で取得）
- QUIC実装をビルド
- `--enable-lib-only` でテストをスキップ
- プリフィックス: `/usr/local/ngtcp2`
- 出力: libngtcp2.so

### ステージ3: curl_builder
- openssl、ngtcp2に依存
- curl本体をコンパイル
- HTTP/3機能: `--enable-http3 --with-ngtcp2`
- OpenSSL統合: `--with-openssl-quic`
- プリフィックス: `/usr/local/curl3`
- 出力: curllバイナリ＋ライブラリ

### ステージ4: executor
- 実行時最小イメージ
- ステージ1-3から必要な成果物をCOPY
- ldconfigセットアップで動的リンクを解決
- ENTRYPOINT: `/usr/local/curl3/bin/curl`

## ビルドパラメータ規約

```
OPENSSL_PREFIX=/usr/local/openssl    # OpenSSl install location
NGTCP2_PREFIX=/usr/local/ngtcp2      # ngtcp2 install location
CURL3_PREFIX=/usr/local/curl3        # curl install location & entrypoint
```

各パラメータは複数ステージで参照されるため、ARGで一度定義し、COPY時のパス指定に使用。

## 重要なビルド詳細

### 並列ビルド
```bash
make -j$(grep -c processor /proc/cpuinfo)
```
利用可能なすべてのCPUコアでビルド。ビルド時間を大幅短縮。

### PKG_CONFIG_PATH設定
```bash
PKG_CONFIG_PATH=$OPENSSL_PREFIX/lib64/pkgconfig:$NGTCP2_PREFIX/lib/pkgconfig \
  ./configure ...
```
カスタムビルドした依存関係を検出するために必須。標準パスにないため明示的に指定。

### ldconfigセットアップ（executor）
```bash
echo "$OPENSSL_PREFIX/lib64" >> /etc/ld.so.conf.d/openssl.conf
echo "$NGTCP2_PREFIX/lib" >> /etc/ld.so.conf.d/ngtcp2.conf
echo "$CURL3_PREFIX/lib" >> /etc/ld.so.conf.d/curl3.conf
ldconfig -v
```
ランタイムが動的リンクされたライブラリを解決できるようにする。3つすべてが必要。

## レイヤーキャッシング

Dockerfile内の命令順序は重要：
- 変更頻度が低い順（git clone）から高い順（configure）へ
- ステージ依存関係がある場合、下位ステージの変更は上位ステージのキャッシュ無効化をトリガー
- 開発時は `--no-cache` で再ビルド、本番ビルドはキャッシング活用

## トラブルシューティング

**ライブラリが見つからないエラー**: PKG_CONFIG_PATH を確認。値がないか、パスが間違っていないか。

**ldconfig: cannot find** エラー: executor ステージで `/etc/ld.so.conf.d/` エントリが漏れていないか確認。

**configure がフラグを認識しない**: OpenSSL が `--with-openssl-quic` をサポートしているか確認。バージョンが古すぎないか。
