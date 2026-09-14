# Ordinary least squares with robust standard errors

[`stats::lm()`](https://rdrr.io/r/stats/lm.html) underneath, with the
covariance matrix replaced by one that survives the two things macro
data always has: heteroskedasticity and serial correlation.

## Usage

``` r
ols(formula, data, se = c("classical", "hc1", "hac"), lags = NULL, ...)
```

## Arguments

- formula:

  A model formula, as for
  [`stats::lm()`](https://rdrr.io/r/stats/lm.html).

- data:

  A data frame.

- se:

  Which standard errors: `"classical"`, `"hc1"` or `"hac"`.

- lags:

  Bandwidth for `"hac"`. Ignored otherwise.

- ...:

  Passed to [`stats::lm()`](https://rdrr.io/r/stats/lm.html), e.g.
  `subset` or `weights`.

## Value

An object of class `econ_fit`: a list with `fit` (the `lm`), `vcov`,
`se_type`, `lags`, `nobs` and `df`.
[`coef_table()`](https://mjorden.github.io/econscape/reference/coef_table.md)
gives the coefficient table;
[`plot_coefficients()`](https://mjorden.github.io/econscape/reference/plot_coefficients.md)
draws it.

## Details

- `"classical"` – the usual \\\sigma^2 (X'X)^{-1}\\.

- `"hc1"` – White's heteroskedasticity-consistent estimator with the \\n
  / (n - k)\\ degrees-of-freedom correction (the default in Stata's
  `robust` option).

- `"hac"` – Newey and West (1987): Bartlett-weighted autocovariances of
  the score up to `lags`. With `lags = NULL` the bandwidth is \\\lfloor
  4 (n/100)^{2/9} \rfloor\\, the rule of thumb most software uses. No
  small-sample adjustment is applied.

Both robust estimators are computed directly from the design matrix and
residuals – a dozen lines of linear algebra – rather than through a
dependency, and the tests pin them against hand-computed sandwich
matrices.

## Examples

``` r
econ <- ggplot2::economics
econ$unemp_rate <- 100 * econ$unemploy / econ$pop

# Saving and unemployment, with serial correlation handled
fit <- ols(psavert ~ unemp_rate, econ, se = "hac")
fit
#> <OLS: psavert ~ unemp_rate>
#>   574 observations; Newey-West HAC, 5 lags standard errors
#>             estimate std_error     t       p    
#> (Intercept)     8.43      1.21  6.96 9.5e-12 ***
#> unemp_rate    0.0475      0.36 0.132     0.9    
#>   R-squared 0.000 (adjusted -0.002); residual s.e. 2.97 on 572 df
coef_table(fit)
#>          term   estimate std_error statistic      p_value   conf_low  conf_high
#> 1 (Intercept) 8.42512202 1.2110200 6.9570459 9.538376e-12  6.0465334 10.8037106
#> 2  unemp_rate 0.04754984 0.3604405 0.1319215 8.950928e-01 -0.6603985  0.7554982
```
