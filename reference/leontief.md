# Perfect complements (Leontief) functions

Builds \\f(x, y) = A \min(x / a, y / b)\\: the goods are only useful in
the fixed proportion \\a : b\\, so the contours are L-shaped with the
kink on the ray \\x / a = y / b\\. The consumer always chooses the kink,
whatever the prices.

## Usage

``` r
leontief(a = 1, b = 1, A = 1, kind = c("utility", "production"))
```

## Arguments

- a, b:

  Units of `x` and `y` needed per unit of output. Positive. (`b` here is
  the textbook coefficient, not a
  [`budget()`](https://mjorden.github.io/econscape/reference/budget.md).)

- A:

  Scale factor. Positive.

- kind:

  `"utility"` or `"production"`.

## Value

A function of `x` and `y` of class `leontief`, with `a`, `b`, `A` and
`kind` as attributes.

## Details

The MRS is not a single number here. Below the ray (`x / a < y / b`) `x`
is the scarce good and the consumer would give up any amount of `y` for
it, so [`mrs()`](https://mjorden.github.io/econscape/reference/mrs.md)
returns `Inf`; above the ray it returns `0`; on the ray itself the curve
has a corner and the MRS is undefined, returned as `NA`.

## Examples

``` r
u <- leontief(a = 1, b = 2)   # one x for every two y
u(3, 6)
#> [1] 3
optimal_bundle(u, budget(100, 2, 5))
#>          x        y  utility
#> 1 8.333333 16.66667 8.333333
mrs(u, c(1, 3, 5), 6)          # Inf below the ray, NA on it, 0 above
#> [1] Inf  NA   0
```
