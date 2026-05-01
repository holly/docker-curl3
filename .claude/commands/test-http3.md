# コマンド: HTTP/3テスト

HTTP/3サポートの確認とテスト。

## サポート確認

```bash
./run.sh --version
```

出力に以下が含まれるはず：
```
Features: ...HTTP/3... H3... QUIC...
```

## 詳細機能確認

```bash
./run.sh -V
```

以下のような行が表示：
```
Protocols: ... http3 ...
TLS: OpenSSL/3.x.x + QUIC
```

## HTTP/3接続テスト

公開H3対応サーバへの接続：

```bash
# HTTP/3強制
./run.sh --http3 https://h3.example.com

# 詳細出力
./run.sh --http3 -v https://h3.example.com
```

## テスト対応サーバ（例）

```bash
# Google（HTTP/3対応）
./run.sh --http3 https://www.google.com

# Cloudflare
./run.sh --http3 https://www.cloudflare.com

# akamai
./run.sh --http3 https://www.akamai.com
```

## プロトコル選択テスト

```bash
# HTTP/1.1のみ
./run.sh --http1.1 https://example.com

# HTTP/2のみ
./run.sh --http2 https://example.com

# HTTP/3（利用不可なら他へフォールバック）
./run.sh --http3 https://example.com
```

## バナー表示

バイナリが正しくコンパイルされているか確認：

```bash
./run.sh 2>&1 | head -1
```

`curl 7.x.x (...)` が表示されればOK。
