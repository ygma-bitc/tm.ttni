## Resubmission

This is a resubmission of tm.ttni 0.1.0 addressing the 2026-11-03 review from Leonore Hochhauser. Version remains 0.1.0.

* Maintainer: `Authors@R` now gives the maintainer's first and last name, Yaoguang Ma <ygma0929@gmail.com>.

* References: none added. There is no package-specific method citation beyond standard Kaplan-Meier and hazard-ratio tooling. Kaplan-Meier summaries, hazard ratios, Wald confidence intervals, and log-rank tests come from 'tern' and 'rtables'. No additional reference of the form authors (year) <doi:...>, <ISBN:...>, or <https:...> applies.

## Test environments

* local Ubuntu 24.04.5 LTS (x86_64-pc-linux-gnu), R 4.6.2 (2026-10-29), `R CMD check --as-cran`

## R CMD check results

There was 1 NOTE:

* checking CRAN incoming feasibility ... NOTE

  Maintainer: Yaoguang Ma <ygma0929@gmail.com>

  New submission

## Comments

The package name prefix `tm` means teal module (`tm_t_*`). It is not an extension of the text-mining package tm.
