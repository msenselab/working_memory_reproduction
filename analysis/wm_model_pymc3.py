#%%
import matplotlib.pyplot as plt
import numpy as np
import pandas as pd
import pymc3 as pm


# %% read raw data
raw = [pd.read_csv('./data/Exp' + str(x) + '.csv') for x in range(1,4)]
# %%
def getMeans(dat, showFigure  = False):
    dat = dat.query("valid == 1 & repDur > 0.25 & repDur < 3.4")
    mdat = dat.groupby(['WMSize','curDur']).agg(
        {'repDur':['mean','std'] }).reset_index()
    #dat.pivot_table('repDur', 'curDur', 'WMSize').plot()
    # check the log distribution
    #dat.repDur.plot.hist(bins = 50)
    #plt.figure()
    #log_rep = np.log(dat.repDur)
    #log_rep.plot.hist(bins = 50)
    #
    #dat.query('curDur == 1.1').repDur.plot.hist(bins = 50)
    if showFigure:
        colors = 'rgb'
        fig, axs = plt.subplots(2, sharex = True, figsize = (4,6))
        for m in range(3):
            cur = mdat[mdat.WMSize == 1 + 2*m]
            axs[0].plot(cur.curDur, cur.repDur['mean'],colors[m])
            axs[1].plot(cur.curDur, cur.repDur['std'], colors[m])
        axs[0].legend(['WM1',"WM3","WM5"])
        axs[0].set_ylabel('Reproduction (secs)')
        axs[1].set_ylabel('Reproduction STD')
        axs[1].set_xlabel('Duration (secs)')
    end
return mdat


# %% for whole data analysis (pool model)
def findMAP(dat):
    #prepare data
    dat = dat.query("valid == 1 & repDur > 0.25 & repDur < 3.4")
    wm_idx = np.intc((dat.WMSize.values-1)/2)
    durs = dat.curDur.to_numpy()
    repDur = dat.repDur
    lnDur = np.log(durs)
    # define model
    with pm.Model() as model:
        # sensory measurement
        sig_s = pm.HalfNormal('sig_s',1.) # noise of the sensory measurement
        k_s = pm.Normal('k_s',0, sigma = 1) # working memory coeff. on ticks
        l_s = pm.HalfNormal('l_s',1) # working memory impacts on variance
        # sensory measurement with log encoding + ticks loss by memory task
        D_s = lnDur + k_s * wm_idx
        sig_sm = sig_s + l_s * wm_idx # variance influenced by memory tasks
        # prior (internal log encoding)
        mu_p = pm.Normal('mu_p', 0, sigma=1)
        sig_p = pm.HalfNormal('sig_p', 1)

        k_r = pm.Normal('k_r',0, sigma = 1) # working memory influence on reproduction   
        sig_n = pm.HalfNormal('sig_n', 1.) #pm.Bound( pm.HalfNormal, lower = 0.15)('sig_n', 5.) # constant decision /motor noise
        # integration
        w_p = sig_sm*sig_sm / (sig_p*sig_p + sig_sm*sig_sm)
        u_x = (1-w_p)*D_s + w_p * mu_p
        sig_x2 = sig_sm*sig_sm*sig_p*sig_p/(sig_sm*sig_sm + sig_p*sig_p)

        # reproduction
        # reproduced duration
        u_r = np.exp(u_x + k_r * wm_idx + sig_x2/2) # reproduced duration with corrupted from memory task
        #reproduced sigmas
        sig_r = np.sqrt((np.exp(sig_x2)-1)*np.exp(2*(u_x + k_r * wm_idx) +sig_x2 )  + 
            sig_n*sig_n /durs )

        # Data likelihood 
        resp_like = pm.Normal('resp_like', mu = u_r, 
            sigma = sig_r, observed = repDur)

    # use defined model to find MAP estimation
    map = pm.find_MAP(model=model)
    return model, map 

#%% draw function

def plotPrediction(map,mdat):
    M = np.array([0,1,2])
    curDur = np.unique(mdat.curDur).repeat(3)
    D_s = np.log(curDur).reshape(5,3) + map['k_s']*M
    sig_sm = map['sig_s'] + map['l_s']*M
    w_p = sig_sm*sig_sm / (map['sig_p']*map['sig_p'] + sig_sm*sig_sm)
    u_x = (1-w_p)*D_s + w_p * map['mu_p']
    sig_x2 = sig_sm*sig_sm*map['sig_p']*map['sig_p']/(sig_sm*sig_sm + map['sig_p']*map['sig_p'])
    # reproduced duration
    u_r = np.exp(u_x + map['k_r'] * M + sig_x2/2) # reproduced duration with corrupted from memory task
    #reproduced sigma
    sig_r = np.sqrt((np.exp(sig_x2)-1)*np.exp(2*(u_x + map['k_r'] * M ) + sig_x2)  + \
        map['sig_n']*map['sig_n']/curDur.reshape(5,3))

    # 
    markers = 'dov'
    colors = 'bcr'
    fig, axs = plt.subplots(2, sharex = True, figsize = (4,8))
    for m in range(3):
        cur = mdat[mdat.WMSize == 1 + 2*m]
        axs[0].plot(cur.curDur, cur.repDur['mean'],markers[m]+colors[m])
        axs[0].plot(cur.curDur, u_r[:,m],colors[m])
        axs[1].plot(cur.curDur, cur.repDur['std'],markers[m]+colors[m])
        axs[1].plot(cur.curDur, sig_r[:,m],colors[m])
    axs[0].legend(['low',"medium","high"])
    axs[0].set_ylabel('Reproduction (secs)')
    axs[1].set_ylabel('Reproduction variance')
    axs[1].set_xlabel('Sample intervals (secs)')

    return fig
# %%
models = []
maps = []
mdats = []
figs = []
for i in range(4):
    model, map = findMAP(raw[i])
    dat = raw[i]
    mdat = getMeans(dat)
    #
    fig=plotPrediction(map, mdat)
    figs.append(fig)
    models.append(model)
    maps.append(map)
    mdats.append(mdat)

#%%
figs[0].savefig('./figures/exp1.png')
figs[1].savefig('./figures/exp2.png')
figs[2].savefig('./figures/exp3.png')
figs[3].savefig('./figures/exp4.png')
#%%

# %% ------ individual data analysis -----
dat = raw[3].query('NSub < 2')
# non-pooling analysis
# dat.NSub =1  # just for crossvalid pool vs. unpool sampling
nsub = len(dat.NSub.unique())
mdat = getMeans(dat)
wm_idx = np.intc((dat.WMSize.values-1)/2)
sub_idx = dat.NSub-1
durs = dat.curDur.to_numpy()
lnDur = np.log(durs)
# %% 
# note: using pooled model, it seems that PyMC does different sampling as the unpooled model. 
# so better using pm.sample() than pm.find_MAP()

with pm.Model() as model:
    # sensory measurement
    sig_s = pm.HalfNormal('sig_s',1., shape = nsub) # noise of the sensory measurement
    k_s = pm.Normal('k_s',0, sigma = 1, shape = nsub) # working memory coeff. on mean Dur
    l_s = pm.HalfNormal('l_s',1, shape = nsub) # working memory impacts on variance
    # sensory measurement with log encoding + ticks loss by memory task
    D_s = lnDur[sub_idx] + k_s[sub_idx] * wm_idx
    sig_sm = sig_s[sub_idx] + l_s[sub_idx] * wm_idx # variance influenced by memory tasks
    # prior (internal log encoding)
    mu_p = pm.Normal('mu_p', 0, sigma=1, shape = nsub)
    sig_p = pm.HalfNormal('sig_p', 1, shape = nsub)

    k_r = pm.Normal('k_r',0, sigma = 1, shape = nsub) # working memory influence on reproduction   
    sig_n = pm.HalfNormal('sig_n', 1., shape = nsub) # constant decision /motor noise
    # integration
    w_p = sig_sm[sub_idx]*sig_sm[sub_idx] / (sig_p[sub_idx]*sig_p[sub_idx] + 
                                    sig_sm[sub_idx]*sig_sm[sub_idx])
    u_x = (1-w_p)*D_s + w_p * mu_p[sub_idx]
    sig_x2 = sig_sm[sub_idx]*sig_sm[sub_idx]*sig_p[sub_idx]*sig_p[sub_idx]/(
        sig_sm[sub_idx]*sig_sm[sub_idx] + sig_p[sub_idx]*sig_p[sub_idx])

    # reproduction
#    k_n = pm.HalfNormal('k_n',2.) # reproduction noise that related to sub-/sup-seconds  
    # reproduced duration
    u_xm = u_x + k_r[sub_idx] * wm_idx # mean corrupted by memory task
    u_r = np.exp(u_xm + sig_x2/2) # reproduced duration with corrupted from memory task
    #reproduced sigmas
    sig_r = np.sqrt((np.exp(sig_x2)-1)*np.exp(2*u_xm +sig_x2)  
                 + sig_n[sub_idx]*sig_n[sub_idx]/durs  )
    # Data likelihood 
    resp_like = pm.Normal('resp_like', mu = u_r, 
        sigma = sig_r, observed = dat.repDur)



#%%
map = pm.find_MAP(model=model)
map 
# %%
M = np.array([0,1,2])
curDur = np.unique(dat.curDur).repeat(3) # three WM condition
subdat = dat.groupby(['NSub','WMSize','curDur']).agg(
        {'repDur':['mean','std'] }).reset_index()
# change column names, avoid multi-index 
subdat.columns = ['NSub','WMSize', 'curDur','mrep','rep_std']


fig, axs = plt.subplots(2, nsub, sharex = True, figsize = (4*nsub,8))
for sub in range(nsub):
    k_s =map['k_s'][sub]
    sig_s = map['sig_s'][sub]
    l_s = map['l_s'][sub]
    sig_p = map['sig_p'][sub]
    mu_p = map['mu_p'][sub]
    k_r = map['k_r'][sub]
    sig_n = map['sig_n'][sub]
    # follow the model
    D_s = np.log(curDur).reshape(5,3) + k_s*M
    sig_sm = sig_s + l_s*M
    w_p = sig_sm*sig_sm / (sig_p*sig_p + sig_sm*sig_sm)
    u_x = (1-w_p)*D_s + w_p * mu_p
    sig_x2 = sig_sm*sig_sm*sig_p*sig_p/(sig_sm*sig_sm + sig_p*sig_p)
    u_xm = u_x + k_r * M # corrupted by memory task
    # reproduced duration and its sigma
    u_r = np.exp(u_xm + sig_x2/2) # reproduced duration with corrupted from memory task
    sig_r = np.sqrt((np.exp(sig_x2)-1)*np.exp(2*u_xm + sig_x2)  +  \
        sig_n*sig_n/curDur.reshape(5,3))
    for m in range(3):
        cur = subdat.query('WMSize == 1 + 2*@m and NSub == @sub +1')
        if nsub > 1 :
            axs[0][sub].plot(cur.curDur, cur.mrep,'o')
            axs[0][sub].plot(cur.curDur, u_r[:,m])
            axs[1][sub].plot(cur.curDur, cur.rep_std,'o')
            axs[1][sub].plot(cur.curDur, sig_r[:,m])
        else: # all samples
            axs[0].plot(cur.curDur, cur.mrep,'o')
            axs[0].plot(cur.curDur, u_r[:,m])
            axs[1].plot(cur.curDur, cur.rep_std,'o')
            axs[1].plot(cur.curDur, sig_r[:,m])

# %%
    
# %%
with model:
    model_trace = pm.sample(500, tune = 300, target_accept = .95)

# %%
#pm.traceplot(model_trace,
#             var_names=['mu_p', 'sig_p',
#                        'k_r', 'k_s','sig_n']);

# %%
pm.summary(model_trace)

