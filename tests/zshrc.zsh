#!/bin/zsh
set -eu
repo_root=${0:A:h:h}
tmpdir=$(mktemp -d "${TMPDIR:-/tmp}/dotfiles-zshrc.XXXXXX")
trap 'rm -rf "$tmpdir"' EXIT
mkdir -p "$tmpdir/home" "$tmpdir/bin"
ln -s "$repo_root/.zshrc" "$tmpdir/home/.zshrc"
cat > "$tmpdir/bin/starship" <<'MOCK'
#!/bin/sh
printf '%s\n' "$STARSHIP_CONFIG" > "$HOME/starship-config"
MOCK
chmod +x "$tmpdir/bin/starship"
HOME="$tmpdir/home" PATH="$tmpdir/bin:/usr/bin:/bin:/usr/sbin:/sbin" \
  zsh -f -c 'source "$HOME/.zshrc"'
[[ "$(<"$tmpdir/home/starship-config")" == "$repo_root/starship.toml" ]]
HOME="$tmpdir/home" PATH="$tmpdir/bin:/usr/bin:/bin:/usr/sbin:/sbin" \
  zsh -fi -c 'source "$HOME/.zshrc"; print -s -- "dotfiles-history-test"; fc -W'
grep -Fq 'dotfiles-history-test' "$tmpdir/home/.zsh_history"

cat > "$tmpdir/bin/brew" <<'MOCK'
#!/bin/sh
printf 'call\n' >> "$HOME/brew-calls"
if [ "${BREW_FAIL:-}" = 1 ]; then
  printf '/invalid-prefix\n'
  exit 1
fi
printf '%s\n' "$HOME/brew-prefix"
MOCK
chmod +x "$tmpdir/bin/brew"
HOME="$tmpdir/home" PATH="$tmpdir/bin:/usr/bin:/bin:/usr/sbin:/sbin" \
  zsh -f -c 'source "$HOME/.zshrc"; [[ ":$FPATH:" == *":$HOME/brew-prefix/share/zsh-completions:"* && ":$PATH:" == *":$HOME/brew-prefix/opt/libpq/bin:"* ]]'
[[ "$(<"$tmpdir/home/brew-calls")" == call ]]
rm "$tmpdir/home/brew-calls"
HOME="$tmpdir/home" PATH="$tmpdir/bin:/usr/bin:/bin:/usr/sbin:/sbin" BREW_FAIL=1 \
  zsh -f -c 'source "$HOME/.zshrc"; [[ ":$FPATH:" != *":/invalid-prefix/share/zsh-completions:"* && ":$FPATH:" != *":/share/zsh-completions:"* && ":$PATH:" != *":/invalid-prefix/opt/libpq/bin:"* && ":$PATH:" != *":/opt/libpq/bin:"* ]]'
[[ "$(<"$tmpdir/home/brew-calls")" == call ]]

HOME="$tmpdir/home" PATH="$tmpdir/bin:/usr/bin:/bin:/usr/sbin:/sbin" \
  zsh -f -c '
    source "$HOME/.zshrc"
    CURRENT=2 BUFFER="npm test" CURSOR=8 words=(npm test)
    npm() { return 7; }
    compadd() { return 99; }
    _npm_completion
    [[ $? -eq 7 ]] || exit 1
    npm() { [[ "$COMP_POINT" == 8 ]] || return 1; printf "first option\nsecond\n"; }
    compadd() { [[ $# -eq 3 && "$1" == -- && "$2" == "first option" && "$3" == second ]]; }
    _npm_completion || exit 1
    npm() { return 0; }
    compadd() { return 99; }
    _npm_completion || exit 1
  '

ln -s "$repo_root/.zshenv" "$tmpdir/home/.zshenv"
# Cargo・Vite+・mise がなくてもシェルを起動できる
HOME="$tmpdir/home" PATH="$tmpdir/bin:/usr/bin:/bin:/usr/sbin:/sbin" \
  zsh -dc '[[ ! -e "$HOME/.cargo/env" && ! -e "$HOME/.vite-plus/env" ]]'

mkdir -p "$tmpdir/home/.vite-plus/bin" "$tmpdir/home/.local/bin" "$tmpdir/home/.local/share/mise/shims"
cat > "$tmpdir/home/.vite-plus/bin/node" <<'MOCK'
#!/bin/sh
echo vite
MOCK
cat > "$tmpdir/home/.local/share/mise/shims/node" <<'MOCK'
#!/bin/sh
echo mise
MOCK
cat > "$tmpdir/home/.local/bin/mise" <<'MOCK'
#!/bin/sh
[ "$1" = activate ] && [ "$2" = zsh ] || exit 1
printf 'export PATH="%s/.local/share/mise/shims:$PATH"\n' "$HOME"
MOCK
cat > "$tmpdir/home/.vite-plus/env" <<'MOCK'
printf 'load\n' >> "$HOME/vite-loads"
export PATH="$HOME/.vite-plus/bin:$PATH"
if [[ -o interactive ]]; then
  (( $+functions[compdef] )) || return 1
fi
MOCK
chmod +x "$tmpdir/home/.vite-plus/bin/node" "$tmpdir/home/.local/share/mise/shims/node" "$tmpdir/home/.local/bin/mise"
for flags in -dc -dic; do
  rm -f "$tmpdir/home/vite-loads"
  HOME="$tmpdir/home" PATH="$tmpdir/bin:/usr/bin:/bin:/usr/sbin:/sbin" \
    zsh "$flags" '[[ "$(node)" == mise ]]'
  [[ "$(<"$tmpdir/home/vite-loads")" == load ]]
done

echo 'zshrc: OK'
