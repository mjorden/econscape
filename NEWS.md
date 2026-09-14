# econscape 0.14.1

Theory and classroom fixes from the 2026-09-14 review.

* `mu_per_dollar()` builds the purchase order as a constrained greedy (the
  next unit of each good competes, never a later one), so tables without
  diminishing marginal utility no longer get a scrambled order (#31). When
  the greedy set differs from `optimal_bundle()` (a non-concave table, or
  leftover cash on a kinked budget) it warns and attaches a `note`
  attribute.
* The market solvers score candidates on a 4,000-point grid instead of 200
  and integrate each candidate up to its polished root, so a marginal feature
  narrower than a fiftieth of the quantity range is no longer invisible
  (#32).
* `transform_series()` returns rows in the order they arrived, as documented,
  rather than re-sorted by series and date (#35).
* A `trend_cycle` keeps its attributes when rows are subset and drops its
  class when the value columns go; `print()` and `plot_trend_cycle()` explain
  an incomplete object instead of failing on `attr(x, "method")` (#36).
* `plot_consumer_choice()` takes the axis labels from a `utility_table()`'s
  goods when `goods` is not given (#37).
* `econ_colours("brown")` is the academic primary; `budget()` documents that
  its cost closures make `identical()` on two budgets false (#38).

# econscape 0.14.0

Econometrics fixes from the 2026-09-14 review.

* `ols()` accepts `weights` (#28). The `lm()` call is now built with
  `match.call()`, so `weights` and `subset` are evaluated in `data` the way
  `lm()` evaluates them, and all three covariance estimators use the weighted
  bread and weighted scores. A weighted fit prints as "weighted OLS".
* `econ_fit` gains `confint()`, `predict()`, `model.matrix()` and `formula()`
  methods (#34). `confint()` now returns the same t interval as
  `coef_table()` instead of falling through to the normal-based default.
* `hp_filter()` solves the pentadiagonal system with a banded factorisation
  (#33): linear in the series length rather than cubic. Twenty thousand
  observations take a few hundredths of a second where they took hours.
* `adf_test()` refuses a regression with fewer than three residual degrees of
  freedom and skips such candidates in the AIC lag search (#29). Previously a
  short series with `type = "trend"` could return a `NaN` statistic.
* `hamilton_filter()` requires more than `h + 2p + 2` observations and aborts
  on a rank-deficient forecasting regression (#30), instead of returning a
  cycle of exact zeros.
* `plot_coefficients(terms = "(Intercept)")` explains that the intercept is
  excluded by `intercept = FALSE` rather than calling it an unknown term;
  the HAC estimator's row-contiguity assumption is documented; and
  `fred_recessions()` has a test (part of #38).

# econscape 0.13.0

* The academic style is now the default. `set_style("economist")` restores
  the newspaper look; nothing else about either style changes. The README
  figures, the pkgdown accent and the package description follow.

# econscape 0.12.0

The package is now called **econscape**. It began as a FRED client with an
Economist-style theme and grew into consumer, producer and market theory,
price discrimination, an econometrics toolkit and a second house style; the
old name described a tenth of it. Nothing else changes: every function keeps
its name (the `fred_*` functions are named for their data source, which is
still FRED), the options are now `econscape.style` and `econscape.base_url`,
and the GitHub repository redirects from the old address.

Reinstall with `remotes::install_github("mjorden/econscape")`.

# econscape 0.11.0

Two things the introductory course asks for that the package could not do,
and a second look.

* `utility_table(tu_x, tu_y)` -- preferences given as a table of total
  utility from 1, 2, ... units of each good. `optimal_bundle()` searches
  whole bundles, `indifference_curve()` interpolates the table so the
  curves can be drawn, `mrs()` uses the marginal utilities at the table
  rows, and `mu_per_dollar()` prints the purchase order the textbook
  argument walks through, with the running cost so the answer for any
  income is read off directly.
* `price_schedule()` -- a unit price that changes with the quantity bought
  (quantity discounts, block tariffs). `budget()` accepts one in place of a
  number and the budget line is then kinked: `budget_line()` traces the
  frontier through the kinks, `geom_budget()` draws it as a path,
  `optimal_bundle()` searches along the frontier (the kink is a candidate),
  and `expenditure()` and the Hicks/Slutsky decomposition search over income.
* `set_style()` -- the house styles. `"economist"` is the default and is
  unchanged. `"academic"` is a fork for papers and lecture notes: a
  parchment panel, a serif face, a tan-to-espresso categorical palette
  (`econ_pal("academic")`), a `"browns"` sequential ramp, a rust masthead
  and matching recession bands. Every `plot_*()` helper, the colour scales,
  `theme_econ()` and `econ_masthead()` follow the style unless told
  otherwise; `style_colour()` exposes the role colours for your own layers.

# econscape 0.10.0

Naming and API decisions from the code review (#18), settled before a 1.0.

Breaking:

* `geom_indifference()`, `budget_line()` and the internal grid helpers take
  `n_points`, not `n`: `n` is a number of firms in `cournot()` and
  `perfect_competition()` and a number of consumers in `two_part_tariff()`,
  and a grid size has nothing to do with either. Old calls keep working
  through R's partial argument matching (`n` resolves to `n_points`), but
  `n_points` is the documented name.

Decided and documented rather than changed:

* `b` stays a `budget()` in the consumer functions and a scalar coefficient
  in `quadratic_cost()`, `leontief()` and `perfect_substitutes()`, because
  the latter are the textbook letters; each of those pages now says so.
* Validation before `UseMethod()` in the generics stays, and the extension
  contract it implies -- subclass `demand`, `cost` or `budget`, or supply
  any callable for a utility -- is written down on `?econscape-extending`.
* `quasilinear()` has no `kind` because `f(x) + y` has no production
  reading; its documentation says so.
* `plot_producer_choice()` documents that it relabels whatever `kind` the
  function was built with, and the perfect-substitutes tie test documents
  its tolerance.

Internal: `market_outcome()`'s override arguments no longer shadow the
`consumer_surplus()` / `producer_surplus` names, and the producer-side
marginal-cost helper is `mc_from_production()`, so it cannot be mistaken for
the public `marginal_cost()` generic on cost objects.

# econscape 0.9.1

Numerical robustness, from the code review (#17). No API changes.

* The market solvers are now two named primitives instead of one:
  `maximise_on()` scores the endpoints and every downward crossing of a
  marginal function by the integral and returns the best, so an upward-only
  crossing (a profit minimum) is never returned and several crossings are
  compared rather than the last one assumed; `find_crossing()` keeps the
  last-downward-crossing rule for `third_degree()`'s search over the common
  marginal-revenue level, where an integral means nothing.
* `demand_fn()` checks on a coarse grid that inverse demand is finite and
  decreasing, and refuses it otherwise.
* `marginal_cost()` of a `production_cost()` built on a plain function no
  longer differences below the inner solver's noise floor; at zero output it
  reports the cost of the first thousandth of a unit rather than a
  derivative that may not exist.

# econscape 0.9.0

Econometrics (#21): estimating things from the series you fetched, in base R
and stats only.

* `ols()` -- `lm()` with `"classical"`, `"hc1"` (heteroskedasticity-robust)
  or `"hac"` (Newey-West) standard errors, computed directly and tested
  against hand-built sandwich matrices. `coef_table()` for the tidy table,
  `coef()` / `vcov()` / `nobs()` / `residuals()` / `fitted()` methods, and
  `plot_coefficients()` for the dot-and-whisker chart.
* `hp_filter()` (Hodrick-Prescott, lambda by frequency or explicit) and
  `hamilton_filter()` (Hamilton 2018) trend-cycle decompositions, returning
  one `trend_cycle` shape; `plot_trend_cycle()` draws both panels with NBER
  shading.
* `adf_test()` -- augmented Dickey-Fuller with MacKinnon (2010)
  response-surface critical values and AIC lag selection over a common
  sample.
* `transform_series()` -- the FRED `units` transformations (`chg`, `ch1`,
  `pch`, `pc1`, `pca`, `cch`, `cca`, `log`, plus `index`) applied locally to
  a tidy frame, with the frequency inferred from the dates.

# econscape 0.8.1

Housekeeping from the code review (#19). No user-facing behaviour changes.

* `scales` and `knitr` dropped from Suggests: nothing used them.
* The private `%||%` is gone; `rlang`'s is imported instead.
* One `fmt_num()` behind every `print()` method and one `econ_axes()` behind
  every two-axis diagram, replacing four copies of each.
* The `grid_<panel>` palette entries are documented as the gridline colour
  *for* that panel (they looked swapped; they are not), and the `geom_*()`
  return convention -- one layer for one thing, a list for several -- is
  written down once.
* A pkgdown configuration and deploy workflow; the site builds from the
  existing reference documentation. The committed `adversarial-review-log/`
  is explained in the README as the review trail it is.

# econscape 0.8.0

Price discrimination (#15):

* `first_degree()` -- perfect discrimination: the efficient quantity, zero
  deadweight loss, all surplus to the seller. Returns a `market_outcome`.
* `third_degree()` -- segmented markets with one marginal cost,
  `MR_i = MC(sum Q_i)`; per-segment price, quantity, elasticity and Lerner
  index, plus the uniform-price benchmark from `aggregate_demand()`, the
  horizontal sum of the segments' demands.
* `two_part_tariff()` -- fee plus per-unit price. Identical consumers give
  price at marginal cost and the fee equal to surplus; with several types
  every serve-this-type-and-above cut-off is evaluated, so the result says
  who is served and why the price sits above marginal cost when everyone is.
* `plot_two_part_tariff()` shades the fee as surplus above the unit price.
* `market_outcome` accounting now accepts explicit price and surplus values
  for sellers with no single price.

Fixes from the pre-merge code review:

* `ces(rho = 1)` now behaves as the perfect-substitutes case it is:
  `optimal_bundle()` no longer returns `NaN` when `y` wins the corner and
  `expenditure()` no longer collapses to the level itself (its price index
  degenerated at `sigma = Inf`).
* `third_degree()` brackets the common marginal-revenue level with the same
  grid scan as the other structures; with falling marginal cost it used to
  assume monotonicity and report zero output.
* `expenditure()` gains a `quasilinear` method, so every constructor has a
  dedicated method rather than the generic root-find.
* A partially named list of demands (`list(students = s, d)`) now names the
  blanks instead of leaving `""`, which broke `plot_two_part_tariff()`;
  duplicated names are rejected.
* `quantity_at()` on an `aggregate_demand()` result uses the summed
  quantities directly instead of running a root-find inside a root-find.
* `plot_market()` titles and shades first-degree discrimination correctly
  (it fell through to the long-run competition title) and aborts on an
  unknown structure.


# econscape 0.7.0

Market structure (#13): the demand side, and the equilibria that put it
together with the cost side.

* Demand objects: `linear_demand(intercept, slope)` and `demand_fn()` for
  any inverse demand; `price_at()`, `quantity_at()`, `marginal_revenue()`,
  `elasticity()`, `consumer_surplus()`, closed-form for linear.
* Cost objects: `quadratic_cost(fixed, a, b)` and `production_cost()` built
  on `expenditure()`; `total_cost()`, `variable_cost()`, `marginal_cost()`,
  `average_cost()`, `min_average_cost()`.
* `monopoly()`, `cournot(n)` and `perfect_competition(n)` (short run with a
  shutdown check; long run with free entry when `n` is omitted) all return a
  `market_outcome`: price, industry and per-firm quantity, profit, consumer
  and producer surplus, deadweight loss against the `P = MC` benchmark,
  Lerner index and demand elasticity at the outcome.
* `plot_market()` draws demand, marginal revenue and marginal cost with the
  surplus and deadweight-loss areas shaded; `compare_structures()` tabulates
  how price and welfare move as the number of firms grows.

# econscape 0.6.0

Producer theory (#8), on the same machinery as the consumer side:

* `expansion_path()` -- cost-minimising input bundles as outlay grows.
* `conditional_demand()` -- the cheapest bundle for each output, and its cost.
* `cost_curves()` -- total, average and marginal cost; marginal cost is
  closed-form for Cobb-Douglas and a numerical derivative of `expenditure()`
  otherwise. A `fixed` cost gives average cost its U shape.
* `plot_cost_curves()` for the AC / MC pair, and `plot_producer_choice()`,
  which draws isoquants and an isocost line for any production function.

Also: `check_positive()`'s `zero_ok` argument, flagged as dead code in #4,
now has a caller (`fixed = 0` is a valid cost). #4 is closed by this
release.

# econscape 0.5.0

The substitution / income decomposition of a price change (#7):

* `price_change()`, with `hicks()` and `slutsky()` shorthands, returns the
  original, compensated and final bundles, the three budgets, and the
  substitution / income / total effects on both goods.
* `expenditure()` -- the expenditure function -- underlies Hicksian
  compensation, with closed forms for every constructor and a `uniroot()`
  fallback. It is also the total-cost function of producer theory, which the
  next release builds on.
* `plot_price_change()` draws the diagram: both budget lines, the dashed
  compensated line, the indifference curves through the bundles, and
  bracketed arrows along the axis for each effect.

# econscape 0.4.0

Curves traced by the optimal bundle (#6):

* `demand_curve()` and `engel_curve()` evaluate `optimal_bundle()` across a
  vector of prices or incomes and return tidy `(price, quantity)` /
  `(income, quantity)` frames; `price_consumption_path()` and
  `income_consumption_path()` keep the whole bundle.
* `geom_demand()` draws price against quantity the textbook way round;
  `geom_engel()` and `geom_consumption_path()` draw the other two.
* `geom_budget()` accepts a list of budgets and draws one line each, with
  `colour` / `linetype` recycled across the family.

# econscape 0.3.0

Four more utility (and production) function constructors, each with the same
closed-form `indifference_curve()`, `optimal_bundle()` and `mrs()` methods
that `cobb_douglas()` has (#5):

* `ces(rho, alpha, A)` -- constant elasticity of substitution. Nests
  Cobb-Douglas (rho near 0), perfect substitutes (rho = 1) and Leontief
  (rho to minus infinity); the nesting is tested.
* `leontief(a, b, A)` -- perfect complements. L-shaped contours, the optimum
  always at the kink; `mrs()` returns `Inf` below the ray, `0` above it and
  `NA` on it; `geom_indifference()` draws the vertical arm.
* `perfect_substitutes(a, b, A)` -- linear. Corner solutions, with the
  knife-edge tie returning the midpoint of the budget line and an
  `indeterminate` attribute.
* `quasilinear(f, f_prime)` -- `f(x) + y`. Demand for `x` is independent of
  income; corners are checked; `f_prime` is approximated numerically when not
  supplied.

# econscape 0.2.0

Consumer and producer theory, drawn in the house style.

* `cobb_douglas()` builds a callable utility or production function that
  remembers its parameters; `print()` reports returns to scale.
* `budget()` and `budget_line()` describe a budget constraint or isocost.
* `indifference_curve()` returns contours: closed form for Cobb-Douglas, a
  `uniroot()` fallback for any other function of two goods (Leontief, CES,
  quasi-linear, ...).
* `optimal_bundle()` solves the consumer's problem: Cobb-Douglas share rule in
  closed form, `optimize()` along the budget line otherwise, with the corners
  checked so perfect substitutes land on the right axis.
* `mrs()` gives the marginal rate of substitution, closed form or finite
  difference.
* `geom_indifference()`, `geom_budget()` and `geom_optimum()` add each piece
  to a ggplot; `plot_consumer_choice()` composes the whole chart with the
  curves labelled by level.

Fixes from the pre-release adversarial review:

* The finite-difference fallback in `mrs()` now scales its step to the
  coordinate and never evaluates the utility on a negative quantity, so it is
  finite near the axes and accurate at large magnitudes instead of silently
  returning `NaN` or a degraded number (#2).
* `indifference_curve()` for Cobb-Douglas returns the documented `NA` at
  `x <= 0` and `level <= 0` rather than `Inf`/`NaN`, matching the numeric
  method (#3).

# econscape 0.1.0

First release.

* FRED client: `fred_series()`, `fred_series_info()`, `fred_search()` and
  `fred_recessions()`, all returning plain data frames. Missing observations
  (`"."` in the API) become `NA` without a coercion warning.
* Key handling via the `FRED_API_KEY` environment variable, with local shape
  validation and scrubbing of anything key-shaped out of API error messages.
* `theme_econ()`, with `"blue"`, `"white"` and `"dark"` panel styles.
* Colour scales over the Economist data palette, plus sequential and diverging
  ramps: `scale_colour_econ()`, `scale_fill_econ()`, `scale_colour_econ_c()`,
  `scale_fill_econ_c()`, `econ_pal()`, `econ_colours()`.
* `labs_econ()` for title, subtitle and a formatted source line;
  `scale_y_econ()` and `scale_x_econ_date()` for the axis conventions.
* `econ_masthead()` for the red block above the title.
* `annotate_recessions()` and the bundled `nber_recessions` table, covering
  every NBER-dated US contraction from 1857 to 2020.
