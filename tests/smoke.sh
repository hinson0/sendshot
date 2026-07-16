#!/usr/bin/env bash
set -Eeuo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

bash -n "$ROOT/install.sh"
bash -n "$ROOT/bin/sendshot"
bash -n "$ROOT/shell/sendshot.bash"

"$ROOT/bin/sendshot" --help >/dev/null
"$ROOT/bin/sendshot" --version | grep -q '^sendshot '

printf 'smoke tests passed\n'
