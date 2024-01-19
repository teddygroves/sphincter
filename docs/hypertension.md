# Hypertensive challenge

## Dependent variable

The raw data on hypertension challenge were correlation coefficients relating
blood pressure and vessel diameter, which are constrained to lie on the $[-1,
1]$ interval. For easier modelling we transformed these by applying an inverse
hyperbolic tangent function for use in modelling. The dependent variables then
had support on the entire real number line.

The resulting dataset is shown in figure @fig-hypertension-data. The transformed
correlation coefficients do not appear extremely dispersed, indicating that
standard modelling techniques ought to be able to describe them.

:::{#fig-hypertension-data}

![](../plots/hypertension-data.png)

:::

### Statistical model

Our final statistical model had the following form.

\begin{align}
\ln(y_{vtm}) &\sim N(\hat{y}_{vtm}, \sigma_v) \label{eq-hypertension-model} \\
\hat{y}_{vtm} &= \mu_a \nonumber \\
  &+ \alpha^{treatment}_{t} \nonumber \\
  &+ \alpha^{vesseltype}_{v} \nonumber \\
\alpha^{treatment}_t &\sim N(0, 0.5) \nonumber \\
\alpha^{vesseltype}_v &\sim N(0, \tau^{vesseltype}) \nonumber \\
\sigma_v &\sim HN(0, 0.5) \nonumber \\
\mu &\sim N(0, 0.5) \nonumber \\
\tau^{vesseltype} &\sim HN(0, 0.5) \nonumber
\end{align}

This model is different from the others in that we did not partially pool the
treatment effects, since there were only two of these in this case. We also
allowed the measurement error parameters $\sigma$ to vary according to vessel
type, since this improved model fit and predictive performance.

As in the other analyses, for investigation of interaction effects we fit
another model that extended our final model with a vessel type:treatment
interaction effect as follows:

\begin{align}
\hat{y}_{vtm} &= \mu_a \nonumber \\
  &+ \alpha^{treatment}_{t} \nonumber \\
  &+ \alpha^{vesseltype}_{v} \nonumber \\
  &+ \alpha^{vesseltype:treatment}_{vt} \nonumber \\
\alpha^{vesseltype:treatment}_v &\sim N(0, \tau^{vesseltype:treatment}) \nonumber \\
\tau^{vesseltype:treatment} &\sim HN(0, 0.5) \nonumber

\end{align}


## Results

@fig-hypertension-loo shows that, as in the other cases, including interaction
effects did not improve estimated predictive performance.

:::{#fig-hypertension-loo}

![](../plots/hypertension-loo.png)

Comparison of out-of-sample predictive performance of our hypertension models,
as measured by estimated leave-one-out expected log predictive density. The
two models have similar estimated performance, but the `hypertension-big` model
is clearly worse.

:::

@fig-hypertension-parameters shows the marginal distributions for the
non-hierarchical parameters in our final model.

:::{#fig-hypertension-parameters}

![](../plots/hypertension-parameters.png)

1%-99% posterior intervals for parameters in our final hypertension model.

:::

@fig-hypertension-predictions shows graphical prior and posterior predictive
checks for our final hypertension model. The fit is fairly good, with no obvious
systematic pattern in the errors, though slightly more observations lie outside
the plotted intervals than might be expected.

:::{#fig-hypertension-predictions}

![](../plots/hypertension-prior-predictive.png)

![](../plots/hypertension-posterior-predictive.png)

:::
