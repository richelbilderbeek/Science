library(nLTT) #nolint
set.seed(42)
#tree1 <- TESS::tess.sim.age(n = 1, age = 4, lambda = 0.4, mu = 0)[[1]]
#tree2 <- TESS::tess.sim.age(n = 1, age = 4, lambda = 0.25, mu = 0)[[1]]

tree1 <- ape::rcoal(n = 5)
tree2 <- ape::rcoal(n = 5)

svg("~/example_tree_1.svg")
ape::plot.phylo(tree1, show.tip.label = FALSE)
dev.off()

svg("~/example_tree_2.svg")
ape::plot.phylo(tree2, show.tip.label = FALSE)
dev.off()

svg("~/example_nltt_plot.svg")
nltt_plot(tree1, col = "red")
nltt_lines(tree2, col = "blue")
legend("topleft", c("tree1", "tree2"), col = c("red", "blue"), lty = 1)
dev.off()

