# Quasi-linear utility

Builds \\u(x, y) = f(x) + y\\ for a concave `f`: utility is linear in
`y`, so `y` absorbs all income effects and the demand for `x` depends on
prices alone (as long as the consumer can afford the interior optimum).
The textbook case is `f = log`.

## Usage

``` r
quasilinear(f, f_prime = NULL)
```

## Arguments

- f:

  A concave function of one argument.

- f_prime:

  Its derivative, or `NULL` to approximate numerically.

## Value

A function of `x` and `y` of class `quasilinear`, with `f`, `f_prime`
and `kind = "utility"` as attributes.

## Details

Demand solves \\f'(x) = p_x / p_y\\. Pass `f_prime` if you have it;
otherwise it is approximated numerically and the root is found with
[`stats::uniroot()`](https://rdrr.io/r/stats/uniroot.html). Either way
the corners are checked: if even the first unit of `x` is not worth its
price the consumer buys none, and if the last affordable unit still is,
the consumer buys nothing but `x`.

Unlike the other constructors this one has no `kind` argument: a
function linear in one input has no sensible reading as a technology, so
it is always a utility function.

## Examples

``` r
u <- quasilinear(log, f_prime = function(x) 1 / x)
optimal_bundle(u, budget(100, 2, 5))
#>     x  y  utility
#> 1 2.5 19 19.91629
optimal_bundle(u, budget(500, 2, 5))   # same x: no income effect
#>     x  y  utility
#> 1 2.5 99 99.91629
```
