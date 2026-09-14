# Fetch recession dates live from FRED

Downloads `USREC`, the NBER-based recession indicator (1 during a
contraction, 0 otherwise), and collapses each run of ones into a
peak/trough interval. Use this instead of the bundled
[nber_recessions](https://mjorden.github.io/econscape/reference/nber_recessions.md)
when you need the current dating, including any recession called since
this package was last released.

## Usage

``` r
fred_recessions(key = fred_key())
```

## Arguments

- key:

  A FRED API key. Defaults to
  [`fred_key()`](https://mjorden.github.io/econscape/reference/fred_key.md).

## Value

A data frame with `peak` and `trough` `Date` columns, in the same shape
[`annotate_recessions()`](https://mjorden.github.io/econscape/reference/annotate_recessions.md)
expects.

## Examples

``` r
if (FALSE) { # econscape::fred_has_key()
tail(fred_recessions(), 3)
}
```
