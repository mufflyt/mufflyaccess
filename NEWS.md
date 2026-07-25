# mufflyaccess (development version)

* Expanded `README.md` to a full reference of all 34 exported objects, grouped by
  domain, with design principles and a scope-boundary note.
* Added `URL` and `BugReports` to `DESCRIPTION`.
* Added this `NEWS.md` changelog.

# mufflyaccess 0.1.4

* Promoted the accessibility-disparity **pure statistics** shared by `isochrones`
  and `twostep` into `R/accessibility_stats.R`: `weighted_mean_all()`,
  `zero_access_share()`, `mc_weighted_ci()`, `annual_trend()`,
  `rurality_from_ruca()`, `tract_vintage_of()`, `acs_year_of()`, plus the ACS
  variable codes `TOTAL_FEMALE_VAR` and `RACE_FEMALE_VARS`. Base R + `stats` only.
* Promoted the **safe-division family** into `R/safe_divide.R`: `safe_divide()`,
  `safe_divide_manu()`, `safe_percent()`, `safe_pct_manu()`, `safe_rate()`, and
  `safe_ratio()` — one zero-denominator guarantee across all pipelines.

# mufflyaccess 0.1.3

* Promoted from `isochrones`: `RUCA_NONMETRO_MIN` (2-level metro/rural
  breakpoint), the ACS margin-of-error z multipliers (`ACS_MOE_Z90`, `CI_Z95`,
  `MOE90_TO_CI95_FACTOR`), and the Wu-2014 age-specific PFD prevalence table
  (`WU2014_PFD_PREVALENCE`, `pfd_prevalence()`, `pfd_prevalence_acs_bands()`).

# mufflyaccess 0.1.2

* Fixed the package test to strip provenance attributes before comparison
  (`expect_equal` attribute mismatch on `ACS2020_CONUS_FEMALE_POP`).

# mufflyaccess 0.1.1

* Attached `vintage`/`table`/`scope`/`units` provenance attributes to
  `ACS2020_CONUS_FEMALE_POP` to match consumer contracts.

# mufflyaccess 0.1.0

* Initial release: single-source-of-truth constants shared across the OB/GYN
  subspecialty geographic-access repositories (`isochrones`, `twostep`, `cliff`)
  — primary access band, canonical bands, total-female denominator category,
  tract "reached" coverage cut, national CONUS ACS female population, and the
  contiguous / non-contiguous state code lists. Every value carries provenance
  and fail-loud load-time validation.
