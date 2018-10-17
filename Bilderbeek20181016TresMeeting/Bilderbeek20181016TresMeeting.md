Today's errors in Bayesian phylogenetics
========================================================
author: Richel J.C. Bilderbeek
date: 2018-10-17
autosize: true

[https://github.com/richelbilderbeek/Science](https://github.com/richelbilderbeek/Science)  ![CC-BY-NC-SA](CC-BY-NC-SA.png)

![RuG and GELIFES and TECE logo](footer.png)



A theoretician's dream
========================================================

![](Hopetoun_falls.jpg)



Goal
========================================================

  * What Bayesian phylogenetics is
  * What is the error we make today?

***
![babette logo](babette_logo.png)


Research questions
========================================================

![A primate cladogram](primate_cladogram_simplified_beast2.png)
***
 * Who lived when?
 * How complex should that calculation be?

What do we have?
========================================================


```r
fasta_filename <- "primates.fas"
alignment <- read.FASTA(
  fasta_filename
)
```

```r
image(alignment)
```
***
![plot of chunk unnamed-chunk-4](Bilderbeek20181016TresMeeting-figure/unnamed-chunk-4-1.png)

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

 * So when exactly?

***
![plot of chunk unnamed-chunk-9](Bilderbeek20181016TresMeeting-figure/unnamed-chunk-9-1.png)

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
![plot of chunk unnamed-chunk-14](Bilderbeek20181016TresMeeting-figure/unnamed-chunk-14-1.png)

How complex should that calculation be?
========================================================

![JC69](nucleotide_substitutions_no_annotation.png)
***
 * JC69 site model
 * Strict clock model
 * Constant-rate birth death tree model


Constant-rate birth death
========================================================


```r
tree <- pbtree(
  b = 0.2,
  d = 0.1,
  n = 10,
  extant.only = TRUE
)
```


```r
plot.phylo(
  tree,
  edge.width = 1,
  cex = 2
)
```
***
![plot of chunk unnamed-chunk-17](Bilderbeek20181016TresMeeting-figure/unnamed-chunk-17-1.png)

Constant-rate birth death assumptions
========================================================

 * Instantaneous speciation  (Fennessy et al., 2016)

![](fenessy_nubian_giraffe.jpg)


***

 * No co-occurence of speciation

![](fishes_in_lake.png)

Speciation takes time
========================================================




```r
pbd_tree <- bco_pbd_sim(
  create_pbd_params(
    erg = 0.2,
    eri = 0.2,
    scr = 0.01,
    sirg = 1.0,
    siri = 1.0
  ),
  crown_age = 2.0
)$igtree.extant
```

***

![plot of chunk unnamed-chunk-20](Bilderbeek20181016TresMeeting-figure/unnamed-chunk-20-1.png)

Speciation can co-occur
========================================================




```r
mbd_tree <- bco_mbd_sim(
  create_mbd_params(
    mu = 0.1,
    lambda = 0.1,
    nu = 1.0,
    q = 0.5
  ),
  crown_age = 2.0
)$tes
```

***

![plot of chunk unnamed-chunk-23](Bilderbeek20181016TresMeeting-figure/unnamed-chunk-23-1.png)

How to measure the error?
========================================================

 1. Create true tree
 2. Create DNA alignment
 3. Do Bayesian inference
 4. Compare posterior trees with true tree
 5. Does that error matter?


1. Create true tree
========================================================


```r
true_tree <- mbd_tree
```

```r
plot.phylo(true_tree)
```
***
![plot of chunk unnamed-chunk-26](Bilderbeek20181016TresMeeting-figure/unnamed-chunk-26-1.png)

2. Create DNA alignment
========================================================


```r
alignment <- sim_alignment(
  true_tree,
  sequence_length = 100,
  mutation_rate = 0.2
)
write.FASTA(alignment, "alignment.fas")
```


```r
image(alignment)
```
***
![plot of chunk unnamed-chunk-29](Bilderbeek20181016TresMeeting-figure/unnamed-chunk-29-1.png)

3. Do Bayesian inference
========================================================


```r
trees <- bbt_run("alignment.fas", mcmc = mcmc)$alignment_trees[51:100]
```


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
![plot of chunk unnamed-chunk-32](Bilderbeek20181016TresMeeting-figure/unnamed-chunk-32-1.png)

4. Compare posterior trees with true tree
========================================================


```r
plot_densitree(
  c(true_tree, trees[[1]]),
  alpha = 1.0,
  scaleX = TRUE,
  width = c(6, 4),
  cex = 2,
  col = c("black", "red")
)
```
***
![plot of chunk unnamed-chunk-34](Bilderbeek20181016TresMeeting-figure/unnamed-chunk-34-1.png)

4. Compare posterior trees with true tree
========================================================


```r
nltt_plot(true_tree)
nltt_lines(trees[[1]], col = "red")
```

 * nLTT statistic: area between the lines

***
![plot of chunk unnamed-chunk-36](Bilderbeek20181016TresMeeting-figure/unnamed-chunk-36-1.png)


4. Compare posterior trees with true tree
========================================================


```r
nltts <- nLTT::nltts_diff(true_tree, trees)
```


```r
ggplot(
  data = data.frame(error = nltts),
  aes(x = error)
) + geom_histogram()
```
***
![plot of chunk unnamed-chunk-39](Bilderbeek20181016TresMeeting-figure/unnamed-chunk-39-1.png)

5. Does that error matter?
========================================================

![](garden_of_eden.jpg)

***

 * Background noise
 * Do parameters actually occur?

Summary
========================================================

 * Bayesian phylogenetics can seem easy
 * `babette` answers the core of a research question
 * ... but the details matter

Questions?
========================================================

[https://github.com/richelbilderbeek/Science](https://github.com/richelbilderbeek/Science)  ![CC-BY-NC-SA](CC-BY-NC-SA.png)

References
========================================================

 * Fennessy, Julian, et al. "Multi-locus analyses reveal four giraffe species instead of one." Current Biology 26.18 (2016): 2543-2549.
