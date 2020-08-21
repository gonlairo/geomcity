source('rq.ivpanelR.R')
library(quantreg)
library(MASS)

# time FIXED EFFECTS?

# A simple example:
set.seed(25)

n <- 10                                         # number of cross sectional units
t <- 25                                         # number of time series units
rdu = 0.5                                       # correlation parameter
tau = 0.5                                       # quantile of interest
s <- rep(1:n, each = t)                         # strata 
Z <- model.matrix(s ~ as.factor(s) - 1)[,-1]    # incidence matrix (factor 2-10)


mu  = rep(rchisq(n, df = 3), each = t)
eps = rchisq(length(s), df = 3)
XZ  = cbind(mu + eps, Z) # X + dummies

iv  = rep(rnorm(n), each = t) + rnorm(length(s))
ief = rep(rnorm(n), each = t)
v   = rep(rnorm(n), each = t) + rnorm(length(s))
u   = v*rdu + rnorm(length(s))*sqrt(1-rdu^2)
d   = iv + v
y   = ief + u

## COMPUTATION ##

# coefficients
bhat = rq.fit.ivpanel(d = d, exo =  XZ[,1],
                      iv = iv, y = y , s = s, tau = tau)
bhat = round(bhat, 3)

#standard errors
bsehat = rq.se.ivpanel(bhat = bhat, d = d, exo = XZ[,1],
                       iv = iv, y = y, s = s, tau = tau) 
bsehat = round(bsehat,3)  

# results
colnames(bsehat) = c("endog", "exog", rep("ie", n-1), "int") # ie: individual effects
rownames(bsehat) = c("beta", "se")                           # se: standard errors
print(bsehat)
