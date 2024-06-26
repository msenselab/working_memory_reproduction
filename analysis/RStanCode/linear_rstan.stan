//
// This Stan program defines a logarithmic encoding model for working memory task
//
// Learn more about this model, please refer to paper
// Duration reproduction under memory pressure: Modeling the roles of visual memory load in duration encoding and reproduction
//
//    https://github.com/msenselab/working_memory_reproduction
//
// self-defined functions
functions {
matrix predictor_rng(real[] x, int[] size, real ks, real ls, real kr, real sig_s2, real sigma_pr2,  real mu_prior, real sig_mn2, real[] par) {
    vector[num_elements(x)] predY;    //predication of RP generated by model
    vector[num_elements(x)] mu_sm; 
    vector[num_elements(x)] sig_sm2;   // sigma^2 of posterior
    vector[num_elements(x)] wp_pr;    //weight of prior
    vector[num_elements(x)] mu_r;      //mean of reproduction
    vector[num_elements(x)] sig_wm2;   // sigma^2 of sensory measurement
    vector[num_elements(x)] sig_r;     //sigma of RP 
    vector[num_elements(x)] log_lik;
    
    for (i in 1:num_elements(x))
    {
      if(par[1] == 1){
        mu_sm[i] = x[i]*(1-ks*size[i]);
      }
      else{
        mu_sm[i] = x[i];
      }
      if(par[2] == 1){
        sig_sm2[i] = sig_s2*(1+ls*size[i]);
      }
      else{
        sig_sm2[i] = sig_s2;
      }
      wp_pr[i] = sig_sm2[i] /(sig_sm2[i] + sigma_pr2); 
      sig_wm2[i] = sigma_pr2 *sig_sm2[i]/(sigma_pr2 + sig_sm2[i]);
      sig_r[i] = sqrt(sig_mn2 + sig_wm2[i]);
      if(par[3] == 1){
        mu_r[i] =  (wp_pr[i]*mu_prior +(1-wp_pr[i]) *mu_sm[i]) *(1+ kr*size[i]); //mu_X_i
      }
      else{
        mu_r[i] =  (wp_pr[i]*mu_prior +(1-wp_pr[i]) *mu_sm[i]); //mu_X_i
      }
      predY[i] = normal_rng(mu_r[i], sig_r[i]); 
      log_lik[i] = normal_lpdf(predY[i]|mu_r[i], sig_r[i]);
    }
   return(append_col(append_col(append_col(wp_pr, mu_r), append_col(sig_r, predY)), append_col(sig_wm2, log_lik)));
  }
}

// The input data 
data {
  int<lower=0> n;
  real<lower=0> y[n];   //measured reproductive duration 
  real<lower=0> x[n];   //stimulus duration
  int WMSize[n];
  int WMSize_new[423];       //new wm task size
  real<lower=0> xnew[423];  //new target duration
  real par[3]; // ks, ls, kr
}

// The parameters accepted by the model. Our model
// accepts 7 parameters
parameters {  
  //hyperparameters
  real<lower=0,upper=4> sig_s2;   //Weber Fraction 
  real<lower=0> mu_pr;  // mean of internal prior 
  real<lower=0,upper=4> sig_pr2;  // sigma^2 of prior
  real<lower=0,upper=4> sig_mn2; //square of sigma of motor noise caused by WM task
  real<lower=0, upper=1> ks;  // scale factor of mu_sm in production phase 
  real<lower=0, upper=1> ls;  // scale factor of sig_sm in production phase 
  real<lower=0, upper=1> kr;  // scale factor of mu_r in reproduction phase 
} 

model {
  real mu_sm[n];      
  real sig_sm2[n];   // sigma^2 of sensory measuremnet
  real sig_wm2[n];   // sigma^2 of posterior
  real mu_r[n];   // mean of posterior
  real wp[n];        //weight of prior
  ks ~ cauchy(0, 1);
  ls ~ cauchy(0, 1);
  kr ~ cauchy(0, 1);
  mu_pr ~ normal(1, 1);
  sig_s2 ~ cauchy(0, 1);
  
  for (i in 1:n)
  {
    if(par[1] == 1){
      mu_sm[i] = x[i]*(1-ks*WMSize[i]);
    }
    else{
      mu_sm[i] = x[i];
    }
    if(par[2] == 1){
      sig_sm2[i] =  sig_s2 * (1+ ls*WMSize[i]);
    }
    else{
      sig_sm2[i] =  sig_s2;
    }
    wp[i] = sig_sm2[i] /(sig_sm2[i] + sig_pr2); 
    sig_wm2[i] = sig_pr2 *sig_sm2[i]/(sig_pr2 + sig_sm2[i]);
    
    if(par[3] == 1){
      mu_r[i] = (wp[i]*mu_pr +(1-wp[i]) *mu_sm[i])*(1 + kr*WMSize[i]);
    }
    else{
      mu_r[i] = (wp[i]*mu_pr +(1-wp[i]) *mu_sm[i]);
    }
    y[i] ~ normal(mu_r[i], sqrt(sig_mn2 + sig_wm2[i])); 
  }
}

generated quantities {
  matrix[n,6] predRP;
  matrix[423,6] ynew;
  vector[n] log_lik;
  real log_lik_sum;
  predRP = predictor_rng(x, WMSize, ks, ls, kr, sig_s2, sig_pr2, mu_pr, sig_mn2, par);
  ynew = predictor_rng(xnew, WMSize_new, ks, ls, kr, sig_s2, sig_pr2, mu_pr, sig_mn2, par);
  log_lik = col(predRP, 6);
  log_lik_sum =  sum(log_lik);
}

