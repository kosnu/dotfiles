[ ! -f "$HOME/.cargo/env" ] || . "$HOME/.cargo/env"

# 対話シェルでは補完の初期化後に .zshrc から読み込む
if [[ ! -o interactive && -f "$HOME/.vite-plus/env" ]]; then
  . "$HOME/.vite-plus/env"
fi

# 非対話シェルでもプロジェクトの mise 設定でコマンドを解決する
if [[ -x "$HOME/.local/bin/mise" ]]; then
  path=("$HOME/.local/share/mise/shims" "${(@)path:#$HOME/.local/share/mise/shims}")
fi
