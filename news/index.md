# Changelog

## tm.ttni 0.1.0

- Encoding-panel `teal.picks` badges show the selected column
  (`PARAMCD`, `TRT01A`) without the dataset name. The dataset stays on
  the badge tooltip (`datasets:` / `variables:`). `teal.picks` has no
  argument to omit that slot from the summary.
- PARAMCD selection now uses `teal.picks`. Legacy `choices_selected`
  input is still accepted and signals a deprecation warning.
- Treatment / group variable and population flag now use `teal.picks`
  column selectors (`multiple = FALSE`). A character vector for
  `group_vars`, and `population_var` / `population_choices`, are still
  accepted and signal a deprecation warning.
- Initial TTNI table builder using `tern` / `rtables`.
- Automatic two-arm vs multi-arm detection via
  [`detect_arm_design()`](https://ygma-bitc.github.io/tm.ttni/reference/detect_arm_design.md).
- Hazard ratio, Wald CI, and log-rank p-value are calculated only for
  two-arm designs.
- Multi-arm / dose-level tables keep event counts, Kaplan-Meier
  quartiles, follow-up time, and landmark rates.
- Teal module uses `shinyvalidate`, a no-data path, and Show R Code.
- [`build_ttni_table()`](https://ygma-bitc.github.io/tm.ttni/reference/build_ttni_table.md)
  accepts a `prepped` object so the server prepares data once.
- Synthetic fixtures expose a subject-level ADSL and a BDS ADTTE
  (`TTNI` + `OS`).
- The demo HR-off example uses the public CDISC Pilot three-arm study;
  synthetic multi-arm labels are generic (`Arm A` / `Arm B` / `Arm C`).
- Interactive tables omit method footnotes by default; definitions are
  in the README. Pass
  [`default_ttni_footnotes()`](https://ygma-bitc.github.io/tm.ttni/reference/default_ttni_footnotes.md)
  for a TFL-style footer.
- Time-to-event statistics include descriptive Mean (SD) of `AVAL`.
  Median and 95% CI are always one `median_ci_3d` row. Quartiles and
  range are labeled `Q1, Q3` and `Min, Max`.
- CDISC Pilot / `random.cdisc.data` adapters via
  [`standardize_adsl()`](https://ygma-bitc.github.io/tm.ttni/reference/standardize_adsl.md)
  and
  [`standardize_adtte()`](https://ygma-bitc.github.io/tm.ttni/reference/standardize_adtte.md).
