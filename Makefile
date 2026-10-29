DOTFILES_FILES := .bash_profile .bashrc .commit_template .gitconfig .profile .vimrc .zprofile .zshenv .zshrc .config/mise/config.toml

.PHONY: symbolic_link init_zsh test

symbolic_link:
	@set -e; for file in $(DOTFILES_FILES); do \
	  target="$(CURDIR)/$$file"; dest="$(HOME)/$$file"; \
	  if [ ! -f "$$target" ]; then \
	    echo "リンク元のファイルがありません: $$target" >&2; exit 1; \
	  fi; \
	  parent="$$(dirname "$$dest")"; \
	  while [ ! -d "$$parent" ]; do \
	    if [ -e "$$parent" ] || [ -L "$$parent" ]; then \
	      echo "リンク先の親がディレクトリではありません: $$parent" >&2; exit 1; \
	    fi; \
	    parent="$$(dirname "$$parent")"; \
	  done; \
	  if [ -e "$$dest" ] || [ -L "$$dest" ]; then \
	    if [ ! -L "$$dest" ] || [ "$$(readlink "$$dest")" != "$$target" ]; then \
	      echo "既存ファイルを保持します: $$dest" >&2; exit 1; \
	    fi; \
	  fi; \
	done; \
	for file in $(DOTFILES_FILES); do \
	  dest="$(HOME)/$$file"; \
	  if [ ! -L "$$dest" ]; then \
	    mkdir -p "$$(dirname "$$dest")"; \
	    ln -sv "$(CURDIR)/$$file" "$$dest"; \
	  fi; \
	done

init_zsh:
	brew bundle install --file="$(CURDIR)/Brewfile" --no-upgrade

test:
	zsh -n .zshrc
	zsh -n .zprofile
	zsh -n .zshenv
	sh -n .profile
	bash -n .bashrc
	bash -n .bash_profile
	bash -n npm_completion.sh
	zsh tests/gitcleanbr.zsh
	zsh tests/zshrc.zsh
	bash tests/npm_completion.sh
	sh tests/setup.sh
