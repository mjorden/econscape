# Decompose a price change into substitution and income effects

When the price of one good changes, the consumer moves from the original
bundle to a new one. The textbook splits that move in two by imagining
an intermediate, *compensated* budget at the new prices:

## Usage

``` r
price_change(
  u,
  b,
  new_px = NULL,
  new_py = NULL,
  method = c("hicks", "slutsky")
)

slutsky(u, b, new_px = NULL, new_py = NULL)

hicks(u, b, new_px = NULL, new_py = NULL)
```

## Arguments

- u:

  A function of `x` and `y`, typically from
  [`cobb_douglas()`](https://mjorden.github.io/econscape/reference/cobb_douglas.md)
  or one of its siblings.

- b:

  The original
  [`budget()`](https://mjorden.github.io/econscape/reference/budget.md).

- new_px, new_py:

  The new price. Supply exactly one.

- method:

  `"hicks"` (the default) or `"slutsky"`.

## Value

An object of class `price_change`: a list with

- `bundles` – a data frame with one row each for the `original`,
  `compensated` and `final` bundles: `stage`, `x`, `y`, `utility`,
  `income`.

- `effects` – a data frame with rows `substitution`, `income` and
  `total`, and columns `dx` and `dy`.

- `budgets` – the three
  [`budget()`](https://mjorden.github.io/econscape/reference/budget.md)
  objects, in the same order.

- `method`, `good` (the good whose price changed), `old_price`,
  `new_price`.

## Details

- **Hicks** compensation gives the consumer just enough income to reach
  the original utility at the new prices. The compensated bundle sits on
  the original indifference curve.

- **Slutsky** compensation gives just enough income to afford the
  original bundle at the new prices. The compensated budget line passes
  through the original bundle.

The move from the original bundle to the compensated one is the
*substitution effect* (a pure response to relative prices); the move
from the compensated bundle to the final one is the *income effect*.

`slutsky()` and `hicks()` are shorthands for `price_change()` with
`method` fixed.

## See also

[`plot_price_change()`](https://mjorden.github.io/econscape/reference/plot_price_change.md)
to draw it.

## Examples

``` r
u <- cobb_douglas(alpha = 0.4)
b <- budget(income = 120, px = 3, py = 4)

pc <- price_change(u, b, new_px = 6)
pc
#> <Price change: px 3 -> 6, Hicksian compensation>
#>   original     x =       16  y =       18  (income 120)
#>   compensated  x =    10.56  y =    23.75  (income 158.3)
#>   final        x =        8  y =       18  (income 120)
#>   effects on x :
#>     substitution -5.444
#>     income       -2.556
#>     total        -8
pc$effects
#>         effect        dx        dy
#> 1 substitution -5.443937  5.751142
#> 2       income -2.556063 -5.751142
#> 3        total -8.000000  0.000000

# Quasi-linear preferences: the income effect on x vanishes
q <- quasilinear(log, f_prime = function(x) 1 / x)
slutsky(q, b, new_px = 6)$effects
#>         effect            dx dy
#> 1 substitution -6.666667e-01  1
#> 2       income  3.105294e-13 -1
#> 3        total -6.666667e-01  0
```
