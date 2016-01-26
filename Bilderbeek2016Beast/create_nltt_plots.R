library(ape)
library(nLTT)

set.seed(10)
p <- rcoal(10)

png("tree.png")
plot(p)
dev.off()

png("ltt.png")
ltt.plot(p)
dev.off()

png("nltt.png")
nLTT.plot(p)
dev.off()
