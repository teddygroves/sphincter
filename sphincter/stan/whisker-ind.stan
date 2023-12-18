/* First attempt to answer question 1a. */

functions {
#include custom_functions.stan
  vector get_eta(
    array[] int vessel_type,
    array[] int treatment,
    array[] int age,
    array[] int mouse,
    vector mu,
    vector a_mouse,
    vector a_treatment,
    vector a_vessel_type
  ){
    int N = size(vessel_type);
    vector[N] eta;
    for (n in 1:N){
      eta[n] = mu[age[mouse[n]]]
      + a_mouse[mouse[n]]
      + a_vessel_type[vessel_type[n]]
      + a_treatment[treatment[n]];
    }
    return eta;
  }
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
  vector[N] y;
  array[N_train] int<lower=1,upper=N> ix_train;
  array[N_test] int<lower=1,upper=N> ix_test;
  int<lower=0,upper=1> likelihood;
}
transformed data {
  vector[N] y_std = standardise_vector(y, mean(y), sd(y));
}
parameters {
  real<lower=1> nu;
  vector[N_age] mu;
  vector[N_mouse] a_mouse_z;
  vector[N_vessel_type] a_vessel_type_z;
  vector[N_treatment] a_treatment_z;
  real<lower=0> sigma;
  real<lower=0> tau_mouse;
  real<lower=0> tau_vessel_type;
  real<lower=0> tau_treatment;
}
transformed parameters {
  vector[N_mouse] a_mouse = a_mouse_z * tau_mouse;
  vector[N_vessel_type] a_vessel_type = a_vessel_type_z * tau_vessel_type;
  vector[N_treatment] a_treatment = a_treatment_z * tau_treatment;
}
model {
  nu ~ gamma(2, 0.1);
  mu ~ normal(0, 1);
  a_mouse_z ~ normal(0, 1);
  a_vessel_type_z ~ normal(0, 1);
  a_treatment_z ~ normal(0, 1);
  tau_mouse ~ normal(0, 0.5);
  tau_vessel_type ~ normal(0, 0.5);
  tau_treatment ~ normal(0, 0.5);
  sigma ~ lognormal(0, 0.5);
  if (likelihood){
    vector[N] eta_std = get_eta(
      vessel_type,
      treatment,
      age,
      mouse,
      mu,
      a_mouse,
      a_treatment,
      a_vessel_type
    );
    y_std[ix_train] ~ student_t(nu, eta_std[ix_train], sigma);
  }
}
generated quantities {
  vector[N_test] yrep;
  vector[N_test] llik;
  {
    vector[N] eta_std = get_eta(
      vessel_type,
      treatment,
      age,
      mouse,
      mu,
      a_mouse,
      a_treatment,
      a_vessel_type
    );
    vector[N] eta = unstandardise_vector(eta_std, mean(y), sd(y));
    for (n in 1:N_test){
      yrep[n] = student_t_rng(nu, eta[ix_test[n]], sigma * sd(y));
      llik[n] = student_t_lpdf(y[ix_test[n]] | nu, eta[ix_test[n]], sigma * sd(y));
    }
  }
}

