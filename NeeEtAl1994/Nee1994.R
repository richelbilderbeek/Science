rm(list=ls())
library(ape)
library(DDD)
library(expoTree)
library(laser)
library(testit)

# Chance a lineage survives the next T timesteps
# lambda: birth rate
# mu: death rate
# T: later time
CalcChanceSurvival <- function(lambda,mu,T)
{
  assert("CalcChanceSurvival: Birth rate is at least zero",lambda >= 0)
  assert("CalcChanceSurvival: Birth rate is at most one",lambda <= 1)
  assert("CalcChanceSurvival: Death rate is at least zero",mu >= 0)
  assert("CalcChanceSurvival: Death rate is at most one",mu <= 1)
  assert("CalcChanceSurvival: Later time (T) is positive",T >= 0)

  chance <- CalcP(lambda = lambda,mu = mu,t = 0,T = T)
  return (chance)
}



# lambda: birth rate
# mu: death rate
# T: later time, the present, the time the tree ends
# branching_times: times that nodes branch, up to the user what the branching time of 0 is, but all these must be less than T
# Equation 21 from Nee et al., 1994
CalcLikelihoodBirthDeath <- function(lambda,mu,branching_times,T)
{
  assert("DO NOT USE, USE CalcLikelihoodDdd instead",1==2)
  assert("LikelihoodBirthDeath: Birth rate is above zero (would result in a division by zero when defining a)",lambda > 0) 
  assert("LikelihoodBirthDeath: Birth rate is at most one",lambda <= 1)
  assert("LikelihoodBirthDeath: Death rate is at least zero",mu >= 0)
  assert("LikelihoodBirthDeath: Death rate is at most one",mu <= 1)
  for (branching_time in branching_times) { assert("All branching times must be before time T",branching_time < T) }

  # Construct xs, as that x[i] == x_i
  xs <- T - branching_times
  xs <- c(NA,xs)

  a <- mu / lambda
  r <- lambda - mu
  assert("LikelihoodBirthDeath: a is above zero (because Nee says so)",a > 0)
  assert("LikelihoodBirthDeath: a is less than one (because Nee says so)",a < 1)
  assert("LikelihoodBirthDeath: r is above zero (because Nee says so)",mu > 0)
  N <- length(branching_times) + 1
  assert("LikelihoodBirthDeath: There must be at least two lineages (otherwise we would not oberve a tree)",N >= 2) 

  first_term <- factorial(N-1)*(r^(N-2))

  sum <- 0.0
  if (2 < N - 1)
  {
    for (n in seq(2,N-1)) 
    { 
      index <- n + 1
      assert("Must be a valid index",index >= 1 && index <= length(xs)) 
      sum <- sum + xs[index] 
    }
  }
  
  third_term <- ((1-a) ^ N)

  product <- 1.0
  for (n in seq(2,N)) 
  { 
    product <- product * (1.0 / ((exp(r * xs[n]) - a) ^ 2)) 
  }

  likelihood <- first_term * exp(sum) * third_term * product
  
  print(paste(first_term,sum,third_term,product))
  
  return (likelihood)
}

# CalcLikelihoodDdd calculates the likelihood of a phylogeny given a speciation rate (lambda) and extinction rate (mu),
# when conditioned by crown age and survival of the lineages
#
# Suppose the input is:
#
#  +----+----+----+----+
#  |
# -+    +----+----+----+
#  |    |
#  +----+
#       |
#       +----+----+----+
#
#  +----+----+----+----+ time
#  0    1    2    3    4
#
#  speciation_rate <- 0.2
#  extinction_rate <- 0.01 
#
#  Then CalcLikelihoodDdd must be called by 
#  CalcLikelihoodDdd(lambda = speciation_rate,mu = extinction_rate, branch_lengths = c(3,4))
#
#  What is the likelihood of this tree?
CalcLikelihoodDdd <- function(lambda,mu,branch_lengths)
{
  # Use the DDD package

  # model of time-dependence: 
  # - 0: no time dependence 
  # - 1: speciation and/or extinction rate is exponentially declining with time 
  # - 2: stepwise decline in speciation rate as in diversity-dependence without extinction 
  # - 3: decline in speciation rate following deterministic logistic equation for ddmodel = 1 
  model_of_time_dependence <- 0

  # conditioning: 
  # - 0: conditioning on stem or crown age 
  # - 1: conditioning on stem or crown age and non-extinction of the phylogeny 
  # - 2: conditioning on stem or crown age and on the total number of extant taxa (including missing species) 
  # - 3: conditioning on the total number of extant taxa (including missing species) 
  conditioning <- 1

  # Likelihood of what:
  # - 0: branching times
  # - 1: the phylogeny
  likelihood_of_what <- 1

  # Show parameters and likelihood on screen:
  # - 0: no
  # - 1: yes
  show_parameters_and_likelihood_on_screen <- 0

  # first data point is:
  # - 1: stem age
  # - 2: crown age
  first_data_point_is <- 2

  # I call the result of bd_loglik 'log_likelihood_ddd_without_combinational_term', because
  # it is not the true likelihood (true as in: when integrated over all parameters these probabilities sum up to one).
  # The true likelihood is given in Nee et al., 1994:
  #
  # Equation 20:
  #
  # lik = (N-1)!*(lambda^(N-2))*PRODUCT{i=3,N}(P(t_i,T))*((1-u_x_2)^2)*PRODUCT{i=3,N}(1 - u_x_i)
  #
  # Etienne & Haegeman, 2012, use:
  #
  # lik =        (lambda^(N-2))*PRODUCT{i=3,N}(P(t_i,T))*((1-u_x_2)^2)*PRODUCT{i=3,N}(1 - u_x_i)
  #       ^^^^^^ 
  #          
  # The bd_loglik function return the log of (the non-combinatorial) likelihood,
  # so it is transformed back afterwards
  #
  log_likelihood_ddd_without_combinational_term <- bd_loglik(
    pars1 = c(lambda,mu),
    pars2 = c(
      model_of_time_dependence,
      conditioning,
      likelihood_of_what,
      show_parameters_and_likelihood_on_screen,
      first_data_point_is
    ), 
    brts=branch_lengths,
    missnumspec = 0
  )

  likelihood_ddd_without_combinational_term  <- exp(log_likelihood_ddd_without_combinational_term )
  likelihood_ddd <- likelihood_ddd_without_combinational_term * 2
  return (likelihood_ddd)
}

# Equation 2 in Nee et al., The reconstructed evolutionary process, 1994
# lambda: birth rate
# mu: death rate
# t: current time
# T: later time
CalcP <- function(lambda,mu,t,T)
{
  assert("CalcP: Birth rate is at least zero",lambda >= 0)
  assert("CalcP: Birth rate is at most one",lambda <= 1)
  assert("CalcP: Death rate is at least zero",mu >= 0)
  assert("CalcP: Death rate is at most one",mu <= 1)
  assert("CalcP: Current time (t) is positive",t >= 0)
  assert("CalcP: Later time (T) is positive",T >= 0)

  numerator <- lambda - mu
  denominator <- lambda - (mu * exp(-(lambda-mu)*(T-t) ) )
  assert("CalcP: Cannot divide by zero",denominator != 0.0)
  P <- numerator / denominator
  return (P)
}


# Equation 3 in Nee et al., The reconstructed evolutionary process, 1994
# lambda: birth rate
# mu: death rate
# t: current time
# T: later time
# i: number of lineages
CalcPr1 <- function(i,lambda,mu,t,T)
{
  assert("CalcPr1: Number of lineages is at least zero",i >= 0)
  assert("CalcPr1: Birth rate is at least zero",lambda >= 0)
  assert("CalcPr1: Birth rate is at most one",lambda <= 1)
  assert("CalcPr1: Death rate is at least zero",mu >= 0)
  assert("CalcPr1: Death rate is at most one",mu <= 1)
  assert("CalcPr1: Current time (t) is positive",t >= 0)
  assert("CalcPr1: Later time (T) is positive",T >= 0)
  if (i == 0)
  {
    Pr1 <- 1.0 - CalcP(lambda = lambda,mu = mu,t = 0,T = t)
    return (Pr1)
  } else {
    u_t <- CalcU(lambda = lambda,mu = mu,t = t)
    Pr1 <- CalcP(lambda = lambda,mu = mu,t = 0,T = t) * (1.0 - u_t) * (u_t ^ (i-1))
    return (Pr1)
  }
}


# Equation 4 in Nee et al., The reconstructed evolutionary process, 1994
# lambda: birth rate
# mu: death rate
# t: current time
# T: later time
# i: number of lineages
CalcPr2 <- function(i,lambda,mu,t,T)
{
  assert("CalcPr2: Number of lineages is at least one",i >= 1)
  assert("CalcPr2: Birth rate is at least zero",lambda >= 0)
  assert("CalcPr2: Birth rate is at most one",lambda <= 1)
  assert("CalcPr2: Death rate is at least zero",mu >= 0)
  assert("CalcPr2: Death rate is at most one",mu <= 1)
  assert("CalcPr2: Current time (t) is positive",t >= 0)
  assert("CalcPr2: Later time (T) is positive",T >= 0)
  u_t <- CalcU(lambda = lambda,mu = mu,t = t)
  Pr2 <- (1.0 - u_t) * (u_t ^ (i-1))
  return (Pr2)
}

# Equation 5 in Nee et al., The reconstructed evolutionary process, 1994
# lambda: birth rate
# mu: death rate
# t: current time
# T: later time
# i: number of lineages
CalcPr3 <- function(i,lambda,mu,t,T)
{
  assert("CalcPr3: Number of lineages is at least one",i >= 1)
  assert("CalcPr3: Birth rate is at least zero",lambda >= 0)
  assert("CalcPr3: Birth rate is at most one",lambda <= 1)
  assert("CalcPr3: Death rate is at least zero",mu >= 0)
  assert("CalcPr3: Death rate is at most one",mu <= 1)
  assert("CalcPr3: Current time (t) is positive",t >= 0)
  assert("CalcPr3: Later time (T) is positive",T >= 0)
  u_t <- CalcU(lambda = lambda,mu = mu,t = t)
  numerator <- (1 - u_t) * (u_t ^ (i-1)) * (1 - (1 - (CalcP(lambda = lambda, mu = mu, t = t, T = T) ^ i)))
  denominator <- 0.0
  
  #Use j instead of i, as i is already a function argument
  j <- 1
  while (1)
  {
    x <- (1 - u_t) * (u_t ^ (j-1)) * (1 - (1 - (CalcP(lambda = lambda, mu = mu, t = t, T = T) ^ j)))
    if (x == 0) break;
    denominator <- denominator + x
    j <- j + 1
  }
  assert("CalcPr3: Cannot divide by zero",denominator != 0)
  Pr3 <- numerator / denominator
  return (Pr3)
}

# Equation 9 in Nee et al., The reconstructed evolutionary process, 1994
# lambda: birth rate
# mu: death rate
# t: current time
# T: later time
# i: number of lineages
CalcPr4 <- function(i,lambda,mu,t,T)
{
  assert("CalcPr4: Number of lineages is at least one",i >= 1)
  assert("CalcPr4: Birth rate is at least zero",lambda >= 0)
  assert("CalcPr4: Birth rate is at most one",lambda <= 1)
  assert("CalcPr4: Death rate is at least zero",mu >= 0)
  assert("CalcPr4: Death rate is at most one",mu <= 1)
  assert("CalcPr4: Current time (t) is positive",t >= 0)
  assert("CalcPr4: Later time (T) is positive",T >= 0)
  u_t <- CalcU(lambda = lambda,mu = mu,t = t)
  first_term <- 1 - (u_t * CalcP(lambda=lambda,mu=mu,t=0,T=T) / CalcP(lambda=lambda,mu=mu,t=0,T=t))
  second_term <- (u_t * CalcP(lambda=lambda,mu=mu,t=0,T=T) / CalcP(lambda=lambda,mu=mu,t=0,T=t)) ^ (i - 1)
  Pr4 <- first_term * second_term
  return (Pr4)
}

# Equation 1 in Nee et al., The reconstructed evolutionary process, 1994
# lambda: birth rate
# mu: death rate
# t: current time
CalcU <- function(lambda,mu,t)
{
  assert("CalcU: Birth rate is at least zero",lambda >= 0)
  assert("CalcU: Birth rate is at most one",lambda <= 1)
  assert("CalcU: Death rate is at least zero",mu >= 0)
  assert("CalcU: Death rate is at most one",mu <= 1)

  numerator <- lambda * (1.0-exp(-(lambda-mu)*t))
  denominator <- lambda - (mu * exp(-((lambda-mu))*t))
  
  # debugging code
  if (denominator == 0)
  {
    print(paste("CalcU: ERROR: denominator == 0 for lambda = ",lambda,", mu: ",mu,", t: ",t,sep=""))
  }
  
  assert("CalcU: Cannot divide by zero",denominator != 0.0)
  u <- numerator / denominator
  return (u)
}

# Count the number of times search_value occurs in list
Count <- function(list,search_value)
{
  count <- 0
  for (value in list)
  {
    if (value == search_value)
    {
      count <- count + 1
    }
  }
  return (count)
}

PlotAll <- function()
{
  svg(filename="Nee1994P.svg")
  PlotP(lambda = 0.2,mu = 0.1,T = 10)
  dev.off()

  pdf(file="Nee1994P.pdf")
  PlotP(lambda = 0.2,mu = 0.1,T = 10)
  dev.off()

  svg(filename="Nee1994U.svg")
  PlotU(lambda,mu,10)
  dev.off()

  pdf(file="Nee1994U.pdfg")
  PlotU(lambda,mu,10)
  dev.off()

  svg(filename="Nee1994Pr1.svg")
  PlotPr1(lambda = 0.15, mu = 0.1, T = 10)
  dev.off()

  pdf(file="Nee1994Pr1.pdf")
  PlotPr1(lambda = 0.15, mu = 0.1, T = 10)
  dev.off()

  svg(filename="Nee1994Pr2.svg")
  PlotPr2(lambda = 0.15, mu = 0.1, T = 10)
  dev.off()

  pdf(file="Nee1994Pr2.pdf")
  PlotPr2(lambda = 0.15, mu = 0.1, T = 10)
  dev.off()

  svg(filename="Nee1994Pr3.svg")
  PlotPr3(lambda = 0.15, mu = 0.1, T = 10)
  dev.off()

  pdf(file="Nee1994Pr3.pdf")
  PlotPr3(lambda = 0.15, mu = 0.1, T = 10)
  dev.off()

  svg(filename="Nee1994Pr4.svg")
  PlotPr3(lambda = 0.15, mu = 0.1, T = 10)
  dev.off()

  pdf(file="Nee1994Pr4.pdf")
  PlotPr3(lambda = 0.15, mu = 0.1, T = 10)
  dev.off()
}

# Plot P for time [0,T + 1]
PlotP <- function(lambda,mu,T)
{
  assert("PlotP: Birth rate is at least zero",lambda >= 0)
  assert("PlotP: Birth rate is at most one",lambda <= 1)
  assert("PlotP: Death rate is at least zero",mu >= 0)
  assert("PlotP: Death rate is at most one",mu <= 1)
  assert("PlotP: Later time (T) is positive",T >= 0)

  t <- 0
  ys <- CalcP(lambda,mu,0.0,T) #Calculate for t = 0
  xs <- 0
  max_t <- T + 2 # Show what happens beyond t=T
  for (t in seq(1,max_t)) #Start at 1, as t = 0 is already in y
  {
    ys <- rbind(ys,CalcP(lambda,mu,t,T))
    xs <- rbind(xs,t)
  }
  plot(xs,ys,main=paste("P(lambda=",lambda,", mu=",mu,", T=",T,")",sep=""),xlab="t",ylab="P",ylim=c(0.0,max(ys)))
  # Horizontal line
  abline(v=T,lty=3)
  # Vertical line
  abline(h=1.0,lty=3)
}

PlotPr1 <- function(lambda,mu,T)
{
  assert("PlotPr1: Birth rate is at least zero",lambda >= 0)
  assert("PlotPr1: Birth rate is at most one",lambda <= 1)
  assert("PlotPr1: Death rate is at least zero",mu >= 0)
  assert("PlotPr1: Death rate is at most one",mu <= 1)
  assert("PlotPr1: Later time (T) is positive",T >= 0)

  t <- 0
  ys0 <- CalcPr1(i=0,lambda,mu,0.0,T) #Calculate for t = 0
  ys1 <- CalcPr1(i=1,lambda,mu,0.0,T) #Calculate for t = 0
  ys2 <- CalcPr1(i=2,lambda,mu,0.0,T) #Calculate for t = 0
  ys3 <- CalcPr1(i=3,lambda,mu,0.0,T) #Calculate for t = 0
  ys4 <- CalcPr1(i=4,lambda,mu,0.0,T) #Calculate for t = 0
  xs <- 0
  max_t <- T + 2 # Show what happens beyond t=T
  for (t in seq(1,max_t)) #Start at 1, as t = 0 is already in y
  {
    ys0 <- rbind(ys0,CalcPr1(i=0,lambda,mu,t,T))
    ys1 <- rbind(ys1,CalcPr1(i=1,lambda,mu,t,T))
    ys2 <- rbind(ys2,CalcPr1(i=2,lambda,mu,t,T))
    ys3 <- rbind(ys3,CalcPr1(i=3,lambda,mu,t,T))
    ys4 <- rbind(ys4,CalcPr1(i=4,lambda,mu,t,T))
    xs <- rbind(xs,t)
  }
  maxy <- max(c(ys0,ys1,ys2,ys3,ys4))
  plot(type="n",xs,ys0,
    main=paste(
      "Probability that there are i lineages in time\n",
      "Pr1(lambda=",lambda,", mu=",mu,", T=",T,")",sep=""
    ),
    xlab="t",ylab="Pr",ylim=c(0.0,maxy)
  )
  col0 <- "red"
  col1 <- "orange"
  col2 <- "yellow"
  col3 <- "green"
  col4 <- "blue"
  lines(xs,ys0,col=col0)
  lines(xs,ys1,col=col1)
  lines(xs,ys2,col=col2)
  lines(xs,ys3,col=col3)
  lines(xs,ys4,col=col4)
  # Horizontal line
  abline(v=T,lty=3)
  # Vertical line
  abline(h=1.0,lty=3)
  
  legend("topright",
    title = "i", c("0","1","2","3","4"),
    horiz=FALSE,
    inset=0.05,
    fill=c(col0,col1,col2,col3,col4), 
    cex = 1.0
  )  
}

PlotPr2 <- function(lambda,mu,T)
{
  assert("PlotPr2: Birth rate is at least zero",lambda >= 0)
  assert("PlotPr2: Birth rate is at most one",lambda <= 1)
  assert("PlotPr2: Death rate is at least zero",mu >= 0)
  assert("PlotPr2: Death rate is at most one",mu <= 1)
  assert("PlotPr2: Later time (T) is positive",T >= 0)

  t <- 0
  ys1 <- CalcPr2(i=1,lambda,mu,0.0,T) #Calculate for t = 0
  ys2 <- CalcPr2(i=2,lambda,mu,0.0,T) #Calculate for t = 0
  ys3 <- CalcPr2(i=3,lambda,mu,0.0,T) #Calculate for t = 0
  ys4 <- CalcPr2(i=4,lambda,mu,0.0,T) #Calculate for t = 0
  ys5 <- CalcPr2(i=5,lambda,mu,0.0,T) #Calculate for t = 0
  xs <- 0
  max_t <- T + 2 # Show what happens beyond t=T
  for (t in seq(1,max_t)) #Start at 1, as t = 0 is already in y
  {
    ys1 <- rbind(ys1,CalcPr2(i=1,lambda,mu,t,T))
    ys2 <- rbind(ys2,CalcPr2(i=2,lambda,mu,t,T))
    ys3 <- rbind(ys3,CalcPr2(i=3,lambda,mu,t,T))
    ys4 <- rbind(ys4,CalcPr2(i=4,lambda,mu,t,T))
    ys5 <- rbind(ys5,CalcPr2(i=5,lambda,mu,t,T))
    xs <- rbind(xs,t)
  }
  maxy <- max(c(ys1,ys2,ys3,ys4,ys5))
  plot(type="n",xs,ys1,
    main=paste(
      "Probability that there are i surviving lineages in time\n",
      "Pr2(lambda=",lambda,", mu=",mu,", T=",T,")",sep=""
    ),
    xlab="t",ylab="Pr",ylim=c(0.0,maxy)
  )
  col1 <- "red"
  col2 <- "orange"
  col3 <- "yellow"
  col4 <- "green"
  col5 <- "blue"
  lines(xs,ys1,col=col1)
  lines(xs,ys2,col=col2)
  lines(xs,ys3,col=col3)
  lines(xs,ys4,col=col4)
  lines(xs,ys5,col=col5)
  # Horizontal line
  abline(v=T,lty=3)
  # Vertical line
  abline(h=1.0,lty=3)
  
  legend("topright",
    title = "i", c("1","2","3","4","5"),
    horiz=FALSE,
    inset=0.05,
    fill=c(col1,col2,col3,col4,col5), 
    cex = 1.0
  )  
}





PlotPr3 <- function(lambda,mu,T)
{
  assert("PlotPr3: Birth rate is at least zero",lambda >= 0)
  assert("PlotPr3: Birth rate is at most one",lambda <= 1)
  assert("PlotPr3: Death rate is at least zero",mu >= 0)
  assert("PlotPr3: Death rate is at most one",mu <= 1)
  assert("PlotPr3: Later time (T) is positive",T >= 0)

  t <- 0
  ys1 <- CalcPr3(i=1,lambda,mu,0.0,T) #Calculate for t = 0
  ys2 <- CalcPr3(i=2,lambda,mu,0.0,T) #Calculate for t = 0
  ys3 <- CalcPr3(i=3,lambda,mu,0.0,T) #Calculate for t = 0
  ys4 <- CalcPr3(i=4,lambda,mu,0.0,T) #Calculate for t = 0
  ys5 <- CalcPr3(i=5,lambda,mu,0.0,T) #Calculate for t = 0
  xs <- 0
  max_t <- T + 2 # Show what happens beyond t=T
  for (t in seq(1,max_t)) #Start at 1, as t = 0 is already in y
  {
    ys1 <- rbind(ys1,CalcPr3(i=1,lambda,mu,t,T))
    ys2 <- rbind(ys2,CalcPr3(i=2,lambda,mu,t,T))
    ys3 <- rbind(ys3,CalcPr3(i=3,lambda,mu,t,T))
    ys4 <- rbind(ys4,CalcPr3(i=4,lambda,mu,t,T))
    ys5 <- rbind(ys5,CalcPr3(i=5,lambda,mu,t,T))
    xs <- rbind(xs,t)
  }
  maxy <- max(c(ys1,ys2,ys3,ys4,ys5))
  plot(type="n",xs,ys1,
    main=paste(
      "Probability that at least one of the i lineages survives to time T\n",
      "Pr3(lambda=",lambda,", mu=",mu,", T=",T,")",sep=""
    ),
    xlab="t",ylab="Pr",ylim=c(0.0,maxy)
  )
  col1 <- "red"
  col2 <- "orange"
  col3 <- "yellow"
  col4 <- "green"
  col5 <- "blue"
  lines(xs,ys1,col=col1)
  lines(xs,ys2,col=col2)
  lines(xs,ys3,col=col3)
  lines(xs,ys4,col=col4)
  lines(xs,ys5,col=col5)
  # Horizontal line
  abline(v=T,lty=3)
  # Vertical line
  abline(h=1.0,lty=3)
  
  legend("topright",
    title = "i", c("1","2","3","4","5"),
    horiz=FALSE,
    inset=0.05,
    fill=c(col1,col2,col3,col4,col5), 
    cex = 1.0
  )  
}






PlotPr4 <- function(lambda,mu,T)
{
  assert("PlotPr4: Birth rate is at least zero",lambda >= 0)
  assert("PlotPr4: Birth rate is at most one",lambda <= 1)
  assert("PlotPr4: Death rate is at least zero",mu >= 0)
  assert("PlotPr4: Death rate is at most one",mu <= 1)
  assert("PlotPr4: Later time (T) is positive",T >= 0)

  t <- 0
  ys1 <- CalcPr4(i=1,lambda,mu,0.0,T) #Calculate for t = 0
  ys2 <- CalcPr4(i=2,lambda,mu,0.0,T) #Calculate for t = 0
  ys3 <- CalcPr4(i=3,lambda,mu,0.0,T) #Calculate for t = 0
  ys4 <- CalcPr4(i=4,lambda,mu,0.0,T) #Calculate for t = 0
  ys5 <- CalcPr4(i=5,lambda,mu,0.0,T) #Calculate for t = 0
  xs <- 0
  max_t <- T + 2 # Show what happens beyond t=T
  for (t in seq(1,max_t)) #Start at 1, as t = 0 is already in y
  {
    ys1 <- rbind(ys1,CalcPr4(i=1,lambda,mu,t,T))
    ys2 <- rbind(ys2,CalcPr4(i=2,lambda,mu,t,T))
    ys3 <- rbind(ys3,CalcPr4(i=3,lambda,mu,t,T))
    ys4 <- rbind(ys4,CalcPr4(i=4,lambda,mu,t,T))
    ys5 <- rbind(ys5,CalcPr4(i=5,lambda,mu,t,T))
    xs <- rbind(xs,t)
  }
  maxy <- max(c(ys1,ys2,ys3,ys4,ys5))
  plot(type="n",xs,ys1,
    main=paste(
      "?Reconstructed probability that at least one of the i lineages survives to time T\n",
      "Pr4(lambda=",lambda,", mu=",mu,", T=",T,")",sep=""
    ),
    xlab="t",ylab="Pr",ylim=c(0.0,maxy)
  )
  col1 <- "red"
  col2 <- "orange"
  col3 <- "yellow"
  col4 <- "green"
  col5 <- "blue"
  lines(xs,ys1,col=col1)
  lines(xs,ys2,col=col2)
  lines(xs,ys3,col=col3)
  lines(xs,ys4,col=col4)
  lines(xs,ys5,col=col5)
  # Horizontal line
  abline(v=T,lty=3)
  # Vertical line
  abline(h=1.0,lty=3)
  
  legend("topright",
    title = "i", c("1","2","3","4","5"),
    horiz=FALSE,
    inset=0.05,
    fill=c(col1,col2,col3,col4,col5), 
    cex = 1.0
  )  
}


# lambda: birth rate
# mu: death rate
# t: current time
# max_t: until what time to plot u
PlotU <- function(lambda,mu,max_t)
{
  assert("PlotU: Birth rate is at least zero",lambda >= 0)
  assert("PlotU: Birth rate is at most one",lambda <= 1)
  assert("PlotU: Death rate is at least zero",mu >= 0)
  assert("PlotU: Death rate is at most one",mu <= 1)
  assert("PlotU: Plotting time must be positive",max_t >= 0)
  
  t <- 0
  ys <- CalcU(lambda,mu,0) #Calculate for t = 0
  xs <- 0
  for (t in seq(1,max_t)) #Start at 1, as t = 0 is already in y
  {
    ys <- rbind(ys,CalcU(lambda,mu,t))
    xs <- rbind(xs,t)
  }
  plot(xs,ys,main=paste("u(lambda=",lambda,", mu=",mu,", max_t=",max_t,")",sep=""),xlab="t",ylab="u")
}


Test <- function()
{
  # Count
  {
    x <- c(0.0,1.1,2.2,0.0)
    assert("",Count(x,0.0) == 2)
    assert("",Count(x,1.1) == 1)
    assert("",Count(x,2.2) == 1)
  }
  # CalcChanceSurvival
  {
    assert("Test: If death rate (mu) is zero, chance of survival is 100%",
      CalcChanceSurvival(lambda = 0.2,mu = 0.0, T = 100) == 1
    )
    assert("Test: If death rate (mu) is one, chance of survival is very small",
      CalcChanceSurvival(lambda = 0.2,mu = 1.0, T = 100) < 0.00000000001
    )
  }
  # CalcP
  {
    t_is_T <- 10
    assert("Test: The chance a lineage survives from now to now is 100%",
      CalcP(lambda = 0.2,mu = 0.01,t_is_T,t_is_T) == 1
    )
  }
  {
    assert("Test: If death rate (mu) is zero, chance of survival is 100%",
      CalcP(lambda = 0.9, mu = 0.0, t = 0, T = 10) == 1
    )
  }
  {
    survival_low_death_rate  <- CalcP(lambda = 0.9, mu = 0.1, t = 0, T = 10)
    survival_high_death_rate <- CalcP(lambda = 0.9, mu = 0.2, t = 0, T = 10)
    assert("Test: The higher death rate (mu), the lower the chance of extinction",
       survival_low_death_rate > survival_high_death_rate
    )
  }
  # CalcPr1
  {
    # Only try t e [0,5]
    for (t in seq(0,3))
    {
      sum <- 0.0
      # i is an accuracy measure: the higher t, the higher i must be to have a sum of 1
      for (i in seq(0,100))
      {
        p <- CalcPr1(i=i,lambda = 0.7, mu = 0.1, t = t, T = 10)
        sum <- sum + p
      }
      assert("Test: SUM of CalcPr1 must be 1.0",abs(sum-1.0) < 0.000001)
    }
  }
  # CalcLikelihoodBirthDeath
  {
    assert(
      "With negligible birth and death, the probability of finding a two-clade tree is close to one",
      CalcLikelihoodBirthDeath(lambda = 0.00000001, mu = 0.000000000001, branching_times = c(0.0), T = 1.0) > 0.9999999
    )
  }
  # bd_loglik
  {
    #
    #  +----+----+----+----+
    #  |
    # -+    +----+----+----+
    #  |    |
    #  +----+
    #       |
    #       +----+----+----+
    #
    #  +----+----+----+----+ time
    #  0    1    2    3    4
    #
    #  lambda = 0.2 (speciation rate)
    #  mu = 0.01 (extinction rate)
    #
    #  What is the log(likelihood) of this tree?
    #
    #  From calculations by hand (thanks to Cesar Martinez), 
    #  following Nee et al. (1996) we found 
    #  (when conditioning on crown age and survival):
    #
    #  likelihood = 0.04474506
    #  log(likelihood) = -3.106774
    #
    #  I think it is correct, as I calculated it twice, 
    #  using equations 20 and 21 from Nee et al. (1996).
    #
    #  Equation 20, from Nee et al. (1996):
    #
    #  lik = (N-1)!*(lambda^(N-2))*PRODUCT{i=3,N}(P(t_i,T))*((1-u_x_2)^2)*PRODUCT{i=3,N}(1 - u_x_i)
    #
    #  lambda <- 0.2
    #  mu <- 0.01
    #  result20 <- 2 * lambda * CalcP(lambda,mu,t=1,T=4) 
    #    * ((1 - CalcU(lambda,mu,t = 4)) ^ 2) * (1 - CalcU(lambda,mu,t=3))
    #  r <- lambda - mu
    #  a <- mu / lambda
    #  result21 <- 2 * r * exp(3 * r) *((1-a)^3) 
    #    * (1 /( (exp(4*r)-a)^2) ) * (1 /( (exp(3*r)-a)^2) )
    lambda <- 0.2
    mu <- 0.01
    expected_likelihood <- 0.04474506 #From calculations by hand
    expected_log_likelihood <- -3.106774 #From calculations by hand
    branching_times_from_crown = c(0.0,1.0) #branching_times_from_crown[1] is the starting time
    T <- 4.0

    # Use the DDD package

    # model of time-dependence: 
    # - 0: no time dependence 
    # - 1: speciation and/or extinction rate is exponentially declining with time 
    # - 2: stepwise decline in speciation rate as in diversity-dependence without extinction 
    # - 3: decline in speciation rate following deterministic logistic equation for ddmodel = 1 
    model_of_time_dependence <- 0

    # conditioning: 
    # - 0: conditioning on stem or crown age 
    # - 1: conditioning on stem or crown age and non-extinction of the phylogeny 
    # - 2: conditioning on stem or crown age and on the total number of extant taxa (including missing species) 
    # - 3: conditioning on the total number of extant taxa (including missing species) 
    conditioning <- 1

    # Likelihood of what:
    # - 0: branching times
    # - 1: the phylogeny
    likelihood_of_what <- 1

    # Show parameters and likelihood on screen:
    # - 0: no
    # - 1: yes
    show_parameters_and_likelihood_on_screen <- 0

    # first data point is:
    # - 1: stem age
    # - 2: crown age
    first_data_point_is <- 2

    xs <- T - branching_times_from_crown

    # I call the result of bd_loglik 'log_likelihood_ddd_without_combinational_term', because
    # it is not the true likelihood (true as in: when integrated over all parameters these probabilities sum up to one).
    # The true likelihood is given in Nee et al., 1994:
    #
    # Equation 20:
    #
    # lik = (N-1)!*(lambda^(N-2))*PRODUCT{i=3,N}(P(t_i,T))*((1-u_x_2)^2)*PRODUCT{i=3,N}(1 - u_x_i)
    #
    # Etienne & Haegeman, 2012, use:
    #
    # lik =        (lambda^(N-2))*PRODUCT{i=3,N}(P(t_i,T))*((1-u_x_2)^2)*PRODUCT{i=3,N}(1 - u_x_i)
    #       ^^^^^^ 
    #          
    # The bd_loglik function return the log of (the non-combinatorial) likelihood,
    # so it is transformed back afterwards
    #
    log_likelihood_ddd_without_combinational_term <- bd_loglik(
      pars1 = c(lambda,mu),
      pars2 = c(
        model_of_time_dependence,
        conditioning,
        likelihood_of_what,
        show_parameters_and_likelihood_on_screen,
        first_data_point_is
      ), 
      brts=xs,
      missnumspec = 0
    )

    likelihood_ddd_without_combinational_term  <- exp(log_likelihood_ddd_without_combinational_term )
    likelihood_ddd <- likelihood_ddd_without_combinational_term * 2
    log_likelihood_ddd <- log(likelihood_ddd)

    assert("The calculated likelihood must match the one calculated by hand",abs(likelihood_ddd - expected_likelihood) < 0.0001)
    assert("The calculated log likelihood must match the one calculated by hand",abs(log_likelihood_ddd - expected_log_likelihood) < 0.0001)
  }
  # CalcLikelihoodDdd 
  {
    # same test as bd_loglik
    lambda <- 0.2
    mu <- 0.01
    expected_likelihood <- 0.04474506 #From calculations by hand
    expected_log_likelihood <- -3.106774 #From calculations by hand
    branch_lengths <- c(4.0,3.0)
    likelihood_ddd <- CalcLikelihoodDdd(lambda,mu,branch_lengths)

    assert("CalcLikelihoodDdd must match the one calculated by hand",abs(likelihood_ddd - expected_likelihood) < 0.0001)
    assert("CalcLikelihoodDdd must match the one calculated by hand",abs(likelihood_ddd - expected_likelihood) < 0.0001)
  }
}



Test()


lambda <- 0.2
mu <- 0.01
branching_times_from_crown <- c(0.0,1.0)
T <- 4.0
branch_lengths <- T - branching_times_from_crown

likelihood_ddd <- CalcLikelihoodDdd(lambda,mu,branch_lengths)
log_likelihood_ddd <- log(likelihood_ddd)
log_likelihood_laser <- calcLHbd(x = branch_lengths, r = lambda - mu, a = mu / lambda)
likelihood_laser <- exp(log_likelihood_laser)

assert("DDD and LASER package must give the same result",abs(likelihood_ddd - likelihood_laser) < 0.0000000000001)
assert("DDD and LASER package must give the same result",abs(log_likelihood_ddd - log_likelihood_laser) < 0.0000000000001)
print(likelihood_ddd)
print(likelihood_laser)
print(log_likelihood_ddd)
print(log_likelihood_laser)

assert("DONE!",1 == 2)

# Use my implementation, from Nee et al., 1994
# Reduce the tree to two branching times, at t=0 and t=1, and a final time, T=4
# My implementation does not work, but feel free to fix it :-)
my_likelihood <- CalcLikelihoodBirthDeath(
    lambda = lambda, 
    mu = mu, 
    branching_times = branching_times_from_crown, 
    T = T
)

# Use the expoTree package
#
# I could not put it to good use. If you know how, feel free to fix it
#
N <- 3
ttypes <- rep(1,3)
psi <- 0
rho <- 1
pars <- matrix(c(N,lambda,mu,psi,rho),nrow=1)
loglik_expoTree1 <- runExpoTree(pars,times=branching_times_from_crown,ttypes) # 'times' must be sorted
loglik_expoTree2 <- runExpoTree(pars,times=c(branching_times_from_crown,T),ttypes) # 'times' must be sorted
loglik_expoTree3 <- runExpoTree(pars,times=rev(branch_lengths),ttypes) # 'times' must be sorted
loglik_expoTree4 <- runExpoTree(pars,times=c(rev(branch_lengths),T),ttypes) # 'times' must be sorted
print(paste(loglik_expoTree1,loglik_expoTree2,loglik_expoTree3,loglik_expoTree4))
print(paste(exp(loglik_expoTree1),exp(loglik_expoTree2),exp(loglik_expoTree3),exp(loglik_expoTree4)))
?runExpoTree

#
# References
#
# * Etienne, R.S. & B. Haegeman 2012. Am. Nat. 180: E75-E89, doi: 10.1086/667574
# * Nee, Sean, Robert M. May, and Paul H. Harvey. 
#   "The reconstructed evolutionary process." 
#   Philosophical Transactions of the Royal Society B: Biological Sciences 
#   344.1309 (1994): 305-311.
