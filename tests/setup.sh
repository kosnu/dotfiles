#!/bin/sh
set -eu
repo_root=$(CDPATH= cd -- "$(dirname "$0")/.." && pwd)
tmpdir=$(mktemp -d "${TMPDIR:-/tmp}/dotfiles-setup.XXXXXX")
trap 'rm -rf "$tmpdir"' EXIT
mkdir "$tmpdir/home"
make -s -C "$repo_root" symbolic_link HOME="$tmpdir/home"
[ "$(readlink "$tmpdir/home/.zshrc")" = "$repo_root/.zshrc" ]
[ "$(readlink "$tmpdir/home/.zshenv")" = "$repo_root/.zshenv" ]
[ "$(readlink "$tmpdir/home/.profile")" = "$repo_root/.profile" ]
[ "$(readlink "$tmpdir/home/.config/mise/config.toml")" = "$repo_root/.config/mise/config.toml" ]
[ ! -e "$tmpdir/home/.idea" ]
make -s -C "$repo_root" symbolic_link HOME="$tmpdir/home"
rm "$tmpdir/home/.bashrc"
printf 'keep\n' > "$tmpdir/home/.bashrc"
if make -s -C "$repo_root" symbolic_link HOME="$tmpdir/home"; then
  echo '既存ファイルの上書きを拒否するべきです' >&2
  exit 1
fi
[ "$(cat "$tmpdir/home/.bashrc")" = keep ]
mkdir -p "$tmpdir/incomplete/.config/mise" "$tmpdir/empty-home"
cp "$repo_root/Makefile" "$tmpdir/incomplete/Makefile"
for file in .bash_profile .bashrc .commit_template .gitconfig .profile .zprofile .zshenv .zshrc .config/mise/config.toml; do
  cp "$repo_root/$file" "$tmpdir/incomplete/$file"
done
if make -s -C "$tmpdir/incomplete" symbolic_link HOME="$tmpdir/empty-home"; then
  echo 'リンク元のファイルがない場合は停止するべきです' >&2
  exit 1
fi
[ -z "$(ls -A "$tmpdir/empty-home")" ]
mkdir "$tmpdir/conflict-home"
printf 'keep\n' > "$tmpdir/conflict-home/.config"
if make -s -C "$repo_root" symbolic_link HOME="$tmpdir/conflict-home"; then
  echo '親ディレクトリがファイルの場合はリンク作成前に停止するべきです' >&2
  exit 1
fi
[ "$(cat "$tmpdir/conflict-home/.config")" = keep ]
[ "$(ls -A "$tmpdir/conflict-home")" = .config ]
echo 'setup: OK'
