# Command
export PATH=$PATH:${HOME}/bin
export PATH=/usr/local/bin:$PATH
export PATH=/usr/local:$PATH
export PATH=/opt/homebrew/bin:$PATH
[ ! -f "$HOME/.cargo/env" ] || . "$HOME/.cargo/env"
if [ -x "$HOME/.local/bin/mise" ]; then
  export PATH="$HOME/.local/share/mise/shims:$PATH"
fi
