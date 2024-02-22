functions {
#include custom_functions.stan
  vector get_eta(
    array[] int age,
    array[] int mouse,
    array[] int vessel_type,
    array[] real mu,
    array[,] real a_age_vessel_type,
    real a_vert
  ){
    int N = size(vessel_type);
    vector[N] out;
    for (n in 1:N){
      out[n] = 
        mu[age[mouse[n]]] 
        + a_age_vessel_type[age[mouse[n]], vessel_type[n]];
      if ((vessel_type[n] == 2) || (vessel_type[n] == 15))
        out[n] += a_vert;
    }
    return out;
  }
}
data {
  int<lower=1> N;
  int<lower=1> N_age;
  int<lower=1> N_mouse;
  int<lower=1> N_vessel_type;
  int<lower=1> N_train;
  int<lower=1> N_test;
  array[N_mouse] int<lower=1,upper=N_age> age;
  array[N] int<lower=1,upper=N_mouse> mouse;
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
  array[N_age, N_vessel_type] real a_age_vessel_type;
  array[2] real<lower=0> lambda;
  real<lower=0> sigma_std;
  real a_vert;
}
model {
  a_age_vessel_type[:,1] ~ normal(0, 1);
  array[N_vessel_type] real age_diff = to_array_1d(to_vector(a_age_vessel_type[2]) - to_vector(a_age_vessel_type[1]));
  for (v in 2:N_vessel_type){
    a_age_vessel_type[1, v] ~ normal(a_age_vessel_type[1, v-1], lambda[1]);
    age_diff[v] ~ normal(age_diff[v-1], lambda[2]);
  }
  a_vert ~ normal(0, 0.1);
  mu ~ normal(0, 1);
  lambda[1] ~ normal(0, 0.3);
  lambda[2] ~ normal(0, 0.1);
  sigma_std ~ normal(0, 1);
  if (likelihood){
    vector[N] eta_std = get_eta(
      age,
      mouse,
      vessel_type,
      mu,
      a_age_vessel_type,
      a_vert
    );
    for (n in 1:N_train){
      logy_std[ix_train[n]] ~ normal(eta_std[ix_train[n]], sigma_std);
    }
  }
}
generated quantities {
  array[N_test] real yrep;
  vector[N] yhat;
  vector[N_test] llik;
  real sigma = sigma_std * sd(logy);
  {
    vector[N] eta_std = get_eta(
      age,
      mouse,
      vessel_type,
      mu,
      a_age_vessel_type,
      a_vert
    );
    vector[N] eta = unstandardise_vector(eta_std, mean(logy), sd(logy));
    for (n in 1:N_test){
      yhat[n] = exp(eta[n]);
      yrep[n] = exp(normal_rng(eta[ix_test[n]], sigma));
      llik[n] = normal_lpdf(logy_std[ix_test[n]] | eta_std[ix_test[n]], sigma_std);
    }
  }
}
