#  From Jotun Hein, Mikkel H. Schierup and Carsten Wiuft, 'Gene genealogies, variation and evolution', 2005

# Equation1.1. page 14
# No idea what it does exactly
Equation_1_1 <- function(v_i,N)
{
  k <- v_i
  p <- choose(2 * N,k) * ((1 / (2.0 * N)) ^ k) * ((1 - (1 / (2.0 * N))) ^ ((2*N) - k))
  return (p)
}


N <- 5

xs <- seq(0,5)
ys <- c()
for (x in xs)
{
  y <- Equation_1_1(v_i = x,N = N)
  if (length(ys) == 0) {
    ys <- y 
  } else {
    ys <- c(ys,y) 
  }
}
plot(
  xs,ys,
  ylab="Probability"
)