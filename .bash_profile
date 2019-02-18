source ~/.bashrc

# Command
export PATH=$PATH:${HOME}/bin
export PATH=$PATH:/usr/local/bin
# Android SDK
export ANDROID_HOME=${HOME}/Library/Android/sdk
export PATH=$PATH:$ANDROID_HOME/platform-tools
export PATH=$PATH:$ANDROID_HOME/emulator
export PATH=$PATH:$ANDROID_HOME/tools
export PATH=$PATH:$ANDROID_HOME/tools/bin
# Python
export PATH=$PATH:/Library/Python/2.7/
# Node.js
export PATH=$PATH:${HOME}.nodebrew/current/bin
# Golang
export GOPATH=$(go env GOPATH)
export PATH=$PATH:$GOPATH/bin
# Ruby
[[ -d ~/.rbenv  ]] && \
  export PATH=${HOME}/.rbenv/bin:${PATH} && \
  eval "$(rbenv init -)"
