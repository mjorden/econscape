# The marginal-utility-per-dollar purchase order

Lists every unit of both goods in the order a rational consumer buys
them – highest marginal utility per dollar first – with the running
total spent, so the answer to "what do I buy with \$35?" is read off
where the cumulative cost passes the income. This is the argument the
introductory course makes;
[`optimal_bundle()`](https://mjorden.github.io/fredscape/reference/optimal_bundle.md)
reaches the same bundle by exhaustive search, and the two agree whenever
marginal utility is diminishing.

## Usage

``` r
mu_per_dollar(u, b)
```

## Arguments

- u:

  A
  [`utility_table()`](https://mjorden.github.io/fredscape/reference/utility_table.md).

- b:

  A
  [`budget()`](https://mjorden.github.io/fredscape/reference/budget.md);
  prices may be
  [`price_schedule()`](https://mjorden.github.io/fredscape/reference/price_schedule.md)s,
  in which case each unit is priced at its own tier.

## Value

A data frame with one row per unit: `good`, `unit`, `price`, `mu`,
`mu_per_dollar`, `cumulative_cost`, `affordable`.

## Examples

``` r
u <- utility_table(c(20, 37, 50, 60, 65), c(16, 30, 40, 46, 48),
                   goods = c("movies", "popcorn"))
mu_per_dollar(u, budget(35, px = 7.5, py = 3))
#>       good unit price mu mu_per_dollar cumulative_cost affordable
#> 1  popcorn    1   3.0 16     5.3333333             3.0       TRUE
#> 2  popcorn    2   3.0 14     4.6666667             6.0       TRUE
#> 3  popcorn    3   3.0 10     3.3333333             9.0       TRUE
#> 4   movies    1   7.5 20     2.6666667            16.5       TRUE
#> 5   movies    2   7.5 17     2.2666667            24.0       TRUE
#> 6  popcorn    4   3.0  6     2.0000000            27.0       TRUE
#> 7   movies    3   7.5 13     1.7333333            34.5       TRUE
#> 8   movies    4   7.5 10     1.3333333            42.0      FALSE
#> 9   movies    5   7.5  5     0.6666667            49.5      FALSE
#> 10 popcorn    5   3.0  2     0.6666667            52.5      FALSE
```
