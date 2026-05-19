#!/usr/bin/env bash
set -euo pipefail

repo_root="$(git rev-parse --show-toplevel)"
cd "$repo_root"

make pdf

if ! git diff --quiet -- podplane-icla.pdf podplane-ccla.pdf; then
	echo "Generated PDFs are out of date. Review and stage the updated PDFs:" >&2
	echo "  git add podplane-icla.pdf podplane-ccla.pdf" >&2
	exit 1
fi
