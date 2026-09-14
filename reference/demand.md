# Market demand

The demand side of a market, written as inverse demand \\P(Q)\\: the
price at which buyers take quantity \\Q\\. `linear_demand()` is the
textbook \\P = a - bQ\\ and has closed forms for everything below;
`demand_fn()` accepts any decreasing function of `q` and falls back to
numerical methods.

## Usage

``` r
linear_demand(intercept, slope)

demand_fn(p_of_q, q_max)
```

## Arguments

- intercept:

  Choke price \\a\\: the price at which demand is zero.

- slope:

  \\b\\: how fast price falls per unit of quantity. Positive.

- p_of_q:

  A function of one argument returning the price at that quantity. Must
  be decreasing.

- q_max:

  The largest quantity worth considering (for example, where price
  reaches zero). Numerical searches are confined to `[0, q_max]`.

## Value

An object of class `demand` (and `linear_demand` or `general_demand`).

## See also

[`price_at()`](https://mjorden.github.io/econscape/reference/demand_curve_values.md),
[`marginal_revenue()`](https://mjorden.github.io/econscape/reference/demand_curve_values.md),
[`consumer_surplus()`](https://mjorden.github.io/econscape/reference/demand_curve_values.md),
and the market structures
[`monopoly()`](https://mjorden.github.io/econscape/reference/market_structure.md),
[`cournot()`](https://mjorden.github.io/econscape/reference/market_structure.md),
[`perfect_competition()`](https://mjorden.github.io/econscape/reference/market_structure.md).

## Examples

``` r
d <- linear_demand(intercept = 100, slope = 1)
d
#> <Linear demand>
#>   P = 100 - 1 * Q   (Q = 0 at P = 100; P = 0 at Q = 100)
price_at(d, 40)
#> [1] 60
marginal_revenue(d, 40)
#> [1] 20
elasticity(d, 40)
#> [1] -1.5

# Constant-elasticity demand, handled numerically
ce <- demand_fn(function(q) 400 / sqrt(q + 1), q_max = 1000)
marginal_revenue(ce, 15)
#> [1] 53.125
```
