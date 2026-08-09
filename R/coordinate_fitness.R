#' @title Coordinate fitness for travel-time analysis
#' @description
#' Not every coordinate is fit for every purpose. A city centroid is a valid
#' county or congressional-district locator and an invalid isochrone origin: a
#' drive-time polygon drawn from the middle of a city is a polygon around a
#' place nobody works. Geocode quality therefore has to travel with the
#' coordinates and be enforced at the point of use.
#'
#' @section Why it errors instead of filtering:
#' Silently dropping unfit rows changes a denominator without anyone noticing,
#' which is the failure this guard exists to prevent. In the midwifery workforce
#' study the generalist population was once defined as "whoever happened to be
#' geocoded" -- 28,512 of a 50,556-person roster -- and the missingness was
#' invisible precisely because the missing were never counted. A loud stop
#' forces the caller to filter deliberately and report the exclusion.
#'
#' @family coordinate-fitness
#' @author Tyler Muffly, MD + Claude Code
#' @name coordinate_fitness
NULL

#' Refuse coordinates that are not fit for routing
#'
#' @description
#' Call at the top of any function that generates isochrones, computes drive
#' times, or otherwise treats a coordinate as a real practice location.
#'
#' @details
#' Two independent signals are checked, either of which is disqualifying:
#' \itemize{
#'   \item a logical `usable_for_travel_time` column that is `FALSE`;
#'   \item a `coord_source` value containing "centroid" (city, county or ZIP
#'     centroid geocodes).
#' }
#' A data frame carrying neither column passes, so this is safe to call on
#' inputs that predate the convention -- it constrains what it can see and does
#' not invent a verdict about what it cannot.
#'
#' @param df `data.frame`/`tibble`/`sf`: rows to check. May carry
#'   `usable_for_travel_time` (logical) and/or `coord_source` (character).
#' @param context `character(1)`: label for the error message, e.g. the calling
#'   function. Default "travel-time analysis".
#' @return Invisibly `TRUE` when every row is fit; otherwise `stop()`s with a
#'   count of the offending rows and how to exclude them.
#' @examples
#' \dontrun{
#'   generate_isochrones <- function(points) {
#'     assert_travel_time_eligible(points, context = "generate_isochrones()")
#'     # ...
#'   }
#'
#'   # Deliberate exclusion, which must then be reported:
#'   routable <- subset(providers, !grepl("centroid", coord_source))
#'   message(nrow(providers) - nrow(routable), " excluded: centroid geocodes")
#' }
#' @family coordinate-fitness
#' @export
assert_travel_time_eligible <- function(df, context = "travel-time analysis") {
  if (!is.data.frame(df))
    stop("assert_travel_time_eligible(): `df` must be a data frame or sf object.",
         call. = FALSE)

  if ("usable_for_travel_time" %in% names(df)) {
    bad <- which(!df$usable_for_travel_time)
    if (length(bad))
      stop(context, " received ", length(bad),
           " row(s) flagged usable_for_travel_time = FALSE. Filter them out ",
           "deliberately and report the exclusion.", call. = FALSE)
  }

  if ("coord_source" %in% names(df)) {
    bad <- which(grepl("centroid", df$coord_source, ignore.case = TRUE))
    if (length(bad))
      stop(context, " received ", length(bad),
           " centroid geocode(s). A centroid is a valid area locator and an ",
           "invalid routing origin. Filter with ",
           "!grepl('centroid', coord_source) and report the exclusion.",
           call. = FALSE)
  }

  invisible(TRUE)
}
