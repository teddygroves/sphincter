/* Model for answering question 2. Basic version */

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
    array[,] real a_age_vessel_type,
    array[,] real a_vessel_type_treatment
  ){
    int N = size(treatment);
    vector[N] out;
    for (n in 1:N){
      out[n] = mu[age[mouse[n]]]
      + a_treatment[treatment[n]] 
      + a_vessel_type[vessel_type[n]]
      + a_vessel_type_treatment[vessel_type[n], treatment[n]]
      + a_age_vessel_type[age[mouse[n]], vessel_type[n]];
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
parameters {
  array[N_age] real mu;
  real<lower=0> tau_treatment;
  real<lower=0> tau_vessel_type;
  array[N_age] real<lower=0> tau_age_vessel_type;
  array[N_treatment] real<lower=0> tau_vessel_type_treatment;
  real<lower=0> sigma;
  array[N_treatment] real a_treatment_z;
  array[N_vessel_type] real a_vessel_type_z;
  array[N_vessel_type, N_treatment] real a_vessel_type_treatment_z;
  array[N_age, N_vessel_type] real a_age_vessel_type_z;
}
transformed parameters {
  array[N_treatment] real a_treatment; 
  array[N_vessel_type] real a_vessel_type; 
  array[N_age, N_vessel_type] real a_age_vessel_type;
  array[N_vessel_type, N_treatment] real a_vessel_type_treatment;
  for (t in 1:N_treatment){
    a_treatment[t] = a_treatment_z[t] * tau_treatment;
  }
  for (vt in 1:N_vessel_type){
    a_vessel_type[vt] = a_vessel_type_z[vt] * tau_vessel_type;
    for (a in 1:N_age){
      a_age_vessel_type[a, vt] = a_age_vessel_type_z[a, vt] * tau_age_vessel_type[a];
    }  
    for (t in 1:N_treatment){
      a_vessel_type_treatment[vt, t] = a_vessel_type_treatment_z[vt, t] * tau_vessel_type_treatment[t];
      
    }
  }
}
model {
  sigma ~ normal(0, 0.5);
  mu ~ normal(2, 0.5);
  tau_vessel_type ~ normal(0, 0.5);
  tau_treatment ~ normal(0, 0.5);
  tau_age_vessel_type ~ normal(0, 0.5);
  tau_vessel_type_treatment ~ normal(0, 0.5);
  a_vessel_type_z ~ normal(0, 1);
  a_treatment_z ~ normal(0, 1);
  for (a in 1:N_age){
    a_age_vessel_type_z[a] ~ normal(0, 1);
  }
  for (t in 1:N_treatment){
    a_vessel_type_treatment_z[,t] ~ normal(0, 1);
  }
  if (likelihood){
    vector[N] eta = get_eta(
      age,
      mouse,
      vessel_type,
      treatment,
      mu,
      a_treatment,
      a_vessel_type,
      a_age_vessel_type,
      a_vessel_type_treatment
    );
    for (n in 1:N_train){
      y[ix_train[n]] ~ lognormal(eta[ix_train[n]], sigma);
    }
  }
}
generated quantities {
  array[N_test] real yrep;
  vector[N_test] llik;
  {
    vector[N] eta = get_eta(
      age,
      mouse,
      vessel_type,
      treatment,
      mu,
      a_treatment,
      a_vessel_type,
      a_age_vessel_type,
      a_vessel_type_treatment
    );
    for (n in 1:N_test){
      yrep[n] = lognormal_rng(eta[ix_test[n]], sigma);
      llik[n] = lognormal_lpdf(y[ix_test[n]] | eta[ix_test[n]], sigma);
    }
  }
}


