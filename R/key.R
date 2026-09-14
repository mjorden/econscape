#' Manage the FRED API key
#'
#' FRED requires a free API key for every request. `econscape` reads it from the
#' `FRED_API_KEY` environment variable so that the key never has to appear in a
#' script, a git history, or an error message.
#'
#' Request a key at <https://fredaccount.stlouisfed.org/apikeys>, then either
#' add `FRED_API_KEY=<your key>` to your user-level `.Renviron`
#' (`usethis::edit_r_environ()`) or call [fred_set_key()] for the current
#' session.
#'
#' @param key A 32-character lower-case alphanumeric FRED API key.
#'
#' @return
#' `fred_key()` returns the key as a string, and errors if none is set.
#' `fred_has_key()` returns `TRUE` or `FALSE` and never errors.
#' `fred_set_key()` invisibly returns the previous value of the environment
#' variable, so it can be restored.
#'
#' @examples
#' fred_has_key()
#'
#' # Set a key for this session only:
#' old <- fred_set_key(strrep("a", 32))
#' fred_has_key()
#' Sys.setenv(FRED_API_KEY = old)
#' @name fred_key
NULL

#' @rdname fred_key
#' @export
fred_key <- function() {
  key <- Sys.getenv("FRED_API_KEY", unset = "")
  if (!nzchar(key)) {
    cli::cli_abort(c(
      "No FRED API key found.",
      "i" = "Request a free key at {.url https://fredaccount.stlouisfed.org/apikeys}.",
      "i" = "Then set {.envvar FRED_API_KEY} in {.file ~/.Renviron}, or call
             {.run econscape::fred_set_key(\"<key>\")} for this session."
    ))
  }
  validate_key(key)
}

#' @rdname fred_key
#' @export
fred_has_key <- function() {
  nzchar(Sys.getenv("FRED_API_KEY", unset = ""))
}

#' @rdname fred_key
#' @export
fred_set_key <- function(key) {
  key <- validate_key(key)
  old <- Sys.getenv("FRED_API_KEY", unset = "")
  Sys.setenv(FRED_API_KEY = key)
  invisible(old)
}

#' Check that a string looks like a FRED API key
#'
#' FRED keys are 32 lower-case alphanumeric characters. Checking the shape here
#' turns a typo into a clear local error instead of an opaque HTTP 400.
#'
#' @param key A candidate key.
#' @return The key, unchanged.
#' @noRd
validate_key <- function(key) {
  if (!is.character(key) || length(key) != 1L || is.na(key)) {
    cli::cli_abort("{.arg key} must be a single string.")
  }
  if (!grepl("^[0-9a-z]{32}$", key)) {
    cli::cli_abort(c(
      "{.arg key} does not look like a FRED API key.",
      "x" = "Expected 32 lower-case alphanumeric characters, got {nchar(key)}.",
      "i" = "The key is not shown here on purpose."
    ))
  }
  key
}
