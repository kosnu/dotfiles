if [ -f ~/.bashrc ]; then
  source ~/.bashrc
fi

# Added by Toolbox App
export PATH="$PATH:$HOME/Library/Application Support/JetBrains/Toolbox/scripts"

eval "$(/opt/homebrew/bin/brew shellenv)"
