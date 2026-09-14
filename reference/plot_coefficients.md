# Draw a coefficient table

A dot-and-whisker plot of the estimates in an
[`ols()`](https://mjorden.github.io/fredscape/reference/ols.md) fit with
their confidence intervals, in the house style. Coefficients whose
interval excludes zero are drawn in blue, the rest in grey.

## Usage

``` r
plot_coefficients(
  fit,
  level = 0.95,
  intercept = FALSE,
  terms = NULL,
  title = NULL,
  subtitle = NULL,
  source = NULL,
  panel = NULL
)
```

## Arguments

- fit:

  An `econ_fit` from
  [`ols()`](https://mjorden.github.io/fredscape/reference/ols.md).

- level:

  Confidence level for the whiskers.

- intercept:

  Include the intercept? Usually on a different scale from the slopes,
  so off by default.

- terms:

  Optional character vector of terms to show, in order.

- title, subtitle, source:

  Passed to
  [`labs_econ()`](https://mjorden.github.io/fredscape/reference/labs_econ.md);
  sensible defaults are filled in.

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
econ$unemp_rate <- 100 * econ$unemploy / econ$pop
fit <- ols(psavert ~ unemp_rate + uempmed, econ, se = "hac")
plot_coefficients(fit)
```
