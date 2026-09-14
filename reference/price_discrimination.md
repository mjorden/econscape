# Price discrimination

What a monopolist does with more than one price.

## Usage

``` r
first_degree(demand, cost)

third_degree(demands, cost)
```

## Arguments

- demand:

  A demand object.

- cost:

  A cost object.

- demands:

  A list of demand objects, one per segment. Names, if given, label the
  segments.

## Value

`first_degree()` returns a `market_outcome` (see
[market_structure](https://mjorden.github.io/econscape/reference/market_structure.md)).
`third_degree()` returns an object of class `third_degree`: a list with
`segments` (a data frame: `segment`, `price`, `quantity`, `elasticity`,
`lerner`, `revenue`), `quantity`, `marginal_cost`, `profit`, and
`uniform` (the `market_outcome` under a single price).

## Details

`first_degree()` is perfect discrimination: every unit sells at the
buyer's willingness to pay, so the seller keeps producing until price
equals marginal cost – the efficient quantity, with no deadweight loss –
and takes the entire surplus. There is no single price; `price` in the
result is the price of the last unit, \\P(Q) = MC\\.

`third_degree()` is segmentation: separate groups with their own demand
curves, one marginal cost, and no resale between them. The seller
equates marginal revenue across groups to the common marginal cost,
\\MR_i(Q_i) = MC(\sum Q_i)\\, which by the inverse-elasticity rule means
the less elastic group pays more. The result also carries the
uniform-price benchmark,
[`monopoly()`](https://mjorden.github.io/econscape/reference/market_structure.md)
on the
[`aggregate_demand()`](https://mjorden.github.io/econscape/reference/aggregate_demand.md),
so the gain from segmenting is explicit.

## Examples

``` r
d <- linear_demand(intercept = 100, slope = 1)
cst <- quadratic_cost(a = 20)

first_degree(d, cst)     # Q = 80, all 3200 of surplus to the seller
#> <Market outcome: first-degree discrimination, 1 firm>
#>   price 20, quantity 80 (80 per firm), profit per firm 3200
#>   consumer surplus 0, producer surplus 3200, deadweight loss 0
#>   Lerner index 0, demand elasticity -0.25
#>   note: price is that of the last unit; earlier units sold at willingness to pay 
monopoly(d, cst)         # for comparison: Q = 40, deadweight loss 800
#> <Market outcome: monopoly, 1 firm>
#>   price 60, quantity 40 (40 per firm), profit per firm 1600
#>   consumer surplus 800, producer surplus 1600, deadweight loss 800
#>   Lerner index 0.6667, demand elasticity -1.5

students <- linear_demand(intercept = 60, slope = 0.5)
third_degree(list(students = students, others = d), cst)
#> <Third-degree price discrimination>
#>   students     price 40, quantity 40, elasticity -2
#>   others       price 60, quantity 40, elasticity -1.5
#>   total quantity 80 at marginal cost 20; profit 2400
#>   uniform price instead: price 46.67, quantity 80, profit 2133
```
