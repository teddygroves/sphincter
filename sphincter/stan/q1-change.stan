/* First attempt to answer question 1a. */

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
  vector[N] y;
  array[N_train] int<lower=1,upper=N> ix_train;
  array[N_test] int<lower=1,upper=N> ix_test;
  int<lower=0,upper=1> likelihood;
}
transformed data {
  vector[N] y_std = standardise_vector(y, mean(y), sd(y));
}
parameters {
  vector[N_age] a_age;
  vector[N_mouse] a_mouse_z;
  vector[N_treatment] a_treatment_z;
  vector[N_vessel_type] a_vessel_type_z;
  real<lower=0> sigma;
  real<lower=0> tau_mouse;
  real<lower=0> tau_treatment;
  real<lower=0> tau_vessel_type;
}
transformed parameters {
  vector[N_mouse] a_mouse = a_mouse_z * tau_mouse;
  vector[N_treatment] a_treatment = a_treatment_z * tau_treatment;
  vector[N_vessel_type] a_vessel_type = a_vessel_type_z * tau_vessel_type;
}
model {
  a_age ~ normal(0, 1);
  a_mouse_z ~ normal(0, 1);
  a_treatment_z ~ normal(0, 1);
  a_vessel_type_z ~ normal(0, 1);
  tau_mouse ~ normal(0, 0.2);
  tau_treatment ~ normal(0, 0.2);
  tau_vessel_type ~ normal(0, 0.2);
  sigma ~ lognormal(0, 0.5);
  if (likelihood){
    vector[N] eta = 
    a_age[age] 
    + a_mouse[mouse]
    + a_treatment[treatment] 
    + a_vessel_type[vessel_type];
    y_std[ix_train] ~ normal(eta[ix_train], sigma);
  }
}
generated quantities {
  vector[N_test] yrep;
  vector[N_test] llik;
  {
    vector[N] eta = unstandardise_vector( 
      a_age[age] 
      + a_mouse[mouse]
      + a_treatment[treatment] 
      + a_vessel_type[vessel_type], 
      mean(y),
      sd(y)
    );  
    for (n in 1:N_test){
      yrep[n] = normal_rng(eta[ix_test[n]], sigma * sd(y));
      llik[n] = normal_lpdf(y[ix_test[n]] | eta[ix_test[n]], sigma * sd(y));
    }
  }
}
