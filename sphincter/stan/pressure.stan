/* Model for answering question 2. */

functions {
#include custom_functions.stan
}
data {
  int<lower=1> N;
  int<lower=1> N_age;
  int<lower=1> N_mouse;
  int<lower=1> N_treatment;
  int<lower=1> N_vessel_type;
  int<lower=1> N_train;
  int<lower=1> N_test;
  array[N_mouse] int<lower=1,upper=N_age> age;
  array[N] int<lower=1,upper=N_mouse> mouse;
  array[N] int<lower=1,upper=N_treatment> treatment;
  array[N] int<lower=1,upper=N_vessel_type> vessel_type;
  array[2, N] real<lower=0> y;
  vector<lower=0>[N] pressure;
  vector<lower=0,upper=1>[N] hyper;
  array[N_train] int<lower=1,upper=N> ix_train;
  array[N_test] int<lower=1,upper=N> ix_test;
  int<lower=0,upper=1> likelihood;
}
transformed data {
  vector[N] log_pressure_std = 
    standardise_vector(log(pressure), mean(log(pressure)), sd(log(pressure)));
}
parameters {
  real mu_lambda;
  real mu_delta;
  real<lower=0> tau_lambda;
  real<lower=0> tau_delta;
  real<lower=0> sigma;
  array[N_age] real a_age;
  array[N_mouse] real lambda_z;
  array[N_mouse] real delta_z;
}
transformed parameters {
  array[N_mouse] real lambda;  // baseline pressure
  array[N_mouse] real delta;   // effect of hypertensive drug
  array[N] real log_pressure_std_hat;
  for (m in 1:N_mouse){
   lambda[m] = mu_lambda + a_age[age[m]]  + lambda_z[m] * tau_lambda;
   delta[m] = mu_delta + delta_z[m] * tau_delta;
  }
  for (n in 1:N){
    log_pressure_std_hat[n] = lambda[mouse[n]] + hyper[n] * delta[mouse[n]];
   }
}
model {
  if (likelihood){
    for (n in 1:N_train) 
      log_pressure_std[ix_train[n]] ~ student_t(4, log_pressure_std_hat[ix_train[n]], sigma);
  }
  mu_lambda ~ normal(0, 1);
  mu_delta ~ normal(0, 1);
  tau_lambda ~ normal(0, 1);
  tau_delta ~ normal(0, 1);
  sigma ~ normal(0, 1);
  a_age ~ normal(0, 1);
  lambda_z ~ normal(0, 1);
  delta_z ~ normal(0, 1);
}
generated quantities {
  array[N_test] real yrep;
  vector[N_test] llik;
  vector[N] pressure_hat;
  for (n in 1:N){
   pressure_hat[n] = exp(mean(log(pressure)) + log_pressure_std_hat[n] * sd(log(pressure)));
  }
  for (n in 1:N_test){
    yrep[n] = exp(mean(log(pressure)) + student_t_rng(4, log_pressure_std_hat[ix_test[n]], sigma) * sd(log(pressure)));
    llik[n] = student_t_lpdf(log_pressure_std[ix_test[n]] | 4, log_pressure_std_hat[ix_test[n]], sigma);
  }
}



