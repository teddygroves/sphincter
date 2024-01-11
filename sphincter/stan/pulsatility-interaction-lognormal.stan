/* Model for answering question 2. Version with age:treatment and
   age:vessel_type interaction effects */

functions {
#include custom_functions.stan
  tuple(vector, vector) get_eta(
    vector diameter_std, 
    array[] int age,
    array[] int mouse,
    array[] int vessel_type,
    array[] int treatment,
    array[,] real mu,
    array[,] real a_treatment,
    array[,] real a_vessel_type,
    array[,,] real a_treatment_vessel_type,
    array[] real b_diameter
  ){
    int N = rows(diameter_std);
    tuple(vector[N], vector[N]) out;
    for (n in 1:N){
      out.1[n] = mu[1, age[mouse[n]]]
      + a_treatment[1, treatment[n]] 
      + a_vessel_type[1, vessel_type[n]]
      + a_treatment_vessel_type[1, treatment[n], vessel_type[n]]
      + b_diameter[1] * diameter_std[n];
      out.2[n] = mu[2, age[mouse[n]]]
      + a_treatment[2, treatment[n]] 
      + a_vessel_type[2, vessel_type[n]]
      + a_treatment_vessel_type[2, treatment[n], vessel_type[n]]
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
  array[2] vector<lower=0>[N] y;
  vector[N] pressure;
  vector[N] diameter;
  array[N_train] int<lower=1,upper=N> ix_train;
  array[N_test] int<lower=1,upper=N> ix_test;
  int<lower=0,upper=1> likelihood;
}
transformed data {
  vector[N] pressure_std = standardise_vector(pressure, mean(pressure), sd(pressure));
  vector[N] diameter_std = standardise_vector(log(diameter), mean(log(diameter)), sd(log(diameter)));
  array[2] vector[N] log_y_std;
  for (mt in 1:2){
    log_y_std[mt] = standardise_vector(log(y[mt]), mean(log(y[mt])), sd(log(y[mt])));
  }
}
parameters {
  array[2, N_age] real mu;
  array[2] real<lower=0> tau_treatment;
  array[2] real<lower=0> tau_vessel_type;
  array[2] real<lower=0> tau_treatment_vessel_type;
  array[2, N_treatment, N_vessel_type] real a_treatment_vessel_type_z;
  array[2, N_treatment] real a_treatment_z;
  array[2, N_vessel_type] real a_vessel_type_z;
  array[2] real b_diameter;
  array[2] real<lower=0> sigma;
}
transformed parameters {
  array[2, N_treatment] real a_treatment;
  array[2, N_vessel_type] real a_vessel_type;
  array[2, N_treatment, N_vessel_type] real a_treatment_vessel_type;
  for (mt in 1:2){
    for (a in 1:N_age){
      for (t in 1:N_treatment){
        for (v in 1:N_vessel_type)
          a_treatment_vessel_type[mt, t, v] = 
            a_treatment_vessel_type_z[mt, t, v] * tau_treatment_vessel_type[mt];
      }
    }
    for (t in 1:N_treatment)
      a_treatment[mt, t] = a_treatment_z[mt, t] * tau_treatment[mt];
    for (v in 1:N_vessel_type){
      a_vessel_type[mt, v] = a_vessel_type_z[mt, v] * tau_vessel_type[mt];
    }
  }
}
model {
  for (mt in 1:2){
    sigma[mt] ~ normal(0, 1);
    mu[mt] ~ normal(-2, 1);
    tau_treatment[mt] ~ normal(0, 0.5);
    tau_vessel_type[mt] ~ normal(0, 1);
    tau_treatment_vessel_type[mt] ~ cauchy(0, 0.5);
    a_vessel_type_z[mt] ~ normal(0, 1);
    a_treatment_z[mt] ~ normal(0, 1);
    b_diameter[mt] ~ normal(0, 1);
    for (a in 1:N_age){
      for (t in 1:N_treatment){
        a_treatment_vessel_type_z[mt, t] ~ normal(0, 1);
      }
    }
  }
  if (likelihood){
    tuple(vector[N], vector[N]) eta = get_eta(
      diameter_std, 
      age,
      mouse,
      vessel_type,
      treatment,
      mu,
      a_treatment,
      a_vessel_type,
      a_treatment_vessel_type,
      b_diameter
    );
    for (n in 1:N_train){
      log_y_std[1, ix_train[n]] ~ normal(eta.1[ix_train[n]], sigma[1]);
      log_y_std[2, ix_train[n]] ~ normal(eta.2[ix_train[n]], sigma[2]);
    }
  }
}
generated quantities {
  array[2, N_test] real yrep;
  vector[N_test] llik;
  {
    tuple(vector[N], vector[N]) eta_std = get_eta(
      diameter_std, 
      age,
      mouse,
      vessel_type,
      treatment,
      mu,
      a_treatment,
      a_vessel_type,
      // a_age_treatment,
      a_treatment_vessel_type,
      b_diameter
    );
    for (n in 1:N_test){
      yrep[1, n] = exp(mean(log(y[1])) + normal_rng(eta_std.1[ix_test[n]], sigma[1]) * sd(log(y[1])));
      yrep[2, n] = exp(mean(log(y[2])) + normal_rng(eta_std.2[ix_test[n]], sigma[2]) * sd(log(y[2])));
      llik[n] = normal_lpdf(log_y_std[1, ix_test[n]] | eta_std.1[ix_test[n]], sigma[1])
      + normal_lpdf(log_y_std[2, ix_test[n]] | eta_std.2[ix_test[n]], sigma[2]); 
    }
  }
}



