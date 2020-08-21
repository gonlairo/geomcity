#################################################
# Quantile Regression IV Panel Data Functions
# Harding and Lamarche, Economics Letters (2009)
################################################

rq.fit.fe <- function(X, y, w = 1, taus = tau){
  
  require(SparseM)  
  require(quantreg)
  
  K <- length(w)
  if(K != length(taus)) stop("length of w and taus must match")
  
  # X is n x p matrix
  X <- as.matrix(X)
  p <- ncol(X)
  #n <- length(levels(as.factor(s)))
  N <- length(y) # N: number of units * number of periods (example = 2500)
  
  if( N != nrow(X)) stop("dimensions of y, X must match")
  
  D <- cbind(as(w,"matrix.diag.csr") %x% X)
  y <- c(w %x% y)
  a <- c((w*(1-taus)) %x% (t(X)%*%rep(1,N)))
  
  
  # qr using a sparse implementation of the Frisch-Newton interior-point algorithm.
  rq.fit.sfn(D, y, rhs = a) 
}
  

rq.fit.ivpanel <- function(d,exo,iv,y,s,tau){
  # IV Quantile Regression with Fixed Effects
  # s is an strata indicator
  # d is the endogenous variable
  # exo are the exogenous variables, no intercept.
  # iv is the intrument
  library(MASS)
  print(1)

  Z      = model.matrix(s ~ as.factor(s)-1)[,-1] #zit is an indicator variable for the individual effect αi
  print(dim(Z))
  exo    = cbind(exo,Z) #XZ in the example
  X      = cbind(exo,1) # add a column of 1 to exogenous vaiables
  x      = cbind(d,X)
  w      = as.matrix(cbind(iv,X))

  print(class(w))

  
  print(2)
  # "building" instrument
  ww     = t(w) %*% w          # w'w
  ww.inv = MASS::ginv(as.matrix(ww)) # (w'w)ˆ-1
  wd     = t(w)%*%d            # w'd
  dhat   = w%*%ww.inv%*%wd     # w(w'w)(w'd) projection matrix of -> d = b*w + u
  
  PSI    = cbind(dhat,X)       #psi: greek letter
  PSI1   = as.matrix(cbind(d,X))
  
  print(3)
  
  # coefficients with fixed effects
  coef = rq.fit.fe(PSI, y, tau = tau)$coef
  print(4)
  #print(dim(coef))
  #print(coef)
  #print(dim(PSI1))
  #print(class(PSI1))
  
  resid <- y - PSI1%*%coef
  mu1 <- mean(resid)
  sigma1 <- var(resid)
  c <- ((1-tau)*tau)/(dnorm(qnorm(tau,mu1,sqrt(sigma1)),mu1,sqrt(sigma1))^2)
  PSIinv <- diag(length(coef))
  PSIinv <- backsolve(qr(x)$qr[1:length(coef), 1:length(coef)], PSIinv)
  PSIinv <- PSIinv %*% t(PSIinv)
  vc1 <- c*PSIinv
  std <- sqrt((length(y)/100)*diag(vc1))
  alpha <- seq(coef[1]-2*std[1],coef[1]+2*std[1],by=std[1]/20)
  z <- cbind(dhat,X)
  betas <- matrix(NA,dim(z)[2],length(alpha))
  g <- matrix(NA,length(alpha),1)
  
  print(5)
  for (i in 1:length(alpha)){ 
    ya <- y - alpha[i]*d
    # more fixed effects coefficients??
    betas[,i] <- rq.fit.fe(z, ya ,tau = tau)$coef
    g[i,] <- max(svd(betas[1:dim(dhat)[2],i])$d)
  }
    
  I <- which.min(g[,1])
  param1 <- alpha[I] # param1 is the one we are interested in (endog)
  est1 <- betas[(dim(dhat)[2]+1):dim(z)[2], I] # What are est1?
  
  c(param1,est1)
}
  
rq.se.ivpanel <- function(bhat,d,exo,iv,y,s,tau){
  # dual inference?
  n = length(y)
  Z <- model.matrix(s~as.factor(s)-1)[,-1]
  X <- cbind(exo,Z,1)
  S0 <- as.matrix(cbind(iv,X))
  D <- as.matrix(cbind(d,X))
  k = dim(D)[2]
  
  # initialize vc matrix
  vc <- matrix(0,k,k)
  
  resid <- y - D%*%bhat
  
  # bandwith h
  h <- c(1.364 * ((2*sqrt(pi))^(-1/5)) * sqrt(var(resid)) * (n^(-1/5)))
  
  # S and J
  S <- (1/n)*t(S0)%*%S0
  J = (1/(n * h)) * t(c(dnorm(resid/h)) %o% c(rep(1,dim(D)[2])) * D)%*%S0
  
  # variance covariance matrix
  vc = (1/n) * (tau-tau^2) * ginv(as.matrix(J)) %*% S %*% ginv(as.matrix(J)) 
  
  rbind(bhat,(sqrt(diag(vc))))
}



