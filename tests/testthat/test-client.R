test_that("as_fred_date() accepts Dates and date-like strings", {
  expect_identical(as_fred_date("2020-01-31"), "2020-01-31")
  expect_identical(as_fred_date(as.Date("2020-01-31")), "2020-01-31")
  expect_null(as_fred_date(NULL))
})

test_that("as_fred_date() rejects things that are not a single date", {
  expect_error(as_fred_date("not a date"), "must be a single date")
  expect_error(as_fred_date(c("2020-01-01", "2020-02-01")), "must be a single date")
})

test_that("match_code() names the offending argument", {
  units <- "bogus"
  expect_error(match_code(units, c("lin", "pch")), "units")
  expect_identical(match_code("lin", c("lin", "pch")), "lin")
})

test_that("drop_null() removes NULL parameters but keeps falsy ones", {
  params <- list(a = 1, b = NULL, c = "", d = FALSE)
  expect_named(drop_null(params), c("a", "c", "d"))
})

test_that("redact_key() masks anything key-shaped", {
  key <- strrep("a", 32)
  msg <- paste0("Bad request for api_key=", key, " sorry")
  expect_false(grepl(key, redact_key(msg), fixed = TRUE))
  expect_match(redact_key(msg), "<api key redacted>")
})

test_that("redact_key() leaves ordinary text alone", {
  expect_identical(redact_key("Series ID is not valid."), "Series ID is not valid.")
})

test_that("the base URL is overridable for testing", {
  expect_match(fred_base_url(), "^https://api\\.stlouisfed\\.org/fred$")
  withr::local_options(econscape.base_url = "http://localhost:9999/fred")
  expect_identical(fred_base_url(), "http://localhost:9999/fred")
})

test_that("%||% falls through on NULL only", {
  expect_identical(NULL %||% "b", "b")
  expect_identical("a" %||% "b", "a")
  expect_identical(NA %||% "b", NA)
})
