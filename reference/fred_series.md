# Download FRED series observations

Fetches one or more series from the FRED `series/observations` endpoint
and returns them stacked in a single tidy data frame – one row per
series per date – which is the shape ggplot2 wants for a multi-series
chart.

## Usage

``` r
fred_series(
  series_id,
  start = NULL,
  end = NULL,
  units = "lin",
  frequency = NULL,
  aggregation_method = "avg",
  key = fred_key()
)
```

## Arguments

- series_id:

  Character vector of FRED series IDs, e.g. `"UNRATE"` or
  `c("UNRATE", "GDPC1")`.

- start, end:

  Optional observation window. A `Date`, or anything
  [`as.Date()`](https://rdrr.io/r/base/as.Date.html) accepts. `NULL`
  means the full available history.

- units:

  Unit transformation applied by FRED before it returns the data:
  `"lin"` (levels, the default), `"chg"` (change), `"ch1"` (change from
  a year ago), `"pch"` (percent change), `"pc1"` (percent change from a
  year ago), `"pca"` (compounded annual rate of change), `"cch"`,
  `"cca"` or `"log"`.

- frequency:

  Optional lower frequency to aggregate to, e.g. `"m"`, `"q"` or `"a"`.
  FRED can only aggregate downwards.

- aggregation_method:

  How to aggregate when `frequency` is set: `"avg"`, `"sum"` or `"eop"`
  (end of period).

- key:

  A FRED API key. Defaults to
  [`fred_key()`](https://mjorden.github.io/econscape/reference/fred_key.md).

## Value

A data frame with columns `series_id` (character), `date` (`Date`) and
`value` (numeric), sorted by series then date. A series with no
observations in the requested window contributes no rows.

## Details

FRED encodes a missing observation as the string `"."`; those become
`NA` rather than a coercion warning.

## See also

[`fred_series_info()`](https://mjorden.github.io/econscape/reference/fred_series_info.md)
for the metadata behind a series, and
[`fred_search()`](https://mjorden.github.io/econscape/reference/fred_search.md)
to find an ID in the first place.

## Examples

``` r
if (FALSE) { # econscape::fred_has_key()
fred_series("UNRATE", start = "2000-01-01")

# Several series at once, as year-on-year percent change
fred_series(c("CPIAUCSL", "PCEPI"), start = "2015-01-01", units = "pc1")
}
```
