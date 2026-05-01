---
name: Curl設定を変更する
description: ./configureオプションでcurl機能を追加/削除する方法
---

# スキル: Curl設定を変更する

curl コンパイル時の `./configure` オプションを変更して、機能を有効/無効化する手順。

## 設定位置

Dockerfile の curl_builder ステージ（行65～95）：

```dockerfile
PKG_CONFIG_PATH=$OPENSSL_PREFIX/lib64/pkgconfig:$NGTCP2_PREFIX/lib/pkgconfig \
  ./configure \
    --prefix=$CURL3_PREFIX \
    --with-openssl=$OPENSSL_PREFIX \
    ... [機能オプション]
```

## よくある設定変更

### HTTP/3を無効化する

```dockerfile
# 削除：
--enable-http3
--with-ngtcp2=$NGTCP2_PREFIX
--with-nghttp3
```

### HTTP/2を無効化する

```dockerfile
# 削除：
--with-nghttp2
```

### デバッグシンボルを追加

```dockerfile
# 追加：
--enable-debug
```

### 圧縮機能を削除（イメージサイズ縮小）

```dockerfile
# 削除：
--with-brotli
--with-zlib
```

## 有効化フラグの種類

### `--enable-*` / `--disable-*`
機能の有効/無効を切り替え。

```dockerfile
--enable-http          # HTTP をサポート（デフォルト有効）
--enable-ftp           # FTP をサポート（デフォルト有効）
--disable-ldap         # LDAP を無効化
--disable-telnet       # TELNET を無効化
```

### `--with-*` / `--without-*`
外部ライブラリとの統合。

```dockerfile
--with-openssl=$OPENSSL_PREFIX       # OpenSSLパスを指定
--with-ngtcp2=$NGTCP2_PREFIX         # ngtcp2パスを指定
--with-brotli                        # brotli圧縮対応
--with-zlib                          # zlib圧縮対応
```

## カスタムOpenSSLの重要性

`--with-openssl=$OPENSSL_PREFIX` は必須。このプロジェクトでは OpenSSL をカスタムビルドしているため、標準パスではなく明示的にパスを指定。

## PKG_CONFIG_PATH の調整

新しい依存関係を追加する場合、PKG_CONFIG_PATH も更新が必要なことがあります：

```dockerfile
PKG_CONFIG_PATH=$OPENSSL_PREFIX/lib64/pkgconfig:$NGTCP2_PREFIX/lib/pkgconfig:/path/to/new/lib/pkgconfig \
  ./configure ...
```

## 設定確認

ビルド後、設定が反映されているか確認：

```bash
./run.sh --version          # 機能リスト確認
./run.sh -h | grep http3    # HTTP/3フラグ確認
```

## 設定ファイルの確認

curl がサポートしているすべてのオプション：

```bash
# Dockerfile内でcurlクローン直後
./configure --help | less
```

または GitHub リポジトリの `INSTALL` ドキュメント参照。

## トラブルシューティング

**「unknown option」エラー**: 指定したオプションがこのcurl バージョンでサポートされていません。
- curl のバージョンを確認
- GitHub リポジトリのドキュメント確認

**コンパイルエラー**: 依存ライブラリが見つからない
- PKG_CONFIG_PATH が正しく設定されているか確認
- 参照先のライブラリ（OpenSSL、ngtcp2）がビルドされているか確認

**バイナリが起動しない**: `./run.sh --version` で動的リンク失敗
- `ldd /usr/local/curl3/bin/curl` でライブラリ依存関係確認
- .claude/rules/dockerfile.md の ldconfig セクション参照
