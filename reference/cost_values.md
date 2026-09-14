# Cost at a level of output

Cost at a level of output

## Usage

``` r
total_cost(cost, q, ...)

variable_cost(cost, q, ...)

marginal_cost(cost, q, ...)

average_cost(cost, q, ...)

average_variable_cost(cost, q, ...)

min_average_cost(cost, q_max = NULL, ...)
```

## Arguments

- cost:

  A cost object from
  [`quadratic_cost()`](https://mjorden.github.io/econscape/reference/cost.md)
  or
  [`production_cost()`](https://mjorden.github.io/econscape/reference/cost.md).

- q:

  Output. May be a vector.

- ...:

  Passed on to methods.

- q_max:

  Upper bound for the numerical search in `min_average_cost()`; only
  needed for a
  [`production_cost()`](https://mjorden.github.io/econscape/reference/cost.md).

## Value

A numeric vector, except `min_average_cost()`, which returns a list with
the output `q` at which average cost is lowest and the average cost `ac`
there. For a
[`quadratic_cost()`](https://mjorden.github.io/econscape/reference/cost.md)
with no fixed cost or no quadratic term average cost has no interior
minimum; `q` is then `NA` and `ac` the limiting value.

## Examples

``` r
cst <- quadratic_cost(fixed = 100, a = 20, b = 0.5)
total_cost(cst, c(0, 10, 20))
#> [1] 100 350 700
marginal_cost(cst, 10)     # 20 + 2 * 0.5 * 10
#> [1] 30
average_cost(cst, 10)
#> [1] 35
min_average_cost(cst)       # q = sqrt(F / b)
#> $q
#> [1] 14.14214
#> 
#> $ac
#> [1] 34.14214
#> 
```
