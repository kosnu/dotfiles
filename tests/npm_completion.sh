#!/bin/bash
set -eu
repo_root=$(CDPATH= cd -- "$(dirname "$0")/.." && pwd)
source "$repo_root/npm_completion.sh"
npm() { return 7; }
COMP_WORDS=(npm test)
COMP_CWORD=1
COMP_LINE='npm test'
COMP_POINT=8
status=0
_npm_completion || status=$?
if [ "$status" -ne 7 ]; then
  echo "npm 補完の終了コードが正しくありません: $status" >&2
  exit 1
fi
echo 'npm completion: OK'
