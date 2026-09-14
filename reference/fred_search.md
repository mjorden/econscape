# Search FRED for series matching free text

Search FRED for series matching free text

## Usage

``` r
fred_search(text, limit = 25L, order_by = "search_rank", key = fred_key())
```

## Arguments

- text:

  Search terms, e.g. `"real median household income"`.

- limit:

  Maximum number of results, 1 to 1000.

- order_by:

  Ranking: `"search_rank"`, `"popularity"`, `"observation_start"`,
  `"observation_end"` or `"last_updated"`.

- key:

  A FRED API key. Defaults to
  [`fred_key()`](https://mjorden.github.io/econscape/reference/fred_key.md).

## Value

A data frame in the same shape as
[`fred_series_info()`](https://mjorden.github.io/econscape/reference/fred_series_info.md).

## Examples

``` r
if (FALSE) { # econscape::fred_has_key()
head(fred_search("unemployment rate", limit = 5)[, c("series_id", "title")])
}
```
