functions {
#include custom_functions.stan
  vector get_eta(
    array[] int age,
    array[] int mouse,
    array[] int vessel_type,
    array[,] real a_age_vessel_type
  ){
    int N = size(vessel_type);
    vector[N] out;
    for (n in 1:N){
      out[n] = a_age_vessel_type[age[mouse[n]], vessel_type[n]];
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
  vector<lower=0,upper=1>[N_vessel_type] vessel_type_is_big;
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
  real<lower=1> nu;
  array[N_age, N_vessel_type] real a_age_vessel_type;
  array[2] real<lower=0> lambda;
  real<lower=0> lambda_s;
  vector[N_vessel_type] log_sigma_std;
}
transformed parameters {
  vector[N_vessel_type] sigma_std = exp(log_sigma_std);
}
model {
  nu ~ gamma(2, 0.1);
  a_age_vessel_type[:,1] ~ normal(0, 1);
  log_sigma_std[1] ~ normal(-1.5, 0.8);
  for (v in 2:N_vessel_type){
   log_sigma_std[v] ~ normal(log_sigma_std[v-1], lambda_s);
   for (a in 1:N_age){
     a_age_vessel_type[a, v] ~ student_t(nu, a_age_vessel_type[a, v-1], lambda[a]);
   }
  }
  lambda ~ normal(0, 0.2);
  lambda_s ~ normal(0, 0.2);
  if (likelihood){
    vector[N] eta_std = get_eta(
      age,
      mouse,
      vessel_type,
      a_age_vessel_type
    );
    for (n in 1:N_train){
      logy_std[ix_train[n]] ~ normal(eta_std[ix_train[n]], sigma_std[vessel_type[ix_train[n]]]);
    }
  }
}
generated quantities {
  array[N_test] real yrep;
  vector[N] yhat;
  vector[N_test] llik;
  vector[N_vessel_type] sigma = sigma_std * sd(logy);
  {
    vector[N] eta_std = get_eta(
      age,
      mouse,
      vessel_type,
      a_age_vessel_type
    );
    vector[N] eta = unstandardise_vector(eta_std, mean(logy), sd(logy));
    for (n in 1:N_test){
      yhat[n] = exp(eta[n]);
      yrep[n] = exp(normal_rng(eta[ix_test[n]], sigma[vessel_type[ix_test[n]]]));
      llik[n] = normal_lpdf(logy_std[ix_test[n]] | eta_std[ix_test[n]], sigma_std[vessel_type[ix_test[n]]]);
    }
  }
}


