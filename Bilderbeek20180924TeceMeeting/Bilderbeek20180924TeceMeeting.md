From alignment to Bayes factor
========================================================
author: Richel J.C. Bilderbeek
date: 2018-09-24
autosize: true

[https://github.com/richelbilderbeek/Science](https://github.com/richelbilderbeek/Science)  ![CC-BY-NC-SA](CC-BY-NC-SA.png)

![RuG and GELIFES and TECE logo](footer.png)



Goal
========================================================

Show some aspects of phylogenetic research
  * Driven by research questions
  * Bayesian approach
  * Model comparison
  * first, using BEAST2
  * second, using `babette`

***
![BEAST2 logo](beast2_logo.png)
![babette logo](babette_logo.png)


Research questions
========================================================

![A primate cladogram](primate_cladogram_simplified_beast2.png)
***
 * 1. Whom are closest related?
 * 2. Who lived when?
 * 3. Which model to use?

1. Whom are closest related?
========================================================

![A primate cladogram](primate_cladogram_simplified_beast2.png)
***
And is it really that clear-cut?

What do we have?
========================================================


```r
fasta_filename <- "primates.fas"
alignment <- ape::read.FASTA(
  fasta_filename
)
```

```r
image(alignment)
```
***
![plot of chunk unnamed-chunk-3](Bilderbeek20180924TeceMeeting-figure/unnamed-chunk-3-1.png)

What tool do we use?
========================================================

 * BEAST2: Bayesian Evolutionary Analysis by Sampling Trees
 * Widely used
 * Easy to get started

***
![BEAST2 book](beast_book.jpg)

Demo
========================================================

Show how to:

 * View the posterior phylogenies
 * View the trace
 * View the effective sample size

Demo pictures
========================================================

![Densitree](densitree.png)
***
![Tracer](tracer.png)

Conclusion
========================================================
![A primate cladogram](primate_cladogram_simplified_beast2.png)
***
![Densitree](densitree.png)

But ... how often?
========================================================


```r
library(babette)
```

```r
trees <- parse_beast_trees(
  "primates_undated.trees"
)[51:100]
```

```r
plot_densitree(trees)
```
***
![plot of chunk unnamed-chunk-7](Bilderbeek20180924TeceMeeting-figure/unnamed-chunk-7-1.png)

But ... how often?
========================================================


```r
has_canonical_topology <- function(tree) {
  !is.na(stringr::str_match(
    ape::write.tree(tree),
    "siamang:[0-9\\.]+\\):0;")[1][1])
}
count_canonical_topologies <- function(trees) {
  n <- 0
  for (tree in trees) {
    n <- n + has_canonical_topology(tree)
  }
  n
}
count_canonical_topologies(trees) # out of 50
```

```
[1] 44
```

Discussion
========================================================

 * Approximately 40 out of 50 phylogenies follow the canonical topology
 * Effective sample size is below the recommended 200
 * Undated nodes
 * Use JC69 site model and Yule (Pure-Birth) speciation model

Do the same with `babette`
========================================================


```r
mcmc <- create_mcmc(chain_length = 100000)
count_canonical_topologies(
  bbt_run(
    "primates.fas",
    mcmc = mcmc
  )$primates_trees[51:100]
) # out of 5
```

```
[1] 34
```

2. Who lived when?
========================================================
![Densitree](densitree.png)
***
 * But when?
 * Assume a crown age of 17.58 Mya (from Purvis, 1995)

Demo
========================================================
Show how to:

 * View the dated posterior phylogenies
 * View the effective sample size

Demo pictures
========================================================
![Densitree dated](densitree_dated.png)
***
![Tracer dated](tracer_dated.png)

Conclusion
========================================================

 * We can now estimate the time humans and chimps diverged


```r
get_divergence_time <- function(tree) {
  human_index <- which(tree$tip.label == "human")
  chimp_index <- which(tree$tip.label == "chimp")
  ape::dist.nodes(tree)[human_index, chimp_index] / 2.0
}
get_divergence_times <- function(trees) {
  ts <- NULL
  for (tree in trees) {
    ts <- c(ts, get_divergence_time(tree))
  }
  ts
}
```

Conclusion
========================================================


```r
trees <- parse_beast_trees(
  "primates_dated.trees"
)[51:100]
mean(get_divergence_times(trees))
```

```
[1] 6.167756
```

Discussion
========================================================

 * Effective sample size is below the recommended 200
 * Use JC69 site model and Yule (Pure-Birth) speciation model

Do the same with `babette`
========================================================

Specify the crown age:


```r
mrca_distr <- create_normal_distr(
  mean = create_mean_param(value = 17.58),
  sigma = create_sigma_param(value = 0.01)
)
```

Specify an MRCA prior containing all species:


```r
mrca_prior <- create_mrca_prior(
  get_alignment_id("primates.fas"),
  taxa_names = get_taxa_names("primates.fas"),
  mrca_distr = mrca_distr,
  is_monophyletic = TRUE
)
```

Do the same with `babette`
========================================================


```r
mean(
  get_divergence_times(
    bbt_run(
      "primates.fas",
      mcmc = mcmc,
      mrca_priors = mrca_prior
    )$primates_trees[51:100]
  )
)
```

```
[1] 6.153677
```

3. Which model to use?
========================================================
![Nucleotide substitution rates](nucleotide_substitutions.gif)
***
Nucleotide substitution models:
 * JC69: all rates are the same
 * GTR: all rates can be different

But how to guard against overfitting?

Bayes' theorem
========================================================

```
            likelihood * prior
posterior = --------------------
            marginal likelihood
```

 * Marginal likelihood hard to calculate
 * BEAST2 circumvents to do so

Bayes factor
========================================================

```
     marginal likelihood model A
BF = ----------------------------
     marginal likelihood model B
```

 * Marginal likelihood is the likelihood of the data fitting the model
 * More complex models are penalized

Bayes factor interpretation
========================================================

K|Strength evidence
---|---
`0` to `10^0` | Negative
`10^0` to `10^0.5`|Barely worth mentioning
`10^0.5` to `10^1.0`|Substantial
`10^1.0` to `10^1.5`|Strong
`10^1.5` to `10^2.0`|Very strong
`10^2` and above|Decisive

Estimating a marginal likelihood
========================================================

![](maturana_et_al_2018.png)

Demo
========================================================

Show in BEAST2.

```
<run id="mcmc" spec="beast.gss.NS" chainLength="100000" particleCount="1" subChainLength="5000" epsilon="1e-12">
```

Demo figures
========================================================
![BEAST2 package manager](beast2_package_manager.png)
***
JC69:
![Marginal likelihood JC69](primates_mar_lik_jc69.png)
GTR:
![Marginal likelihood GTR](primates_mar_lik_gtr.png)

Conclusion
========================================================

```
     e ^ -1935
BF = ---------- = e ^ -125
     e ^ -1810
```

Decisive support for the GTR model!

Discussion
========================================================

 * Effective sample size is below the recommended 200
 * Nested sampling setup was also short
 * We only compare two models

Do the same with `babette`
========================================================

Setup the MCMC to use nested sampling:


```r
mcmc <- create_mcmc_nested_sampling(
  chain_length = 100000, sub_chain_length = 5000
)
```

Do the same with `babette`
========================================================

Run with JC69:


```r
ns_jc69 <- bbt_run(
  "primates.fas",
  site_models = create_jc69_site_model(),
  mcmc = mcmc,
  beast2_path = get_default_beast2_bin_path()
)$ns
```

Do the same with `babette`
========================================================

Run with GTR:


```r
ns_gtr <- bbt_run(
  "primates.fas",
  site_models = create_gtr_site_model(),
  mcmc = mcmc,
  beast2_path = get_default_beast2_bin_path()
)$ns
```

Do the same with `babette`
========================================================


```r
exp(ns_jc69$marg_log_lik - ns_gtr$marg_log_lik)
```

```
[1] 6.683701e-60
```

Overall conclusion
========================================================

 * BEAST2 offers a flexible framework to answer many questions
 * BEAST2 is beginner-friendly
 * `babette` provides for iterative usage

Questions?
========================================================

