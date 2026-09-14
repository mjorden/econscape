# Indifference curves and isoquants

For each `level`, finds the `y` that gives \\u(x, y) = \\ `level` at
every `x`, i.e. the contour of the function. Functions built by
[`cobb_douglas()`](https://mjorden.github.io/fredscape/reference/cobb_douglas.md),
[`ces()`](https://mjorden.github.io/fredscape/reference/ces.md),
[`leontief()`](https://mjorden.github.io/fredscape/reference/leontief.md),
[`perfect_substitutes()`](https://mjorden.github.io/fredscape/reference/perfect_substitutes.md)
and
[`quasilinear()`](https://mjorden.github.io/fredscape/reference/quasilinear.md)
use their closed forms (for Cobb-Douglas, \\y = (U / (A
x^{\alpha}))^{1/\beta}\\); any other function of two arguments is solved
numerically by bisection, which requires it to be non-decreasing in `y`
("more is better"). Where a contour is flat in `y` – perfect
complements, for instance – the smallest `y` that attains the level is
returned, which is the point on the L-shaped curve rather than somewhere
along its vertical arm.

## Usage

``` r
# S3 method for class 'utility_table'
indifference_curve(u, level, x, ...)

indifference_curve(u, level, x, ...)

# S3 method for class 'cobb_douglas'
indifference_curve(u, level, x, ...)

# Default S3 method
indifference_curve(u, level, x, ..., y_range = c(1e-09, 1e+09))

# S3 method for class 'ces'
indifference_curve(u, level, x, ...)

# S3 method for class 'leontief'
indifference_curve(u, level, x, ...)

# S3 method for class 'perfect_substitutes'
indifference_curve(u, level, x, ...)

# S3 method for class 'quasilinear'
indifference_curve(u, level, x, ...)
```

## Arguments

- u:

  A function of `x` and `y`, typically from
  [`cobb_douglas()`](https://mjorden.github.io/fredscape/reference/cobb_douglas.md).

- level:

  One or more utility (or output) levels.

- x:

  Numeric vector of `x` values at which to evaluate the curve.

- ...:

  Passed on to methods.

- y_range:

  Search interval for the numeric solver. Defaults to a wide positive
  range; narrow it if the function is only well-behaved on part of the
  plane.

## Value

A data frame with columns `x`, `y` and `level`, one row per `x` per
level, stacked in `level` order. `y` is `NA` where no solution exists:
for the numeric method, where the level is unreachable within `y_range`;
for Cobb-Douglas, at `x <= 0` or `level <= 0`, where the closed form is
undefined. The two methods agree wherever a level is unattainable and at
`x = 0` for any positive level, so a caller can filter on `is.na(y)`
without knowing which one ran. (At `level = 0` exactly, a Cobb-Douglas
contour is the pair of axes; the closed form reports `NA` rather than
pretend that is a curve.)

## Examples

``` r
u <- cobb_douglas(alpha = 0.5)
indifference_curve(u, level = c(2, 4), x = c(1, 2, 4, 8))
#>   x    y level
#> 1 1  4.0     2
#> 2 2  2.0     2
#> 3 4  1.0     2
#> 4 8  0.5     2
#> 5 1 16.0     4
#> 6 2  8.0     4
#> 7 4  4.0     4
#> 8 8  2.0     4

# A perfect-complements (Leontief) utility, solved numerically
leontief <- function(x, y) pmin(x, y)
indifference_curve(leontief, level = 3, x = c(3, 4, 5))
#>   x y level
#> 1 3 3     3
#> 2 4 3     3
#> 3 5 3     3
```
