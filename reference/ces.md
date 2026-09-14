# Constant elasticity of substitution (CES) functions

Builds \\f(x, y) = A \left(\alpha x^{\rho} + (1 - \alpha)
y^{\rho}\right)^{1/\rho}\\. The single parameter \\\rho \le 1\\ sets how
easily one good stands in for the other, through the elasticity of
substitution \\\sigma = 1 / (1 - \rho)\\:

## Usage

``` r
ces(rho, alpha = 0.5, A = 1, kind = c("utility", "production"))
```

## Arguments

- rho:

  Substitution parameter, at most 1 and not 0.

- alpha:

  Share parameter on `x`, strictly between 0 and 1.

- A:

  Scale factor. Positive.

- kind:

  `"utility"` or `"production"`.

## Value

A function of `x` and `y` of class `ces`, with `rho`, `alpha`, `A`,
`sigma` and `kind` as attributes.

## Details

- \\\rho = 1\\ is perfect substitutes (linear contours) –
  [`perfect_substitutes()`](https://mjorden.github.io/econscape/reference/perfect_substitutes.md)
  gives the same thing directly.

- \\\rho \to 0\\ is Cobb-Douglas; use
  [`cobb_douglas()`](https://mjorden.github.io/econscape/reference/cobb_douglas.md)
  for that limit, as the formula is undefined at exactly zero.

- \\\rho \to -\infty\\ is perfect complements –
  [`leontief()`](https://mjorden.github.io/econscape/reference/leontief.md).

Like
[`cobb_douglas()`](https://mjorden.github.io/econscape/reference/cobb_douglas.md),
the result is a callable function that carries its parameters, so
contours, demand and the MRS use closed forms.

## Examples

``` r
u <- ces(rho = 0.5, alpha = 0.4)
u
#> <CES utility function>
#>   f(x, y) = 1 * (0.4 * x^0.5 + 0.6 * y^0.5)^(1/0.5)
#>   elasticity of substitution sigma = 2
optimal_bundle(u, budget(100, 2, 5))
#>          x        y utility
#> 1 26.31579 9.473684    15.2

# Close to Cobb-Douglas when rho is small:
optimal_bundle(ces(rho = 1e-4, alpha = 0.3), budget(100, 2, 5))
#>          x        y  utility
#> 1 15.00007 13.99997 14.29279
optimal_bundle(cobb_douglas(0.3), budget(100, 2, 5))
#>    x  y  utility
#> 1 15 14 14.29279
```
