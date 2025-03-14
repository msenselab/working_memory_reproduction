###########################################################################
# Hierarchical Bayesian modeling (logarithmic encoding version)
# for manuscript: Duration reproduction under memory pressure: Modeling the roles of visual memory load in duration encoding and reproduction
############################################################################
library(parallel)
library(doParallel)
library(tidyverse)
library(rstan)
library(rlist)
library(reshape2)
library(loo)
#library(readr)

# flag for running rstan model and saving the results
runModellocally = FALSE
# flag for running rstan model on  lrz cluster parallely
runModelparallel = FALSE
# flag for compile models
compileModels = FALSE
# model version
modelversion = 'gap_log_rstan'

## The definition of the function to run Rstan model locally
## when parameter alluseOneModel is true marks all data fits with one model version , Exp1 or Exp4 
funFitStan <- function(subdat, myrstanModel, alluseOneModel,  onemodelname){
  # subdat <-sub_exp[[1]]
  library(rstan)
  library(tidyverse)
  library(dplyr)
  library(loo)
  
  #modelname <-  unique(subdat$model)
  subNo <- unique(subdat$NSub)
  expName <- unique(subdat$Exp)

  subdat$WMSize = as.numeric(subdat$WMSize)
  #subdat$WMSize1 = (subdat$WMSize +1)/2
  n = length(subdat$repDur)
  xnew <- rep(seq(0.4,1.8,0.01), 6)
  #WMSizenew <- c(rep(1,141), rep(3,141), rep(5,141))
  WMSizenew <- c(rep(1,141), rep(3,141), rep(5,141),rep(1,141), rep(3,141), rep(5,141))
  Gapnew <- c(rep(500,141*6))
  
  par = c(0,0,0)
  modelname = 'Exp1'
  if(!alluseOneModel){
    if(expName == 'Exp4'){
      par = c(1,1,1)
    } 
    if(expName == 'Exp5'){
      par = c(1,1,1)
      Gapnew <- c(rep(500,141*3),rep(2500,141*3))
    }
    
    if(expName == 'Exp2'){
      par = c(1,1,0)
      Gapnew <-  c(rep(2450,141), rep(2950,141), rep(3100,141), rep(2450,141), rep(2950,141), rep(3100,141))
    }
    
    if(expName == 'Exp3'){
      par = c(0,0,1)
      Gapnew <- c(rep(2000,141*3),rep(2000,141*3))
    }
    modelname = expName
  }else{
    if(onemodelname == 'Exp4'){
      par = c(1,1,1)
    }
    if(onemodelname == 'Exp5'){
      par =c(1,1,1)
      Gapnew <- c(rep(500,141*3),rep(2500,141*3))
    }
    if(onemodelname == 'Exp2'){
      par = c(1,1,0)
      Gapnew <-  c(rep(2450,141), rep(2950,141), rep(3100,141), rep(2450,141), rep(2950,141), rep(3100,141))
    }
    if(onemodelname == 'Exp1'){
      par =c(0,0,0)
    }
    if(onemodelname == 'Exp3'){
      par = c(0,0,1)
      Gapnew <- c(rep(2000,141*3),rep(2000,141*3))
    }
    modelname = onemodelname
  }
  
  subdat$model <- expName
  print(paste0('Start run rstan model ', modelname,' on Subject No.',subNo, ' in ', expName))
  
  
  
  stan_data = list( y= subdat$repDur, n=n, x = subdat$curDur,
                    WMSize = subdat$WMSize, Gap = subdat$Gap,
                    xnew = xnew, WMSize_new = WMSizenew, Gap_new = Gapnew,  par = par)  #data passed to stan
  
  PredY_list <- subdat[c('NSub','curDur', 'repDur','Exp','WMSize', 'model', 'gap', 'Gap')]
  NewY_list <- data.frame(cbind(xnew, WMSizenew, Gapnew))
  colnames(NewY_list)  <-c("curDur", "WMSize", "Gap")
  NewY_list$NSub =subNo
  NewY_list$Exp = expName
  NewY_list$model = modelname
  
  myinits <- list()
  parameters <- {}
  parameters <- c("sig_s2","ks", "ls", "ts", "kr",  "mu_pr_log", "sig_mn2",  "sig_pr2_log", "predRP", "ynew", "log_lik", "log_lik_sum") 
  init_mem1 <-  list(sig_s2=0.1, ks= 0.1, ls= 0.1, kr= 0.1, mu_pr_log= 0, sig_pr2_log = 0.1, sig_mn2 = 0.1)
  myinits <- list(init_mem1, init_mem1, init_mem1, init_mem1)
  
  # fit models
  subfit <- sampling(myrstanModel, 
                     data = stan_data,
                     init=myinits,
                     iter=4000,
                     chains=4,
                     thin=1,
                     control = list(adapt_delta = 0.84,
                                    max_treedepth = 10))
  
  log_lik_rlt <- extract_log_lik(subfit)
  loo_1 <- loo(log_lik_rlt)
  waic = waic(log_lik_rlt)
  
  fitpar <- summary(subfit, pars = parameters)$summary
  list_of_draws <- rstan::extract(subfit, pars = parameters)
  
  
  log_lik_list <- list_of_draws$log_lik
  log_lik <-0 #matrix(rep(0, n, 6), nrow = n, ncol = 6)
  
  for (j in 1:n){
    log_lik[j] <-  mean(log_lik_list[,j] )
  }
  log_lik_sum <- sum(log_lik)
  log_lik_mean <- mean(log_lik)
  
  sig_s2 =  mean(list_of_draws$sig_s2)
  ks = 0
  ls = 0
  kr = 0
  ts = 0
  sig_mn2 = mean(list_of_draws$sig_mn2)
  
  
  if(modelname == 'Exp4'| modelname == 'Exp5'| modelname == 'Exp2'){
    ks =  mean(list_of_draws$ks)
    ls =  mean(list_of_draws$ls)
  }
  
  if(modelname == 'Exp4'| modelname == 'Exp5'| modelname == 'Exp3'){
    kr=  mean(list_of_draws$kr)
  }
  
  ts=  mean(list_of_draws$ts)
  mu_pr_log = mean(list_of_draws$mu_pr_log)
  sig_pr2_log =  mean(list_of_draws$sig_pr2_log)
  
  pred_y <- matrix(rep(0, n, 6), nrow = n, ncol = 6)
  predRP_list <- list_of_draws$predRP
  
  for (i in 1:6){
    for (j in 1:n){
      pred_y[j,i] <-  mean(predRP_list[,j,i] )
    }
  }
  colnames(pred_y)  <-c("wp", "mu_r", "sig_r", "predY", "mu_post", "log_lik")
  PredY_list <- cbind(PredY_list, pred_y)
  
  y_new <- matrix(rep(0, 423, 6), nrow = 423, ncol = 6)
  YNew_list <- list_of_draws$ynew
  for (i in 1:6){
    for (j in 1:423){
      y_new[j,i] <-  mean(YNew_list[,j,i] )
    }
  }
  colnames(y_new)  <-c("wp", "mu_r", "sig_r", "predY", "mu_post", "log_lik")
  NewY_list = cbind(NewY_list, y_new)
  
  Baypar = data.frame(
    NSub = subNo,
    Exp = expName,
    model = modelname,
    sig_s2 = sig_s2,
    ks = ks,
    ls = ls,
    ts = ts,
    kr = kr,
    sig_mn2 =sig_mn2,
    mu_pr_log = mu_pr_log,  
    sig_pr2_log = sig_pr2_log,
    looic = loo_1$looic,
    p_loo = loo_1$p_loo,
    elpd_loo = loo_1$elpd_loo,
    se_looic = loo_1$se_looic,
    se_p_loo = loo_1$se_p_loo,
    waic = waic$waic,
    p_waic =waic$p_waic,
    se_waic = waic$se_waic,
    se_p_waic = waic$se_p_waic,
    elpd_waic = waic$elpd_waic,
    se_waic = waic$se_waic,
    log_lik_sum = log_lik_sum,
    log_lik_mean = log_lik_mean
  )
  
 # NewY_list[which(NewY_list$WMSize== 3),"WMSize"] = 5
  #NewY_list[which(NewY_list$WMSize== 2),"WMSize"] = 3
  
  return(list("Baypar" = Baypar, "PredY_list" = PredY_list, "NewY_list" = NewY_list, "loo" = loo_1,  "waic" = waic))
}


#Parallel compute parameters for each subject each model
runModelcluster<- function(sub_exp_dat){
  cl <- makeCluster(detectCores() - 1)
  clusterEvalQ(cl, {library(dplyr, rstan) })
  clusterExport(cl, c('funFitStan'))
  t0 = proc.time()
  resultlist <- clusterMap(cl, funFitStan, sub_exp_dat)
  stopCluster(cl)
  print(proc.time()-t0)
  return(resultlist)
}
