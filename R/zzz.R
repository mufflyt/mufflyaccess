# Deprecated URPS workforce constants as warn-on-access active bindings.
# (Data objects cannot warn on access, so they are installed here.)
.onLoad <- function(libname, pkgname) {
  ns <- asNamespace(pkgname)
  make_dep <- function(name, value, incl) {
    force(name); force(value); force(incl)
    getter <- function() {
      warning(sprintf(
        "%s is deprecated; use urps_count(2023L, include_urology = %s).",
        name, incl), call. = FALSE)
      value
    }
    if (exists(name, envir = ns, inherits = FALSE)) {
      if (bindingIsLocked(name, ns)) unlockBinding(name, ns)
      rm(list = name, envir = ns)
    }
    makeActiveBinding(name, getter, ns)
  }
  make_dep("URPS_COUNT_ABOG_ONLY_2025", 1031L, "FALSE")
  make_dep("URPS_COUNT_ABOG_PLUS_ABU_2025", 1339L, "TRUE")
}
