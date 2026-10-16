# Script to generate deterministic fixtures directly from careless 1.2.2
# Reference archive: https://cloud.r-project.org/src/contrib/careless_1.2.2.tar.gz
# Archive SHA-256: 6AD3D4C8B1B2910A7C2E98C5A8BF37E65071164D13BA66896490D9FFCB678ED9

# 1. Verify and load careless strictly from isolated library
careless_lib <- file.path(dirname(dirname(dirname(getwd()))), "tmp", "v0.2.0-review-correction", "careless-lib")
if (!dir.exists(careless_lib)) {
  # fallback for running from project root
  careless_lib <- file.path(getwd(), "tmp", "v0.2.0-review-correction", "careless-lib")
}

if (!requireNamespace("careless", lib.loc = careless_lib, quietly = TRUE)) {
  stop("careless 1.2.2 is not installed in isolated library: ", careless_lib)
}

ver <- packageVersion("careless", lib.loc = careless_lib)
if (as.character(ver) != "1.2.2") {
  stop("Expected careless version 1.2.2, found: ", ver)
}
cat(sprintf("Using careless version %s from %s\n", ver, careless_lib))

# 2. Load upstream datasets directly from fixture RDA files
data_env <- new.env(parent = emptyenv())
fixture_dir <- if (file.exists("tests/testthat/fixtures/careless_dataset.rda")) {
  "tests/testthat/fixtures"
} else if (file.exists("fixtures/careless_dataset.rda")) {
  "fixtures"
} else {
  file.path(getwd(), "tests", "testthat", "fixtures")
}

load(file.path(fixture_dir, "careless_dataset.rda"), envir = data_env)
load(file.path(fixture_dir, "careless_dataset2.rda"), envir = data_env)

cd1 <- data_env$careless_dataset
cd2 <- data_env$careless_dataset2

cat(sprintf("Loaded careless_dataset: %d x %d\n", nrow(cd1), ncol(cd1)))
cat(sprintf("Loaded careless_dataset2: %d x %d\n", nrow(cd2), ncol(cd2)))

# Save RNG state
old_rng <- RNGkind()
old_seed <- if (exists(".Random.seed", envir = .GlobalEnv)) get(".Random.seed", envir = .GlobalEnv) else NULL

fixtures <- list()

# 1. longstring
ls_mat <- matrix(c(1,1,1,2, 3,3,3,3, 1,2,3,4), nrow = 3, byrow = TRUE)
fixtures$longstring_vec <- careless::longstring(ls_mat)
fixtures$longstring_df <- careless::longstring(ls_mat, avg = TRUE)

# 2. irv
irv_mat <- matrix(c(1, 2, 3, 4, 5, 6, 2, 2, 2, 2, 2, 2), nrow = 2, byrow = TRUE)
fixtures$irv_vec <- careless::irv(irv_mat)
fixtures$irv_split <- careless::irv(irv_mat, split = TRUE, num.split = 2)

# 3. evenodd
eo_sample <- cd1[1:10, 1:20]
fixtures$evenodd_vec <- suppressWarnings(careless::evenodd(eo_sample, factors = rep(5, 4)))
fixtures$evenodd_diag <- suppressWarnings(careless::evenodd(eo_sample, factors = rep(5, 4), diag = TRUE))

# 4. psychsyn_critval
fixtures$critval_pos <- head(careless::psychsyn_critval(cd1[1:20, 1:5]), 3)
fixtures$critval_neg <- head(careless::psychsyn_critval(cd1[1:20, 1:5], anto = TRUE), 3)

# 5. psychsyn
# 5a. Deterministic case (resample_na = FALSE)
fixtures$psychsyn_det <- careless::psychsyn(cd1[1:15, ], critval = 0.50, resample_na = FALSE)
fixtures$psychsyn_diag <- careless::psychsyn(cd1[1:15, ], critval = 0.50, diag = TRUE, resample_na = FALSE)

# 5b. Resample case where resample_na actually triggers
# Crafted dataset with 3 synonym pairs where row 1 has 0 variance across first items of pairs
set.seed(1)
n <- 30
x1 <- rnorm(n)
x2 <- x1 + rnorm(n, sd = 0.1)
x3 <- rnorm(n)
x4 <- x3 + rnorm(n, sd = 0.1)
x5 <- rnorm(n)
x6 <- x5 + rnorm(n, sd = 0.1)
mat_resample <- data.frame(X1 = x1, X2 = x2, X3 = x3, X4 = x4, X5 = x5, X6 = x6)
mat_resample[1, ] <- c(1, 2, 1, 3, 1, 4)

# Without resample -> NA
fixtures$resample_craft_no <- careless::psychsyn(mat_resample, critval = 0.8, resample_na = FALSE)[1]

# With resample under fixed seed -> -0.755928946018455
RNGkind("Mersenne-Twister", "Inversion", "Rejection")
set.seed(123)
fixtures$resample_craft_yes <- careless::psychsyn(mat_resample, critval = 0.8, resample_na = TRUE)[1]

# 6. psychant
fixtures$psychant_vec <- careless::psychant(cd2[1:15, ], critval = -0.50)
fixtures$psychant_diag <- careless::psychant(cd2[1:15, ], critval = -0.50, diag = TRUE)

# 7. mahad
fixtures$mahad_vec <- careless::mahad(cd1[1:10, 1:5], plot = FALSE)
fixtures$mahad_flag <- careless::mahad(cd1[1:10, 1:5], plot = FALSE, flag = TRUE, confidence = 0.95)

# Restore RNG state
if (!is.null(old_seed)) assign(".Random.seed", old_seed, envir = .GlobalEnv) else rm(".Random.seed", envir = .GlobalEnv)
RNGkind(old_rng[1], old_rng[2], old_rng[3])

cat("\n=== Generated Fixtures Output ===\n")
print(fixtures)
