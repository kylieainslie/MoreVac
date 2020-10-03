### For cluster
# getting started
 # install.packages("drat") # if you don't have it already
 # drat:::add("mrc-ide")
 # install.packages("provisionr")
 # install.packages("didehpc")
 # install.packages("buildr)

# setwd('/Volumes/kainslie/cluster')
setwd('Q:/cluster')
# set up your details and which cluster you want (big or small)
options(didehpc.username = "kainslie",
        didehpc.cluster = "big")

# dont really know what these lines do but you need them
context::context_log_start()
root <- "contexts"

# setting up the context: what files need to be sourced for your function to work, what packages you need
# package sources only required here because the package I am using is not on CRAN
ctx <- context::context_save(path = root,
                             packages = c("morevac","Rcpp","dplyr","data.table","rdist", "Matrix"),
                             package_sources = provisionr::package_sources(local = "Q:/cluster/morevac_1.0.zip",
                                                                           cran = "https://cran.ma.imperial.ac.uk/")
                             )

# this line should give you a login prompt
obj <- didehpc::queue_didehpc(ctx)

# run a single job
# 'job' is the thing I am running on the cluster
# job <- obj$enqueue(run_sims_all(params_file = "param_values.csv", out_file = "sim"))

# bulk jobs
library(morevac)
library(lhs)
# params <- create_params_file(n_sim = 100, n_indiv = 30000, lhc_size = 500, start_year = 1918, end_year = 2028,
#                              out_file = "param_values", vac_cutoff = 10, seed = 1234)
# params_16 <- create_params_file(n_sim = 100, n_indiv = 30000, lhc_size = 500, start_year = 1918, end_year = 2028,
#                              out_file = "param_values_16", vac_cutoff = 16, seed = 1234)
params_baseline <- read.csv(file = "param_values_baseline.csv", header = TRUE)

job_bulk <- obj$enqueue_bulk(params_baseline, run_sims_clust, do_call = TRUE)

