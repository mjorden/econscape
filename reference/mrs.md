# Marginal rate of substitution

The slope of the indifference curve at `(x, y)`, expressed as a positive
number: how much `y` the consumer would give up for one more unit of
`x`. For Cobb-Douglas this is \\\frac{\alpha}{\beta} \frac{y}{x}\\;
other functions use a central finite difference on each partial
derivative. The step is scaled to the coordinate (`h * |x|`, floored at
`h * 1e-8`) so the estimate stays well-conditioned from near-axis points
to quantities in the millions, and the backward point is never taken
below zero – at a point within a step of an axis the difference becomes
one-sided rather than evaluating `u` on a negative quantity, where most
utilities return `NaN`.

## Usage

``` r
# S3 method for class 'utility_table'
mrs(u, x, y, ...)

mrs(u, x, y, ...)

# S3 method for class 'cobb_douglas'
mrs(u, x, y, ...)

# Default S3 method
mrs(u, x, y, ..., h = 1e-06)

# S3 method for class 'ces'
mrs(u, x, y, ...)

# S3 method for class 'leontief'
mrs(u, x, y, ...)

# S3 method for class 'perfect_substitutes'
mrs(u, x, y, ...)

# S3 method for class 'quasilinear'
mrs(u, x, y, ...)
```

## Arguments

- u:

  A function of `x` and `y`.

- x, y:

  Coordinates, recycled against each other.

- ...:

  Passed on to methods.

- h:

  Relative step for the finite difference (default method only).

## Value

A numeric vector.

## Details

At the optimal bundle the MRS equals the price ratio `px / py` – the
tangency condition – which is a handy check on
[`optimal_bundle()`](https://mjorden.github.io/fredscape/reference/optimal_bundle.md).

## Examples

``` r
u <- cobb_douglas(alpha = 0.3)
b <- budget(100, 2, 5)
opt <- optimal_bundle(u, b)
mrs(u, opt$x, opt$y)   # equals px / py = 0.4
#> [1] 0.4
```
