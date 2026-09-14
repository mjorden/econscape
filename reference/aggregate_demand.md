# Horizontal summation of demand curves

The market demand faced by a seller who cannot tell buyer groups apart:
at every price, the sum of the quantities each group demands. The
inverse is found numerically, so the result is a
[`demand_fn()`](https://mjorden.github.io/econscape/reference/demand.md)
and works anywhere a demand object does – most usefully as the
uniform-price benchmark for
[`third_degree()`](https://mjorden.github.io/econscape/reference/price_discrimination.md).

## Usage

``` r
aggregate_demand(demands)
```

## Arguments

- demands:

  A list of demand objects.

## Value

A `general_demand` object whose `q_max` is the sum of the parts'.

## Examples

``` r
students <- linear_demand(intercept = 60, slope = 0.5)
others <- linear_demand(intercept = 100, slope = 1)
both <- aggregate_demand(list(students, others))
quantity_at(both, 40)   # 40 + 60
#> [1] 100
price_at(both, 100)
#> [1] 40
```
