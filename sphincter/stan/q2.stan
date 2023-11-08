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
  array[N] int<lower=1,upper=N_age> age;
  array[N] int<lower=1,upper=N_mouse> mouse;
  array[N] int<lower=1,upper=N_treatment> treatment;
  array[N] int<lower=1,upper=N_vessel_type> vessel_type;
  vector<lower=0>[N] y;
  array[N_train] int<lower=1,upper=N> ix_train;
  array[N_test] int<lower=1,upper=N> ix_test;
  int<lower=0,upper=1> likelihood;
}
parameters {
  vector[N_age] a_age;
  vector[N_mouse] a_mouse_z;
  vector[N_treatment] a_treatment_z;
  array[N_age] vector[N_vessel_type] a_vessel_type_z;
  real<lower=0> tau_mouse;
  real<lower=0> tau_treatment;
  vector<lower=0>[N_age] tau_vessel_type;
}
transformed parameters {
  vector[N_mouse] a_mouse = a_mouse_z * tau_mouse;
  vector[N_treatment] a_treatment = a_treatment_z * tau_treatment;
  array[N_age] vector[N_vessel_type] a_vessel_type;
  for (a in 1:N_age) 
    a_vessel_type[a] = a_vessel_type_z[a] * tau_vessel_type[a];
}
model {
  a_age ~ normal(0, 1);
  a_mouse_z ~ normal(0, 1);
  a_treatment_z ~ normal(0, 1);
  for (a in 1:N_age)
    a_vessel_type_z[a] ~ normal(0, 1);
  tau_mouse ~ normal(0, 0.2);
  tau_treatment ~ normal(0, 0.2);
  tau_vessel_type ~ normal(0, 0.2);
  if (likelihood){
    vector[N] eta;
    for (n in 1:N){
      eta[n] = 
        a_age[age[n]] 
        + a_mouse[mouse[n]]
        + a_treatment[treatment[n]] 
        + a_vessel_type[age[n], vessel_type[n]];
    }
    y[ix_train] ~ exponential(exp(eta[ix_train]));
  }
}
generated quantities {
  vector[N_test] yrep;
  vector[N_test] llik;
  {
    vector[N] eta;
    for (n in 1:N)
      eta[n] = 
        a_age[age[n]] 
        + a_mouse[mouse[n]]
        + a_treatment[treatment[n]] 
        + a_vessel_type[age[n], vessel_type[n]];
    for (n in 1:N_test){
      yrep[n] = exponential_rng(exp(eta[ix_test[n]]));
      llik[n] = exponential_lpdf(y[ix_test[n]] | exp(eta[ix_test[n]]));
    }
  }
}

