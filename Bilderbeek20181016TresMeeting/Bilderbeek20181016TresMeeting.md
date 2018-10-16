Today's errors in Bayesian phylogenetics
========================================================
author: Richel J.C. Bilderbeek
date: 2018-10-17
autosize: true

[https://github.com/richelbilderbeek/Science](https://github.com/richelbilderbeek/Science)  ![CC-BY-NC-SA](CC-BY-NC-SA.png)

![RuG and GELIFES and TECE logo](footer.png)



Goal
========================================================

  * Introduction to Bayesian inference
  * Using `babette`
  * Describe my research

***
![babette logo](babette_logo.png)


Research questions
========================================================

![A primate cladogram](primate_cladogram_simplified_beast2.png)
***
 * Who lived when?
 * How complex should that calculation be?

![Garden of Eden](garden_of_eden.jpg)

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
![plot of chunk unnamed-chunk-3](Bilderbeek20181016TresMeeting-figure/unnamed-chunk-3-1.png)

Where do we go?
========================================================

![Densitree](densitree_dated.png)
***
 * A posterior: phylogenies and parameter estimates

![tracer](tracer_dated.png)

What tool could we use?
========================================================

 * BEAST2: Bayesian Evolutionary Analysis by Sampling Trees
 * Widely used
 * Easy to get started

![](beast2_logo.png)

***
![BEAST2 book](beast_book.jpg)

What tool do we use?
========================================================

![babette logo](babette_logo.png)
***
 * `babette`
 * Package to call BEAST2 from R
 * Completely automate pipeline


```r
library(babette)
```

Who lived when?
========================================================

 * Create a (too) short Markov chain Monte-Carlo:


```r
mcmc <- create_mcmc(chain_length = 100000)
```

Who lived when?
========================================================

 * Do the analysis


```r
trees <- bbt_run(
  "primates.fas",
  mcmc = mcmc
)$primates_trees[51:100] # out of 50
```

Who lived when?
========================================================

 * Visualize the results


```r
plot_densitree(
  trees,
  alpha = 0.1,
  width = 3,
  cex = 2
)
```

 * So when exactly?

***
![plot of chunk unnamed-chunk-8](Bilderbeek20181016TresMeeting-figure/unnamed-chunk-8-1.png)

Who lived when?
========================================================

 * Specify the crown age:


```r
mrca_distr <- create_normal_distr(
  mean = create_mean_param(value = 17.58),
  sigma = create_sigma_param(value = 0.01)
)
```

(from Purvis, 1995)

Who lived when?
========================================================

 * Specify an MRCA prior containing all species:


```r
mrca_prior <- create_mrca_prior(
  get_alignment_id("primates.fas"),
  taxa_names = get_taxa_names("primates.fas"),
  mrca_distr = mrca_distr,
  is_monophyletic = TRUE
)
```

Who lived when?
========================================================

 * Do the MCMC run


```r
trees <- bbt_run(
  "primates.fas",
  mcmc = mcmc,
  mrca_priors = mrca_prior
)$primates_trees[51:100]
```

Who lived when?
========================================================

 * Visualize the results


```r
plot_densitree(
  trees,
  alpha = 0.1,
  width = 3,
  cex = 2
)
```
`
***
![plot of chunk unnamed-chunk-13](Bilderbeek20181016TresMeeting-figure/unnamed-chunk-13-1.png)

How complex should that calculation be?
========================================================

![JC69](nucleotide_substitutions_no_annotation.png)
***
 * JC69 site model
 * Strict clock model
 * Constant-rate birth death


Constant-rate birth death
========================================================


```r
tree <- phytools::pbtree(
  b = 0.2,
  d = 0.1,
  n = 10,
  extant.only = TRUE
)
```


```r
ape::plot.phylo(
  tree,
  edge.width = 1,
  cex = 2
)
```
***
![plot of chunk unnamed-chunk-16](Bilderbeek20181016TresMeeting-figure/unnamed-chunk-16-1.png)

Constant-rate birth death
========================================================

 * Speciation is instantaneous

![](fenessy_nubian_giraffe.jpg)

From Fennessy et al., 2016

***

 * Speciation events are at different time


References
========================================================

 * Fennessy, Julian, et al. "Multi-locus analyses reveal four giraffe species instead of one." Current Biology 26.18 (2016): 2543-2549.