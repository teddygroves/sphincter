/*
    Model of red blood cell flow. Version with a vesseltype:treatment 
    interaction effect
*/

functions {
#include custom_functions.stan
  vector get_eta(
    array[] int age,
    array[] int mouse,
    array[] int vessel_type,
    array[] int treatment,
    array[] real mu,
    array[] real a_treatment,
    array[] real a_vessel_type,
    array[,] real a_vessel_type_treatment
  ){
    int N = size(vessel_type);
    vector[N] out;
    for (n in 1:N){
      out[n] = mu[age[mouse[n]]]
      + a_treatment[treatment[n]] 
      + a_vessel_type[vessel_type[n]]
      + a_vessel_type_treatment[vessel_type[n], treatment[n]];
    }
    return out;
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
  vector<lower=0>[N] y;
  array[N_train] int<lower=1,upper=N> ix_train;
  array[N_test] int<lower=1,upper=N> ix_test;
  int<lower=0,upper=1> likelihood;
}
transformed data {
  vector[N] logy = log(y);
  vector[N] logy_std = standardise_vector(logy, mean(logy), sd(logy));
}
parameters {
  array[N_age] real mu;
  real<lower=0> tau_treatment;
  real<lower=0> tau_vessel_type;
  real<lower=0> tau_vessel_type_treatment;
  array[N_treatment] real<lower=0> sigma_std;
  array[N_treatment] real a_treatment_z;
  array[N_vessel_type] real a_vessel_type_z;
  array[N_vessel_type, N_treatment] real a_vessel_type_treatment_z;
}
transformed parameters {
  array[N_treatment] real a_treatment;
  array[N_vessel_type] real a_vessel_type;
  array[N_vessel_type, N_treatment] real a_vessel_type_treatment;
  for (t in 1:N_treatment){
    a_treatment[t] = a_treatment_z[t] * tau_treatment;
    for (v in 1:N_vessel_type)
      a_vessel_type_treatment[v, t] = 
        a_vessel_type_treatment_z[v, t] * tau_vessel_type_treatment;
  }
  for (v in 1:N_vessel_type){
    a_vessel_type[v] = a_vessel_type_z[v] * tau_vessel_type;
  }
}
model {
  mu ~ normal(0, 0.5);
  tau_treatment ~ normal(0, 0.5);
  tau_vessel_type ~ normal(0, 0.5);
  tau_vessel_type_treatment ~ normal(0, 0.5);
  sigma_std ~ normal(0, 0.5);
  a_vessel_type_z ~ normal(0, 1);
  a_treatment_z ~ normal(0, 1);
  for (v in 1:N_vessel_type)
    a_vessel_type_treatment_z[v] ~ normal(0, 1);
  if (likelihood){
    vector[N] eta_std = get_eta(
      age,
      mouse,
      vessel_type,
      treatment,
      mu,
      a_treatment,
      a_vessel_type,
      a_vessel_type_treatment
    );
    for (n in 1:N_train){
      logy_std[ix_train[n]] ~ normal(eta_std[ix_train[n]], sigma_std[treatment[ix_train[n]]]);
    }
  }
}
generated quantities {
  array[N_test] real yrep;
  vector[N_test] llik;
  array[N_treatment] real sigma;
  for (t in 1:N_treatment) sigma[t] = sigma_std[t] * sd(logy);
  {
    vector[N] eta_std = get_eta(
      age,
      mouse,
      vessel_type,
      treatment,
      mu,
      a_treatment,
      a_vessel_type,
      a_vessel_type_treatment
    );
    vector[N] eta = unstandardise_vector(eta_std, mean(logy), sd(logy));
    for (n in 1:N_test){
      yrep[n] = exp(normal_rng(eta[ix_test[n]], sigma[treatment[ix_test[n]]]));
      llik[n] = normal_lpdf(logy_std[ix_test[n]] | eta_std[ix_test[n]], sigma_std[treatment[ix_test[n]]]);
    }
  }
}

