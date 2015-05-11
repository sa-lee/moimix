# Title: binomial_mixture_utility.R
# Description: Tools for model selection and evalution
# for binomial mixture model.
# Author: Stuart Lee
# Date: 11/05/2015

#' Bayesian Information Criterion for binomial mixture model
#'
#' @param mixture estimated mixture model
#' @return The BIC of a model
#' @export
bic <- function(mixture) {
  # we multiply k by 2 since we estimate
  # 2k paramters in the binommix
  -2 * mixture$log.lik + 2*mixture$k*log(mixture$n)
}

#' Akaike Infomation Criterion for binomial mixture model
#'
#' @inheritParams bic
#' @return The AIC of a model
#' @export
aic <- function(mixture) {
  2 * (2*mixture$k - mixture$log.lik)
}

#' Mean Square Error for binomial mixture model
#'
#' @param mixture estimated mixture model
#' @param pi     true mixture weights
mseMM <- function(mixture, pi) {
  # potential matching problem
  # which we avoid by sorting the components
  pi.hat <- sort(mixture$pi)
  pi <- sort(pi)
  mean((pi - pi.hat)^2)
}

