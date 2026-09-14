# Cobb-Douglas utility and production functions

Builds the function \\f(x, y) = A x^{\alpha} y^{\beta}\\ as a callable R
function that also remembers its parameters, so the closed-form results
(indifference curves, demand, marginal rate of substitution) can be read
straight off it rather than re-derived numerically.

## Usage

``` r
cobb_douglas(alpha, beta = 1 - alpha, A = 1, kind = c("utility", "production"))
```

## Arguments

- alpha:

  Exponent on `x`. Must be positive.

- beta:

  Exponent on `y`. Defaults to `1 - alpha`, which gives a
  homogeneous-of-degree-one function; any positive value is allowed.

- A:

  Scale factor (total factor productivity, for a production function).
  Must be positive.

- kind:

  `"utility"` or `"production"`.

## Value

A function of two arguments `x` and `y`, of class `cobb_douglas`,
carrying `alpha`, `beta`, `A` and `kind` as attributes.

## Details

The same object serves as a utility function over two goods or a
production function over two inputs; the maths is identical, only the
vocabulary changes (indifference curve vs isoquant, budget line vs
isocost). `kind` records which reading is intended and drives the labels
that
[`plot_consumer_choice()`](https://mjorden.github.io/econscape/reference/plot_consumer_choice.md)
and [`print()`](https://rdrr.io/r/base/print.html) use.

## See also

[`indifference_curve()`](https://mjorden.github.io/econscape/reference/indifference_curve.md),
[`optimal_bundle()`](https://mjorden.github.io/econscape/reference/optimal_bundle.md),
[`mrs()`](https://mjorden.github.io/econscape/reference/mrs.md),
[`budget()`](https://mjorden.github.io/econscape/reference/budget.md).

## Examples

``` r
u <- cobb_douglas(alpha = 0.3)
u
#> <Cobb-Douglas utility function>
#>   f(x, y) = 1 * x^0.3 * y^0.7
#>   constant returns to scale (degree 1)
u(x = 4, y = 9)
#> [1] 7.056474

f <- cobb_douglas(alpha = 0.6, beta = 0.6, A = 2, kind = "production")
f
#> <Cobb-Douglas production function>
#>   f(x, y) = 2 * x^0.6 * y^0.6
#>   increasing returns to scale (degree 1.2)
```
