# Market equilibrium under monopoly, oligopoly and perfect competition

Each function puts a demand curve together with a cost function and
solves for the outcome:

## Usage

``` r
monopoly(demand, cost)

cournot(demand, cost, n)

perfect_competition(demand, cost, n = NULL)
```

## Arguments

- demand:

  A demand object from
  [`linear_demand()`](https://mjorden.github.io/econscape/reference/demand.md)
  or
  [`demand_fn()`](https://mjorden.github.io/econscape/reference/demand.md).

- cost:

  A cost object from
  [`quadratic_cost()`](https://mjorden.github.io/econscape/reference/cost.md)
  or
  [`production_cost()`](https://mjorden.github.io/econscape/reference/cost.md).

- n:

  Number of firms. For `perfect_competition()`, `NULL` for the long run.

## Value

An object of class `market_outcome`: a list with `structure`, `n`,
`price`, `quantity` (industry), `q_firm`, `profit_firm`,
`consumer_surplus`, `producer_surplus`, `deadweight_loss` (against the
efficient `P = MC` outcome for the same number of firms), `lerner`
(\\(P - MC) / P\\), `elasticity` (of demand at the outcome), and
`efficient` (the benchmark `price` and `quantity`). Surpluses exclude
fixed costs, which are sunk.

## Details

- `monopoly()` – a single seller sets marginal revenue equal to marginal
  cost.

- `cournot()` – `n` identical firms choose quantities simultaneously;
  the symmetric equilibrium solves \\P(nq) + q P'(nq) = MC(q)\\. With
  `n = 1` it is the monopoly; as `n` grows it approaches competition.

- `perfect_competition()` – price-taking firms set marginal cost equal
  to price. With `n` given this is the short run: `n` firms, each
  producing where \\MC(q) = P\\, unless price is below average variable
  cost, in which case they shut down. With `n = NULL` it is the long
  run: entry drives price to minimum average cost and the number of
  firms follows from demand (it need not be a whole number).

Every function returns the same `market_outcome` object, so the
structures can be compared directly;
[`compare_structures()`](https://mjorden.github.io/econscape/reference/compare_structures.md)
does exactly that.

## Examples

``` r
d <- linear_demand(intercept = 100, slope = 1)
cst <- quadratic_cost(a = 20)          # constant marginal cost 20

monopoly(d, cst)                       # Q = 40, P = 60
#> <Market outcome: monopoly, 1 firm>
#>   price 60, quantity 40 (40 per firm), profit per firm 1600
#>   consumer surplus 800, producer surplus 1600, deadweight loss 800
#>   Lerner index 0.6667, demand elasticity -1.5
cournot(d, cst, n = 2)                 # each firm 80/3
#> <Market outcome: cournot, 2 firms>
#>   price 46.67, quantity 53.33 (26.67 per firm), profit per firm 711.1
#>   consumer surplus 1422, producer surplus 1422, deadweight loss 355.6
#>   Lerner index 0.5714, demand elasticity -0.875
perfect_competition(d, cst, n = 10)    # P = 20, no deadweight loss
#> <Market outcome: competition, 10 firms>
#>   price 20, quantity 80 (8 per firm), profit per firm 0
#>   consumer surplus 3200, producer surplus 0, deadweight loss 0
#>   Lerner index 0, demand elasticity -0.25

# Long run with U-shaped average cost: entry until P = min AC
perfect_competition(d, quadratic_cost(fixed = 100, a = 20, b = 1))
#> <Market outcome: competition (long run), 6 firms>
#>   price 40, quantity 60 (10 per firm), profit per firm 0
#>   consumer surplus 1800, producer surplus 600, deadweight loss 0
#>   Lerner index 0, demand elasticity -0.6667
```
