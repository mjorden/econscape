# Prices, quantities and revenue along a demand curve

Prices, quantities and revenue along a demand curve

## Usage

``` r
price_at(d, q, ...)

quantity_at(d, p, ...)

marginal_revenue(d, q, ...)

elasticity(d, q, ...)

consumer_surplus(d, q, ...)
```

## Arguments

- d:

  A demand object from
  [`linear_demand()`](https://mjorden.github.io/econscape/reference/demand.md)
  or
  [`demand_fn()`](https://mjorden.github.io/econscape/reference/demand.md).

- q:

  Quantity. May be a vector.

- ...:

  Passed on to methods.

- p:

  Price. May be a vector.

## Value

A numeric vector.

- `price_at()` – the price at which `q` is demanded (inverse demand).

- `quantity_at()` – the quantity demanded at price `p`.

- `marginal_revenue()` – \\P(q) + q P'(q)\\, the extra revenue from one
  more unit when the price must fall to sell it.

- `elasticity()` – the price elasticity of demand at `q`,
  \\(dQ/dP)(P/Q)\\; negative, and below \\-1\\ where demand is elastic.

- `consumer_surplus()` – the area under the demand curve and above the
  price, up to `q`.

## Examples

``` r
d <- linear_demand(intercept = 100, slope = 1)
price_at(d, c(0, 40, 100))
#> [1] 100  60   0
quantity_at(d, 60)
#> [1] 40
marginal_revenue(d, 40)      # 100 - 2 * 40
#> [1] 20
elasticity(d, c(20, 50, 80)) # elastic above the midpoint
#> [1] -4.00 -1.00 -0.25
consumer_surplus(d, 40)
#> [1] 800
```
