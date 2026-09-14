# Coefficient table for an `econ_fit`

Coefficient table for an `econ_fit`

## Usage

``` r
coef_table(x, level = 0.95)
```

## Arguments

- x:

  An `econ_fit` from
  [`ols()`](https://mjorden.github.io/econscape/reference/ols.md).

- level:

  Confidence level for the interval.

## Value

A data frame with one row per coefficient: `term`, `estimate`,
`std_error`, `statistic`, `p_value`, `conf_low`, `conf_high`. The
statistic is compared to a t distribution with the residual degrees of
freedom whichever standard errors were chosen.

## Examples

``` r
fit <- ols(psavert ~ uempmed, ggplot2::economics, se = "hc1")
coef_table(fit)
#>          term   estimate std_error statistic       p_value   conf_low
#> 1 (Intercept) 10.5875798 0.2337834  45.28798 2.601086e-191 10.1284011
#> 2     uempmed -0.2346847 0.0202791 -11.57273  5.630921e-28 -0.2745153
#>    conf_high
#> 1 11.0467585
#> 2 -0.1948541
```
