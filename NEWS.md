# tm.ttni 0.1.0

* Initial TTNI table builder using `tern` / `rtables`.
* Automatic two-arm vs multi-arm detection via `detect_arm_design()`.
* Hazard ratio, Wald CI, and log-rank p-value are calculated only for two-arm designs.
* Multi-arm / dose-level tables keep event counts, Kaplan-Meier quartiles, follow-up time, and landmark rates.
* Teal module uses `teal.transform` PARAMCD selection, `shinyvalidate`, a no-data path, and Show R Code.
* `build_ttni_table()` accepts a `prepped` object so the server prepares data once.
* Synthetic fixtures expose a subject-level ADSL and a BDS ADTTE (`TTNI` + `OS`).
* The demo HR-off example uses the public CDISC Pilot three-arm study; synthetic multi-arm labels are generic (`Arm A` / `Arm B` / `Arm C`).
* Interactive tables omit method footnotes by default; definitions are in the README. Pass `default_ttni_footnotes()` for a TFL-style footer.
* Time-to-event statistics include descriptive Mean (SD) of `AVAL`. Median and 95% CI are always one `median_ci_3d` row. Quartiles and range are labeled `Q1, Q3` and `Min, Max`.
* CDISC Pilot / `random.cdisc.data` adapters via `standardize_adsl()` and `standardize_adtte()`.
