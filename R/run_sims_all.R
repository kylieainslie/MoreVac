### run simulations on cluster ###
# created: 23/01/2020
# last modified: 23/01/2020

run_sims_all <- function(params_file, out_file = "test"){

  ### read in parameter file
  params <- fread(params_file)

  for (i in 1:nrow(params)){
  cat("\n Simulation ",i," of",nrow(params),"\n")
  ### parameter values
  n_sim = params$n_sim[i]
  n_indiv = params$n_indiv[i]
  max_age = params$max_age[i]
  years = params$start_year[i]:params$end_year[i]
  betas = c(params$pandemic_beta[i], rep(params$epidemic_beta[i],length(years)-1))
  wane = params$wane[i]
  take = params$take[i]
  epsilon = params$exposure_penalty[i]
  vac_protect = params$vac_protect[i]
  rho = params$rho[i]
  vac_cutoff = params$vac_cutoff[i]

  vac_cov_dat <- data.frame(Age = 0:(max_age-1), No_Vac = numeric(max_age), Annual = numeric(max_age), Biennial = numeric(max_age))
  vac_cov_dat$Annual[3:(vac_cutoff + 1)] <- params$vac_cov[i]
  vac_cov_dat$Biennial[seq(3,vac_cutoff+1,2)] <- params$vac_cov[i]
  ### run simulations
  # cat("\n No vaccination simulation running... \n")
  # returns 3 arrays with inf_hist_mat, vac_hist_mat, and ages_mat from each sim
  sim_test0 <- run_sim_2(sim = n_sim, n = n_indiv, years = years, betas = betas, vac_cov = vac_cov_dat$No_vac, vac_strategy = 0,
                         wane = wane, take = take, epsilon = epsilon, vac_protect = vac_protect, rho = rho)
  # cat("\n Annual vaccination simulation running... \n")
  sim_test1 <- run_sim_2(sim = n_sim, n = n_indiv, years = years, betas = betas, vac_cov = vac_cov_dat$Annual, vac_strategy = 1,
                         wane = wane, take = take, epsilon = epsilon, vac_protect = vac_protect, rho = rho)
  # cat("\n Every other year vaccination simulation running... \n")
  sim_test2 <- run_sim_2(sim = n_sim, n = n_indiv, years = years, betas = betas, vac_cov = vac_cov_dat$Biennial, vac_strategy = 2,
                         wane = wane, take = take, epsilon = epsilon, vac_protect = vac_protect, rho = rho)

  # extract cohorts from each sim and combine raw inf and vac histories for every simulation
  sim0_results <- postprocess_sim_results_for_rolling_cohort(simdat = sim_test0, total_year_range = years, nsim = n_sim)
  sim1_results <- postprocess_sim_results_for_rolling_cohort(simdat = sim_test1, total_year_range = years, nsim = n_sim)
  sim2_results <- postprocess_sim_results_for_rolling_cohort(simdat = sim_test2, total_year_range = years, nsim = n_sim)

  # combine sim results into one data.table
  inf_histories <- rbindlist(list(No_Vac = sim0_results$inf_history, Annual = sim1_results$inf_history, Biennial = sim2_results$inf_history), idcol = 'Vac_Strategy')
  vac_histories <- rbindlist(list(No_Vac = sim0_results$vac_history, Annual = sim1_results$vac_history, Biennial = sim2_results$vac_history), idcol = 'Vac_Strategy')

  # write raw output to file
  try(data.table::fwrite(inf_histories, file = paste0(out_file,i,"_inf_hist.csv"), col.names = TRUE,
                         row.names = FALSE, sep = ","))
  try(data.table::fwrite(vac_histories, file = paste0(out_file,i,"_vac_hist.csv"), col.names = TRUE,
                         row.names = FALSE, sep = ","))
  }
}