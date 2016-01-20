#  From Guillaume Achaz, 2009

# Probability of finding k mutations after t time for mutation rate mu
# Equation 12
# mu: mutation_rate
# t: time
# k: number of mutations
Equation_12 <- function(k,mu,t)
{
  p <- exp(-mu*t) * ((mu*t)^k)/factorial(k)
  return (p)
}

Poisson <- function(k,lambda)
{
  p <- exp(-lambda) * (lambda ^ k) / factorial(k)
  return (p)
}


ks <- seq(0,10)
lambda = 1.0
ps <- c()
for (k in ks)
{
  p <- Poisson(k=k,lambda=lambda)
  if (length(ys) == 0) { 
    ps <- p 
  } else {
    ps <- c(ps,p)
  }
}

#plot(ks,ps)


mu <- 0.1
t <- 10
ks <- seq(0,10)
ps <- c()
for (k in ks)
{
  p <- Equation_12(k=k,mu,t)
  if (length(ps) == 0) { 
    ps <- p 
  } else {
    ps <- c(ps,p)
  }
}

plot(ks,ps)