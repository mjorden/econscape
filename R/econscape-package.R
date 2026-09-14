#' @keywords internal
"_PACKAGE"

## usethis namespace: start
#' @importFrom rlang .data %||%
#' @importFrom stats coef fitted nobs residuals vcov
## usethis namespace: end
NULL

# `nber_recessions` is a lazy-loaded data set used as the default value of an
# argument, which codetools reads as an unbound global.
utils::globalVariables("nber_recessions")
