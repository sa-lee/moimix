# seqarray_process_baf_methods.R
# Methods for estimating and plotting BAF spectra

#' Compute B-allele frequency spectrum genome-wide
#'
#' @param gdsfile a \code{\link[SeqArray]{SeqVarGDSClass}} object
#' @importFrom  SeqArray seqSummary seqApply seqGetData seqResetFilter
#' @details Constructs a bafMatrix object which is a list consisting of 
#' a matrix of estimated B-allele frequencies and 
#' @return a bafMatrix object 
#' @export
bafMatrix <- function(gdsfile) {
    stopifnot(inherits(gdsfile, "SeqVarGDSClass"))
    # estimate NRAF matrix, currently on GATK vcf file support
    vars <- seqSummary(gdsfile, check="none", verbose=FALSE)$format$ID
    if(!("AD" %in% vars)) {
        stop("Must have annotation/format/AD tag to compute B-allele frequencies")
    }
    
    is_valid <- seqGetData(gdsfile, "annotation/format/AD")$length == 2
    variant_id <- seqGetData(gdsfile, "variant.id")
    seqSetFilter(gdsfile, variant.id = variant_id[is_valid])
    
    # compute BAF for each sample 
    nrf <- seqApply(gdsfile, "annotation/format/AD",
                    function(x) x[,2] / rowSums(x),
                    margin = "by.variant",
                    as.is = "list")
    # convert list to matrix
    baf <- matrix(unlist(nrf), ncol = length(nrf),
                  dimnames = list(sample = seqGetData(gdsfile, "sample.id"),
                                  variant = variant_id[is_valid]))
    
    # compute per variant B-allele frequencies
    total_depth <- perSiteCoverage(gdsfile)
    b_depth <- seqApply(gdsfile, "annotation/format/AD",
                        function(x) colSums(x)[2],
                        margin = "by.variant",
                        as.is = "integer")
    # return class of baf
    baf_matrix <- structure(list(baf_matrix = baf,
                                 baf_site = b_depth / total_depth,
                                coords = getCoordinates(gdsfile)),
                               class = "bafMatrix")
    seqResetFilter(gdsfile)
    baf_matrix
}


#' Plot bafMatrix object
#' 
#' @param x a bafMatrix object
#' @param sample.id character name of sample to plot
#' @param assignments integer vector of cluster memberships (NULL)
#' @param y unnused argument for plot.bafMatrix
#' @param xlab Axis label along chromosome regions
#' @param ylab Axis label for SNV frequency 
#' @param ylim Limits for y axis default is between 0 and 1
#' @param pch Plot symbol default is 16
#' @param ... other parameters to pass to \code{\link[graphics]{plot}}
#' @details Plots the genome-wide signal of MOI within an isolate from
#' B-allele frequencies.
#' @importFrom scales alpha
#' @importFrom RColorBrewer brewer.pal
#' @method plot bafMatrix
#' @export
plot.bafMatrix <- function(x, sample.id, assignments = NULL, y = NULL, xlab = "", ylab = "SNV frequency", ylim = c(0,1), pch = 16, ...) {
    if(!(sample.id %in% rownames(x$baf_matrix))) {
        stop("sample.id not present in bafMatrix object")
    }
    # order coords by chromosome, then position
    coords_ordered <- x$coords[order(x$coords$chromosome, x$coords$position), ]
    breaks <- tapply(1:nrow(coords_ordered),
                     coords_ordered$chromosome, median)
    bf <- x$baf_matrix[sample.id, as.character(coords_ordered$variant.id)]
    
    if(is.null(assignments)) {
        plot(bf, xaxt ="n", xlab = xlab, 
             ylim = ylim, ylab = ylab, 
             col = alpha("black", 0.5), pch = pch, ...)
        axis(side = 1, at = breaks, labels = names(breaks), 
             las = 3, cex.axis = 0.6, ...)
    } else {
        # remove missing values 
        memberships <- assignments[as.character(coords_ordered$variant.id)]
        stopifnot(length(bf) == length(assignments))
        color_clusters <- brewer.pal(length(unique(memberships)), "Paired")
        plot(bf, xaxt ="n", xlab = xlab, 
             ylim = ylim, ylab = ylab, 
             col = alpha(color_clusters[memberships], 0.5), pch = pch, ...)
        axis(side = 1, at = breaks, labels = names(breaks), 
             las = 3, cex.axis = 0.6, ...)
    }
    
}



#' Construct non-overlapping Genomic Windows by Chromosome
#' 
#' @param gdsfile a \code{\link{SeqVarGDSClass}} object
#' @param window_size size of overlapping window in base-pairs
#' @export
generateWindows <- function(gdsfile, window_size) {
    coords <- getCoordinates(gdsfile)
    # split by  chromosome
    coord_by_chrom <- split(coords, coords$chromosome)
    windows_by_chrom <- lapply(coord_by_chrom, function(z) {
        start <- min(z$position)
        end <-  max(z$position)
        out_df <- data.frame(variant.id = z$variant.id, 
                   position = z$position,
                   window = findInterval(z$position, seq(start, end, 
                                                        by = window_size)))
        out_df
    })
    windows_by_chrom

}

#' averageVar <- function(window, baf_matrix, by.sample) {
#'     if(length(window$variant.id) > 1 ) {
#'         sample.var <- apply(baf_matrix[, window$variant.id], 1, 
#'                             var, na.rm = TRUE)
#'         if (by.sample) {
#'             return(sample.var)
#'         } else {
#'             mean(sample.var, na.rm = TRUE)
#'         }
#'         
#'     } else {
#'         NA
#'     }
#' }
#' 
#' #' Estimate variance in BAF spectra along the genome in non-overlapping windows
#' #' 
#' #' @param baf_matrix a \code{\link[moimix]{bafMatrix}} object
#' #' @param window_size integer size of window in bp
#' #' @param by.sample FALSE partition by sample
#' #' @details This function computes 
#' #' @return data.frame with chromosome, window id, start, midpoint and end of window
#' #' and estimates of average variance for window. If by.sample is TRUE, then there
#' #' will be additional sample.id column with   
#' #' @export 
#' getBAFvar <- function(baf_matrix, window_size, by.sample = FALSE) {
#'     # checks
#'     stopifnot(inherits(baf_matrix, "bafMatrix"))
#'     stopifnot(is.numeric(window_size) & length(window_size) == 1)
#'     stopifnot(is.finite(window_size))
#'     
#'     # step 1 -  retrieve BAF matrix
#'     baf <- baf_matrix$baf_matrix
#'     
#'     # step 2 -  contstruct windows by chromosome
#'     coord <- baf_matrix$coords
#'     # split by  chromosome
#'     coord_by_chrom <- split(coord, coord$chromosome)
#'     intervals <- lapply(coord_by_chrom, 
#'                         function(y) generateWindows(y$variant.id, y$position, window_size))
#'     
#'     # further split list by windows
#'     intervals_by_window <- lapply(intervals, function(y) split(y, y$window))
#'     
#'     # compute the median position for each window for plotting purposes
#'     median_pos <- lapply(intervals_by_window, 
#'                          function(chrom) lapply(chrom, 
#'                                                 function(window) data.frame(start = min(window$position),
#'                                                                             end = max(window$position),
#'                                                                             mid = median(window$position))))
#'     median_pos <- do.call(rbind, lapply(median_pos, 
#'                                         function(x) do.call(rbind, x)))
#'     
#'     ids <- matrix(unlist(strsplit(rownames(median_pos), split = "\\.")), 
#'                   ncol = 2, byrow = TRUE)
#'     median_pos$chr <- ids[,1]
#'     median_pos$window <-ids[,2]
#'     rownames(median_pos) <- NULL
#'     
#'     # now apply variance to each window in the list
#'     baf_var <- lapply(intervals_by_window, 
#'                       function(chrom) lapply(chrom, 
#'                                              function(window) averageVar(window, baf, by.sample)))
#'     if (by.sample) {
#'         validDF <- function(x) {
#'             if (length(x) > 1) {
#'                 summary.df <- data.frame(sample.id = names(x), vb = unlist(x))
#'                 rownames(summary.df) <- NULL
#'                 summary.df
#'             }
#'         }
#'         baf_var <- lapply(baf_var, 
#'                           function(chrom) lapply(chrom, function(x) validDF(x)))
#'         
#'         baf_var_df <- do.call(rbind, lapply(baf_var, 
#'                                             function(y) do.call(rbind, y)))
#'         ids <- matrix(unlist(strsplit(rownames(baf_var_df), split = "\\.")), 
#'                       ncol = 3, byrow = TRUE)
#'         baf_var_df$chr <- ids[,1]
#'         baf_var_df$window <- ids[,2]
#'         rownames(baf_var_df) <- NULL
#'         # merge in 
#'         return(merge(median_pos, baf_var_df, by = c("chr", "window")))
#'         
#'     }
#'     
#'     # much simpler if we aren't doing this by sample
#'     baf_var_df <- do.call(rbind, lapply(baf_var, 
#'                                         function(x) data.frame(vb = unlist(x))))
#'     
#'     baf_var_df$chr <- ids[,1]
#'     baf_var_df$window <- ids[,2]
#'     rownames(baf_var_df) <- NULL
#'     # merge in 
#'     merge(median_pos, baf_var_df, by = c("chr", "window"))
#'     
#' }