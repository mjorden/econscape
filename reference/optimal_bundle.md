# The bundle a consumer (or producer) chooses

Maximises `u` subject to the budget constraint `b`. A Cobb-Douglas
consumer spends the fixed share \\\alpha / (\alpha + \beta)\\ of income
on `x`, which gives the closed form \\x^\* = \frac{\alpha}{\alpha +
\beta} \frac{I}{p_x}\\. Any other function is maximised numerically
along the budget line with
[`stats::optimize()`](https://rdrr.io/r/stats/optimize.html), which
finds the global optimum only if `u` is quasi-concave – true for the
usual textbook cases.

## Usage

``` r
# S3 method for class 'utility_table'
optimal_bundle(u, b, ...)

optimal_bundle(u, b, ...)

# S3 method for class 'cobb_douglas'
optimal_bundle(u, b, ...)

# Default S3 method
optimal_bundle(u, b, ...)

# S3 method for class 'ces'
optimal_bundle(u, b, ...)

# S3 method for class 'leontief'
optimal_bundle(u, b, ...)

# S3 method for class 'perfect_substitutes'
optimal_bundle(u, b, ...)

# S3 method for class 'quasilinear'
optimal_bundle(u, b, ...)
```

## Arguments

- u:

  A function of `x` and `y`.

- b:

  A
  [`budget()`](https://mjorden.github.io/fredscape/reference/budget.md).

- ...:

  Passed on to methods.

## Value

A one-row data frame with `x`, `y` and `utility` (the value of `u` at
the optimum).

## Examples

``` r
u <- cobb_douglas(alpha = 0.3)
b <- budget(income = 100, px = 2, py = 5)
optimal_bundle(u, b)
#>    x  y  utility
#> 1 15 14 14.29279

# Spends 30% of income on x regardless of prices:
optimal_bundle(u, budget(100, 4, 5))$x * 4
#> [1] 30
```
