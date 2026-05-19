#!/usr/bin/env bash
set -euo pipefail

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$repo_root"

for command_name in gs python3; do
	if ! command -v "$command_name" >/dev/null 2>&1; then
		echo "error: $command_name is required to check PDFs" >&2
		exit 1
	fi
done

tmp_dir="$(mktemp -d "${TMPDIR:-/tmp}/podplane-cla-check.XXXXXX")"
restore_pdfs() {
	cp "$tmp_dir/original/podplane-icla.pdf" podplane-icla.pdf
	cp "$tmp_dir/original/podplane-ccla.pdf" podplane-ccla.pdf
	rm -rf "$tmp_dir"
}
trap restore_pdfs EXIT

mkdir -p "$tmp_dir/original" "$tmp_dir/generated" "$tmp_dir/text"
cp podplane-icla.pdf podplane-ccla.pdf "$tmp_dir/original/"

pdf_date="${PDF_DATE:-}"
if [[ -z "$pdf_date" ]]; then
	pdf_date="$(python3 - <<'PY'
import re
from pathlib import Path

dates = []
for path in ("podplane-icla.pdf", "podplane-ccla.pdf"):
    data = Path(path).read_bytes().decode("latin-1", errors="ignore")
    match = re.search(r"<xmp:CreateDate>(\d{4}-\d{2}-\d{2})T", data)
    if not match:
        raise SystemExit(f"Could not find xmp:CreateDate in {path}")
    dates.append(match.group(1))

if len(set(dates)) != 1:
    raise SystemExit(f"Committed PDFs have different dates: {dates}")

print(dates[0])
PY
)"
fi

echo "Checking PDFs generated with PDF_DATE=$pdf_date"
PDF_DATE="$pdf_date" ./scripts/generate-pdfs.sh
cp podplane-icla.pdf podplane-ccla.pdf "$tmp_dir/generated/"

extract_text() {
	local input_file="$1"
	local output_file="$2"

	gs -q -dBATCH -dNOPAUSE -sDEVICE=txtwrite -sOutputFile="$output_file" "$input_file"
}

normalize_text() {
	local input_file="$1"
	local output_file="$2"

	python3 - "$input_file" "$output_file" <<'PY'
import re
import sys
from pathlib import Path

source = Path(sys.argv[1]).read_text(errors="ignore")
normalized = re.sub(r"\s+", " ", source).strip()
Path(sys.argv[2]).write_text(normalized + "\n")
PY
}

for pdf_name in podplane-icla.pdf podplane-ccla.pdf; do
	extract_text "$tmp_dir/original/$pdf_name" "$tmp_dir/text/original-$pdf_name.txt"
	extract_text "$tmp_dir/generated/$pdf_name" "$tmp_dir/text/generated-$pdf_name.txt"
	normalize_text "$tmp_dir/text/original-$pdf_name.txt" "$tmp_dir/text/original-$pdf_name.normalized.txt"
	normalize_text "$tmp_dir/text/generated-$pdf_name.txt" "$tmp_dir/text/generated-$pdf_name.normalized.txt"
	diff -u "$tmp_dir/text/original-$pdf_name.normalized.txt" "$tmp_dir/text/generated-$pdf_name.normalized.txt"
done
