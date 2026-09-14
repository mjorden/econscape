# A budget constraint

Describes the set of bundles affordable at income `income` when the two
goods cost `px` and `py`: every \\(x, y)\\ with \\p_x x + p_y y \le I\\.
For a producer the same object is an isocost line, with `income` read as
total outlay and the prices as input prices.

## Usage

``` r
budget(income, px, py)
```

## Arguments

- income:

  Income, or total outlay. Positive.

- px, py:

  Prices of `x` and `y`: a positive number, or a
  [`price_schedule()`](https://mjorden.github.io/econscape/reference/price_schedule.md)
  for a good whose unit price changes with the quantity bought (quantity
  discounts, block tariffs). A schedule makes the budget line kinked;
  see
  [`price_schedule()`](https://mjorden.github.io/econscape/reference/price_schedule.md)
  for what that changes.

## Value

A list of class `budget` with the inputs plus the derived `x_max` and
`y_max` (the most of each good the income buys on its own), `slope`
(`-px / py`, or `NA` when a price is a schedule), `kinked` (`TRUE` when
either price is a schedule) and the cost functions `cost_x` and
`cost_y`.

## See also

[`budget_line()`](https://mjorden.github.io/econscape/reference/budget_line.md)
to get plottable coordinates,
[`optimal_bundle()`](https://mjorden.github.io/econscape/reference/optimal_bundle.md)
to solve against a utility function.

## Examples

``` r
b <- budget(income = 100, px = 2, py = 5)
b
#> <Budget constraint>
#>   2 * x + 5 * y <= 100
#>   intercepts: x = 50, y = 20; slope -0.4
b$x_max
#> [1] 50
```
