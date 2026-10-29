# dotfiles

macOS 向けのシェル・Git・Vim・Starship の設定です。

## セットアップ

Git・make・Homebrew を用意し、リポジトリのルートで実行します。

```sh
make init_zsh       # Brewfile のパッケージを導入
make symbolic_link # ホームディレクトリに設定をリンク
```

既存の設定は上書きせずに停止します。内容を確認して退避後、再実行してください。
設定を読み込むには、新しいターミナルを開きます。

mise を使う場合は `~/.local/bin/mise` に導入し、新しいターミナルで `mise install` を実行します。Starship・Google Cloud SDK・Vite+ は必要に応じて別途導入します。

## 設定の更新

このリポジトリ内の設定ファイルを直接編集します。

- シェルの操作・補完は [.zshrc](.zshrc)、プロンプトは [starship.toml](starship.toml)。
- 言語ランタイム・CLI のバージョンは [mise の設定](.config/mise/config.toml)。変更後に `mise install` を実行します。同じ CLI の `npm install -g` との重複は避けます。
- Homebrew のパッケージは [Brewfile](Brewfile)。変更後に `make init_zsh` を実行します。

通常の `node` は mise、`vp node` は Vite+ 側の設定に従います。

## ブランチの整理

GitHub リポジトリ内で、マージ済みのローカルブランチを整理できます。`gh` の認証と、GitHub を指す `origin` が必要です。

```sh
gitcleanbr --dry-run # 削除候補を確認
gitcleanbr           # 確認後に削除
```

現在のブランチ・既定ブランチ・`main`・`master`・`production`・worktree で使用中のブランチは対象外です。squash マージは、直近 1,000 件のマージ済み PR と先端のコミットが一致する場合に判定できます。

## 変更後の確認

`make test` でシェル構文・補完・ブランチ削除・リンク作成を検証します。
