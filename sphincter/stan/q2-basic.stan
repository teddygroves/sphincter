/* Model for answering question 2. Basic version */

functions {
#include custom_functions.stan
  tuple(vector, vector) get_eta(
    vector pressure_std, 
    vector diameter_std, 
    array[] int age,
    array[] int mouse,
    array[] int vessel_type,
    array[] int treatment,
    array[,] real mu,
    array[,] real a_treatment,
    array[,] real a_vessel_type,
    array[] real b_diameter
  ){
    int N = rows(pressure_std);
    tuple(vector[N], vector[N]) out;
    for (n in 1:N){
      out.1[n] = mu[1, age[mouse[n]]]
      + a_treatment[1, treatment[n]] 
      + a_vessel_type[1, vessel_type[n]]
      + b_diameter[1] * diameter_std[n];
      out.2[n] = mu[2, age[mouse[n]]]
      + a_treatment[2, treatment[n]] 
      + a_vessel_type[2, vessel_type[n]]
      + b_diameter[2] * diameter_std[n];
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
  array[2, N] real<lower=0> y;
  vector[N] pressure;
  vector[N] diameter;
  array[N_train] int<lower=1,upper=N> ix_train;
  array[N_test] int<lower=1,upper=N> ix_test;
  int<lower=0,upper=1> likelihood;
}
transformed data {
  vector[N] pressure_std = standardise_vector(pressure, mean(pressure), sd(pressure));
  vector[N] diameter_std = standardise_vector(diameter, mean(diameter), sd(diameter));
  array[2, N] real<lower=0> y_std;
  for (n in 1:N){
    y_std[1, n] = y[1, n] / 1000;
    y_std[2, n] = y[2, n] / 1000;
  }
}
parameters {
  array[2, N_age] real mu;
  array[2] real<lower=0> tau_treatment;
  array[2] real<lower=0> tau_vessel_type;
  array[2, N_treatment] real a_treatment_z;
  array[2, N_vessel_type] real a_vessel_type_z;
  array[2] real b_diameter;
}
transformed parameters {
  array[2, N_treatment] real a_treatment;
  array[2, N_vessel_type] real a_vessel_type;
  for (i in 1:2){
    for (t in 1:N_treatment)
      a_treatment[i, t] = a_treatment_z[i, t] * tau_treatment[i];
    for (v in 1:N_vessel_type){
      a_vessel_type[i, v] = a_vessel_type_z[i, v] * tau_vessel_type[i];
    }
  }
}
model {
  for (i in 1:2){
    mu[i] ~ normal(-2, 1);
    tau_treatment[i] ~ normal(0, 1);
    tau_vessel_type[i] ~ normal(0, 1);
    a_vessel_type_z[i] ~ normal(0, 1);
    a_treatment_z[i] ~ normal(0, 1);
    b_diameter[i] ~ normal(0, 1);
  }
  if (likelihood){
    tuple(vector[N], vector[N]) eta = get_eta(
      pressure_std, 
      diameter_std, 
      age,
      mouse,
      vessel_type,
      treatment,
      mu,
      a_treatment,
      a_vessel_type,
      b_diameter
    );
    for (n in 1:N_train){
      y_std[1, ix_train[n]] ~ exponential(exp(-eta.1[ix_train[n]]));
      y_std[2, ix_train[n]] ~ exponential(exp(-eta.2[ix_train[n]]));
    }
  }
}
generated quantities {
  array[2, N_test] real yrep;
  vector[N_test] llik;
  {
    tuple(vector[N], vector[N]) eta = get_eta(
      pressure_std, 
      diameter_std, 
      age,
      mouse,
      vessel_type,
      treatment,
      mu,
      a_treatment,
      a_vessel_type,
      b_diameter
    );
    for (n in 1:N_test){
      yrep[1, n] = 1000 * exponential_rng(exp(-eta.1[ix_test[n]]));
      yrep[2, n] = 1000 * exponential_rng(exp(-eta.2[ix_test[n]]));
      llik[n] = exponential_lpdf(y_std[1, ix_test[n]] | exp(-eta.1[ix_test[n]]))
      + exponential_lpdf(y_std[2, ix_test[n]] | exp(-eta.2[ix_test[n]])); 
    }
  }
}

