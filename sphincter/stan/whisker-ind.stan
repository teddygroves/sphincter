/* Model whisker stimulation data with interaction effects. */

functions {
#include custom_functions.stan
  vector get_eta(
    array[] int vessel_type,
    array[] int treatment,
    array[] int age,
    array[] int mouse,
    array[] real mu,
    array[] real a_treatment,
    array[] real a_vessel_type
  ){
    int N = size(vessel_type);
    vector[N] eta;
    for (n in 1:N){
      int a = age[mouse[n]];
      int v = vessel_type[n];
      int t = treatment[n];
      int m = mouse[n];
      eta[n] = mu[a] + a_treatment[t] + a_vessel_type[v];
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
  array[N_age] real mu;
  array[N_treatment] real<lower=0> sigma;
  array[N_treatment] real a_treatment_z;
  array[N_vessel_type] real a_vessel_type_z;
  real<lower=0> tau_treatment;
  real<lower=0> tau_vessel_type;
}
transformed parameters {
  array[N_vessel_type] real a_vessel_type;
  array[N_treatment] real a_treatment;
  for (t in 1:N_treatment){
    a_treatment[t] = a_treatment_z[t] * tau_treatment;
  }
  for (v in 1:N_vessel_type){
    a_vessel_type[v] = a_vessel_type_z[v] * tau_vessel_type;
  }
}
model {
  nu ~ gamma(2, 0.1);
  mu ~ normal(0, 0.7);
  tau_treatment ~ normal(0, 1);
  tau_vessel_type ~ normal(0, 0.7);
  a_vessel_type_z ~ normal(0, 1);
  a_treatment_z ~ normal(0, 1);
  sigma ~ normal(0, 0.5);
  if (likelihood){
    vector[N] eta_std = get_eta(
      vessel_type,
      treatment,
      age,
      mouse,
      mu,
      a_treatment,
      a_vessel_type
    );
    y_std[ix_train] ~ student_t(nu, eta_std[ix_train], sigma[treatment[ix_train]]);
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
      a_treatment,
      a_vessel_type
    );
    vector[N] eta = unstandardise_vector(eta_std, mean(y), sd(y));
    for (n in 1:N_test){
      yrep[n] = student_t_rng(nu, eta[ix_test[n]], sigma[treatment[ix_test[n]]] * sd(y));
      llik[n] = student_t_lpdf(y[ix_test[n]] | nu, eta[ix_test[n]], sigma[treatment[ix_test[n]]]* sd(y));
    }
  }
}
