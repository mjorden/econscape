# The expenditure function

The least income needed to reach a given utility (or, for a production
function, the least outlay needed to produce a given output) at the
stated prices. This is the object behind Hicksian compensation and
behind the total-cost curve, so every constructor has a dedicated
method: closed forms for Cobb-Douglas, CES, Leontief and perfect
substitutes, and for quasi-linear utility a single root-find for the
first-order condition followed by the closed form. Any other function is
solved by finding the income at which
[`optimal_bundle()`](https://mjorden.github.io/econscape/reference/optimal_bundle.md)
just reaches `level`, using
[`stats::uniroot()`](https://rdrr.io/r/stats/uniroot.html).

## Usage

``` r
expenditure(u, px, py, level, ...)

# S3 method for class 'cobb_douglas'
expenditure(u, px, py, level, ...)

# S3 method for class 'ces'
expenditure(u, px, py, level, ...)

# S3 method for class 'quasilinear'
expenditure(u, px, py, level, ...)

# S3 method for class 'leontief'
expenditure(u, px, py, level, ...)

# S3 method for class 'perfect_substitutes'
expenditure(u, px, py, level, ...)

# Default S3 method
expenditure(u, px, py, level, ...)
```

## Arguments

- u:

  A function of `x` and `y`.

- px, py:

  Prices.

- level:

  Target utility or output. May be a vector.

- ...:

  Passed on to methods.

## Value

A numeric vector the length of `level`.

## Examples

``` r
u <- cobb_douglas(alpha = 0.3)
b <- budget(100, 2, 5)
u0 <- optimal_bundle(u, b)$utility
expenditure(u, 2, 5, u0)   # recovers the income: 100
#> [1] 100

# What the same utility costs after px doubles
expenditure(u, 4, 5, u0)
#> [1] 123.1144
```
