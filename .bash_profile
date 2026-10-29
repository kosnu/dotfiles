if [ -f ~/.bashrc ]; then
  source ~/.bashrc
fi

# Added by Toolbox App
export PATH="$PATH:$HOME/Library/Application Support/JetBrains/Toolbox/scripts"

[ ! -x /opt/homebrew/bin/brew ] || eval "$(/opt/homebrew/bin/brew shellenv)"
