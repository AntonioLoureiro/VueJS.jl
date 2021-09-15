# File system locations
EXAMPLES_DIR    = joinpath(@__DIR__, "examples")
NOTEBOOKS_DIR   = joinpath(@__DIR__, "notebooks")

# Repository name
REPO_NAME       = "VueJS.jl"

# Relative web locations
BASE_PATH       = "/$REPO_NAME"
DOCS_PATH       = joinpath(BASE_PATH, "docs")
NOTEBOOKS_PATH  = joinpath(DOCS_PATH, "notebooks")
TARGET_DIR      = "public"
INDEX_PAGE      = "index.html"
INDEX_ALIAS     = "components.html"
INDEX_PATH      = joinpath(BASE_PATH, INDEX_PAGE)
