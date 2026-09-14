# Two-part tariffs

A seller who charges an entry fee plus a per-unit price. With identical
consumers the answer is Disneyland's: set the price at marginal cost and
the fee at the whole of each consumer's surplus, which replicates
[`first_degree()`](https://mjorden.github.io/econscape/reference/price_discrimination.md)
profit with only two numbers.

## Usage

``` r
two_part_tariff(demands, cost, n = 1)
```

## Arguments

- demands:

  A demand object (one consumer type), or a list of them, one per type,
  each describing a single consumer's demand.

- cost:

  A cost object.

- n:

  Number of consumers of each type. Recycled to the number of types.

## Value

An object of class `two_part_tariff`: a list with `price`, `fee`,
`served` (logical, per type), `types` (a data frame: `type`, `n`,
`served`, `quantity` per consumer, `surplus` per consumer after the
fee), `quantity` (total), `profit`, `marginal_cost`, and `candidates`
(the profit of each cut-off considered).

## Details

With different types of consumer the seller faces a trade-off. Serving
everyone means pinning the fee to the *lowest* type's surplus, which
pushes the optimal price above marginal cost so the higher types pay
more through the per-unit charge. Alternatively the seller can exclude
the low types and take the high types' full surplus. `two_part_tariff()`
evaluates every "serve this type and above" cut-off, optimises the price
for each, and returns the most profitable.

## See also

[`plot_two_part_tariff()`](https://mjorden.github.io/econscape/reference/plot_two_part_tariff.md).

## Examples

``` r
d <- linear_demand(intercept = 100, slope = 1)
cst <- quadratic_cost(a = 20)

two_part_tariff(d, cst)                    # p = 20, fee = 3200
#> <Two-part tariff>
#>   fee 3200, price per unit 20 (marginal cost 20)
#>   segment_1    n = 1, buys 80, surplus after fee 0
#>   total quantity 80, profit 3200

light <- linear_demand(intercept = 60, slope = 1)
two_part_tariff(list(light = light, heavy = d), cst, n = c(5, 1))  # serve both, p > MC
#> <Two-part tariff>
#>   fee 555.6, price per unit 26.67 (marginal cost 20)
#>   light        n = 5, buys 33.33, surplus after fee 0
#>   heavy        n = 1, buys 73.33, surplus after fee 2133
#>   total quantity 240, profit 4933
two_part_tariff(list(light = light, heavy = d), cst, n = c(1, 1))  # exclude light users
#> <Two-part tariff>
#>   fee 3200, price per unit 20 (marginal cost 20)
#>   light        n = 1, not served
#>   heavy        n = 1, buys 80, surplus after fee 0
#>   total quantity 80, profit 3200
```
