# Deprecated frozen URPS workforce constants

**Deprecated – use
[`urps_count()`](https://mufflyt.github.io/mufflyaccess/reference/urps_count.md).**
`URPS_COUNT_ABOG_ONLY_2025` (1031) and `URPS_COUNT_ABOG_PLUS_ABU_2025`
(1339) are the **2025 `roster_snapshot`** values (ABOG-only and ABOG +
ABU), *not* the 2023 board-certified active count (which under contract
v3.0.0 is 1027 / 1306). The bare `_2025` suffix cannot express the
measure/geography a value belongs to;
[`urps_count()`](https://mufflyt.github.io/mufflyaccess/reference/urps_count.md)
does, explicitly.

The replacement is
`urps_count(2025, "roster_snapshot", "national", include_urology = ...)`.
They are retained as **active bindings that warn on access** and return
the value, so existing references keep working while surfacing the
deprecation (installed in `.onLoad()`).

## See also

[`urps_count()`](https://mufflyt.github.io/mufflyaccess/reference/urps_count.md),
[`urps_lineage()`](https://mufflyt.github.io/mufflyaccess/reference/urps_lineage.md)
