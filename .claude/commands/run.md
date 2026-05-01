# コマンド: 実行

コンテナからcurlを実行。

## 標準実行

```bash
./run.sh [curl arguments]
```

例：

```bash
./run.sh --version
./run.sh -h
./run.sh https://example.com
```

## シンボリックリンク経由

`curl` は `run.sh` へのシンボリックリンク：

```bash
./curl [curl arguments]
```

`./run.sh` と同等。

## 直接Docker実行

```bash
docker run --rm -it $USER/curl3:latest [curl arguments]
```

例:

```bash
docker run --rm -it holly/curl3:latest https://example.com
```

フラグの意味：
- `--rm`: コンテナ終了後に自動削除
- `-it`: インタラクティブ + TTY（ターミナル）

## ボリュームマウント

ローカルファイルを読み込む場合：

```bash
docker run --rm -v /path/to/local:/data -it $USER/curl3:latest \
  --upload-file /data/file.txt https://example.com
```

## HTTP/3テスト

```bash
./run.sh --http3 https://h3.example.com
./run.sh --version  # HTTP/3サポート確認
```

詳細は `.claude/commands/test-http3.md` 参照。

## SSH/SFTP接続

SSH認証でファイルをダウンロード・アップロード：

```bash
# パスワード認証でSFTPダウンロード
./run.sh -u user:password sftp://example.com/path/to/file.txt

# 秘密鍵認証でSCPダウンロード
./run.sh -u user: --key ~/.ssh/id_rsa scp://example.com/~/file.txt

# ディレクトリ一覧表示
./run.sh sftp://user@example.com/

# SFTPでファイルアップロード
./run.sh -T local_file.txt sftp://user@example.com/~/uploads/

# 秘密鍵のパスフレーズ指定付き
./run.sh -u user: --key ~/.ssh/id_rsa --pass "passphrase" \
  scp://example.com/~/file.txt -o sftp

# 詳細出力付き接続
./run.sh -v -u user:password sftp://example.com/
```

注：
- `-u user:password`: パスワード認証
- `-u user:`: パスワード認証（対話的プロンプト）
- `--key ~/.ssh/id_rsa`: 秘密鍵ファイルのパス
- `-T`: ファイルアップロード
- `-O`: ファイルダウンロード（明示的指定）

## 環境変数の指定

```bash
docker run --rm -e DEBUG=1 -it $USER/curl3:latest https://example.com
```

## 詳細出力

```bash
./run.sh -v https://example.com      # Verbose
./run.sh -vv https://example.com     # Very verbose
```

## タイムアウト設定

```bash
./run.sh --max-time 10 https://slow.example.com
```

10秒でタイムアウト。
