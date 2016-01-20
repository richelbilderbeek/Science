rm(list=ls())
library(ape)
library(geiger)
library(laser)
library(DDD)


phylogeny <- read.tree(text = "((A:0.3,B:0.3):0.7,(C:0.6,D:0.6):0.4);"); 

png(filename="~/ExamplePhylogeny.png")
plot(phylogeny) 
dev.off()


branch_lengths <- phylogeny$edge.length

lambda <- 1.0
mu <- 0.0
log_likelihood_laser <- calcLHbd(x = branch_lengths, r = lambda - mu, a = mu / lambda)
print(log_likelihood_laser)

max_likelihood <- bd_ML(
  brts = branch_lengths,
	initparsopt = c(0.1),
	idparsopt = 1,
	parsfix = c(0,0,0),
	idparsfix = c(2,3,4),
	tdmodel = 0,
  cond = 3, # cond == 1 : conditioning on stem or crown age and non-extinction of the phylog
  btorph = 1 # Likelihood is for (0) branching times (1) phylogeny
)
