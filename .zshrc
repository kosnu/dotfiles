# Add deno completions to search path
if [[ ":$FPATH:" != *":$HOME/completions:"* ]]; then export FPATH="$HOME/completions:$FPATH"; fi
export LANG=ja_JP.UTF-8

: ${HISTFILE:=$HOME/.zsh_history}
HISTSIZE=10000
SAVEHIST=10000
# 直前のコマンドの重複を削除
setopt hist_ignore_dups
# 同じコマンドをヒストリに残さない
setopt hist_ignore_all_dups
# 同時に起動したzshの間でヒストリを共有
setopt share_history
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
brew_prefix=''
if command -v brew >/dev/null 2>&1 && brew_prefix="$(brew --prefix 2>/dev/null)" && [[ -n "$brew_prefix" ]]; then
  export ZSH_HIGHLIGHT_HIGHLIGHTERS_DIR="$brew_prefix/share/zsh-syntax-highlighting/highlighters"
  [[ -f "$brew_prefix/share/zsh-autosuggestions/zsh-autosuggestions.zsh" ]] && source "$brew_prefix/share/zsh-autosuggestions/zsh-autosuggestions.zsh"
else
  brew_prefix=''
fi
# コマンドのスペルを訂正
setopt correct
# ビープ音を鳴らさない
setopt no_beep
# コマンドでの*のマッチを無効にする
setopt nonomatch

# for starship
export STARSHIP_CONFIG="${${(%):-%x}:A:h}/starship.toml"
if command -v starship >/dev/null 2>&1; then eval "$(starship init zsh)"; fi

if [[ -n "$brew_prefix" ]]; then
  FPATH="$brew_prefix/share/zsh-completions:$FPATH"
fi

# Docker Desktop の補完を登録してから初期化する
fpath=("$HOME/.docker/completions" $fpath)
autoload -Uz compinit
compinit

# Google Cloud
# The next line updates PATH for the Google Cloud SDK.
if [ -f "$HOME/google-cloud-sdk/path.zsh.inc" ]; then . "$HOME/google-cloud-sdk/path.zsh.inc"; fi

# The next line enables shell command completion for gcloud.
if [ -f "$HOME/google-cloud-sdk/completion.zsh.inc" ]; then . "$HOME/google-cloud-sdk/completion.zsh.inc"; fi
# PostgreSQL psql
if [[ -n "$brew_prefix" ]]; then export PATH="$brew_prefix/opt/libpq/bin:$PATH"; fi

# 便利コマンド
# 既存のaliasがあると関数定義時に展開されて構文エラーになるため解除
unalias gitcleanbr 2>/dev/null
gitcleanbr() {
  local current_branch
  local default_branch
  local base_sha
  local remote_url
  local remote_ref
  local dry_run=0
  local branch
  local branches
  local merged_branches
  local pr_data
  local sha
  local worktree_state
  local key
  local needs_pr=0
  local -A branch_heads merged_heads merged_pr_heads
  local deleted_count=0
  local failed=0

  if [[ $# -gt 1 || ( $# -eq 1 && "$1" != "--dry-run" ) ]]; then
    echo "usage: gitcleanbr [--dry-run]" >&2
    return 2
  fi
  [[ "${1:-}" == "--dry-run" ]] && dry_run=1
  current_branch="$(git branch --show-current)" || return 1
  branches="$(git for-each-ref --format='%(refname:lstrip=2)%09%(objectname)%09%(if)%(worktreepath)%(then)used%(else)free%(end)' refs/heads)" || return 1
  while IFS=$'\t' read -r branch sha worktree_state; do
    [[ -z "$branch" || "$worktree_state" == used ]] && continue
    [[ "$branch" == main || "$branch" == master || "$branch" == production || "$branch" == "$current_branch" ]] && continue
    branch_heads[$branch]="$sha"
  done <<< "$branches"
  if (( ${#branch_heads} == 0 )); then
    (( dry_run )) || echo 'deleted: 0'
    return 0
  fi

  remote_url="$(git remote get-url origin)" || return 1
  default_branch="$(gh repo view "$remote_url" --json defaultBranchRef --jq .defaultBranchRef.name)" || return 1
  [[ -n "$default_branch" ]] || return 1
  remote_ref="$(git ls-remote --exit-code origin "refs/heads/$default_branch")" || return 1
  base_sha="${remote_ref%%$'\t'*}"
  if ! git cat-file -e "$base_sha^{commit}" 2>/dev/null; then
    echo "origin/$default_branch の最新コミットがありません。git fetch origin $default_branch を実行してください。" >&2
    return 1
  fi
  merged_branches="$(git for-each-ref --merged="$base_sha" --format='%(refname:lstrip=2)' refs/heads)" || return 1
  while read -r branch; do
    [[ -z "$branch" ]] && continue
    merged_heads[$branch]=1
  done <<< "$merged_branches"
  for branch in "${(@k)branch_heads}"; do
    [[ "$branch" == "$default_branch" ]] && continue
    if [[ -z "${merged_heads[$branch]:-}" ]]; then
      needs_pr=1
      break
    fi
  done
  if (( needs_pr )); then
    pr_data="$(gh pr list --repo "$remote_url" --state merged --base "$default_branch" --limit 1000 --json headRefName,headRefOid --jq '.[] | [.headRefName, .headRefOid] | @tsv')" || return 1
    while IFS=$'\t' read -r branch sha; do
      [[ -z "$branch" || -z "$sha" ]] && continue
      key="$branch:$sha"
      merged_pr_heads[$key]=1
    done <<< "$pr_data"
  fi

  # 通信中に先端や worktree の使用状態が変わったブランチは除外する
  branches="$(git for-each-ref --format='%(refname:lstrip=2)%09%(objectname)%09%(if)%(worktreepath)%(then)used%(else)free%(end)' refs/heads)" || return 1
  while IFS=$'\t' read -r branch sha worktree_state; do
    [[ -z "$branch" || "$worktree_state" == used || "$branch" == "$default_branch" ]] && continue
    [[ "${branch_heads[$branch]:-}" == "$sha" ]] || continue
    key="$branch:$sha"
    if [[ -z "${merged_heads[$branch]:-}" && -z "${merged_pr_heads[$key]:-}" ]]; then
      continue
    fi

    if (( dry_run )); then
      echo "candidate: $branch"
      continue
    fi
    if git branch -D -- "$branch"; then
      ((++deleted_count))
    else
      failed=1
    fi
  done <<< "$branches"

  (( dry_run )) || echo "deleted: $deleted_count"
  return $failed
}

export PATH="$HOME/.local/bin:$PATH"

export EDITOR='vim'
bindkey -e # emac入力モード

source "${${(%):-%x}:A:h}/npm_completion.sh"

# Vite+ bin (https://viteplus.dev)
if [[ -f "$HOME/.vite-plus/env" ]]; then . "$HOME/.vite-plus/env"; fi
if [[ -x "$HOME/.local/bin/mise" ]]; then eval "$("$HOME/.local/bin/mise" activate zsh)"; fi

if [[ -n "$brew_prefix" && -f "$brew_prefix/share/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh" ]]; then
  source "$brew_prefix/share/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh"
fi
