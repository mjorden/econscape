# Look up FRED series metadata

Returns the title, units, frequency and seasonal-adjustment status of
one or more series – the information needed to label an axis honestly.

## Usage

``` r
fred_series_info(series_id, key = fred_key())
```

## Arguments

- series_id:

  Character vector of FRED series IDs, e.g. `"UNRATE"` or
  `c("UNRATE", "GDPC1")`.

- key:

  A FRED API key. Defaults to
  [`fred_key()`](https://mjorden.github.io/econscape/reference/fred_key.md).

## Value

A data frame with one row per series and columns `series_id`, `title`,
`units`, `units_short`, `frequency`, `seasonal_adjustment`,
`observation_start`, `observation_end`, `last_updated`, `popularity` and
`notes`.

## Examples

``` r
if (FALSE) { # econscape::fred_has_key()
fred_series_info("UNRATE")$title
}
```
