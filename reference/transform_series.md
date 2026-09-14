# Transform a tidy series the way FRED does

[`fred_series()`](https://mjorden.github.io/econscape/reference/fred_series.md)
can ask the API for a transformed series through `units`; this applies
the same definitions locally, so a frame already downloaded (or one
built from any other source) can be reworked without another request.
Each series in the frame is transformed separately.

## Usage

``` r
transform_series(
  df,
  how = c("lin", "chg", "ch1", "pch", "pc1", "pca", "cch", "cca", "log", "index"),
  frequency = NULL
)
```

## Arguments

- df:

  A data frame with `date` and `value` columns and optionally
  `series_id`, as returned by
  [`fred_series()`](https://mjorden.github.io/econscape/reference/fred_series.md).

- how:

  One of the codes above.

- frequency:

  Observations per year (1, 4, 12, 52, 260). Inferred from the dates
  when `NULL`.

## Value

The same frame with `value` transformed. Observations that need an
earlier one that does not exist become `NA` rather than being dropped,
so the rows still line up with the original.

## Details

The codes match FRED's:

- `"lin"` – levels, unchanged.

- `"chg"` – change from the previous observation.

- `"ch1"` – change from a year ago.

- `"pch"` – percent change from the previous observation.

- `"pc1"` – percent change from a year ago.

- `"pca"` – compounded annual rate of change.

- `"cch"` – continuously compounded rate of change (log difference, in
  percent).

- `"cca"` – continuously compounded annual rate of change.

- `"log"` – natural log.

- `"index"` – rescaled so the first non-missing observation is 100.

"A year ago" needs the number of observations per year, inferred from
the spacing of `date` unless `frequency` is given.

## Examples

``` r
econ <- ggplot2::economics
cpi_like <- data.frame(series_id = "PCE", date = econ$date, value = econ$pce)
head(transform_series(cpi_like, "pc1"), 14)
#>    series_id       date    value
#> 1        PCE 1967-07-01       NA
#> 2        PCE 1967-08-01       NA
#> 3        PCE 1967-09-01       NA
#> 4        PCE 1967-10-01       NA
#> 5        PCE 1967-11-01       NA
#> 6        PCE 1967-12-01       NA
#> 7        PCE 1968-01-01       NA
#> 8        PCE 1968-02-01       NA
#> 9        PCE 1968-03-01       NA
#> 10       PCE 1968-04-01       NA
#> 11       PCE 1968-05-01       NA
#> 12       PCE 1968-06-01       NA
#> 13       PCE 1968-07-01 11.15058
#> 14       PCE 1968-08-01 11.22009
head(transform_series(cpi_like, "index"))
#>   series_id       date    value
#> 1       PCE 1967-07-01 100.0000
#> 2       PCE 1967-08-01 100.6118
#> 3       PCE 1967-09-01 101.7565
#> 4       PCE 1967-10-01 101.0855
#> 5       PCE 1967-11-01 102.1117
#> 6       PCE 1967-12-01 103.6313
```
