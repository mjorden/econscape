# A firm's cost function

`quadratic_cost()` is the textbook \\C(q) = F + a q + b q^2\\: constant
marginal cost when `b = 0`, rising marginal cost otherwise, and a
U-shaped average cost whenever both `fixed` and `b` are positive.
`production_cost()` derives the cost function from a production function
and input prices through
[`expenditure()`](https://mjorden.github.io/fredscape/reference/expenditure.md),
so the market module can sit directly on the producer-theory one.

## Usage

``` r
quadratic_cost(fixed = 0, a = 0, b = 0)

production_cost(f, w, r, fixed = 0)
```

## Arguments

- fixed:

  Fixed cost. Non-negative.

- a:

  Linear coefficient: marginal cost at zero output. Non-negative.

- b:

  Quadratic coefficient. Non-negative. (The textbook letter, not a
  [`budget()`](https://mjorden.github.io/fredscape/reference/budget.md);
  see `?fredscape-extending` for the naming conventions.)

- f:

  A production function of `x` and `y`.

- w, r:

  Input prices.

## Value

An object of class `cost` (and `quadratic_cost` or `production_cost`).

## See also

[`total_cost()`](https://mjorden.github.io/fredscape/reference/cost_values.md)
and friends;
[`monopoly()`](https://mjorden.github.io/fredscape/reference/market_structure.md),
[`cournot()`](https://mjorden.github.io/fredscape/reference/market_structure.md),
[`perfect_competition()`](https://mjorden.github.io/fredscape/reference/market_structure.md).

## Examples

``` r
cst <- quadratic_cost(fixed = 100, a = 20, b = 0.5)
cst
#> <Quadratic cost>
#>   C(q) = 100 + 20 * q + 0.5 * q^2
marginal_cost(cst, 10)
#> [1] 30
min_average_cost(cst)
#> $q
#> [1] 14.14214
#> 
#> $ac
#> [1] 34.14214
#> 

pc <- production_cost(cobb_douglas(0.3, 0.5, kind = "production"), w = 20, r = 30)
total_cost(pc, 10)
#> [1] 887.9741
```
