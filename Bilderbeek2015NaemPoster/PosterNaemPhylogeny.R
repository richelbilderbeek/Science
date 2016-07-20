library(ape)
library(PBD)

write_to_file <- FALSE

set.seed(2)
p <- rcoal(3)

if (write_to_file) { svg("Phylogeny1.svg") }
plot(p, edge.width = 10, show.tip.label = FALSE, mar=c(-5,-5,-5,-5))
tiplabels(c(" 1a"," 2 "," 1b"), frame = "rect", bg = "white", cex = 2)
if (write_to_file) { dev.off() }


library(help = ape)
?plot.phylo 
?tiplabels
?plot

# 4 taxa tree
set.seed(5333)
pbd <- pbd_sim(c(0.1,0.3,0.1,0.1,0.1),5,plotit = TRUE) 
colors<-setNames(c("black","red"),c("g","i")) 
if (write_to_file) { svg("~/PbdPhylogeny1.svg") }
plot(pbd$igtree.extant, colors, lwd = 10, fsize = 2)
if (write_to_file) { dev.off() }

plot(pbd$igtree.extant)
?plotSimmap
?rep
names(pbd)

?pbd_sim

# 4 taxa tree
set.seed(3)
pbd <- pbd_sim(c(0.1,0.2,0.1,0.1,0.1),3.1,plotit = TRUE) 
colors<-setNames(c("black","red"),c("g","i"))
if (write_to_file) { svg("~/PbdPhylogeny2.svg") }
plot(pbd$igtree.extant, colors, lwd = 10, fsize = 2)
if (write_to_file) { dev.off() }
