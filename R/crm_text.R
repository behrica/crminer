#' Get full text from a DOI
#'
#' @export
#' @param url (character) A URL.
#' @param type (character) One of xml, plain, pdf, or all
#' @param path (character) Path to store pdfs in. By default we use
#' \code{paste0(rappdirs::user_cache_dir(), "/crminer")}, but you can
#' set this directory to something different. Ignored unless getting
#' pdf
#' @param overwrite (logical) Overwrite file if it exists already?
#' Default: \code{TRUE}
#' @param read (logical) If reading a pdf, this toggles whether we extract
#' text from the pdf or simply download. If \code{TRUE}, you get the text from
#' the pdf back. If \code{FALSE}, you only get back the metadata.
#' Default: \code{TRUE}
#' @param verbose (logical) Print progress messages. Default: \code{TRUE}
#' @param cache (logical) Use cached files or not. All files are written to
#' your machine locally, so this doesn't affect that. This only states whether
#' you want to use cached version so that you don't have to download the file
#' again. The steps of extracting and reading into R still have to be performed
#' when \code{cache=TRUE}. Default: \code{TRUE}
#' @param ... Named parameters passed on to \code{\link[httr]{GET}}
#' @details Note that \code{\link{crm_text}},
#' \code{\link{crm_pdf}}, \code{\link{crm_xml}}, \code{\link{crm_plain}}
#' are not vectorized.
#'
#' Note that some links returned will not in fact lead you to full text
#' content as you would understandbly think and expect. That is, if you
#' use the \code{filter} parameter with e.g., \code{\link[rcrossref]{cr_works}}
#' and filter to only full text content, some links may actually give back
#' only metadata for an article. Elsevier is perhaps the worst offender,
#' for one because they have a lot of entries in Crossref TDM, but most
#' of the links that are apparently full text are not in facct full text,
#' but only metadata.
#' @examples \dontrun{
#' library("rcrossref")
#'
#' # pdf link
#' crm_links(doi = "10.5555/515151", "pdf")
#'
#' # xml and plain text links
#' out <- cr_works(filter=c(has_full_text = TRUE))
#' dois <- out$data$DOI
#' crm_links(dois[1], "pdf")
#' crm_links(dois[2], "xml")
#' crm_links(dois[1], "plain")
#' crm_links(dois[1], "all")
#'
#' # No links
#' crm_links(cr_r(1), "xml")
#'
#' # get full text
#' ## pensoft
#' out <- cr_members(2258, filter=c(has_full_text = TRUE), works = TRUE)
#' (links <- crm_links(out$data$DOI[1], "all"))
#' ### xml
#' crm_text(links, 'xml')
#' ### pdf
#' crm_text(links, "pdf", read=FALSE)
#' crm_text(links, "pdf")
#'
#' ### another pensoft e.g.
#' links <- crm_links("10.3897/phytokeys.42.7604", "all")
#' pdf_read <- crm_text(url = links, type = "pdf", read=FALSE,
#'   verbose = FALSE)
#' pdf <- crm_text(links, "pdf", verbose = FALSE)
#'
#' ## hindawi
#' out <- cr_members(98, filter=c(has_full_text = TRUE), works = TRUE)
#' (links <- crm_links(out$data$DOI[1], "all"))
#' ### xml
#' crm_text(links, 'xml')
#' ### pdf
#' crm_text(links, "pdf", read=FALSE)
#' crm_text(links, "pdf")
#'
#' ## search for works with full text, and with CC-BY 3.0 license
#' ### you can see available licenses with cr_licenses() function
#' out <-
#'  cr_works(filter = list(has_full_text = TRUE,
#'    license_url="http://creativecommons.org/licenses/by/3.0/"),
#'    limit = 100)
#' (links <- crm_links(out$data$DOI[40], "all"))
#' # crm_text(links, 'xml')
#'
#' ## You can use crm_xml, crm_plain, and crm_pdf to go directly to
#' ## that format
#' licenseurl <- "http://creativecommons.org/licenses/by/3.0/"
#' out <- cr_works(
#'   filter = list(has_full_text = TRUE, license_url = licenseurl),
#'   limit = 100)
#' (links <- crm_links(out$data$DOI[50], "all"))
#' crm_xml(links)
#' #crm_pdf(links)
#'
#' ### Caching, for PDFs
#' # out <- cr_members(2258, filter=c(has_full_text = TRUE), works = TRUE)
#' # (links <- crm_links(out$data$DOI[10], "all"))
#' # crm_text(links, type = "pdf", cache=FALSE)
#' # system.time( cacheyes <- crm_text(links, type = "pdf", cache=TRUE) )
#' ### second time should be faster
#' # system.time( cacheyes <- crm_text(links, type = "pdf", cache=TRUE) )
#' # system.time( cacheno <- crm_text(links, type = "pdf", cache=FALSE) )
#' # identical(cacheyes, cacheno)
#'
#' ## elsevier
#' ## requires extra authentication
#' out <- cr_members(78, filter=c(has_full_text = TRUE), works = TRUE)
#' ## set key first
#' # Sys.setenv(CROSSREF_TDM_ELSEVIER = "your-key")
#' ## XML
#' link <- crm_links(out$data$DOI[1], "xml")
#' # res <- crm_text(url = link, type = "xml")
#' ## plain text
#' link <- crm_links(out$data$DOI[1], "plain")
#' # res <- crm_text(url = link, "plain")
#'
#' ## Wiley
#' Sys.setenv(CROSSREF_TDM = "your-key")
#'
#' ### all wiley
#' out <- cr_members(311, filter=c(has_full_text = TRUE,
#'    type = 'journal-article'), works = TRUE)
#' dois <- out$data$DOI[1:10]
#' # res <- list()
#' # for (i in seq_along(dois)) {
#' #   tmp <- crm_links(dois[i], "all")
#' #   tmp <- setNames(tmp, "pdf")
#' #   attr(tmp, "type") <- "pdf"
#' #   res[[i]] <- crm_text(tmp, type = "pdf", cache=FALSE)
#' # }
#' # res
#'
#' #### older dates
#' out <- cr_members(311, filter=c(has_full_text = TRUE,
#'       type = 'journal-article', until_created_date = "2013-12-31"),
#'       works = TRUE)
#'
#' dois <- out$data$DOI[1:10]
#' # res <- list()
#' # for (i in seq_along(dois)) {
#' #   tmp <- crm_links(dois[i], "all")
#' #   tmp <- setNames(tmp, "pdf")
#' #   attr(tmp, "type") <- "pdf"
#' #   res[[i]] <- crm_text(tmp, type = "pdf", cache=FALSE)
#' # }
#' # res
#'
#' ### wiley subset with CC By 4.0 license
#' lic <- "http://creativecommons.org/licenses/by/4.0/"
#' out <- cr_members(311, filter=c(has_full_text = TRUE, license.url = lic),
#'    works = TRUE)
#' dois <- out$data$DOI[1:10]
#' # res <- list()
#' # for (i in seq_along(dois)) {
#' #   tmp <- crm_links(dois[i], "all")
#' #   tmp <- setNames(tmp, "pdf")
#' #   attr(tmp, "type") <- "pdf"
#' #   res[[i]] <- crm_text(tmp, type = "pdf", cache=FALSE)
#' # }
#' }

crm_text <- function(url, type='xml', path = cr_cache_path(), overwrite = TRUE,
                       read=TRUE, verbose=TRUE, cache=TRUE, ...) {

  auth <- cr_auth(url, type)
  switch( pick_type(type, url),
          xml = getTEXT(get_url(url, 'xml'), type, auth, ...),
          plain = getTEXT(get_url(url, 'xml'), type, auth, ...),
          pdf = getPDF(url = get_url(url, 'pdf'), path, auth, overwrite, type,
                       read, verbose, cache, ...)
  )
}

cr_cache_path <- function() paste0(rappdirs::user_cache_dir(), "/crminer")

get_url <- function(a, b){
  url <- if (inherits(a, "tdmurl")) a[[1]] else a[[b]]
  if (grepl("pensoft", url)) {
    url
  } else {
    sub("\\?.+", "", url)
  }
}

#' @export
#' @rdname crm_text
crm_plain <- function(url, path = cr_cache_path(), overwrite = TRUE, read=TRUE,
                        verbose=TRUE, ...) {
  if (is.null(url$plain[[1]])) {
    stop("no plain text link found", call. = FALSE)
  }
  getTEXT(url$plain[[1]], "plain", cr_auth(url, 'plain'), ...)
}

#' @export
#' @rdname crm_text
crm_xml <- function(url, path = cr_cache_path(), overwrite = TRUE, read=TRUE,
                      verbose=TRUE, ...) {
  if (is.null(url$xml[[1]])) {
    stop("no xml link found", call. = FALSE)
  }
  getTEXT(url$xml[[1]], "xml", cr_auth(url, 'xml'), ...)
}

#' @export
#' @rdname crm_text
crm_pdf <- function(url, path = cr_cache_path(), overwrite = TRUE, read=TRUE,
                      cache=FALSE, verbose=TRUE, ...) {
  if (is.null(url$pdf[[1]])) {
    stop("no pdf link found", call. = FALSE)
  }
  getPDF(url$pdf[[1]], path, cr_auth(url, 'pdf'), overwrite, "pdf",
         read, verbose, cache, ...)
}

pick_type <- function(x, z) {
  x <- match.arg(x, c("xml","plain","pdf"))
  if (length(z) == 1) {
    avail <- attr(z, which = "type")
  } else {
    avail <- vapply(z, function(x) attr(x, which = "type"), character(1),
                    USE.NAMES = FALSE)
  }
  if (!x %in% avail) stop("Chosen type not available in links", call. = FALSE)
  x
}

cr_auth <- function(url, type) {
  mem <- attr(url, "member")
  mem_num <- basename(mem)
  if (mem_num %in% c(78, 263, 311)) {
    type <- switch(type,
                   xml = "text/xml",
                   plain = "text/plain",
                   pdf = "application/pdf"
    )
    switch(
      mem_num,
      `78` = {
        key <- Sys.getenv("CROSSREF_TDM_ELSEVIER")
        #add_headers(`X-ELS-APIKey` = key, Accept = type)
        httr::add_headers(`CR-Clickthrough-Client-Token` = key, Accept = type)
      },
      `263` = {
        key <- Sys.getenv("CROSSREF_TDM")
        httr::add_headers(`CR-TDM-Client_Token` = key, Accept = type)
        # add_headers(`CR-Clickthrough-Client-Token` = key, Accept = type)
      },
      `311` = {
        httr::add_headers(
          `CR-Clickthrough-Client-Token` = Sys.getenv("CROSSREF_TDM"),
          Accept = type)
      }
    )
    # add_headers(`CR-TDM-Client_Token` = key, Accept = type)
    # add_headers(`CR-Clickthrough-Client-Token` = key, Accept = type)
  } else {
    NULL
  }
}

getTEXT <- function(x, type, auth, ...){
  res <- httr::GET(x, auth, ...)
  switch(type,
         xml = xml2::read_xml(ct_utf8(res)),
         plain = ct_utf8(res))
}

getPDF <- function(url, path, auth, overwrite, type, read, verbose,
                   cache=FALSE, ...) {
  if (!file.exists(path)) {
    dir.create(path, showWarnings = FALSE, recursive = TRUE)
  }

  # pensoft special handling
  if ( grepl("pensoft", url[[1]]) ) {
    doi <- attr(url, "doi")
    if (is.null(doi)) {
      tmp <- strsplit(url, "=")[[1]]
      doi <- tmp[length(tmp)]
    }
    filepath <- file.path(path, paste0(sub("/", ".", doi), ".pdf"))
  } else {
    ff <- if (!grepl(type, basename(url))) {
      paste0(basename(url), ".", type)
    } else {
      basename(url)
    }
    filepath <- file.path(path, ff)
  }

  filepath <- path.expand(filepath)
  if (cache && file.exists(filepath)) {
    if ( !file.exists(filepath) ) {
      stop( sprintf("%s not found", filepath), call. = FALSE)
    }
  } else {
    if (verbose) message("Downloading pdf...")
    res <- httr::GET(
      url,
      httr::accept("application/pdf"),
      httr::write_disk(path = filepath, overwrite = overwrite),
      auth,
      httr::config(followlocation = TRUE), ...)
    httr::warn_for_status(res)
    if (res$status_code < 202) {
      filepath <- res$request$output$path
    } else {
      unlink(filepath)
      filepath <- res$status_code
      read <- FALSE
    }
  }

  if (read) {
    if (verbose) message("Extracting text from pdf...")
    crm_extract(path = filepath)
  } else {
    filepath
  }
}
