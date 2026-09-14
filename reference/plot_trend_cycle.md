# Draw a trend-cycle decomposition

Two panels in the house style: the series with its trend, and the cycle
below it around zero. With dates present, NBER recessions are shaded.

## Usage

``` r
plot_trend_cycle(
  tc,
  title = NULL,
  subtitle = NULL,
  source = NULL,
  recessions = TRUE,
  panel = NULL
)
```

## Arguments

- tc:

  A `trend_cycle` from
  [`hp_filter()`](https://mjorden.github.io/fredscape/reference/trend_cycle.md)
  or
  [`hamilton_filter()`](https://mjorden.github.io/fredscape/reference/trend_cycle.md).

- title, subtitle, source:

  Passed to
  [`labs_econ()`](https://mjorden.github.io/fredscape/reference/labs_econ.md);
  sensible defaults are filled in.

- recessions:

  Shade NBER recessions? Only possible when `tc` has a `date` column.

- panel:

  Passed to
  [`theme_econ()`](https://mjorden.github.io/fredscape/reference/theme_econ.md).

## Value

A ggplot object. Add
[`econ_masthead()`](https://mjorden.github.io/fredscape/reference/econ_masthead.md)
last if you want the block.

## Examples

``` r
econ <- ggplot2::economics
u <- data.frame(date = econ$date, value = 100 * econ$unemploy / econ$pop)
plot_trend_cycle(hp_filter(u, frequency = "monthly"),
                 title = "Unemployment and its trend")
```
