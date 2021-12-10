library(tidyverse)
library(data.table)
source('functions.R')

data <- read.csv('Exp1_WMatProduction_simple.csv', sep=";")
#data <- read.csv('Exp2_WMatReProduction_simple.csv', sep=";")
#data <- read.csv('Exp3_WMatBothStage_simple.csv', sep=";")
#data <- read.csv('Exp4_WMafter_simple.csv', sep=";")
#names(data)[1] <- "WMSize"




dur <- unique(data$curDur)
M_p <- mean(dur)
## what does this function mean, why generate empty
Bayesian_pre <- data.frame()
bayes_fit_para <- data.frame()
x <- seq(0.4,2,0.01)

subs <- unique(data$NSub)
N <- length(subs)
for(s in subs) {
  data_model = data %>% filter(NSub==s) 
  
  for(m in 1:9) {
    par <- optim(c(0.2,0.3,0.4,0), Bayesian_full_dist_fit, NULL, data=data_model, model=m, 
                 method="BFGS")
    
    print(paste('Model,', as.character(m), "subject", as.character(s)))
    print(ifelse(par$convergence, paste('Failed to converge:', par$message), 'Converged'))
  #out put of a
     print(paste0('nll=', par$value))
    numParam <- 4;
     print(paste0('AIC=', 2*numParam+2*par$value))
    bayes_fit_para <- rbind2(bayes_fit_para,
                             data.frame(sub=s, sig_m=abs(par$par[1]), cp=abs(par$par[2]),
                                        c0=abs(par$par[3]), res=par$par[4], val=par$value, model=m))
    data_temp = data.frame(x=x, y_mdur = Bayesian_mdur(x, par$par[2:4], model=m), 
                           y_vdur = Bayesian_vdur(x, par$par[1:3], model=m), sub=s, model=m)
    Bayesian_pre <- rbind2(Bayesian_pre,data_temp)
  }
  
  
  # Uncomment below for individual subject figures
  #
  # group_by(data_model, curDur) %>% summarize(mrepDur=mean(repDur), sd_repDur = sd(repDur)) -> sdata
  # print(ggplot(sdata, aes(x=curDur, y=mrepDur)) + geom_point(size=3) + theme_bw() + 
  #         geom_line(data=filter(Bayesian_pre, sub==s, model==1), aes(x=x, y=y_mdur), color='black') + 
  #         geom_line(data=filter(Bayesian_pre, sub==s, model==2), aes(x=x, y=y_mdur), color='blue') + 
  #         geom_line(data=filter(Bayesian_pre, sub==s, model==3), aes(x=x, y=y_mdur), color='darkred') + 
  #         geom_line(data=filter(Bayesian_pre, sub==s, model==4), aes(x=x, y=y_mdur), color='forestgreen'))
  # print(ggplot(sdata, aes(x=curDur, y=sd_repDur)) + geom_point(size=3) + theme_bw() + 
  #         geom_line(data=filter(Bayesian_pre, sub==s, model==1), aes(x=x, y=y_vdur), color='black')  + 
  #         geom_line(data=filter(Bayesian_pre, sub==s, model==2), aes(x=x, y=y_vdur), color='blue') + 
  #         geom_line(data=filter(Bayesian_pre, sub==s, model==3), aes(x=x, y=y_vdur), color='darkred') +
  #         geom_line(data=filter(Bayesian_pre, sub==s, model==4), aes(x=x, y=y_vdur), color='forestgreen'))  
}

sdata <- group_by(data, curDur, NSub) %>% 
  summarize(m_repDur=mean(repDur), sd_repDur = sd(repDur)) %>% 
  summarize(m_m_repDur=mean(m_repDur), se_m_repDur=sd(m_repDur)/sqrt(N-1),
            m_sd_repDur=mean(sd_repDur), se_sd_repDur=sd(sd_repDur)/sqrt(N-1))

smodel <- group_by(Bayesian_pre, x, model, sub) %>% 
  summarize(m_repDur=mean(y_mdur), sd_repDur = mean(y_vdur)) %>%
  summarize(m_m_repDur=mean(m_repDur), m_sd_repDur=mean(sd_repDur))

ggplot(sdata, aes(x=curDur, y=m_m_repDur)) + geom_point(size=3) + theme_bw() +
  geom_errorbar(aes(ymin=m_m_repDur - se_m_repDur, ymax=m_m_repDur + se_m_repDur), width=0.04) +
  geom_line(data=filter(smodel, model==1), aes(x=x, y=m_m_repDur), color='black') +
  geom_line(data=filter(smodel, model==2), aes(x=x, y=m_m_repDur), color='blue') +
  geom_line(data=filter(smodel, model==3), aes(x=x, y=m_m_repDur), color='darkred') +
  geom_line(data=filter(smodel, model==4), aes(x=x, y=m_m_repDur), color='forestgreen') +
  geom_line(data=filter(smodel, model==5), aes(x=x, y=m_m_repDur), color='darkblue') +
  geom_line(data=filter(smodel, model==6), aes(x=x, y=m_m_repDur), color='red')

ggplot(sdata, aes(x=curDur, y=m_sd_repDur)) + geom_point(size=3) + theme_bw() +
  geom_errorbar(aes(ymin=m_sd_repDur - se_sd_repDur, ymax=m_sd_repDur + se_sd_repDur), width=0.04) +
  geom_line(data=filter(smodel, model==1), aes(x=x, y=m_sd_repDur), color='black') +
  geom_line(data=filter(smodel, model==2), aes(x=x, y=m_sd_repDur), color='blue') +
  geom_line(data=filter(smodel, model==3), aes(x=x, y=m_sd_repDur), color='darkred') +
  geom_line(data=filter(smodel, model==4), aes(x=x, y=m_sd_repDur), color='forestgreen') + 
  geom_line(data=filter(smodel, model==5), aes(x=x, y=m_sd_repDur), color='darkblue') +
  geom_line(data=filter(smodel, model==6), aes(x=x, y=m_sd_repDur), color='red')
