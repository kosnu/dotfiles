if [ -f ~/.bashrc ]; then
  source ~/.bashrc
fi

# Ruby
[[ -d ~/.rbenv  ]] && \
  export PATH=${HOME}/.rbenv/bin:${PATH} && \
  eval "$(rbenv init -)"
if which rbenv > /dev/null; then eval "$(rbenv init -)"; fi
export PATH="$HOME/.rbenv/shims:$PATH"

# 便利コマンド
alias gitcleanbr="git branch --merged|egrep -v '\* | production | master'|xargs git branch -D"
