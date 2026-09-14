# A unit price that changes with the quantity bought

Quantity discounts ("25% off after the second"), block tariffs and
rationing all make a good's price depend on how much of it you already
have. A price schedule holds the unit price in each tier, and
[`budget()`](https://mjorden.github.io/fredscape/reference/budget.md)
accepts one in place of a number, giving a *kinked* budget line.

## Usage

``` r
price_schedule(price, discount = NULL, after = NULL, breaks = NULL)

schedule_cost(schedule, q)

schedule_quantity(schedule, spend)
```

## Arguments

- price:

  Base unit price, or a vector of tier prices when `breaks` is given.

- discount:

  Fraction off every unit after the first `after` units.

- after:

  Units bought at the base price before the discount applies.

- breaks:

  Upper bound of each tier except the last, which is unbounded. Must be
  increasing.

- schedule:

  A `price_schedule`, or a plain price.

- q:

  Quantities.

- spend:

  Money available.

## Value

An object of class `price_schedule`.

A numeric vector the length of `q`.

## Details

Two ways to build one: the common case as a base price with a discount
after a threshold, or the general case as a vector of tier prices and
the upper bounds of all but the last tier.

A kinked budget changes what the downstream functions can assume:
[`budget_line()`](https://mjorden.github.io/fredscape/reference/budget_line.md)
traces the frontier through the kinks,
[`geom_budget()`](https://mjorden.github.io/fredscape/reference/geom_micro.md)
draws it as a path, and
[`optimal_bundle()`](https://mjorden.github.io/fredscape/reference/optimal_bundle.md)
searches along the frontier numerically instead of using a closed form,
since the tangency condition no longer identifies the optimum on its own
(the kink itself is a candidate). The marginal rate of substitution is
still available from
[`mrs()`](https://mjorden.github.io/fredscape/reference/mrs.md), but the
budget's `slope` is `NA`.

## Examples

``` r
# Paintings $20 each, 25% off after the second
paintings <- price_schedule(20, discount = 0.25, after = 2)
paintings
#> <price schedule: 20 up to 2; 15 beyond 2> 
schedule_cost(paintings, 0:4)      # cumulative cost of 0..4 paintings
#> [1]  0 20 40 55 70
schedule_quantity(paintings, 100)  # how many $100 buys
#> [1] 6

# The same thing as tiers
price_schedule(c(20, 15), breaks = 2)
#> <price schedule: 20 up to 2; 15 beyond 2> 

b <- budget(income = 100, px = 10, py = paintings)
b
#> <Budget constraint, kinked>
#>   income 100; x: 10; y: <price schedule: 20 up to 2; 15 beyond 2>
#>   intercepts: x = 10, y = 6
budget_line(b, n_points = 5)
#>       x   y
#> 1  0.00 6.0
#> 2  2.25 4.5
#> 3  4.50 3.0
#> 4  6.00 2.0
#> 5  7.00 1.5
#> 6 10.00 0.0
```
