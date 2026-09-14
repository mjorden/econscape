# Extending econscape with your own preferences, demand and cost

The theory functions dispatch on S3 classes, and most generics check
their first argument before dispatching. This page is the contract that
implies, so that a new preference, demand curve or cost function slots
in without editing the package.

## Utility and production functions

Anything that is an R function of `x` and `y` is accepted by
[`indifference_curve()`](https://mjorden.github.io/econscape/reference/indifference_curve.md),
[`optimal_bundle()`](https://mjorden.github.io/econscape/reference/optimal_bundle.md),
[`mrs()`](https://mjorden.github.io/econscape/reference/mrs.md),
[`expenditure()`](https://mjorden.github.io/econscape/reference/expenditure.md),
[`plot_consumer_choice()`](https://mjorden.github.io/econscape/reference/plot_consumer_choice.md)
and the rest; with no class it goes through the numerical methods
(bisection contours, a line search along the budget, finite-difference
MRS). To supply closed forms instead, give the function a class and
write the methods:

    stone_geary <- function(alpha, gamma_x, gamma_y) {
      f <- function(x, y) (x - gamma_x)^alpha * (y - gamma_y)^(1 - alpha)
      structure(f, class = c("stone_geary", "function"),
                alpha = alpha, gamma_x = gamma_x, gamma_y = gamma_y, kind = "utility")
    }
    optimal_bundle.stone_geary <- function(u, b, ...) { ... }

Any method you do not write falls back to the numerical default, so a
partial set is fine. Follow the package's own pattern for the rest:
parameters as attributes, a `kind` attribute of `"utility"` or
`"production"` (the diagrams read it for their labels), and a
[`print()`](https://rdrr.io/r/base/print.html) method.

## Demand and cost

[`demand_fn()`](https://mjorden.github.io/econscape/reference/demand.md)
already accepts any decreasing function of quantity, and
[`production_cost()`](https://mjorden.github.io/econscape/reference/cost.md)
any production function, so most needs are met without a new class. For
closed forms, subclass the base class so the generics' checks pass –
`class = c("isoelastic_demand", "demand")`, or `c("cubic_cost", "cost")`
– and write methods for the generics you need:
[`price_at()`](https://mjorden.github.io/econscape/reference/demand_curve_values.md),
[`quantity_at()`](https://mjorden.github.io/econscape/reference/demand_curve_values.md),
[`marginal_revenue()`](https://mjorden.github.io/econscape/reference/demand_curve_values.md),
[`consumer_surplus()`](https://mjorden.github.io/econscape/reference/demand_curve_values.md)
for demand;
[`total_cost()`](https://mjorden.github.io/econscape/reference/cost_values.md),
[`marginal_cost()`](https://mjorden.github.io/econscape/reference/cost_values.md),
[`min_average_cost()`](https://mjorden.github.io/econscape/reference/cost_values.md)
for cost. A demand object must carry `q_max`; a cost object must carry
`fixed`. Unimplemented generics fall through to the `general_demand` or
`production_cost` behaviour only if your object also carries what those
need (`p_of_q`, or `f`/`w`/`r`), so it is simpler to implement the full
set.

## Budgets

A [`budget()`](https://mjorden.github.io/econscape/reference/budget.md)
is a plain list with `income`, `px`, `py`, `x_max`, `y_max` and `slope`;
there is nothing to extend, but a subclass `c("my_budget", "budget")`
carrying extra fields passes every check.

## Why the generics validate before dispatch

[`price_at()`](https://mjorden.github.io/econscape/reference/demand_curve_values.md)
checks `inherits(d, "demand")` before calling
[`UseMethod()`](https://rdrr.io/r/base/UseMethod.html), and likewise for
cost and budget objects. That rejects an unrelated class with a clear
message instead of a "no applicable method" error deep inside a solver,
at the price of requiring the subclassing above. Utility functions are
the exception: the check is only
[`is.function()`](https://rdrr.io/r/base/is.function.html), so any
callable works.

## Two names that mean two things

`n` is a number of firms in
[`cournot()`](https://mjorden.github.io/econscape/reference/market_structure.md)
and
[`perfect_competition()`](https://mjorden.github.io/econscape/reference/market_structure.md)
and a number of consumers per type in
[`two_part_tariff()`](https://mjorden.github.io/econscape/reference/two_part_tariff.md);
grid sizes are `n_points`. `b` is a
[`budget()`](https://mjorden.github.io/econscape/reference/budget.md) in
the consumer functions and the textbook coefficient in
[`quadratic_cost()`](https://mjorden.github.io/econscape/reference/cost.md),
[`leontief()`](https://mjorden.github.io/econscape/reference/leontief.md)
and
[`perfect_substitutes()`](https://mjorden.github.io/econscape/reference/perfect_substitutes.md);
the coefficient keeps its letter because that is what the formula is
written with.
