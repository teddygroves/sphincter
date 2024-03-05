# Introduction

This project aimed to model brain blood vessel measurements of mice during a
treatment protocol designed to elicit stress responses. 

Measurements included:

- Whisker stimulation response (vessel diameter before and after stimulation)
- Vessel centre and diameter pulsatility 
- Red blood cell flow (i.e. speed and flux)
- Hypertensive challenge response (Correlation between blood pressure and
diameter under different pressure conditions)
- Capillary density

We believed that the mechanisms underlying each kind of measurement were
independent, and moreover each measurement required different data filtering
choices. We therefore conducted a separate analysis for each measurement type.

Our overall modelling approach broadly followed the recommendations in
@gelmanBayesianWorkflow2020. For each analysis, we first constructed a simple
mathematical model of the data generating process, then iteratively improved
it, taking into account estimated predictive performance in and out of sample,
simplicity, interpretability and computational feasibility.

We decided to employ a Bayesian modelling approach primarily because of
the availability of non-experimental information, particularly structural
information concerning the data making it important to partially pool
information between categories given the relatively small number of
measurements. In a Bayesian context partial pooling can be achieved using
a prior distribution on the random effects. The capillary density dataset
also benefitted from a Bayesian approach, as this made it straightforward to
implement smoothing of adjacent capillary orders.

After verification of computational results, our analyses aimed to evaluate
whether each of our models adequately captured the information contained in the
available data and information, and then to interpret and present the results of
the best models.
