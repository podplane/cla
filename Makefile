.PHONY: help pdf check setup

help:
	@echo "Targets:"
	@echo "  make setup  Install the pre-commit hook"
	@echo "  make pdf    Regenerate PDFs from their respective Markdown files"
	@echo "  make check  Regenerate PDFs and fail if their text is not up to date"

pdf:
	./scripts/generate-pdfs.sh

check:
	./scripts/check-pdfs.sh

setup:
	ln -sf ../../scripts/pre-commit.sh .git/hooks/pre-commit
