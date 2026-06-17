# scripts/invalidate_fred.R
# Deletes the _freeze cache for any .qmd that has params: fred-data: true
# Run this script before rendering to force re-execution of FRED documents.

library(stringr)

repo_root   <- "."
freeze_root <- "_freeze"

qmd_files <- list.files(repo_root, pattern = "\\.qmd$", recursive = TRUE, full.names = TRUE)

for (qmd in qmd_files) {
  content <- readLines(qmd, warn = FALSE)
  if (any(str_detect(content, "fred-data:\\s*true"))) {
    rel         <- str_remove(qmd, "^\\./") |> str_remove("\\.qmd$")
    freeze_path <- file.path(freeze_root, rel)
    if (dir.exists(freeze_path)) {
      unlink(freeze_path, recursive = TRUE)
      cat("Invalidated:", freeze_path, "\n")
    } else {
      cat("No cache yet:", rel, "\n")
    }
  }
}
