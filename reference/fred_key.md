# Manage the FRED API key

FRED requires a free API key for every request. `econscape` reads it
from the `FRED_API_KEY` environment variable so that the key never has
to appear in a script, a git history, or an error message.

## Usage

``` r
fred_key()

fred_has_key()

fred_set_key(key)
```

## Arguments

- key:

  A 32-character lower-case alphanumeric FRED API key.

## Value

`fred_key()` returns the key as a string, and errors if none is set.
`fred_has_key()` returns `TRUE` or `FALSE` and never errors.
`fred_set_key()` invisibly returns the previous value of the environment
variable, so it can be restored.

## Details

Request a key at <https://fredaccount.stlouisfed.org/apikeys>, then
either add `FRED_API_KEY=<your key>` to your user-level `.Renviron`
(`usethis::edit_r_environ()`) or call `fred_set_key()` for the current
session.

## Examples

``` r
fred_has_key()
#> [1] FALSE

# Set a key for this session only:
old <- fred_set_key(strrep("a", 32))
fred_has_key()
#> [1] TRUE
Sys.setenv(FRED_API_KEY = old)
```
