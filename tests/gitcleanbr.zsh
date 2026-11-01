#!/bin/zsh
set -eu
repo_root=${0:A:h:h}
tmpdir=$(mktemp -d "${TMPDIR:-/tmp}/gitcleanbr.XXXXXX")
trap 'rm -rf "$tmpdir"' EXIT

git init -q --bare "$tmpdir/origin.git"
git init -q -b main "$tmpdir/repo"
git -C "$tmpdir/repo" config user.name Test
git -C "$tmpdir/repo" config user.email test@example.com
git -C "$tmpdir/repo" commit -q --allow-empty -m initial
git -C "$tmpdir/repo" remote add origin "$tmpdir/origin.git"
git -C "$tmpdir/repo" push -q origin main
git -C "$tmpdir/repo" branch merged
git -C "$tmpdir/repo" branch used
git -C "$tmpdir/repo" worktree add -q "$tmpdir/worktree" used
git -C "$tmpdir/repo" switch -q -c squash
echo squash > "$tmpdir/repo/squash"
git -C "$tmpdir/repo" add squash
git -C "$tmpdir/repo" commit -q -m squash
git -C "$tmpdir/repo" switch -q main
git -C "$tmpdir/repo" merge -q --squash squash
git -C "$tmpdir/repo" commit -q -m squash-merged
git -C "$tmpdir/repo" push -q origin main
git -C "$tmpdir/repo" switch -q -c unmerged
git -C "$tmpdir/repo" commit -q --allow-empty -m unmerged
unmerged_sha=$(git -C "$tmpdir/repo" rev-parse HEAD)
git -C "$tmpdir/repo" switch -q -c child
mkdir "$tmpdir/bin"
git_bin=$(command -v git)
cat > "$tmpdir/bin/git" <<MOCK
#!/bin/zsh
if [[ "\$1" == ls-remote ]]; then
  if [[ -n "\${MOCK_PROGRESS_FILE:-}" ]]; then
    [[ "\$(<\$MOCK_PROGRESS_FILE)" == *'gitcleanbr: origin/main の最新コミットを確認しています...'* ]] || exit 1
  fi
  [[ "\${MOCK_REMOTE_FAIL:-}" != 1 ]] || exit 1
  if [[ "\${MOCK_REF_CHANGE:-}" == 1 ]]; then
    '$git_bin' update-ref refs/heads/moving '$unmerged_sha' || exit 1
    '$git_bin' worktree add -q '$tmpdir/checkout-later' checkout-later || exit 1
  fi
fi
exec '$git_bin' "\$@"
MOCK
cat > "$tmpdir/bin/gh" <<MOCK
#!/bin/zsh
printf '%s %s\\n' "\$1" "\$2" >> '$tmpdir/gh-calls'
case "\$1 \$2" in
  'repo view')
    [[ "\$3" == '$tmpdir/origin.git' ]] || exit 1
    if [[ -n "\${MOCK_PROGRESS_FILE:-}" ]]; then
      [[ "\$(<\$MOCK_PROGRESS_FILE)" == \$'gitcleanbr: ローカルブランチを確認しています...\\ngitcleanbr: origin の既定ブランチを確認しています...' ]] || exit 1
    fi
    echo main
    ;;
  *) exit 1 ;;
esac
MOCK
chmod +x "$tmpdir/bin/git" "$tmpdir/bin/gh"
export PATH="$tmpdir/bin:$PATH"
export GH_REPO=example/unrelated
sed -n '/^gitcleanbr() {/,/^}/p' "$repo_root/.zshrc" > "$tmpdir/function.zsh"
source "$tmpdir/function.zsh"
cd "$tmpdir/repo"
output=$(MOCK_PROGRESS_FILE="$tmpdir/progress" gitcleanbr --dry-run 2> "$tmpdir/progress")
[[ "$output" == 'candidate: merged' ]]
[[ "$(<"$tmpdir/progress")" == *$'gitcleanbr: マージ済みブランチを判定しています...\ngitcleanbr: 確認が完了しました。' ]]
[[ "$output" != *'candidate: unmerged'* ]]
[[ "$output" != *'candidate: used'* && "$output" != *'candidate: child'* ]]
git show-ref --verify -q refs/heads/squash
output=$(gitcleanbr 2> "$tmpdir/delete-errors")
[[ "$output" == *'deleted: 1'* ]]
! git show-ref --verify -q refs/heads/merged
git show-ref --verify -q refs/heads/squash
git show-ref --verify -q refs/heads/unmerged
git show-ref --verify -q refs/heads/used

# 使用中・保護対象だけなら、origin に接続できなくても正常終了する
git worktree add -q "$tmpdir/unmerged-worktree" unmerged
git worktree add -q "$tmpdir/squash-worktree" squash
git remote set-url origin "$tmpdir/unavailable.git"
: > "$tmpdir/gh-calls"
[[ "$(gitcleanbr)" == 'deleted: 0' ]]
[[ -z "$(gitcleanbr --dry-run)" && ! -s "$tmpdir/gh-calls" ]]
git remote set-url origin "$tmpdir/origin.git"

# PR 照会は行わず、通常のマージ履歴だけで判定する
git branch merged-only main
: > "$tmpdir/gh-calls"
[[ "$(gitcleanbr --dry-run)" == 'candidate: merged-only' ]]
[[ "$(<"$tmpdir/gh-calls")" == 'repo view' ]]
git branch -D merged-only >/dev/null

# リモートの照会に失敗したら削除しない
git branch merged-safety main
if MOCK_REMOTE_FAIL=1 gitcleanbr; then
  echo 'リモート照会失敗時は削除前に停止するべきです' >&2
  exit 1
fi
git show-ref --verify -q refs/heads/merged-safety
git show-ref --verify -q refs/heads/squash
git branch -D merged-safety >/dev/null

# 照合中のコミット追加と、新たな worktree での使用開始を保護する
git branch moving main
git branch checkout-later main
git branch merged-race main
output=$(MOCK_REF_CHANGE=1 gitcleanbr 2> "$tmpdir/race-errors")
[[ "$output" == *'deleted: 1'* ]]
[[ "$(git rev-parse moving)" == "$unmerged_sha" ]]
git show-ref --verify -q refs/heads/checkout-later
! git show-ref --verify -q refs/heads/merged-race
git show-ref --verify -q refs/heads/squash

git clone -q "$tmpdir/origin.git" "$tmpdir/other"
git -C "$tmpdir/other" switch -q main
git -C "$tmpdir/other" -c user.name=Test -c user.email=test@example.com commit -q --allow-empty -m newer
git -C "$tmpdir/other" push -q origin main
if gitcleanbr --dry-run; then
  echo '基準コミットがない場合は停止するべきです' >&2
  exit 1
fi
git show-ref --verify -q refs/heads/unmerged
echo 'gitcleanbr: OK'
