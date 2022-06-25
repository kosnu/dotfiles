# Path to your oh-my-zsh installation.

# See https://github.com/robbyrussell/oh-my-zsh/wiki/Themes

plugins=(git)

export ZSH_DISABLE_COMPFIX=true

export LANG=ja_JP.UTF-8

# 直前のコマンドの重複を削除
setopt hist_ignore_dups
# 同じコマンドをヒストリに残さない
setopt hist_ignore_all_dups
# 同時に起動したzshの間でヒストリを共有
setopt share_history
autoload -Uz compinit
compinit
if [ -e /usr/local/share/zsh-completions ]; then
  fpath=(/usr/local/share/zsh-completions $fpath)
fi

# 補完で小文字でも大文字にマッチさせる
zstyle ':completion:*' matcher-list 'm:{a-z}={A-Z}'
# 補完候補を詰めて表示
setopt list_packed
# 補完候補一覧をカラー表示
zstyle ':completion:*' list-colors ''
# プラグインを有効化
source $(brew --prefix)/share/zsh-autosuggestions/zsh-autosuggestions.zsh
source $(brew --prefix)/share/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh
# コマンドのスペルを訂正
setopt correct
# ビープ音を鳴らさない
setopt no_beep
# コマンドでの*のマッチを無効にする
setopt nonomatch

# for lima
export DOCKER_HOST=$(limactl list docker --format 'unix://{{.Dir}}/sock/docker.sock')

# for starship
eval "$(starship init zsh)"

# The next line updates PATH for the Google Cloud SDK.
if [ -f '/Users/kosnu/google-cloud-sdk/path.zsh.inc' ]; then . '/Users/kosnu/google-cloud-sdk/path.zsh.inc'; fi

# The next line enables shell command completion for gcloud.
if [ -f '/Users/kosnu/google-cloud-sdk/completion.zsh.inc' ]; then . '/Users/kosnu/google-cloud-sdk/completion.zsh.inc'; fi

# for Volta
export VOLTA_HOME="$HOME/.volta"
export PATH="$VOLTA_HOME/bin:$PATH"
