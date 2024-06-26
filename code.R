library(gamlss)

###############MZIP1###############
#pmf for MZIP1
pmf_MZIP1 <- function(z,par){
  pi0 <- par[1]
  lambda <- par[2:3]
  if (all(z==0)){
    pmf <- 1-pi0+pi0*prod(dpois(z,lambda))
  }
  else{
    pmf <- pi0*prod(dpois(z,lambda))
  }
  return(pmf)
}

#loglikelihood for MZIP1 
loglik_MZIP1 <- function(par){
  gamma <- par[1:12]
  beta1 <- par[13:24]
  beta2 <- par[25:36]
  pi0 <- c(exp(X%*%gamma)/(1+exp(X%*%gamma)))
  lambda <- exp(cbind(X%*%beta1,X%*%beta2))
  sum(sapply(1:n, function(i) 
    log(pmf_MZIP1(Z[i,],c(pi0[i],lambda[i,])))))
}

#EM for MZIP1
EM_MZIP1 <- function(par){
  repeat{ 
    gamma <- par[1:12]
    beta1 <- par[13:24]
    beta2 <- par[25:36]
    pi0 <- c(exp(X%*%gamma)/(1+exp(X%*%gamma)))
    lambda <- exp(cbind(X%*%beta1,X%*%beta2))
    par1 <- par
    ###E-step###
    u <- (1-pi0)/(1-pi0+pi0*exp(-apply(lambda,1,sum)))
    tau <- 1-u*v
    ###M-step###
    U0 <- (tau-pi0)%*%X
    U1 <- (Z[,1]-tau*lambda[,1])%*%X
    U2 <- (Z[,2]-tau*lambda[,2])%*%X
    H0 <- -t(X)%*%(pi0*(1-pi0)*X)
    H1 <- -t(X)%*%(tau*lambda[,1]*X)
    H2 <- -t(X)%*%(tau*lambda[,2]*X)
    par[1:12] <- par1[1:12]-U0%*%solve(H0)
    par[13:24] <- par1[13:24]-U1%*%solve(H1)
    par[25:36] <- par1[25:36]-U2%*%solve(H2)
    if (loglik_MZIP1(par)-loglik_MZIP1(par1) < 10^-8){
      break
    }
  }
  return (par)
}


###############MZINB1###############
#pmf for MZINB1
pmf_MZINB1 <- function(z,par){
  pi0 <- par[1]
  lambda <- par[2:3]
  phi <- par[4:5] 
  if (all(z==0)){
    pmf <- 1-pi0+pi0*prod(dNBI(z,lambda,1/phi))
  }
  else{
    pmf <- pi0*prod(dNBI(z,lambda,1/phi))
  }
  return(pmf)
}

#loglikelihood for MZINB1 
loglik_MZINB1 <- function(par){
  gamma <- par[1:12]
  beta1 <- par[13:24]
  phi1 <- par[25]
  beta2 <- par[26:37]
  phi2 <- par[38]
  pi0 <- c(exp(X%*%gamma)/(1+exp(X%*%gamma)))
  lambda <- cbind(exp(X%*%beta1),exp(X%*%beta2))
  sum(sapply(1:n,function(i) 
    log(pmf_MZINB1(Z[i,],c(pi0[i],lambda[i,],phi1,phi2)))))
}

#EM for MZINB1
EM_MZINB1 <- function(par){
  U0 <- rep(0,12) ##score vector
  H0 <- matrix(0,12,12) ##hessian matrix
  U1 <- rep(0,13) ##score vector
  H1 <- matrix(0,13,13) ##hessian matrix
  U2 <- rep(0,13) ##score vector
  H2 <- matrix(0,13,13) ##hessian matrix
  repeat{
    gamma <- par[1:12]
    beta1 <- par[13:24]
    phi1 <- par[25]
    beta2 <- par[26:37]
    phi2 <- par[38]
    pi0 <- c(exp(X%*%gamma)/(1+exp(X%*%gamma)))
    lambda <- cbind(exp(X%*%beta1),exp(X%*%beta2))
    par1 <-par
    ###E-step###
    u <- (1-pi0)/(1-pi0+pi0*(phi1/(lambda[,1]+phi1))^phi1*
                    (phi2/(lambda[,2]+phi2))^phi2)
    tau <- 1-u*v
    ###M-step###
    U0 <- (tau-pi0)%*%X 
    U1[1:12] <- ((Z[,1]-tau*lambda[,1])*phi1/(lambda[,1]+phi1))%*%X
    U1[13] <- sum(tau*log(phi1/(lambda[,1]+phi1))+
                    (tau*lambda[,1]-Z[,1])/(lambda[,1]+phi1)+
                    digamma(Z[,1]+phi1)-digamma(phi1))
    U2[1:12] <- ((Z[,2]-tau*lambda[,2])*phi2/(lambda[,2]+phi2))%*%X
    U2[13] <- sum(tau*log(phi2/(lambda[,2]+phi2))+
                    (tau*lambda[,2]-Z[,2])/(lambda[,2]+phi2)+
                    digamma(Z[,2]+phi2)-digamma(phi2))
    H0 <- -t(X)%*%(pi0*(1-pi0)*X)
    H1[1:12,1:12] <- -t(X)%*%((Z[,1]+tau*phi1)*lambda[,1]*phi1/
                                (lambda[,1]+phi1)^2*X)
    H1[13,13] <- sum((tau*lambda[,1]^2+Z[,1]*phi1)/phi1/
                       (lambda[,1]+phi1)^2+trigamma(Z[,1]+phi1)-
                       trigamma(phi1))
    H1[13,1:12] <- ((Z[,1]-tau*lambda[,1])*lambda[,1]/
                      (lambda[,1]+phi1)^2)%*%X
    H1[1:12,13] <- t(H1[13,1:12])
    H2[1:12,1:12] <- -t(X)%*%((Z[,2]+tau*phi2)*lambda[,2]*phi2/
                                (lambda[,2]+phi2)^2*X)
    H2[13,13] <- sum((tau*lambda[,2]^2+Z[,2]*phi2)/phi2/
                       (lambda[,2]+phi2)^2+trigamma(Z[,2]+phi2)-
                       trigamma(phi2))
    H2[13,1:12] <- ((Z[,2]-tau*lambda[,2])*lambda[,2]/
                      (lambda[,2]+phi2)^2)%*%X
    H2[1:12,13] <- t(H2[13,1:12])
    par[1:12] <- par1[1:12]-U0%*%solve(H0)
    par[13:25] <- par1[13:25]-U1%*%solve(H1)
    par[26:38] <- par1[26:38]-U2%*%solve(H2)
    if (loglik_MZINB1(par)-loglik_MZINB1(par1) < 10^-8){
      break
    }
  }
  return (par)
}


###############MZIH1###############
#pmf for MZIH1 
pmf_MZIH1 <- function(z,par){
  pi0 <- par[1]
  pi <- par[2:3]
  if (all(z==0)){
    pmf <- 1-pi0+pi0*prod(dbinom(z,1,pi))
  }
  else{
    pmf <- pi0*prod(dbinom(z,1,pi))
  }
  return(pmf)
}

#loglikelihood for MZIH1 
loglik_MZIH1 <- function(par){
  gamma <- par[1:12]
  beta1 <- par[13:24]
  beta2 <- par[25:36]
  pi0 <- c(exp(X%*%gamma)/(1+exp(X%*%gamma)))
  pi <- cbind(exp(X%*%beta1)/(1+exp(X%*%beta1)), 
              exp(X%*%beta2)/(1+exp(X%*%beta2)))
  sum(sapply(1:n,function(i) 
    log(pmf_MZIH1(Z0[i,],c(pi0[i],pi[i,])))))
}

#EM for MZIH1 
EM_MZIH1 <- function(par){
  repeat{
    gamma <- par[1:12]
    beta1 <- par[13:24]
    beta2 <- par[25:36]
    pi0 <- c(exp(X%*%gamma)/(1+exp(X%*%gamma)))
    pi <- cbind(exp(X%*%beta1)/(1+exp(X%*%beta1)), 
                exp(X%*%beta2)/(1+exp(X%*%beta2)))
    par1 <-par
    ###E-step###
    u <- (1-pi0)/(1-pi0+pi0*(1-pi[,1])*(1-pi[,2]))
    tau <- 1-u*v
    ###M-step###
    U0 <- (tau-pi0)%*%X
    U1 <- (Z0[,1]-tau*pi[,1])%*%X
    U2 <- (Z0[,2]-tau*pi[,2])%*%X
    H0 <- -t(X)%*%(pi0*(1-pi0)*X)
    H1 <- -t(X)%*%(tau*pi[,1]*(1-pi[,1])*X)
    H2 <- -t(X)%*%(tau*pi[,2]*(1-pi[,2])*X)
    par[1:12] <- par1[1:12]-U0%*%solve(H0)
    par[13:24] <- par1[13:24]-U1%*%solve(H1)
    par[25:36] <- par1[25:36]-U2%*%solve(H2)
    if (loglik_MZIH1(par)-loglik_MZIH1(par1) < 10^-8){
      break
    }
  }
  return(par)
}


#pmf for MP
pmf_MP <- function(z,par){
  lambda0 <- par[1]
  lambda <- par[2:3]
  k <- min(z)
  pmf <- numeric(k+1)
  for (i in 0:k){
    pmf[i+1] <- dpois(i,lambda0)*prod(dpois(z-i,lambda))
  }
  return (sum(pmf))
}

#pmf for MZIP2
pmf_MZIP2 <- function(z,par){
  pi0 <- par[1]
  lambda0 <- par[2]
  lambda <- par[3:4]
  if (all(z==0)){
    pmf <- 1-pi0+pi0*exp(-lambda0-sum(lambda))
  }
  else{
    pmf <- pi0*pmf_MP(z,par[2:4])
  }
  return (pmf)
}

#loglikelihood for MZIP2
loglik_MZIP2 <- function(par){
  gamma <- par[1:12]
  lambda0 <- par[13]
  beta1 <- par[14:25]
  beta2 <- par[26:37]
  pi0 <- c(exp(X%*%gamma)/(1+exp(X%*%gamma)))
  lambda=exp(cbind(X%*%beta1, X%*%beta2))
  sum(sapply(1:n,function(i) 
    log(pmf_MZIP2(Z[i,],c(pi0[i],lambda0,lambda[i,])))))
}

#EM for MZIP2
EM_MZIP2 <- function(par){
  n0 <- numeric(n)
  repeat{ 
    gamma <- par[1:12]
    lambda0 <- par[13]
    beta1 <- par[14:25]
    beta2 <- par[26:37]
    pi0 <- c(exp(X%*%gamma)/(1+exp(X%*%gamma)))
    lambda <- exp(cbind(X%*%beta1, X%*%beta2))
    par1 <- par
    ###E-step###
    u <- (1-pi0)/(1-pi0+pi0*exp(-lambda0-apply(lambda,1,sum)))
    for (i in 1:n){
      if (min(Z[i,])==0){
        n0[i] <- 0
      }
      else{
        n0[i] <- lambda0*pmf_MP(Z[i,]-1,c(lambda0,lambda[i,]))/
          pmf_MP(Z[i,],c(lambda0,lambda[i,]))
      }
    }
    tau=1-u*v
    ###M-step###
    U0 <- (tau-pi0)%*%X
    U1 <- (Z[,1]-n0-tau*lambda[,1])%*%X
    U2 <- (Z[,2]-n0-tau*lambda[,2])%*%X
    H0 <- -t(X)%*%(pi0*(1-pi0)*X)
    H1 <- -t(X)%*%(tau*lambda[,1]*X)
    H2 <- -t(X)%*%(tau*lambda[,2]*X)
    par[1:12] <- par1[1:12]-U0%*%solve(H0)
    par[13] <- sum(n0)/sum(tau)
    par[14:25] <- par1[14:25]-U1%*%solve(H1)
    par[26:37] <- par1[26:37]-U2%*%solve(H2)
    if (loglik_MZIP2(par)-loglik_MZIP2(par1) < 10^-8){
      break
    }
  }
  return (par)
}


###############MZINB2###############
#pmf for MZINB2
pmf_MZINB2 <- function(z,par){
  pi0 <- par[1]
  lambda <- par[2:3]
  phi <- par[4] 
  if (all(z==0)){
    pmf <- 1-pi0+pi0*(phi/(sum(lambda)+phi))^phi
  }
  else{
    pmf <- pi0*gamma(sum(z)+phi)*phi^phi*prod(lambda^z)/
      (gamma(phi)*prod(factorial(z))*(sum(lambda)+phi)^(sum(z)+phi))
  }
  return(pmf)
}

#loglikelihood for MZINB2
loglik_MZINB2 <- function(par){
  gamma <- par[1:12]
  beta1 <- par[13:24]
  beta2 <- par[25:36]
  phi <- par[37]
  pi0 <- c(exp(X%*%gamma)/(1+exp(X%*%gamma)))
  lambda <- cbind(exp(X%*%beta1),exp(X%*%beta2))
  sum(sapply(1:n,function(i) 
    log(pmf_MZINB2(Z[i,],c(pi0[i],lambda[i,],phi)))))
}

#EM for MZINB2
EM_MZINB2 <- function(par){
  repeat{ 
    gamma <- par[1:12]
    beta1 <- par[13:24]
    beta2 <- par[25:36]
    phi <- par[37]
    pi0 <- c(exp(X%*%gamma)/(1+exp(X%*%gamma)))
    lambda <- exp(cbind(X%*%beta1, X%*%beta2))
    par1 <- par
    ###E-step###
    u <- (1-pi0)/(1-pi0+pi0*(phi/(apply(lambda,1,sum)+phi))^phi)
    r <- (apply(Z,1,sum)+phi)/(apply(lambda,1,sum)+phi)
    s <- digamma(apply(Z,1,sum)+phi)-log(apply(lambda,1,sum)+phi)
    tau <- 1-u*v
    ###M-step###
    U0 <- (tau-pi0)%*%X 
    U1 <- (Z[,1]-tau*r*lambda[,1])%*%X
    U2 <- (Z[,2]-tau*r*lambda[,2])%*%X
    H0 <- -t(X)%*%(pi0*(1-pi0)*X)
    H1 <- -t(X)%*%(tau*r*lambda[,1]*X)
    H2 <- -t(X)%*%(tau*r*lambda[,2]*X)
    par[1:12] <- par1[1:12]-U0%*%solve(H0)
    par[13:24] <- par1[13:24]-U1%*%solve(H1)
    par[25:36] <- par1[25:36]-U2%*%solve(H2)
    par[37] <- par1[37]-sum(tau*(log(par1[37])+1-digamma(par1[37])+s-r))/
      sum(tau*(1/par1[37]-trigamma(par1[37])))
    if (loglik_MZINB2(par)-loglik_MZINB2(par1) < 10^-8){
      break
    }
  }
  return (par)
}


###############MZMP1###############
#pmf for MZTP1
pmf_MZTP1 <- function(z,par){
  lambda <- par[1:2]
  pmf <- prod(dpois(z,lambda))/(1-exp(-sum(lambda)))
  return(pmf)
}

#loglikelihood for MZTP1
loglik_MZTP1 <- function(par){
  beta1 <- par[1:12]
  beta2 <- par[13:24]
  lambda <- cbind(exp(X_p%*%beta1), exp(X_p%*%beta2))
  sum(sapply(1:n_p,function(i) 
    log(pmf_MZTP1(Z_p[i,],lambda[i,]))))
}

#MM for MZTP1
MM_MZTP1 <- function(par){
  repeat{ 
    beta1 <- par[1:12]
    beta2 <- par[13:24] 
    lambda <- cbind(exp(X_p%*%beta1), exp(X_p%*%beta2))
    par1 <- par
    ###E-step###
    u <- 1/(1-exp(-apply(lambda,1,sum)))
    ###M-step###
    U1 <- (Z_p[,1]-u*lambda[,1])%*%X_p
    U2 <- (Z_p[,2]-u*lambda[,2])%*%X_p
    H1 <- -t(X_p)%*%(u*lambda[,1]*X_p)
    H2 <- -t(X_p)%*%(u*lambda[,2]*X_p)
    par[1:12] <- par1[1:12]-U1%*%solve(H1)
    par[13:24] <- par1[13:24]-U2%*%solve(H2)
    if (loglik_MZTP1(par)-loglik_MZTP1(par1) < 10^-8){
      break
    }
  }
  return (par)
}

###############MZMNB1###############
#pmf for MZTB1
pmf_MZTNB1 <- function(z,par){
  lambda <- par[1:2]
  phi <- par[3:4] 
  pmf <- prod(dNBI(z,lambda,1/phi))/(1-prod(dNBI(c(0,0),lambda,1/phi)))
  return(pmf)
}

#MM for MZTB1
loglik_MZTNB1 <- function(par){
  beta1 <- par[1:12]
  phi1 <- par[13]
  beta2 <- par[14:25]
  phi2 <- par[26]
  lambda <- cbind(exp(X_p%*%beta1), exp(X_p%*%beta2))
  sum(sapply(1:n_p,function(i)
    log(pmf_MZTNB1(Z_p[i,],c(lambda[i,],phi1,phi2)))))
}

#MM for MZTB1
MM_MZTNB1 <-function(par){
  U1 <- rep(0,13) ##score vector
  H1 <- matrix(0,13,13) ##hessian matrix
  U2 <- rep(0,13) ##score vector
  H2 <- matrix(0,13,13) ##hessian matrix
  repeat{ 
    beta1 <- par[1:12]
    phi1 <- par[13]
    beta2 <- par[14:25]
    phi2 <- par[26]
    lambda <- cbind(exp(X_p%*%beta1), exp(X_p%*%beta2))
    par1 <- par
    ###E-step###
    u <- 1/(1-dNBI(rep(0,n_p),lambda[,1],1/phi1)*dNBI(rep(0,n_p),lambda[,2],1/phi2))
    ###M-step###
    U1[1:12] <- ((Z_p[,1]-u*lambda[,1])*phi1/(lambda[,1]+phi1))%*%X_p
    U1[13] <- sum(u*log(phi1/(lambda[,1]+phi1))+
                    (u*lambda[,1]-Z_p[,1])/ (lambda[,1]+phi1)+
                    digamma(Z_p[,1]+phi1)-digamma(phi1))
    U2[1:12] <- ((Z_p[,2]-u*lambda[,2])*phi2/(lambda[,2]+phi2))%*%X_p
    U2[13] <- sum(u*log(phi2/(lambda[,2]+phi2))+
                    (u*lambda[,2]-Z_p[,2])/ (lambda[,2]+phi2)+
                    digamma(Z_p[,2]+phi2)-digamma(phi2))
    H1[1:12,1:12] <- -t(X_p)%*%((Z_p[,1]+u*phi1)*lambda[,1]*phi1/
                                  (lambda[,1]+phi1)^2*X_p)
    H1[13,13] <- sum((u*lambda[,1]^2+Z_p[,1]*phi1)/phi1/
                       (lambda[,1]+phi1)^2+trigamma(Z_p[,1]+phi1)-
                       trigamma(phi1))
    H1[13,1:12] <- ((Z_p[,1]-u*lambda[,1])*lambda[,1]/
                      (lambda[,1]+phi1)^2)%*%X_p
    H1[1:12,13] <- t(H1[13,1:12])
    H2[1:12,1:12] <- -t(X_p)%*%((Z_p[,2]+u*phi2)*lambda[,2]*phi2/
                                  (lambda[,2]+phi2)^2*X_p)
    H2[13,13] <- sum((u*lambda[,2]^2+Z_p[,2]*phi2)/phi2/
                       (lambda[,2]+phi2)^2+trigamma(Z_p[,2]+phi2)-
                       trigamma(phi2))
    H2[13,1:12] <- ((Z_p[,2]-u*lambda[,2])*lambda[,2]/
                      (lambda[,2]+phi2)^2)%*%X_p
    H2[1:12,13] <- t(H2[13,1:12])
    par[1:13] <- par1[1:13]-U1%*%solve(H1)
    par[14:26] <- par1[14:26]-U2%*%solve(H2)
    if (loglik_MZTNB1(par)-loglik_MZTNB1(par1) < 10^-8){
      break
    }
  }
  return (par)
}


###############MZMH1###############
#pmf for MZTH1
pmf_MZTH1 <- function(z,par){
  pi <- par[1:2]
  pmf <- prod(dbinom(z,1,pi))/(1-prod(1-pi))
  return (pmf)
}

#loglikelihood for MZTH1
loglik_MZTH1 <- function(par){
  beta1 <- par[1:12]
  beta2 <- par[13:24]
  pi <- cbind(exp(X_p%*%beta1)/(1+exp(X_p%*%beta1)), 
              exp(X_p%*%beta2)/(1+exp(X_p%*%beta2)))
  sum(sapply(1:n_p,function(i) log(pmf_MZTH1(Z0_p[i,],pi[i,]))))
}

#MM for MZTH1
MM_MZTH1 <- function(par){
  repeat{
    beta1 <- par[1:12]
    beta2 <- par[13:24] 
    pi <- cbind(exp(X_p%*%beta1)/(1+exp(X_p%*%beta1)), 
                exp(X_p%*%beta2)/(1+exp(X_p%*%beta2)))
    par1 <- par
    ###E-step###
    u <- 1/(1-(1-pi[,1])*(1-pi[,2]))
    ###M-step###
    U1 <- (Z0_p[,1]-u*pi[,1])%*%X_p
    U2 <- (Z0_p[,2]-u*pi[,2])%*%X_p
    H1 <- -t(X_p)%*%(u*pi[,1]*(1-pi[,1])*X_p)
    H2 <- -t(X_p)%*%(u*pi[,2]*(1-pi[,2])*X_p)
    par[1:12] <- par1[1:12]-U1%*%solve(H1)
    par[13:24] <- par1[13:24]-U2%*%solve(H2)
    if (loglik_MZTH1(par)-loglik_MZTH1(par1) < 10^-8){
      break
    }
  }
  return(par)
}

###############MZMP2###############
#pmf for MZTP2
pmf_MZTP2<- function(z,par){
  lambda0=par[1]
  lambda=par[2:3]
  pmf=pmf_MP(z,par)/(1-exp(-lambda0-sum(lambda)))
  return (pmf)
}

#loglikelihood for MZTP2
loglik_MZTP2<- function(par){
  lambda0=par[1]
  beta1=par[2:13]
  beta2=par[14:25]
  lambda=exp(cbind(X_p%*%beta1, X_p%*%beta2))
  sum(sapply(1:n_p,function(i)
    log(pmf_MZTP2(Z_p[i,],c(lambda0,lambda[i,])))))
}

#MM for MZTP2
MM_MZTP2 <- function(par){
  n0 <- numeric(n_p)
  repeat{ 
    lambda0 <- par[1]
    beta1 <- par[2:13]    
    beta2 <- par[14:25]
    lambda <- exp(cbind(X_p%*%beta1, X_p%*%beta2))
    par1 <- par
    ###E-step###
    u <- 1/(1-exp(-lambda0-apply(lambda,1,sum)))
    for (i in 1:n_p){
      if (min(Z_p[i,])==0){
        n0[i] <- 0
      }
      else{
        n0[i] <- lambda0*pmf_MP(Z_p[i,]-1,c(lambda0,lambda[i,]))/
          pmf_MP(Z_p[i,],c(lambda0,lambda[i,]))
      }
    }
    ###M-step###
    U1 <- (Z_p[,1]-n0-u*lambda[,1])%*%X_p
    U2 <- (Z_p[,2]-n0-u*lambda[,2])%*%X_p
    H1 <- -t(X_p)%*%(u*lambda[,1]*X_p)
    H2 <- -t(X_p)%*%(u*lambda[,2]*X_p)
    par[1] <- sum(n0)/sum(u)
    par[2:13] <- par1[2:13]-U1%*%solve(H1)
    par[14:25] <- par1[14:25]-U2%*%solve(H2)
    if (loglik_MZTP2(par)-loglik_MZTP2(par1) < 10^-8){
      break
    }
  }
  return (par)
}


##########MZMNB2############
#pmf for MZTNB2
pmf_MZTNB2 <- function(z,par){
  lambda <- par[1:2]
  phi <- par[3] 
  pmf <- (gamma(sum(z)+phi)*phi^phi*prod(lambda^z)/
            (gamma(phi)*prod(factorial(z))*(phi+sum(lambda))^(sum(z)+phi)))/
    (1-(phi/(sum(lambda)+phi))^phi)
  return(pmf)
}

#loglikelihood for MZTNB2
loglik_MZTNB2 <- function(par){
  beta1 <- par[1:12]
  beta2 <- par[13:24]
  phi <- par[25]
  lambda <- cbind(exp(X_p%*%beta1),exp(X_p%*%beta2))
  sum(sapply(1:n_p,function(i)
    log(pmf_MZTNB2(Z_p[i,],c(lambda[i,],phi)))))
}

#MM for MZTNB2
MM_MZTNB2 <- function(par){
  repeat{ 
    beta1 <- par[1:12]
    beta2 <- par[13:24]
    phi <- par[25] 
    lambda <- exp(cbind(X_p%*%beta1, X_p%*%beta2))
    par1 <- par
    ###E-step###
    u <- 1/(1-(phi/(apply(lambda,1,sum)+phi))^phi)
    r1 <- (apply(Z_p,1,sum)+phi)/(apply(lambda,1,sum)+phi)
    s1 <- digamma(apply(Z_p,1,sum)+phi)-log(apply(lambda,1,sum)+phi)
    r2 <- phi/(apply(lambda,1,sum)+phi)
    s2 <- digamma(phi)-log(apply(lambda,1,sum)+phi)
    r <- r1+(u-1)*r2
    s <- s1+(u-1)*s2
    ###M-step###
    U0 <- sum(u)*(log(par1[25])+1-digamma(par1[25]))+sum(s-r)
    U1 <- (Z_p[,1]-r*lambda[,1])%*%X_p
    U2 <- (Z_p[,2]-r*lambda[,2])%*%X_p
    H0 <- sum(u)*(1/par1[25]-trigamma(par1[25]))
    H1 <- -t(X_p)%*%(r*lambda[,1]*X_p)
    H2 <- -t(X_p)%*%(r*lambda[,2]*X_p)
    par[1:12] <- par1[1:12]-U1%*%solve(H1)
    par[13:24] <- par1[13:24]-U2%*%solve(H2)
    par[25] <- par1[25]-U0/H0
    if (loglik_MZTNB2(par)-loglik_MZTNB2(par1) < 10^-8){
      break
    }
  }
  return (par)
}
