---
name: Dockerビルド失敗をデバッグする
description: ビルド中のエラーを調査し、特定ステージにシェルアクセスする方法
---

# スキル: Dockerビルド失敗をデバッグする

ビルド過程でのエラーを診断し、詳細な情報を取得する手順。

## ビルドの詳細出力

デフォルトでは Docker はレイヤーごとのサマリーのみ表示。詳細を見るには：

```bash
docker build --progress=plain -t $USER/curl3:latest .
```

フラグの意味：
- `--progress=plain`: 各実行ステップを行単位で表示（`auto` より詳細）
- タイムスタンプ付きで各コマンドの出力が見える

## 特定ステージまでのビルド

フルビルドは時間がかかります。特定ステージのみをデバッグ：

```bash
# OpenSSL ビルドのみ確認
docker build --progress=plain -t curl3-openssl:debug --target=openssl_builder .

# ngtcp2 ビルドのみ確認
docker build --progress=plain -t curl3-ngtcp2:debug --target=ngtcp2_builder .

# curl ビルドのみ確認
docker build --progress=plain -t curl3-curl:debug --target=curl_builder .
```

## ビルダーステージへのシェルアクセス

ビルド途中でエラーが発生した場合、そのステージ時点での状態を確認：

### パターン1: ステージをデバッグイメージとして確定させる

```bash
docker build --progress=plain -t debug --target=curl_builder .
docker run -it debug /bin/bash
```

ここで：
- `/app/curl/` ディレクトリ配置確認
- `./configure` スクリプト実行状況確認
- `./config.log` で configure エラー詳細を確認
- `make` の出力ログ確認

### パターン2: 途中で失敗しているステージの検査

Docker ビルド出力から失敗した行番号を特定し、その前のステップで停止：

```bash
# 例：行95でmake installが失敗した場合
# Dockerfile内で行94までをコピーし、行95を削除
docker build --progress=plain -t debug-step94 .
docker run -it debug-step94 /bin/bash
```

## 一般的なエラーと対処

### configure: command not found

原因: `autoreconf -fi` が実行されていない、または autoconf がインストールされていない。

```bash
# Dockerfile内の該当ステージで確認
# apt install -y autoconf automake libtool が実行されているか
```

### configure: OpenSSL not found

原因: PKG_CONFIG_PATH が正しく設定されていない。

```bash
# ビルダー内で確認
echo $PKG_CONFIG_PATH
ls $OPENSSL_PREFIX/lib64/pkgconfig/
```

### make: *** [Makefile] Error 1

原因: コンパイルエラー。詳細は `make` の出力ログを読む。

```bash
# ビルダーシェル内で再実行して詳細確認
cd /app/curl
make -j1        # 並列を1に落とすと出力が見やすくなる
```

### ldconfig: cannot find

原因: `/etc/ld.so.conf.d/` の設定が不足。executor ステージで確認。

```bash
docker run -it debug /bin/bash
cat /etc/ld.so.conf.d/*
ldconfig -p | grep libssl  # OpenSSL ライブラリが見える？
```

## キャッシュの無視

キャッシュが古い状態を保持している場合：

```bash
docker build --no-cache -t $USER/curl3:latest .
```

ただし、フルビルドに15～30分かかるため、上記の `--target` で特定ステージのみをテストすることを推奨。

## ビルドログの保存

後で分析するため、ログを保存：

```bash
docker build --progress=plain -t $USER/curl3:latest . 2>&1 | tee build.log
```

`build.log` にすべての出力が記録される。

## リソース制限の確認

ビルド中にメモリ不足やディスク不足で失敗することもあります：

```bash
# Docker デーモンに割り当てられたメモリ確認
docker system df        # ディスク使用量
docker stats            # リアルタイムリソース監視
```

## 再現可能性の確認

エラーが一度きりか、再現可能か確認：

```bash
./build.sh              # 1回目
./build.sh              # 2回目（キャッシュが効く）
docker build --no-cache -t $USER/curl3:latest .   # 3回目（キャッシュなし）
```
