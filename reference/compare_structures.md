# Compare market structures on the same demand and cost

Runs
[`monopoly()`](https://mjorden.github.io/econscape/reference/market_structure.md),
[`cournot()`](https://mjorden.github.io/econscape/reference/market_structure.md)
for each value of `n`, and
[`perfect_competition()`](https://mjorden.github.io/econscape/reference/market_structure.md)
with the largest `n`, and lines the outcomes up.

## Usage

``` r
compare_structures(demand, cost, n = c(2, 3, 5, 10))
```

## Arguments

- demand:

  A demand object from
  [`linear_demand()`](https://mjorden.github.io/econscape/reference/demand.md)
  or
  [`demand_fn()`](https://mjorden.github.io/econscape/reference/demand.md).

- cost:

  A cost object from
  [`quadratic_cost()`](https://mjorden.github.io/econscape/reference/cost.md)
  or
  [`production_cost()`](https://mjorden.github.io/econscape/reference/cost.md).

- n:

  Numbers of firms to evaluate Cournot at.

## Value

A data frame with one row per structure: `structure`, `n`, `price`,
`quantity`, `profit_firm`, `consumer_surplus`, `producer_surplus`,
`deadweight_loss`, `lerner`.

## Examples

``` r
compare_structures(linear_demand(100, 1), quadratic_cost(a = 20), n = c(2, 3, 5, 10))
#>     structure  n    price quantity profit_firm consumer_surplus
#> 1    monopoly  1 60.00000 40.00000  1600.00000          800.000
#> 2     cournot  2 46.66667 53.33333   711.11111         1422.222
#> 3     cournot  3 40.00000 60.00000   400.00000         1800.000
#> 4     cournot  5 33.33333 66.66667   177.77778         2222.222
#> 5     cournot 10 27.27273 72.72727    52.89256         2644.628
#> 6 competition 10 20.00000 80.00000     0.00000         3200.000
#>   producer_surplus deadweight_loss    lerner
#> 1        1600.0000       800.00000 0.6666667
#> 2        1422.2222       355.55556 0.5714286
#> 3        1200.0000       200.00000 0.5000000
#> 4         888.8889        88.88889 0.4000000
#> 5         528.9256        26.44628 0.2666667
#> 6           0.0000         0.00000 0.0000000
```
