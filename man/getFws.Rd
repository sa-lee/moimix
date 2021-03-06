% Generated by roxygen2: do not edit by hand
% Please edit documentation in R/seqarray_process_popgen.R
\name{getFws}
\alias{getFws}
\title{Compute \eqn{Fws} within-host diversity statistic}
\usage{
getFws(gdsfile)
}
\arguments{
\item{gdsfile}{a \code{\link[SeqArray]{SeqVarGDSClass}} object}
}
\description{
Compute \eqn{Fws} within-host diversity statistic
}
\details{
Compute the within host diversity statistic according to the
method devised in  Manske et.al, 2012. Briefly, within sample heterozygosity
and within population heterozygosity are computed and assigned to ten equal sized
MAF bins [0.0.05]...[0.45,0.5]. For each bin the mean within sample and population
heterozygosity is computed. A regression line of these values through the orgin
is computed for each sample. The \eqn{Fws} is then \eqn{1 - \beta}.
}
\note{
Currently only works on GATK derived gdsfiles. Needs to be updated
to define populations.
}
\references{
Manske, Magnus, et al. "Analysis of Plasmodium falciparum 
diversity in natural infections by deep sequencing." Nature 487.7407 (2012): 
375-379.
}
\seealso{
\code{\link{getHeterozygosity}}, \code{\link{getHeterozygosityBySample}}
}
