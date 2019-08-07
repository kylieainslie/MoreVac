#include <Rcpp.h>
#include <algorithm>    // std::min
using namespace Rcpp;

// Calculate susceptibility and determine infection status
//
// @param inf_history Number years since last infection
// @param years_since_last_vac Number of years since last vaccination
// @param suscept_mat
// @param x
// @param ages_mat
// @param delta_v
// @param gammas
// @param drift
// @param foi
// @param wane_rate
// @param version Which susceptibility function to use: 1 = either-or, 2 = multiplicative
// @return Numeric value of susceptibility
// @keywords morevac
// @export
// [[Rcpp::export]]
List infect_cpp_2(NumericMatrix inf_history,
                        NumericMatrix years_since_last_vac,
                        NumericMatrix suscept_mat,
                        NumericMatrix x,
                        NumericMatrix ages_mat,
                        NumericMatrix delta_v,
                        NumericVector gammas,
                        NumericVector drift,
                        NumericVector foi,
                        double wane_rate,
                        int version
                        ) {

  int nyears = inf_history.ncol();
  int nindiv = inf_history.nrow();
  double w = 0;                          // initialize waning
  int vac_ind = 0;                       // initialize vac_ind
  NumericMatrix delta_x(nindiv,nyears);

  for(int j = 0; j < nyears; ++j){
    NumericVector randnum_inf = runif(nindiv);
    for (int i = 0; i < nindiv; ++i){
      if (ages_mat(i,j) == 0) {x(i,j) = 999;} // reset x if age = 0
     // determine delta_x(i,j)
        if (x(i,j) >= 999){
          delta_x(i,j) = 1;
        } else {
          delta_x(i,j) = delta_x(i,j-1) + drift[j];
        }
      // determine if individual was vaccinated in current year
        if (years_since_last_vac(i,j) >= 999){
          suscept_mat(i,j) = std::min(1.0,std::min(1.0,delta_x(i,j)));
        } else {
          if(years_since_last_vac(i,j) == 0){
            vac_ind = 1;
          } else {vac_ind = 0;}
          // determine amount of waning
            w = (1-vac_ind)*((1 - gammas[j]) * years_since_last_vac(i,j) * wane_rate);
          // determine version of susceptibility
            if (version == 1){
              suscept_mat(i,j) = std::min(1.0, std::min(std::min(1.0,delta_x(i,j)),(vac_ind*gammas[j]) + (1-vac_ind)*(gammas[j] + delta_v(i,j) + w))); // either-or
            } else if (version == 2) {
              suscept_mat(i,j) = std::min(1.0,std::min(1.0,delta_x(i,j)) * std::min(1.0, (vac_ind*gammas[j]) + (1-vac_ind)*(gammas[j] + delta_v(i,j) + w))); // multiplicative
            }
          }
      // determine infection status
        if (randnum_inf[i] <= foi[j]*suscept_mat(i,j)) {
          inf_history(i,j) = 1;
          x(i,j) = 0;
          suscept_mat(i,j) = 0;
          delta_x(i,j) = 0;
        } else {inf_history(i,j) = 0;}
      // update x(i,j+1)
        if (j < nyears - 1){
          if (ages_mat(i,j+1) > 0){
              x(i,j+1) = x(i,j) + 1;
          }
        }
      }
    }
  List rtn;
  rtn["inf_hist_mat"] = inf_history;
  rtn["suscept_mat"] = suscept_mat;
  rtn["x"] = x;
  rtn["delta_x"] = delta_x;
  return(rtn);
}

/*** R
# input parameter values
# nyears <- 30
# maxage <- 20
# nindiv <- 100
# betas <- c(0.4, rep(0.2,nyears-1))
# # initialize population
# init_age_vec <- sample(0:maxage-1,nindiv,replace=TRUE)
# init_pop <- initialize_pop_cpp(n = nindiv, nyears = nyears, init_ages = init_age_vec, max_age = maxage)
# vac_this_year <- c(rep(0,nyears/2),rep(1,nyears/2))
# drift <- drift_func(nyears = nyears, rate = 0.25)
# # determine vaccine update schedule
# run_update <- vaccine_update_cpp(drift = drift, threshold = 0.5, vac_protect = 0.7)
# gammas <- run_update$gammas
# vac <- vaccinate_cpp_2(vac_hist_mat = init_pop$vac_hist_mat, ages_mat = init_pop$ages_mat,
#                        v = init_pop$time_since_last_vac,vac_this_year = vac_this_year,
#                        vac_cov = c(rep(1,maxage)),take = 1, rho = 1, vac_strategy = 2)
# delta_v <- find_delta_v(v = vac$v, drift = drift)
# infect_pop <- infect_cpp_2(inf_history = init_pop$inf_hist_mat,
#                            years_since_last_vac = vac$v,
#                            suscept_mat = init_pop$suscept_mat,
#                            x = init_pop$time_since_last_inf,
#                            ages_mat = init_pop$ages_mat,
#                            drift = drift,
#                            delta_v = delta_v,
#                            gammas = gammas,
#                            foi = betas,
#                            wane_rate = 0,
#                            version = 2)
# person <- data.frame(Year = 1820:(1820+nyears-1), Vac_History = vac$vac_hist_mat[2,],
#                      Inf_History = infect_pop$inf_hist_mat[2,],
#                      X = infect_pop$x[2,],
#                      Susceptibility = infect_pop$suscept_mat[2,],
#                      Drift = drift, Update = run_update$update)
*/