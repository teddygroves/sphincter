---
title: Statistical modelling section
format:
  html: default
  docx: default
bibliography: bibliography.bib
---

# Statistical modelling

Multilevel generalized linear models (GLMs) provide a powerful framework for modelling structured data [@brown2014applied],[@vonesh2006mixed], and are a natural fit for analysing the current data given the many important sources of heterogeneity like mouse, vessel type, vessel, treatment etc. 

Bayesian multilevel GLMs allow information about latent parameters to be encoded using prior distributions, thereby conferring a number of advantages over non-Bayesian approaches including regularization, computational tractability and model identification among others [@fongBayesianInferenceGeneralized2010]. Bayesian multilevel GLMs have successfully been applied to many similar problems [@cobigoDetectionEmergingNeurodegeneration2022],[@sorensenBayesianLinearMixed2016],[@wangPredictingMultidomainProgression2017].

This analysis presents a range of Bayesian multilevel GLMs, which are structurally similar but differ in their measurement distributions, parameter dependencies and prior distributions. These differences arose organically: in each case we started with a simple, naive model of the target measurement type, then iteratively added and removed components as described in [@gelmanBayesianWorkflow2020]. Our aim was to achieve the best possible quantitative and qualitative description of the underlying data generating process while avoiding computational issues. 

Following standard practice for Bayesian statistics [@gelmanBayesianDataAnalysis2020a, Ch. 1] we based all our model evaluations and conclusions on integrals over our models’ posterior distributions, which we estimated using adaptive Hamiltonian Monte Carlo via Stan [@carpenterStanProbabilisticProgramming2017]. 

To assess how well our models described their target data generating processes, we evaluated their out of sample predictive performance using expected leave-one-observation-out log predictive density [@vehtariPracticalBayesianModel2017]. We complemented this quantitative evaluation with a qualitative assessment of agreement between our models’ posterior predictive distributions and the observed measurements based on graphical checks.

When we were satisfied with a model, we extracted conclusions from it by specifying a meaningful test statistic in terms of model parameters and examining the marginal posterior distribution of that statistic. For example, to evaluate the impact of a treatment on measurements of a vessel’s diameter, we could choose as a test statistic the difference in expected diameter between two otherwise similar mice, one treated and the other untreated. If the marginal posterior distribution of this statistic concentrates above zero, we conclude that our model indicates a positive effect. If the marginal posterior distribution concentrates around a certain value, we conclude that the model indicates an effect of around that size. While we generally present these results directly, for summaries we sometimes interpreted thresholds of 95% or 99% posterior mass as signifying qualitative certainty in a quantity being above or below zero.

Note that our method is different from the approach of identifying effects based on the results of null hypothesis significance testing. See [@kruschkejohnk.DoingBayesianData2015, Ch. 11] for a detailed description of the differences between these two methods. In particular, our approach does not involve null models or hypothetical unrealized datasets: the primary questions are simply whether each model adequately describes the actually realized data and, if so, what the model says.

