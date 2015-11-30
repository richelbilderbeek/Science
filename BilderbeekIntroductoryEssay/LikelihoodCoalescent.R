setwd("~")

L <- function(N)
{
  p <- (1/N) * exp(-4/N) * (1/N) * 3 * exp(-9 / N)
	return (p)
}

png("LikelihoodCoalescent.png")
xs <- seq(1,20)
ys <- L(xs)
barplot(ys,names.arg=xs,main="L(N|t={4,3})",xlab="N",ylab="L")
# plot(xs,ys,xlim=c(1,20),main="L(N|t={4,3})",xlab="N",ylab="L",type="S")
dev.off()
