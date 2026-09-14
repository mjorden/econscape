#' Extending fredscape with your own preferences, demand and cost
#'
#' The theory functions dispatch on S3 classes, and most generics check
#' their first argument before dispatching. This page is the contract that
#' implies, so that a new preference, demand curve or cost function slots in
#' without editing the package.
#'
#' @section Utility and production functions:
#' Anything that is an R function of `x` and `y` is accepted by
#' [indifference_curve()], [optimal_bundle()], [mrs()], [expenditure()],
#' [plot_consumer_choice()] and the rest; with no class it goes through the
#' numerical methods (bisection contours, a line search along the budget,
#' finite-difference MRS). To supply closed forms instead, give the function
#' a class and write the methods:
#'
#' ```
#' stone_geary <- function(alpha, gamma_x, gamma_y) {
#'   f <- function(x, y) (x - gamma_x)^alpha * (y - gamma_y)^(1 - alpha)
#'   structure(f, class = c("stone_geary", "function"),
#'             alpha = alpha, gamma_x = gamma_x, gamma_y = gamma_y, kind = "utility")
#' }
#' optimal_bundle.stone_geary <- function(u, b, ...) { ... }
#' ```
#'
#' Any method you do not write falls back to the numerical default, so a
#' partial set is fine. Follow the package's own pattern for the rest:
#' parameters as attributes, a `kind` attribute of `"utility"` or
#' `"production"` (the diagrams read it for their labels), and a `print()`
#' method.
#'
#' @section Demand and cost:
#' [demand_fn()] already accepts any decreasing function of quantity, and
#' [production_cost()] any production function, so most needs are met
#' without a new class. For closed forms, subclass the base class so the
#' generics' checks pass -- `class = c("isoelastic_demand", "demand")`, or
#' `c("cubic_cost", "cost")` -- and write methods for the generics you need:
#' [price_at()], [quantity_at()], [marginal_revenue()], [consumer_surplus()]
#' for demand; [total_cost()], [marginal_cost()], [min_average_cost()] for
#' cost. A demand object must carry `q_max`; a cost object must carry
#' `fixed`. Unimplemented generics fall through to the `general_demand` or
#' `production_cost` behaviour only if your object also carries what those
#' need (`p_of_q`, or `f`/`w`/`r`), so it is simpler to implement the full
#' set.
#'
#' @section Budgets:
#' A [budget()] is a plain list with `income`, `px`, `py`, `x_max`, `y_max`
#' and `slope`; there is nothing to extend, but a subclass
#' `c("my_budget", "budget")` carrying extra fields passes every check.
#'
#' @section Why the generics validate before dispatch:
#' [price_at()] checks `inherits(d, "demand")` before calling
#' `UseMethod()`, and likewise for cost and budget objects. That rejects an
#' unrelated class with a clear message instead of a "no applicable method"
#' error deep inside a solver, at the price of requiring the subclassing
#' above. Utility functions are the exception: the check is only
#' `is.function()`, so any callable works.
#'
#' @section Two names that mean two things:
#' `n` is a number of firms in [cournot()] and [perfect_competition()] and a
#' number of consumers per type in [two_part_tariff()]; grid sizes are
#' `n_points`. `b` is a [budget()] in the consumer functions and the
#' textbook coefficient in [quadratic_cost()], [leontief()] and
#' [perfect_substitutes()]; the coefficient keeps its letter because that is
#' what the formula is written with.
#'
#' @name fredscape-extending
#' @aliases extending
NULL
