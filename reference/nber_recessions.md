# US recession dates from the NBER

Peak and trough months of every US business cycle contraction dated by
the National Bureau of Economic Research, from the contraction that
began in June 1857 to the one that began in February 2020.

## Usage

``` r
nber_recessions
```

## Format

A data frame with 34 rows and 3 columns:

- peak:

  `Date`. First day of the peak month.

- trough:

  `Date`. First day of the trough month.

- months:

  `integer`. Approximate length of the contraction.

## Source

National Bureau of Economic Research, US Business Cycle Expansions and
Contractions,
<https://www.nber.org/research/data/us-business-cycle-expansions-and-contractions>

## Details

The NBER dates turning points to a month, not a day. Each date here is
the first day of the dated month: `peak` is the last month of the
expansion and `trough` the last month of the contraction, which is the
convention behind the shaded bands on FRED's own charts.

The table is a static copy, so a newly dated recession will not appear
until the package is updated.
[`fred_recessions()`](https://mjorden.github.io/econscape/reference/fred_recessions.md)
reads the same turning points live from FRED and is the one to use if
that matters.
