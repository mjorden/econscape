# Changelog

## fredscape 0.11.0

Two things the introductory course asks for that the package could not
do, and a second look.

- `utility_table(tu_x, tu_y)` – preferences given as a table of total
  utility from 1, 2, … units of each good.
  [`optimal_bundle()`](https://mjorden.github.io/fredscape/reference/optimal_bundle.md)
  searches whole bundles,
  [`indifference_curve()`](https://mjorden.github.io/fredscape/reference/indifference_curve.md)
  interpolates the table so the curves can be drawn,
  [`mrs()`](https://mjorden.github.io/fredscape/reference/mrs.md) uses
  the marginal utilities at the table rows, and
  [`mu_per_dollar()`](https://mjorden.github.io/fredscape/reference/mu_per_dollar.md)
  prints the purchase order the textbook argument walks through, with
  the running cost so the answer for any income is read off directly.
- [`price_schedule()`](https://mjorden.github.io/fredscape/reference/price_schedule.md)
  – a unit price that changes with the quantity bought (quantity
  discounts, block tariffs).
  [`budget()`](https://mjorden.github.io/fredscape/reference/budget.md)
  accepts one in place of a number and the budget line is then kinked:
  [`budget_line()`](https://mjorden.github.io/fredscape/reference/budget_line.md)
  traces the frontier through the kinks,
  [`geom_budget()`](https://mjorden.github.io/fredscape/reference/geom_micro.md)
  draws it as a path,
  [`optimal_bundle()`](https://mjorden.github.io/fredscape/reference/optimal_bundle.md)
  searches along the frontier (the kink is a candidate), and
  [`expenditure()`](https://mjorden.github.io/fredscape/reference/expenditure.md)
  and the Hicks/Slutsky decomposition search over income.
- [`set_style()`](https://mjorden.github.io/fredscape/reference/set_style.md)
  – the house styles. `"economist"` is the default and is unchanged.
  `"academic"` is a fork for papers and lecture notes: a parchment
  panel, a serif face, a tan-to-espresso categorical palette
  (`econ_pal("academic")`), a `"browns"` sequential ramp, a rust
  masthead and matching recession bands. Every `plot_*()` helper, the
  colour scales,
  [`theme_econ()`](https://mjorden.github.io/fredscape/reference/theme_econ.md)
  and
  [`econ_masthead()`](https://mjorden.github.io/fredscape/reference/econ_masthead.md)
  follow the style unless told otherwise;
  [`style_colour()`](https://mjorden.github.io/fredscape/reference/set_style.md)
  exposes the role colours for your own layers.

## fredscape 0.10.0

Naming and API decisions from the code review
([\#18](https://github.com/mjorden/fredscape/issues/18)), settled before
a 1.0.

Breaking:

- [`geom_indifference()`](https://mjorden.github.io/fredscape/reference/geom_micro.md),
  [`budget_line()`](https://mjorden.github.io/fredscape/reference/budget_line.md)
  and the internal grid helpers take `n_points`, not `n`: `n` is a
  number of firms in
  [`cournot()`](https://mjorden.github.io/fredscape/reference/market_structure.md)
  and
  [`perfect_competition()`](https://mjorden.github.io/fredscape/reference/market_structure.md)
  and a number of consumers in
  [`two_part_tariff()`](https://mjorden.github.io/fredscape/reference/two_part_tariff.md),
  and a grid size has nothing to do with either. Old calls keep working
  through R’s partial argument matching (`n` resolves to `n_points`),
  but `n_points` is the documented name.

Decided and documented rather than changed:

- `b` stays a
  [`budget()`](https://mjorden.github.io/fredscape/reference/budget.md)
  in the consumer functions and a scalar coefficient in
  [`quadratic_cost()`](https://mjorden.github.io/fredscape/reference/cost.md),
  [`leontief()`](https://mjorden.github.io/fredscape/reference/leontief.md)
  and
  [`perfect_substitutes()`](https://mjorden.github.io/fredscape/reference/perfect_substitutes.md),
  because the latter are the textbook letters; each of those pages now
  says so.
- Validation before
  [`UseMethod()`](https://rdrr.io/r/base/UseMethod.html) in the generics
  stays, and the extension contract it implies – subclass `demand`,
  `cost` or `budget`, or supply any callable for a utility – is written
  down on `?fredscape-extending`.
- [`quasilinear()`](https://mjorden.github.io/fredscape/reference/quasilinear.md)
  has no `kind` because `f(x) + y` has no production reading; its
  documentation says so.
- [`plot_producer_choice()`](https://mjorden.github.io/fredscape/reference/plot_producer_choice.md)
  documents that it relabels whatever `kind` the function was built
  with, and the perfect-substitutes tie test documents its tolerance.

Internal: `market_outcome()`’s override arguments no longer shadow the
[`consumer_surplus()`](https://mjorden.github.io/fredscape/reference/demand_curve_values.md)
/ `producer_surplus` names, and the producer-side marginal-cost helper
is `mc_from_production()`, so it cannot be mistaken for the public
[`marginal_cost()`](https://mjorden.github.io/fredscape/reference/cost_values.md)
generic on cost objects.

## fredscape 0.9.1

Numerical robustness, from the code review
([\#17](https://github.com/mjorden/fredscape/issues/17)). No API
changes.

- The market solvers are now two named primitives instead of one:
  `maximise_on()` scores the endpoints and every downward crossing of a
  marginal function by the integral and returns the best, so an
  upward-only crossing (a profit minimum) is never returned and several
  crossings are compared rather than the last one assumed;
  `find_crossing()` keeps the last-downward-crossing rule for
  [`third_degree()`](https://mjorden.github.io/fredscape/reference/price_discrimination.md)’s
  search over the common marginal-revenue level, where an integral means
  nothing.
- [`demand_fn()`](https://mjorden.github.io/fredscape/reference/demand.md)
  checks on a coarse grid that inverse demand is finite and decreasing,
  and refuses it otherwise.
- [`marginal_cost()`](https://mjorden.github.io/fredscape/reference/cost_values.md)
  of a
  [`production_cost()`](https://mjorden.github.io/fredscape/reference/cost.md)
  built on a plain function no longer differences below the inner
  solver’s noise floor; at zero output it reports the cost of the first
  thousandth of a unit rather than a derivative that may not exist.

## fredscape 0.9.0

Econometrics ([\#21](https://github.com/mjorden/fredscape/issues/21)):
estimating things from the series you fetched, in base R and stats only.

- [`ols()`](https://mjorden.github.io/fredscape/reference/ols.md) –
  [`lm()`](https://rdrr.io/r/stats/lm.html) with `"classical"`, `"hc1"`
  (heteroskedasticity-robust) or `"hac"` (Newey-West) standard errors,
  computed directly and tested against hand-built sandwich matrices.
  [`coef_table()`](https://mjorden.github.io/fredscape/reference/coef_table.md)
  for the tidy table, [`coef()`](https://rdrr.io/r/stats/coef.html) /
  [`vcov()`](https://rdrr.io/r/stats/vcov.html) /
  [`nobs()`](https://rdrr.io/r/stats/nobs.html) /
  [`residuals()`](https://rdrr.io/r/stats/residuals.html) /
  [`fitted()`](https://rdrr.io/r/stats/fitted.values.html) methods, and
  [`plot_coefficients()`](https://mjorden.github.io/fredscape/reference/plot_coefficients.md)
  for the dot-and-whisker chart.
- [`hp_filter()`](https://mjorden.github.io/fredscape/reference/trend_cycle.md)
  (Hodrick-Prescott, lambda by frequency or explicit) and
  [`hamilton_filter()`](https://mjorden.github.io/fredscape/reference/trend_cycle.md)
  (Hamilton 2018) trend-cycle decompositions, returning one
  `trend_cycle` shape;
  [`plot_trend_cycle()`](https://mjorden.github.io/fredscape/reference/plot_trend_cycle.md)
  draws both panels with NBER shading.
- [`adf_test()`](https://mjorden.github.io/fredscape/reference/adf_test.md)
  – augmented Dickey-Fuller with MacKinnon (2010) response-surface
  critical values and AIC lag selection over a common sample.
- [`transform_series()`](https://mjorden.github.io/fredscape/reference/transform_series.md)
  – the FRED `units` transformations (`chg`, `ch1`, `pch`, `pc1`, `pca`,
  `cch`, `cca`, `log`, plus `index`) applied locally to a tidy frame,
  with the frequency inferred from the dates.

## fredscape 0.8.1

Housekeeping from the code review
([\#19](https://github.com/mjorden/fredscape/issues/19)). No user-facing
behaviour changes.

- `scales` and `knitr` dropped from Suggests: nothing used them.
- The private `%||%` is gone; `rlang`’s is imported instead.
- One `fmt_num()` behind every
  [`print()`](https://rdrr.io/r/base/print.html) method and one
  `econ_axes()` behind every two-axis diagram, replacing four copies of
  each.
- The `grid_<panel>` palette entries are documented as the gridline
  colour *for* that panel (they looked swapped; they are not), and the
  `geom_*()` return convention – one layer for one thing, a list for
  several – is written down once.
- A pkgdown configuration and deploy workflow; the site builds from the
  existing reference documentation. The committed
  `adversarial-review-log/` is explained in the README as the review
  trail it is.

## fredscape 0.8.0

Price discrimination
([\#15](https://github.com/mjorden/fredscape/issues/15)):

- [`first_degree()`](https://mjorden.github.io/fredscape/reference/price_discrimination.md)
  – perfect discrimination: the efficient quantity, zero deadweight
  loss, all surplus to the seller. Returns a `market_outcome`.
- [`third_degree()`](https://mjorden.github.io/fredscape/reference/price_discrimination.md)
  – segmented markets with one marginal cost, `MR_i = MC(sum Q_i)`;
  per-segment price, quantity, elasticity and Lerner index, plus the
  uniform-price benchmark from
  [`aggregate_demand()`](https://mjorden.github.io/fredscape/reference/aggregate_demand.md),
  the horizontal sum of the segments’ demands.
- [`two_part_tariff()`](https://mjorden.github.io/fredscape/reference/two_part_tariff.md)
  – fee plus per-unit price. Identical consumers give price at marginal
  cost and the fee equal to surplus; with several types every
  serve-this-type-and-above cut-off is evaluated, so the result says who
  is served and why the price sits above marginal cost when everyone is.
- [`plot_two_part_tariff()`](https://mjorden.github.io/fredscape/reference/plot_two_part_tariff.md)
  shades the fee as surplus above the unit price.
- `market_outcome` accounting now accepts explicit price and surplus
  values for sellers with no single price.

Fixes from the pre-merge code review:

- `ces(rho = 1)` now behaves as the perfect-substitutes case it is:
  [`optimal_bundle()`](https://mjorden.github.io/fredscape/reference/optimal_bundle.md)
  no longer returns `NaN` when `y` wins the corner and
  [`expenditure()`](https://mjorden.github.io/fredscape/reference/expenditure.md)
  no longer collapses to the level itself (its price index degenerated
  at `sigma = Inf`).
- [`third_degree()`](https://mjorden.github.io/fredscape/reference/price_discrimination.md)
  brackets the common marginal-revenue level with the same grid scan as
  the other structures; with falling marginal cost it used to assume
  monotonicity and report zero output.
- [`expenditure()`](https://mjorden.github.io/fredscape/reference/expenditure.md)
  gains a `quasilinear` method, so every constructor has a dedicated
  method rather than the generic root-find.
- A partially named list of demands (`list(students = s, d)`) now names
  the blanks instead of leaving `""`, which broke
  [`plot_two_part_tariff()`](https://mjorden.github.io/fredscape/reference/plot_two_part_tariff.md);
  duplicated names are rejected.
- [`quantity_at()`](https://mjorden.github.io/fredscape/reference/demand_curve_values.md)
  on an
  [`aggregate_demand()`](https://mjorden.github.io/fredscape/reference/aggregate_demand.md)
  result uses the summed quantities directly instead of running a
  root-find inside a root-find.
- [`plot_market()`](https://mjorden.github.io/fredscape/reference/plot_market.md)
  titles and shades first-degree discrimination correctly (it fell
  through to the long-run competition title) and aborts on an unknown
  structure.

## fredscape 0.7.0

Market structure
([\#13](https://github.com/mjorden/fredscape/issues/13)): the demand
side, and the equilibria that put it together with the cost side.

- Demand objects: `linear_demand(intercept, slope)` and
  [`demand_fn()`](https://mjorden.github.io/fredscape/reference/demand.md)
  for any inverse demand;
  [`price_at()`](https://mjorden.github.io/fredscape/reference/demand_curve_values.md),
  [`quantity_at()`](https://mjorden.github.io/fredscape/reference/demand_curve_values.md),
  [`marginal_revenue()`](https://mjorden.github.io/fredscape/reference/demand_curve_values.md),
  [`elasticity()`](https://mjorden.github.io/fredscape/reference/demand_curve_values.md),
  [`consumer_surplus()`](https://mjorden.github.io/fredscape/reference/demand_curve_values.md),
  closed-form for linear.
- Cost objects: `quadratic_cost(fixed, a, b)` and
  [`production_cost()`](https://mjorden.github.io/fredscape/reference/cost.md)
  built on
  [`expenditure()`](https://mjorden.github.io/fredscape/reference/expenditure.md);
  [`total_cost()`](https://mjorden.github.io/fredscape/reference/cost_values.md),
  [`variable_cost()`](https://mjorden.github.io/fredscape/reference/cost_values.md),
  [`marginal_cost()`](https://mjorden.github.io/fredscape/reference/cost_values.md),
  [`average_cost()`](https://mjorden.github.io/fredscape/reference/cost_values.md),
  [`min_average_cost()`](https://mjorden.github.io/fredscape/reference/cost_values.md).
- [`monopoly()`](https://mjorden.github.io/fredscape/reference/market_structure.md),
  `cournot(n)` and `perfect_competition(n)` (short run with a shutdown
  check; long run with free entry when `n` is omitted) all return a
  `market_outcome`: price, industry and per-firm quantity, profit,
  consumer and producer surplus, deadweight loss against the `P = MC`
  benchmark, Lerner index and demand elasticity at the outcome.
- [`plot_market()`](https://mjorden.github.io/fredscape/reference/plot_market.md)
  draws demand, marginal revenue and marginal cost with the surplus and
  deadweight-loss areas shaded;
  [`compare_structures()`](https://mjorden.github.io/fredscape/reference/compare_structures.md)
  tabulates how price and welfare move as the number of firms grows.

## fredscape 0.6.0

Producer theory ([\#8](https://github.com/mjorden/fredscape/issues/8)),
on the same machinery as the consumer side:

- [`expansion_path()`](https://mjorden.github.io/fredscape/reference/producer.md)
  – cost-minimising input bundles as outlay grows.
- [`conditional_demand()`](https://mjorden.github.io/fredscape/reference/producer.md)
  – the cheapest bundle for each output, and its cost.
- [`cost_curves()`](https://mjorden.github.io/fredscape/reference/producer.md)
  – total, average and marginal cost; marginal cost is closed-form for
  Cobb-Douglas and a numerical derivative of
  [`expenditure()`](https://mjorden.github.io/fredscape/reference/expenditure.md)
  otherwise. A `fixed` cost gives average cost its U shape.
- [`plot_cost_curves()`](https://mjorden.github.io/fredscape/reference/plot_cost_curves.md)
  for the AC / MC pair, and
  [`plot_producer_choice()`](https://mjorden.github.io/fredscape/reference/plot_producer_choice.md),
  which draws isoquants and an isocost line for any production function.

Also: `check_positive()`’s `zero_ok` argument, flagged as dead code in
[\#4](https://github.com/mjorden/fredscape/issues/4), now has a caller
(`fixed = 0` is a valid cost).
[\#4](https://github.com/mjorden/fredscape/issues/4) is closed by this
release.

## fredscape 0.5.0

The substitution / income decomposition of a price change
([\#7](https://github.com/mjorden/fredscape/issues/7)):

- [`price_change()`](https://mjorden.github.io/fredscape/reference/price_change.md),
  with
  [`hicks()`](https://mjorden.github.io/fredscape/reference/price_change.md)
  and
  [`slutsky()`](https://mjorden.github.io/fredscape/reference/price_change.md)
  shorthands, returns the original, compensated and final bundles, the
  three budgets, and the substitution / income / total effects on both
  goods.
- [`expenditure()`](https://mjorden.github.io/fredscape/reference/expenditure.md)
  – the expenditure function – underlies Hicksian compensation, with
  closed forms for every constructor and a
  [`uniroot()`](https://rdrr.io/r/stats/uniroot.html) fallback. It is
  also the total-cost function of producer theory, which the next
  release builds on.
- [`plot_price_change()`](https://mjorden.github.io/fredscape/reference/plot_price_change.md)
  draws the diagram: both budget lines, the dashed compensated line, the
  indifference curves through the bundles, and bracketed arrows along
  the axis for each effect.

## fredscape 0.4.0

Curves traced by the optimal bundle
([\#6](https://github.com/mjorden/fredscape/issues/6)):

- [`demand_curve()`](https://mjorden.github.io/fredscape/reference/derived_curves.md)
  and
  [`engel_curve()`](https://mjorden.github.io/fredscape/reference/derived_curves.md)
  evaluate
  [`optimal_bundle()`](https://mjorden.github.io/fredscape/reference/optimal_bundle.md)
  across a vector of prices or incomes and return tidy
  `(price, quantity)` / `(income, quantity)` frames;
  [`price_consumption_path()`](https://mjorden.github.io/fredscape/reference/derived_curves.md)
  and
  [`income_consumption_path()`](https://mjorden.github.io/fredscape/reference/derived_curves.md)
  keep the whole bundle.
- [`geom_demand()`](https://mjorden.github.io/fredscape/reference/geom_demand.md)
  draws price against quantity the textbook way round;
  [`geom_engel()`](https://mjorden.github.io/fredscape/reference/geom_demand.md)
  and
  [`geom_consumption_path()`](https://mjorden.github.io/fredscape/reference/geom_consumption_path.md)
  draw the other two.
- [`geom_budget()`](https://mjorden.github.io/fredscape/reference/geom_micro.md)
  accepts a list of budgets and draws one line each, with `colour` /
  `linetype` recycled across the family.

## fredscape 0.3.0

Four more utility (and production) function constructors, each with the
same closed-form
[`indifference_curve()`](https://mjorden.github.io/fredscape/reference/indifference_curve.md),
[`optimal_bundle()`](https://mjorden.github.io/fredscape/reference/optimal_bundle.md)
and [`mrs()`](https://mjorden.github.io/fredscape/reference/mrs.md)
methods that
[`cobb_douglas()`](https://mjorden.github.io/fredscape/reference/cobb_douglas.md)
has ([\#5](https://github.com/mjorden/fredscape/issues/5)):

- `ces(rho, alpha, A)` – constant elasticity of substitution. Nests
  Cobb-Douglas (rho near 0), perfect substitutes (rho = 1) and Leontief
  (rho to minus infinity); the nesting is tested.
- `leontief(a, b, A)` – perfect complements. L-shaped contours, the
  optimum always at the kink;
  [`mrs()`](https://mjorden.github.io/fredscape/reference/mrs.md)
  returns `Inf` below the ray, `0` above it and `NA` on it;
  [`geom_indifference()`](https://mjorden.github.io/fredscape/reference/geom_micro.md)
  draws the vertical arm.
- `perfect_substitutes(a, b, A)` – linear. Corner solutions, with the
  knife-edge tie returning the midpoint of the budget line and an
  `indeterminate` attribute.
- `quasilinear(f, f_prime)` – `f(x) + y`. Demand for `x` is independent
  of income; corners are checked; `f_prime` is approximated numerically
  when not supplied.

## fredscape 0.2.0

Consumer and producer theory, drawn in the house style.

- [`cobb_douglas()`](https://mjorden.github.io/fredscape/reference/cobb_douglas.md)
  builds a callable utility or production function that remembers its
  parameters; [`print()`](https://rdrr.io/r/base/print.html) reports
  returns to scale.
- [`budget()`](https://mjorden.github.io/fredscape/reference/budget.md)
  and
  [`budget_line()`](https://mjorden.github.io/fredscape/reference/budget_line.md)
  describe a budget constraint or isocost.
- [`indifference_curve()`](https://mjorden.github.io/fredscape/reference/indifference_curve.md)
  returns contours: closed form for Cobb-Douglas, a
  [`uniroot()`](https://rdrr.io/r/stats/uniroot.html) fallback for any
  other function of two goods (Leontief, CES, quasi-linear, …).
- [`optimal_bundle()`](https://mjorden.github.io/fredscape/reference/optimal_bundle.md)
  solves the consumer’s problem: Cobb-Douglas share rule in closed form,
  [`optimize()`](https://rdrr.io/r/stats/optimize.html) along the budget
  line otherwise, with the corners checked so perfect substitutes land
  on the right axis.
- [`mrs()`](https://mjorden.github.io/fredscape/reference/mrs.md) gives
  the marginal rate of substitution, closed form or finite difference.
- [`geom_indifference()`](https://mjorden.github.io/fredscape/reference/geom_micro.md),
  [`geom_budget()`](https://mjorden.github.io/fredscape/reference/geom_micro.md)
  and
  [`geom_optimum()`](https://mjorden.github.io/fredscape/reference/geom_micro.md)
  add each piece to a ggplot;
  [`plot_consumer_choice()`](https://mjorden.github.io/fredscape/reference/plot_consumer_choice.md)
  composes the whole chart with the curves labelled by level.

Fixes from the pre-release adversarial review:

- The finite-difference fallback in
  [`mrs()`](https://mjorden.github.io/fredscape/reference/mrs.md) now
  scales its step to the coordinate and never evaluates the utility on a
  negative quantity, so it is finite near the axes and accurate at large
  magnitudes instead of silently returning `NaN` or a degraded number
  ([\#2](https://github.com/mjorden/fredscape/issues/2)).
- [`indifference_curve()`](https://mjorden.github.io/fredscape/reference/indifference_curve.md)
  for Cobb-Douglas returns the documented `NA` at `x <= 0` and
  `level <= 0` rather than `Inf`/`NaN`, matching the numeric method
  ([\#3](https://github.com/mjorden/fredscape/issues/3)).

## fredscape 0.1.0

First release.

- FRED client:
  [`fred_series()`](https://mjorden.github.io/fredscape/reference/fred_series.md),
  [`fred_series_info()`](https://mjorden.github.io/fredscape/reference/fred_series_info.md),
  [`fred_search()`](https://mjorden.github.io/fredscape/reference/fred_search.md)
  and
  [`fred_recessions()`](https://mjorden.github.io/fredscape/reference/fred_recessions.md),
  all returning plain data frames. Missing observations (`"."` in the
  API) become `NA` without a coercion warning.
- Key handling via the `FRED_API_KEY` environment variable, with local
  shape validation and scrubbing of anything key-shaped out of API error
  messages.
- [`theme_econ()`](https://mjorden.github.io/fredscape/reference/theme_econ.md),
  with `"blue"`, `"white"` and `"dark"` panel styles.
- Colour scales over the Economist data palette, plus sequential and
  diverging ramps:
  [`scale_colour_econ()`](https://mjorden.github.io/fredscape/reference/scale_econ.md),
  [`scale_fill_econ()`](https://mjorden.github.io/fredscape/reference/scale_econ.md),
  [`scale_colour_econ_c()`](https://mjorden.github.io/fredscape/reference/scale_econ.md),
  [`scale_fill_econ_c()`](https://mjorden.github.io/fredscape/reference/scale_econ.md),
  [`econ_pal()`](https://mjorden.github.io/fredscape/reference/econ_pal.md),
  [`econ_colours()`](https://mjorden.github.io/fredscape/reference/econ_colours.md).
- [`labs_econ()`](https://mjorden.github.io/fredscape/reference/labs_econ.md)
  for title, subtitle and a formatted source line;
  [`scale_y_econ()`](https://mjorden.github.io/fredscape/reference/scale_econ_axis.md)
  and
  [`scale_x_econ_date()`](https://mjorden.github.io/fredscape/reference/scale_econ_axis.md)
  for the axis conventions.
- [`econ_masthead()`](https://mjorden.github.io/fredscape/reference/econ_masthead.md)
  for the red block above the title.
- [`annotate_recessions()`](https://mjorden.github.io/fredscape/reference/annotate_recessions.md)
  and the bundled `nber_recessions` table, covering every NBER-dated US
  contraction from 1857 to 2020.
