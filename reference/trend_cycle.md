# Trend-cycle decompositions

Two ways of splitting a series into a slow-moving trend and the cycle
around it.

## Usage

``` r
hp_filter(x, lambda = NULL, frequency = c("quarterly", "annual", "monthly"))

hamilton_filter(x, h = 8L, p = 4L)
```

## Arguments

- x:

  A numeric vector, or a data frame from
  [`fred_series()`](https://mjorden.github.io/econscape/reference/fred_series.md)
  with `date` and `value` columns (a single series).

- lambda:

  Smoothing parameter. Overrides `frequency`.

- frequency:

  `"annual"`, `"quarterly"` or `"monthly"`, used to pick `lambda` when
  it is not given.

- h:

  Forecast horizon.

- p:

  Number of lags in the forecasting regression (including the current
  value).

## Value

An object of class `trend_cycle`: a data frame with columns `date` (if
`x` had one), `value`, `trend` and `cycle`, plus attributes `method` and
the tuning parameters.
[`plot_trend_cycle()`](https://mjorden.github.io/econscape/reference/plot_trend_cycle.md)
draws it.

## Details

`hp_filter()` is Hodrick and Prescott (1997): the trend minimises \\\sum
(y_t - \tau_t)^2 + \lambda \sum (\Delta^2 \tau_t)^2\\, a pentadiagonal
linear system solved directly. The smoothing parameter is usually set by
data frequency; the defaults are the conventional 100 / 1600 / 14400 for
annual / quarterly / monthly data. (Ravn and Uhlig 2002 argue for 6.25 /
1600 / 129600; pass `lambda` to use them.)

`hamilton_filter()` is Hamilton (2018), who argues the HP filter invents
spurious cycles: regress \\y\_{t+h}\\ on the current value and `p - 1`
lags, and call the residual the cycle – the part of the series `h`
periods ahead that could not be forecast from its recent past. The first
`h + p - 1` observations have no cycle value. Defaults `h = 8, p = 4`
are the paper's quarterly recommendation; use `h = 24, p = 12` for
monthly data.

## References

Hodrick, R. J. and Prescott, E. C. (1997). Postwar U.S. business cycles:
an empirical investigation. *Journal of Money, Credit and Banking*
29(1).

Hamilton, J. D. (2018). Why you should never use the Hodrick-Prescott
filter. *Review of Economics and Statistics* 100(5).

Ravn, M. O. and Uhlig, H. (2002). On adjusting the Hodrick-Prescott
filter for the frequency of observations. *Review of Economics and
Statistics* 84(2).

## Examples

``` r
econ <- ggplot2::economics
u <- data.frame(date = econ$date, value = 100 * econ$unemploy / econ$pop)

hp <- hp_filter(u, frequency = "monthly")
head(hp)
#> <Trend-cycle decomposition: Hodrick-Prescott, lambda = 14400; 6 observations>
#>         date    value    trend     cycle
#> 1 1967-07-01 1.481541 1.332146 0.1493954
#> 2 1967-08-01 1.480562 1.339397 0.1411650
#> 3 1967-09-01 1.485589 1.346658 0.1389306
#> 4 1967-10-01 1.576933 1.353950 0.2229826
#> 5 1967-11-01 1.536858 1.361302 0.1755554
#> 6 1967-12-01 1.511592 1.368760 0.1428323

hm <- hamilton_filter(u, h = 24, p = 12)
range(hm$cycle, na.rm = TRUE)
#> [1] -1.086383  2.131866
```
