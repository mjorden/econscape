#' Base URL for the FRED API
#'
#' Exposed as an option so the test suite can point the client at a local stub
#' server without touching the network.
#'
#' @return A URL string.
#' @noRd
fred_base_url <- function() {
  getOption("econscape.base_url", default = "https://api.stlouisfed.org/fred")
}

#' @noRd
econscape_user_agent <- function() {
  paste0(
    "econscape/", utils::packageVersion("econscape"),
    " (https://github.com/mjorden/econscape)"
  )
}

#' Perform a request against a FRED endpoint
#'
#' Every exported function funnels through here so that the key handling,
#' throttling, retry policy and error translation live in exactly one place.
#'
#' FRED allows 120 requests per minute per key; the throttle is set below that
#' so a loop over many series cannot trip the limit on its own.
#'
#' @param endpoint Path below `/fred`, e.g. `"series/observations"`.
#' @param params Named list of query parameters. `NULL` entries are dropped.
#' @param key A FRED API key.
#'
#' @return The parsed JSON body as a nested list.
#' @noRd
fred_get <- function(endpoint, params = list(), key = fred_key()) {
  # Force and check the key before anything else, so a missing or malformed one
  # reports itself rather than surfacing later from inside httr2.
  key <- validate_key(key)
  params <- drop_null(params)

  req <- httr2::request(fred_base_url())
  req <- httr2::req_url_path_append(req, endpoint)
  req <- httr2::req_url_query(req, !!!params, api_key = key, file_type = "json")
  req <- httr2::req_user_agent(req, econscape_user_agent())
  req <- httr2::req_throttle(req, capacity = 100, fill_time_s = 60)
  req <- httr2::req_retry(req, max_tries = 3, retry_on_failure = TRUE)
  req <- httr2::req_error(req, body = fred_error_body)

  resp <- httr2::req_perform(req)
  httr2::resp_body_json(resp, simplifyVector = FALSE)
}

#' Turn a FRED JSON error payload into a readable message
#'
#' FRED answers a bad request with HTTP 400 and a JSON body carrying
#' `error_code` and `error_message`; without this the user only sees the status
#' line. The message is scrubbed in case the API echoes the key back.
#'
#' @param resp An httr2 response.
#' @return A character message, or `NULL` to fall back to httr2's default.
#' @noRd
fred_error_body <- function(resp) {
  if (!grepl("json", httr2::resp_content_type(resp) %||% "", fixed = TRUE)) {
    return(NULL)
  }
  body <- tryCatch(httr2::resp_body_json(resp), error = function(e) NULL)
  msg <- body[["error_message"]]
  if (is.null(msg)) {
    return(NULL)
  }
  redact_key(as.character(msg))
}

#' Remove anything shaped like an API key from a string
#'
#' The key travels as a query parameter, so it can surface in echoed URLs and
#' error text. A 32-character alphanumeric run is replaced wholesale.
#'
#' @param x A character vector.
#' @return `x` with candidate keys masked.
#' @noRd
redact_key <- function(x) {
  gsub("[0-9a-zA-Z]{32}", "<api key redacted>", x)
}

#' Drop `NULL` elements from a list
#' @noRd
drop_null <- function(x) {
  x[!vapply(x, is.null, logical(1))]
}

#' Coerce a date-ish argument to the `YYYY-MM-DD` string FRED expects
#'
#' @param x A `Date`, something [as.Date()] accepts, or `NULL`.
#' @param arg Argument name, used in the error message.
#' @return A single string, or `NULL` if `x` was `NULL`.
#' @noRd
as_fred_date <- function(x, arg = rlang::caller_arg(x)) {
  if (is.null(x)) {
    return(NULL)
  }
  d <- tryCatch(as.Date(x), error = function(e) NA)
  if (length(d) != 1L || is.na(d)) {
    cli::cli_abort("{.arg {arg}} must be a single date, not {.val {x}}.")
  }
  format(d, "%Y-%m-%d")
}

#' Validate a character argument against a fixed set of FRED codes
#'
#' [match.arg()] would do, but its error message does not say which argument
#' failed when the call is several frames deep.
#'
#' @param x The supplied value.
#' @param choices Allowed values.
#' @param arg Argument name for the error message.
#' @return `x`, unchanged.
#' @noRd
match_code <- function(x, choices, arg = rlang::caller_arg(x)) {
  if (!is.character(x) || length(x) != 1L || !x %in% choices) {
    cli::cli_abort(c(
      "{.arg {arg}} must be one of {.val {choices}}.",
      "x" = "Got {.val {x}}."
    ))
  }
  x
}
