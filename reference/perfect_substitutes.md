# Perfect substitutes (linear) functions

Builds \\f(x, y) = A (a x + b y)\\: straight-line contours with constant
MRS \\a / b\\. The consumer spends everything on whichever good gives
more utility per unit of money, so the optimum is a corner unless \\a /
p_x = b / p_y\\ exactly, when every point on the budget line is equally
good. In that knife-edge case
[`optimal_bundle()`](https://mjorden.github.io/econscape/reference/optimal_bundle.md)
returns the midpoint of the budget line and flags the result with an
`indeterminate` attribute set to `TRUE`. "Exactly" means within
[`all.equal()`](https://rdrr.io/r/base/all.equal.html)'s default
tolerance, about 1.5e-8 relative: two utilities-per-dollar that differ
only in the ninth significant figure count as a tie.

## Usage

``` r
perfect_substitutes(a = 1, b = 1, A = 1, kind = c("utility", "production"))
```

## Arguments

- a, b:

  Marginal utility of `x` and `y`. Positive. (`b` here is the textbook
  coefficient, not a
  [`budget()`](https://mjorden.github.io/econscape/reference/budget.md)
  – the letter is kept because that is how the formula is written.)

- A:

  Scale factor. Positive.

- kind:

  `"utility"` or `"production"`.

## Value

A function of `x` and `y` of class `perfect_substitutes`, with `a`, `b`,
`A` and `kind` as attributes.

## Examples

``` r
u <- perfect_substitutes(a = 1, b = 2)   # y is worth twice x
optimal_bundle(u, budget(100, 1, 1))     # all y
#>   x   y utility
#> 1 0 100     200
optimal_bundle(u, budget(100, 1, 3))     # all x
#>     x y utility
#> 1 100 0     100
attr(optimal_bundle(u, budget(100, 1, 2)), "indeterminate")
#> [1] TRUE
```
