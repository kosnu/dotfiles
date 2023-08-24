if [ -f ~/.bashrc ]; then
  source ~/.bashrc
fi

# 便利コマンド
alias gitcleanbr="git branch --merged|egrep -v '\* | production | master'|xargs git branch -D"
