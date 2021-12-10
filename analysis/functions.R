Bayesian_mdur <- function(t, par, model) {
  #set default
  # sig_s, sig_p are scalar
  # the hypothesis of sensory noise and prior noise should be the same
  cp <- par[1]
  cs <- par[2]
  sig_p2 <- c(cp^2*M_p^2)
  sig_s2 <- c(cs^2*t^2)
  
  #set residual
  if(model  <= 4) { res <- par[3] }
  else if (model < 9) { res <- par[4]}
  else { res <- par[5]}
  
  #set sensory noise
  #Model 1: Sigma_s = constant, Sigma_m = constant
  #Model 2: Sigma_s = constant, Sigma_m = scalar
  #Model 6: Sigma_s = constant, Sigma_m = scalar, Sigma:WM_M = constant
  if (model <3 | model ==6) {
    #change sensory noise and prior noise into constant
    sig_s2 <-  c(par[2])^2
  }
  
  else if (model == 7 | model == 8 ) {
     sig_WM_s <- par[3] 
     #sig_s2 <- ( c(par[2]*t) + sig_WM_s) ^2
     sig_s2 <- ( c(par[2])*t)^2 + sig_WM_s^2
  }
  else if (model == 9) {
    sig_WM_s <- par[4] 
    #sig_s2 <- ( c(par[2]*t) + sig_WM_s) ^2
    sig_s2 <- ( c(par[2])*t)^2 + sig_WM_s^2
  }
  y <- sig_p2/(sig_p2+sig_s2)*t+sig_s2/(sig_p2+sig_s2)*(M_p+res)
}

Bayesian_vdur<- function(t, par, model) {
  
  #Model 1: Sigma_s = constant, Sigma_m = constant
  #Model 2: Sigma_s = constant, Sigma_m = scalar
  #Model 3: Sigma_s = scalar, Sigma_m = constant
  #Model 4: Sigma_s = scalar, Sigma_m = scalar
  #Model 5: Sigma_s = scalar, Sigma_m = scalar, Sigma:WM_M = constant
  #Model 6: Sigma_s = constant, Sigma_m = scalar, Sigma:WM_M = constant
  #Model 7: Sigma_s = scalar, Sigma_m = constant, Sigma:WM_S = constant
  #Model 8: Sigma_s = scalar, Sigma_m = scalar, Sigma:WM_S = constant
  #Model 9: Sigma_s = scalar, Sigma_m = scalar, Sigma:WM_S = constant, Sigma:WM_M = constant
  
  #set motor noise
  if(model == 1 | model == 3 | model == 7) {
    sig_m2 <- par[1]^2 #constant motor noise
  } 
  else if(model == 2 | model == 4 | model == 8) { 
    sig_m2 <- c(par[1]*t)^2 #scalar motor noise
  } 
  else if(model == 5 | model == 6 | model == 9) { 
    sig_WM_m = par[4]
    #sig_m2 <- (c(par[1]*t) + sig_WM_m)^2 #scalar motor noise
    sig_m2 <- (c(par[1])*t) ^2+ sig_WM_m^2
  }
  
  
  #set prior noise
  sig_p2 <- c(par[2]^2*M_p^2)
              

  #set sensory noise  st
  if (model < 3 | model == 6){
    sig_s2 = c(par[3])^2 #sensory sigma is constant
  }
  else if (model == 3 | model == 4 | model == 5 ){
    sig_s2  <- c(par[3])^2*t^2#sigma s^2
  }
  
  else if (model == 7 | model == 8 ){
    sig_WM_s <- par[4]
    #sig_s2 <- (c(par[3]*t) + sig_WM_s) ^2
    sig_s2 <- (c(par[3])*t)^2 + sig_WM_s^2
  }
  else if (model == 9  ){
    sig_WM_s <- par[5]
    #sig_s2 <- ( c(par[3]*t) + sig_WM_s) ^2
    sig_s2 <- (c(par[3])*t)^2 + sig_WM_s^2
  }

   #for deterministic prior
   # y <- sqrt(sig_m^2+sp2^2*st2/(sp2+st2)^2)
   #  
  y <- sqrt(sig_m2 + sig_p2*sig_s2/(sig_p2+sig_s2))
  
   # y <- sqrt(1 / (1/sig_m2 + 1/sig_p2 + 1/sig_s2) )
}

Bayesian_full_dist_fit <- function(par, data, model) {
  
  t <- data$curDur
  y <- data$repDur
  n <- length(data$curDur)
  nParm = length(par)

  print(paste0('parameter:',  as.character(nParm), 'model',  as.character(model)))
 
  var_pred <- Bayesian_vdur(t, par[1:(nParm-1) ], model)
  m_pred <- Bayesian_mdur(t, par[2:nParm ], model)

  a <- -sum(log(dnorm(y, m_pred, var_pred)))
  
  #add punishment when the prior is out of the range of 2.5 times the given duration
  prior <- M_p+par[nParm]
  prior
  dur <- unique(t)
  lowTH <- mean(dur) - 2.5* sd(dur)
  highTH <- mean(dur) + 2.5* sd(dur)

  
  if (prior < lowTH) {
    a = a  +    n*sqrt( (prior - lowTH) ^2 )
    # a = a  +   abs(prior - lowTH) 
      }
  if (prior > highTH) {
     a = a +  n*sqrt( (prior - highTH) ^2 )
     #a = a +  abs(prior - highTH)
      }
 

  
  if(a==Inf) {
    a <- 1e9
  }
  return(a)
}



