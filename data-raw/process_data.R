# Optional helper to download public CDISC Pilot ADaM XPTs for local demos.
# Do not commit the XPT files. Attribute the data to CDISC.
#
#   source("data-raw/process_data.R")

pilot_base <- paste(
  "https://raw.githubusercontent.com/cdisc-org/sdtm-adam-pilot-project/master",
  "updated-pilot-submission-package/900172/m5/datasets/cdiscpilot01",
  "analysis/adam/datasets",
  sep = "/"
)

dest_dir <- if (dir.exists("data-raw")) {
  "data-raw"
} else {
  stop("Run this script from the tm.ttni repository root.", call. = FALSE)
}

download_pilot <- function(filename) {
  dest <- file.path(dest_dir, filename)
  if (file.exists(dest)) {
    message("Already present: ", dest)
    return(invisible(dest))
  }
  url <- paste(pilot_base, filename, sep = "/")
  message("Downloading ", filename, " from CDISC Pilot (attribute to CDISC).")
  utils::download.file(url, destfile = dest, mode = "wb", quiet = TRUE)
  dest
}

download_pilot("adsl.xpt")
download_pilot("adtte.xpt")

message("XPTs are gitignored. Use shiny::runApp(\"app.R\") to load them.")
