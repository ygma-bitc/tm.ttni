## Test environments

* local macOS 27.0.1 (aarch64), R 4.6.0, `R CMD check --as-cran --no-manual`
* win-builder R-release and R-devel (submitted; results emailed to the maintainer)
* GitHub Actions, ubuntu-latest, R release (Status: OK)

The local check used `--no-manual` because pdflatex is not installed. Rd checks passed. win-builder builds the PDF manual.

## R CMD check results

There was 1 NOTE:

* checking CRAN incoming feasibility ... NOTE

  Maintainer: Y.G. Ma <ygma0292@gmail.com>

  New submission

  This is the first submission of tm.ttni.

## Comments

The package name prefix `tm` means teal module (`tm_t_*`). It is not an extension of the text-mining package tm.
