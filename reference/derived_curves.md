# Curves traced by the optimal bundle

[`optimal_bundle()`](https://mjorden.github.io/econscape/reference/optimal_bundle.md)
answers one question: what does the consumer choose at one set of prices
and one income? These functions ask it repeatedly and collect the
answers.

## Usage

``` r
demand_curve(u, b, prices, good = "x")

engel_curve(u, b, incomes, good = "x")

price_consumption_path(u, b, prices, good = "x")

income_consumption_path(u, b, incomes)
```

## Arguments

- u:

  A function of `x` and `y`, typically from
  [`cobb_douglas()`](https://mjorden.github.io/econscape/reference/cobb_douglas.md)
  or one of its siblings.

- b:

  A
  [`budget()`](https://mjorden.github.io/econscape/reference/budget.md)
  giving the baseline income and prices. The one being varied is
  overridden.

- prices:

  Vector of prices for `good` to evaluate at.

- good:

  Which good's price to vary or quantity to report: `"x"` or `"y"`.

- incomes:

  Vector of incomes to evaluate at.

## Value

A data frame, one row per price or income:

- `demand_curve()`: `price`, `quantity`, `good`.

- `engel_curve()`: `income`, `quantity`, `good`.

- `price_consumption_path()`: `price`, `x`, `y`, `good`.

- `income_consumption_path()`: `income`, `x`, `y`.

## Details

- `demand_curve()` varies the price of one good, holding the other price
  and income fixed, and records the quantity of that good.

- `engel_curve()` varies income, holding both prices fixed, and records
  the quantity of one good.

- `price_consumption_path()` and `income_consumption_path()` are the
  same experiments, but keep the whole bundle `(x, y)` so the locus can
  be drawn on the indifference-curve diagram.

Every constructor in the package has a closed-form
[`optimal_bundle()`](https://mjorden.github.io/econscape/reference/optimal_bundle.md),
so these are fast; a plain `function(x, y)` goes through the numeric
line search once per point.

## Examples

``` r
u <- cobb_douglas(alpha = 0.4)
b <- budget(income = 120, px = 3, py = 4)

# Cobb-Douglas demand is a rectangular hyperbola: x = 0.4 * 120 / px
demand_curve(u, b, prices = c(1, 2, 4, 8))
#>   price quantity good
#> 1     1       48    x
#> 2     2       24    x
#> 3     4       12    x
#> 4     8        6    x

# ... and the Engel curve a ray through the origin
engel_curve(u, b, incomes = c(60, 120, 240))
#>   income quantity good
#> 1     60        8    x
#> 2    120       16    x
#> 3    240       32    x

# Quasi-linear: the demand for x ignores income entirely
q <- quasilinear(log, f_prime = function(x) 1 / x)
engel_curve(q, b, incomes = c(60, 120, 240))
#>   income quantity good
#> 1     60 1.333333    x
#> 2    120 1.333333    x
#> 3    240 1.333333    x
```
