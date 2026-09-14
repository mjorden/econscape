# Coordinates of a budget line

Coordinates of a budget line

## Usage

``` r
budget_line(b, n_points = NULL)
```

## Arguments

- b:

  A
  [`budget()`](https://mjorden.github.io/fredscape/reference/budget.md).

- n_points:

  Number of points. Two is enough for a straight line (the default); a
  kinked budget defaults to 200 and always includes its kinks.

## Value

A data frame with `x` and `y` columns running from the `y` intercept to
the `x` intercept. For a kinked budget the rows trace the frontier
through every kink.

## Examples

``` r
budget_line(budget(100, 2, 5))
#>    x  y
#> 1  0 20
#> 2 50  0
```
