# Producer theory: expansion paths and cost curves

The consumer's problem and the producer's cost-minimisation problem are
the same mathematics with different names: a production function is a
utility function over inputs, an isocost line is a budget line with
input prices, and the expenditure function is the total-cost function.
These helpers put the producer's vocabulary on the machinery the rest of
the package already has.

## Usage

``` r
expansion_path(f, w, r, outlays)

conditional_demand(f, w, r, q)

cost_curves(f, w, r, q, fixed = 0)
```

## Arguments

- f:

  A production function of `x` and `y`, e.g.
  `cobb_douglas(0.3, 0.5, kind = "production")`.

- w, r:

  Input prices for `x` and `y` (wage and rental rate, by convention).

- outlays:

  Vector of total outlays.

- q:

  Vector of output levels. Positive.

- fixed:

  A fixed cost added to total cost. It does not affect marginal cost,
  but gives average cost its textbook U shape.

## Value

A data frame:

- `expansion_path()`: `outlay`, `x`, `y`, `output`.

- `conditional_demand()`: `output`, `x`, `y`, `cost`.

- `cost_curves()`: `output`, `total`, `average`, `marginal`.

## Details

- `expansion_path()` – the cost-minimising input bundle at each level of
  outlay, i.e. the income-consumption path read as a producer.

- `conditional_demand()` – the cheapest input bundle that produces each
  output level, and what it costs.

- `cost_curves()` – total, average and marginal cost at each output
  level. Marginal cost is closed-form for Cobb-Douglas (\\C(q) \propto
  q^{1/(\alpha+\beta)}\\, so \\MC = C / ((\alpha + \beta) q)\\) and a
  numerical derivative of
  [`expenditure()`](https://mjorden.github.io/econscape/reference/expenditure.md)
  otherwise; for the constant- returns constructors that derivative is
  exact.

## Examples

``` r
f <- cobb_douglas(0.3, 0.5, A = 2, kind = "production")
f   # decreasing returns to scale
#> <Cobb-Douglas production function>
#>   f(x, y) = 2 * x^0.3 * y^0.5
#>   decreasing returns to scale (degree 0.8)

expansion_path(f, w = 20, r = 30, outlays = c(300, 600, 900))
#>   outlay      x     y    output
#> 1    300  5.625  6.25  8.394731
#> 2    600 11.250 12.50 14.616075
#> 3    900 16.875 18.75 20.216397
conditional_demand(f, w = 20, r = 30, q = c(5, 10, 20))
#>   output         x         y     cost
#> 1      5  2.943246  3.270273 156.9731
#> 2     10  7.000258  7.778065 373.3471
#> 3     20 16.649514 18.499460 887.9741
cost_curves(f, w = 20, r = 30, q = c(5, 10, 20), fixed = 100)
#>   output    total  average marginal
#> 1      5 256.9731 51.39463 39.24328
#> 2     10 473.3471 47.33471 46.66839
#> 3     20 987.9741 49.39870 55.49838
```
