# Podplane Contributor License Agreements

This repository contains the contributor license agreements used for contributions to the Podplane open source ecosystem:

- [Individual CLA](podplane-icla.md) ([PDF](podplane-icla.pdf))
- [Corporate CLA](podplane-ccla.md) ([PDF](podplane-ccla.pdf))

Covered projects include, without limitation, Podplane, Nstance, Netsy, Easy OIDC, puidv7, Terraform/OpenTofu modules, Kubernetes operators, SDKs, websites, documentation, and related software owned or managed by Nadrama Pty Ltd.

The CLA documents in this repository are derived from [Apache Software Foundation contributor agreement templates](https://www.apache.org/licenses/contributor-agreements.html).

For maintainers: run `make setup` to install the pre-commit git hook, `make pdf` to regenerate the PDFs from the Markdown source files, and `make check` to verify they are up to date. PDF generation requires Pandoc and Typst. PDF checking also requires Ghostscript. GitHub Actions verifies the PDFs in each commit are in sync with the relevant Markdown file.
