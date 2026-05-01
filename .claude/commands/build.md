# コマンド: ビルド

Docker イメージをビルド。

## クイックビルド

```bash
./build.sh
```

タグ: `$USER/curl3:latest`（例: `holly/curl3:latest`）

## 直接ビルド

```bash
docker build -t $USER/curl3:latest .
```

## 詳細出力付きビルド

```bash
docker build --progress=plain -t $USER/curl3:latest .
```

各ステップの詳細なログが表示される。トラブルシューティング時に有用。

## キャッシュなしビルド

```bash
docker build --no-cache -t $USER/curl3:latest .
```

依存関係を完全に再ビルド（15～30分かかる）。

## 特定ステージまでのビルド

```bash
# OpenSSL のみ
docker build --target=openssl_builder -t curl3-openssl:latest .

# ngtcp2 のみ
docker build --target=ngtcp2_builder -t curl3-ngtcp2:latest .

# curl のみ
docker build --target=curl_builder -t curl3-curl:latest .
```

## イメージ確認

```bash
docker images | grep curl3
```

## ビルド時間

- 初回: 20～30分（フルビルド）
- 2回目以降: 1～5分（キャッシュ活用、ただし依存関係未変更時）
- 依存関係変更時: 5～15分（変更されたステージ以降を再ビルド）
