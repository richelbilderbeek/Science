library(nLTT) #nolint
set.seed(42)
tree1 <- ape::rcoal(n = 5)
tree2 <- ape::rcoal(n = 5)

svg("~/example_tree_1.svg")
ape::plot.phylo(tree1, show.tip.label = FALSE, edge.width = 10, edge.color = "red")
dev.off()

svg("~/example_tree_2.svg")
ape::plot.phylo(tree2, show.tip.label = FALSE, edge.width = 10, edge.color  = "blue")
dev.off()

svg("~/example_nltt_plot.svg")
ape::ltt.plot
my_scale <- 2
nLTT::nltt_plot(tree1, col = "red", lwd = 3, cex.axis = my_scale, cex.lab = my_scale)
nltt_lines(tree2, col = "blue", lwd = 3)
#legend("topleft", c("tree1", "tree2"), col = c("red", "blue"), lty = 1, lwd = 3)
dev.off()

