/* Model for answering question 2. */

functions {
#include custom_functions.stan
}
data {
  int<lower=1> N;
  int<lower=1> N_age;
  int<lower=1> N_mouse;
  int<lower=1> N_treatment;
  int<lower=1> N_train;
  int<lower=1> N_test;
  array[N] int<lower=1,upper=N_age> age;
  array[N] int<lower=1,upper=N_mouse> mouse;
  array[N] int<lower=1,upper=N_treatment> treatment;
  array[3] vector<lower=0>[N] y;
  array[N_train] int<lower=1,upper=N> ix_train;
  array[N_test] int<lower=1,upper=N> ix_test;
  int<lower=0,upper=1> likelihood;
}
transformed data {
  array[3, N] real log_y_std; 
  for (j in 1:3)
    for (n in 1:N)
      log_y_std[j, n] = (log(y[j, n]) - mean(log(y[j]))) / sd(log(y[j]));
}
parameters {
  array[3, N_age] real a_age;
  array[3, N_treatment] real a_treatment;
  array[3, N_age, N_treatment] real a_age_treatment;
  array[3, N_treatment] real<lower=0> sigma_std;
}
model {
  if (likelihood){
    for (j in 1:3){
      for (n in 1:N_train){
        int ix = ix_train[n];
        real etaj_std = a_age[j, age[ix]] + a_treatment[j, treatment[ix]] + a_age_treatment[j, age[ix], treatment[ix]];
        log_y_std[j][ix_train[ix]] ~ normal(etaj_std, sigma_std[j, treatment[ix]]);
      }
    }
  }
  for (j in 1:3){
    a_age[j] ~ normal(0, 0.3);
    a_treatment[j] ~ normal(0, 0.3);
    for (t in 1:N_treatment){
      for (a in 1:N_age){
        a_age_treatment[j, a, t] ~ normal(0, 0.2);
      }
      a_age_treatment[j, t] ~ normal(0, 0.2);
      sigma_std[j, t] ~ normal(0, 0.5);
    }
  }
}
generated quantities {
  array[3, N_test] real yrep;
  vector[N_test] llik;
  for (j in 1:3){
    for (n in 1:N_test){
      int ix = ix_train[n];
      real etaj_std = a_age[j, age[ix]] + a_treatment[j, treatment[ix]] + a_age_treatment[j, age[ix], treatment[ix]];
      real etaj = mean(log(y[j])) + etaj_std * sd(log(y[j]));
      real sigmaj = sigma_std[j, treatment[ix]] * sd(log(y[j]));
      yrep[j, n] = exp(normal_rng(etaj, sigmaj));
      llik[n] += normal_lpdf(log(y[j, ix_test[n]]) | etaj, sigmaj); 
    }
  }
}
