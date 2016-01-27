library(ape)
library(phangorn)
set.seed(42)
alignment_phydat <- simSeq(
  rcoal(10),
  l = 50, # sequence_length,
  rate = 0.1 #mutation_rate
)
alignment_dnabin <- as.DNAbin(alignment_phydat)
png("alignment.png")
image(alignment_dnabin)
dev.off()
