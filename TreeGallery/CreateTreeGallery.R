rm(list=ls())
library(testit)
library(ape)
library(geiger)

n_taxa <- 20

create_pdf <- TRUE
create_svg <- FALSE

assert("Only one create can be true",xor(create_pdf,create_svg))

if (create_svg) { svg(filename="CreateRandomPhylogenyRcoal.svg") 
} else if (create_pdf) { pdf(file="CreateRandomPhylogenyRcoal.pdf") }
par(mfrow=c(3,2))
for (x in seq(1,6))
{
  phy_rcoal <- rcoal(n_taxa)
  plot(phy_rcoal)
}
dev.off()


if (create_svg) { svg(filename="CreateRandomPhylogenyRtree.svg") 
} else if (create_pdf) { pdf(file="CreateRandomPhylogenyRtree.pdf") }
par(mfrow=c(3,2))
for (x in seq(1,6))
{
  phy_rtree <- rtree(n_taxa)
  plot(phy_rtree)
}
dev.off()

# Birth-Death model that stops after a certain time
if (create_svg) { svg(filename="CreateRandomPhylogenyBirthDeath2010.svg") 
} else if (create_pdf) { pdf(file="CreateRandomPhylogenyBirthDeath2010.pdf") }
par(mfrow=c(3,2))
for (x in seq(1,6))
{
  birth_rate <- 0.2
  death_rate <- 0.1
  phy_bdtree <- sim.bdtree(birth_rate, death_rate, stop="taxa",n=n_taxa)
  phy_bdtree <- drop.extinct(phy_bdtree) # Drop extinct
  plot(phy_bdtree)
}
dev.off()

if (create_svg) { svg(filename="CreateRandomPhylogenyBirthDeath2005.svg") 
} else if (create_pdf) { pdf(file="CreateRandomPhylogenyBirthDeath2005.pdf") }
par(mfrow=c(3,2))
for (x in seq(1,6))
{
  birth_rate <- 0.2
  death_rate <- 0.05
  phy_bdtree <- sim.bdtree(birth_rate, death_rate, stop="taxa",n=n_taxa)
  phy_bdtree <- drop.extinct(phy_bdtree) # Drop extinct
  plot(phy_bdtree)
}
dev.off()

if (create_svg) { svg(filename="CreateRandomPhylogenyBirthDeath2001.svg") 
} else if (create_pdf) { pdf(file="CreateRandomPhylogenyBirthDeath2001.pdf") }
par(mfrow=c(3,2))
for (x in seq(1,6))
{
  birth_rate <- 0.2
  death_rate <- 0.01
  phy_bdtree <- sim.bdtree(birth_rate, death_rate, stop="taxa",n=n_taxa)
  phy_bdtree <- drop.extinct(phy_bdtree) # Drop extinct
  plot(phy_bdtree)
}
dev.off()
