# Overall strategy

Although our project involved several statistical analyses, we used a similar
overall strategy in each case. This section describes the aspects of this
strategy that were common to all of our analyses.

## Features

Several of our analyses involved a common data structure, with real-valued
measurements each with multiple categorical features, namely

- age of the measured mouse (adult or young)
- identity of the measured mouse
- stage of the treatment protocol when measured
- measured vessel type (penetrating artery, sphincter, bulb, first order capilary, etc)

## Data processing

We ignored data from one mouse (id 310321) that was determined to be an outlier.
310321 is a mouse where we did not see any whisker response, it reacted to
angiotensin II, but the BP increase was abrupted for a short while and then
re-established. Perhaps due to a clot or a bubble in the venous catheter. This
resulted in a biphasic and slow BP increase.

In all of our analyses we assumed that any missing measurements were caused by
factors that were unrelated to our main target process, or in other words that
the absent measurements were "missing at random". We therefore did not attempt
to model the measurement removal process explicitly.

## Modelling approach

All of our models had a common structure, with generalised linear models used
to describe information from measurements and multi-level prior distributions
used to describe non-experimental information. The modelling choices open to
us concerned the following questions:

1. What generalised linear model to use to model measurements? 

2. Which interaction effects to estimate?

3. What structure to use for the prior model, and in particular how and to what
extent to pool information between categories?

4. What quantitative values to use for our prior model? 

5. In cases where a phenomenon of interest was assessed using multiple,
potentially related measurements, whether to model the possible relatedness?

In order to answer these questions for each analysis, we started with a
simple but plausible model, then iteratively added and removed components
as described in @gelmanBayesianWorkflow2020. Our general aim was to
achieve a better quantitative and qualitative description of the data
generating process while avoiding computational issues. In particular,
we focused on the estimated out of sample predictive performance as
measured by the estimated leave-one-observation-out log predictive density
[@vehtariPracticalBayesianModel2017] and qualitative agreement between
predictive and observed observations in graphical checks.

In order to implement graphical predictive checking, we calculated quantiles
of our models' prior and posterior predictive distributions and plotted these
alongside the measurements. We then inspected the graphs to ascertain whether
the measurements were generally consistent with the predictions.

We calculated estimated leave-one-observation-out log predictive desities using the Python package arviz [@kumarArviZUnifiedLibrary2019]. 

## Software

The raw data are found in csv files which are available from our project's
github repository at the following urls:

- <https://github.com/teddygroves/sphincter/blob/main/data/raw/hyper_challenge.csv>
- <https://github.com/teddygroves/sphincter/blob/main/data/raw/data_sphincter_paper.csv>

For each analysis, we conducted filtering and reshaping operations using the
standard scientific Python stack and validated the resulting prepared datasets
against custom data models constructed using the Python libraries pydantic
[@pydanticdevelopersPydantic2022] and pandera [@niels_bantilan-proc-scipy-2020].
These models can be inspected at this url: <https://github.com/teddygroves/sphincter/blob/main/sphincter/data_preparation.py>.

Statistical computation was carried out using the probabilistic programming
framework Stan [@carpenterStanProbabilisticProgramming2017] via the interface
cmdstanpy [@standevelopmentteamCmdStanPy2022].

Analysis and serialisation of posterior samples was carried out using the
Bayesian inference library arviz [@kumarArviZUnifiedLibrary2019].

Our analysis was orchestrated by the Python package bibat
[@bibat].

## Validation of statistical computation

We validated our statistical computation using standard Hamiltonian
Monte Carlo diagnostics, including the improved $\hat{R}$ statistic
[@vehtariRankNormalizationFoldingLocalization2021] as well as inspection for
post-warmup divergent transitions [@betancourtDiagnosingBiasedInference2017],
problematic EBFI statistics, tree depth or effective sample size to total
sample size ratios. All reported models had improved $\hat{R}$ close to 1 and no
divergent transitions or other signs of algorithm failure.

## Reports of findings

In general the findings we report were cases where our best performing model's
posterior probability distribution gave a high probability to an interesting
and interpretable quantity having an interesting value. Since most of the
interpretable parameters in our models are normalised so that zero indicates
no effect, in practice our main findings are mostly that a parameter, or the
difference between some parameters, is likely to be substantially different
from zero according to our best model's posterior distribution. We present
results with this form using histograms of the relevant marginal posterior
distributions.

## Reproducibility

See the repository readme for instructions on reproducing our analysis: <https://github.com/teddygroves/sphincter/blob/main/README.md>
