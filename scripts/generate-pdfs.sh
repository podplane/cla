#!/usr/bin/env bash
set -euo pipefail

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$repo_root"

for command_name in pandoc typst; do
	if ! command -v "$command_name" >/dev/null 2>&1; then
		echo "error: $command_name is required to generate PDFs" >&2
		echo "Install with: brew install pandoc typst" >&2
		exit 1
	fi
done

tmp_dir="$(mktemp -d "${TMPDIR:-/tmp}/podplane-cla.XXXXXX")"
trap 'rm -rf "$tmp_dir"' EXIT

pdf_date="${PDF_DATE:-$(date -u +%Y-%m-%d)}"

if [[ ! "$pdf_date" =~ ^[0-9]{4}-[0-9]{2}-[0-9]{2}$ ]]; then
	echo "error: PDF_DATE must use YYYY-MM-DD format" >&2
	exit 1
fi

date_to_epoch() {
	local date_value="$1"

	if date -u -d "$date_value 00:00:00" +%s >/dev/null 2>&1; then
		date -u -d "$date_value 00:00:00" +%s
	else
		date -u -j -f "%Y-%m-%d %H:%M:%S" "$date_value 00:00:00" +%s
	fi
}

export SOURCE_DATE_EPOCH="${SOURCE_DATE_EPOCH:-$(date_to_epoch "$pdf_date")}"

echo "Using PDF_DATE=$pdf_date"

sha512_file() {
	local source_file="$1"

	if command -v sha512sum >/dev/null 2>&1; then
		sha512sum "$source_file" | awk '{print $1}'
	else
		shasum -a 512 "$source_file" | awk '{print $1}'
	fi
}

generate_pdf() {
	local source_file="$1"
	local output_file="$2"
	local source_sha512 source_sha512_short generated_date footer_file

	source_sha512="$(sha512_file "$source_file")"
	source_sha512_short="${source_sha512:0:32}"
	generated_date="$pdf_date"
	footer_file="$tmp_dir/${output_file%.pdf}-footer.typ"

	echo "Generating PDF from $source_file ..."
	cat > "$footer_file" <<EOF
#let source_sha512 = "$source_sha512_short"
#let generated_date = "$generated_date"

#set page(
  margin: 0.875in,
  footer: context align(center, text(size: 8pt)[Page #counter(page).display() of #counter(page).final().at(0) · Version: #source_sha512 · Date: #generated_date UTC]),
)

#show heading: it => block(below: 14pt)[#it]
EOF

	pandoc "$source_file" \
		--from=gfm \
		--pdf-engine=typst \
		--include-before-body="$footer_file" \
		--variable=papersize:a4 \
		--variable=fontsize:10pt \
		--variable=linkcolor:0645ad \
		--output="$output_file"

	echo "Done. Created: $output_file"
}

generate_pdf podplane-icla.md podplane-icla.pdf
generate_pdf podplane-ccla.md podplane-ccla.pdf
