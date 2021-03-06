#' Coerce a url to a tdmurl with a specific type
#'
#' @export
#' @param url A URL.
#' @param type A document type, one of xml, pdf, or plain
#' @param doi A DOI, optional, defaults to \code{NULL}
#' @examples \dontrun{
#' as_tdmurl("http://downloads.hindawi.com/journals/bmri/2014/201717.xml",
#'    "xml")
#' as_tdmurl("http://downloads.hindawi.com/journals/bmri/2014/201717.pdf",
#'    "pdf")
#' out <- as_tdmurl("http://downloads.hindawi.com/journals/bmri/2014/201717.pdf",
#'    "pdf", "10.1155/2014/201717")
#' attributes(out)
#' }
as_tdmurl <- function(url, type, doi) UseMethod("as_tdmurl")

#' @export
#' @rdname as_tdmurl
as_tdmurl.tdmurl <- function(url, type, doi) url

#' @export
#' @rdname as_tdmurl
as_tdmurl.character <- function(url, type, doi=NULL) {
  makeurl(check_url(url), type, doi)
}

#' @export
print.tdmurl <- function(x, ...) {
  cat("<url> ", x[[1]], "\n", sep = "")
}

makeurl <- function(x, y, z) {
  structure(x, class = "tdmurl", type=match_type(y), doi=z)
}
check_url <- function(x) {
  if (!grepl("http://", x)) stop("Not a proper url") else x
}
match_type <- function(x) match.arg(x, c("xml","plain","pdf","unspecified"))
