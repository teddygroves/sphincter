/* Model whisker stimulation data with interaction effects. */

functions {
#include custom_functions.stan
  vector get_eta(
    array[] int vessel_type,
    array[] int treatment,
    array[] int mouse,
    array[] real a_treatment,
    array[] real a_vessel_type,
    array[,] real a_vessel_type_treatment,
    array[,] real b_age, 
  ){
    int N = rows(vessel_type);
    for (n in 1:N){
      int v = vessel_type[n];
      int t = treatment[n];
      int m = mouse[n];
      eta[n] = mu 
      + a_treatment[t]
      + a_vessel_type[v] 
      + a_vessel_type_treatment[v, t]
      + b_age[v, t] * (age[m] - 1) 
      + a_mouse[v, t, m];
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
  real mu;
  array[N_vessel_type, N_treatment] real b_age_z;
  array[N_vessel_type, N_treatment] real a_vessel_type_treatment_z;
  array[N_vessel_type, N_treatment, N_mouse] real a_mouse_z;
  real<lower=0> sigma;
  array[N_treatment] real<lower=0> tau_mouse;
  array[N_treatment] real a_treatment_z;
  array[N_vessel_type] real a_vessel_type_z;
  real<lower=0> tau_age;
  real<lower=0> tau_treatment;
  real<lower=0> tau_vessel_type_treatment;
  real<lower=0> tau_vessel_type;
}
transformed parameters {
  array[N_vessel_type, N_treatment, N_mouse] real a_mouse;
  array[N_vessel_type, N_treatment] real a_vessel_type_treatment;
  array[N_vessel_type, N_treatment] real b_age;
  array[N_vessel_type] real a_vessel_type;
  array[N_treatment] real a_treatment;
  for (t in 1:N_treatment)
    a_treatment[t] = a_treatment_z[t] * tau_treatment;
  for (v in 1:N_vessel_type){
    a_vessel_type[v] = a_vessel_type_z[v] * tau_vessel_type;
    for (t in 1:N_treatment){
      b_age[v, t] = b_age_z[v, t] * tau_age;
      a_vessel_type_treatment[v, t] = a_vessel_type_treatment_z[v, t] * tau_vessel_type_treatment;
      for (m in 1:N_mouse){
        a_mouse[v, t, m] = a_mouse_z[v, t, m] * tau_mouse[t];
      }
    }
  }
}
model {
  nu ~ gamma(2, 0.1);
  mu ~ normal(0, 0.7);
  tau_treatment ~ normal(0, 1);
  tau_vessel_type_treatment ~ normal(0, 0.7);
  tau_vessel_type ~ normal(0, 0.7);
  tau_age ~ normal(0, 0.7);
  a_vessel_type_z ~ normal(0, 1);
  a_treatment_z ~ normal(0, 1);
  for (t in 1:N_treatment) tau_mouse[t] ~ normal(0, 0.7);
  for (v in 1:N_vessel_type){
    for (t in 1:N_treatment){
      a_vessel_type_treatment_z[v, t] ~ normal(0, 1);
      b_age_z[v, t] ~ normal(0, 1);
      for(m in 1:N_mouse){
        a_mouse_z[v, t, m] ~ normal(0, 1);
      }
    }
  }
  sigma ~ normal(0, 0.5);
  if (likelihood){
    vector[N] eta_std = get_eta(
      vessel_type,
      treatment,
      mouse,
      a_vessel_type,
      a_treatment,
      a_vessel_type_treatment,
      b_age
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
      mouse,
      a_vessel_type,
      a_treatment,
      a_vessel_type_treatment,
      b_age
    );
    eta = unstandardise_vector(eta_std, mean(y), sd(y));
    for (n in 1:N_test){
      yrep[n] = student_t_rng(nu, eta[ix_test[n]], sigma * sd(y));
      llik[n] = student_t_lpdf(y[ix_test[n]] | nu, eta[ix_test[n]], sigma * sd(y));
    }
  }
}


