# Deprecated 2025 URPS roster-snapshot count constants

`URPS_COUNT_ABOG_ONLY_2025` (1031) and `URPS_COUNT_ABOG_PLUS_ABU_2025`
(1339) are the 2025 `roster_snapshot` headcounts, kept as **deprecated**
warn-on-access bindings. Use
[`urps_count()`](https://mufflyt.github.io/mufflyaccess/reference/urps_count.md)
instead:
`urps_count(2025, "roster_snapshot", "national", include_urology = FALSE)`
and the `include_urology = TRUE` variant. These are the 2025 roster,
**not** the 2023 `board_certified_active` count (1027 / 1306).

## See also

[`urps_count()`](https://mufflyt.github.io/mufflyaccess/reference/urps_count.md)
