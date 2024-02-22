// Some definitions presupposed by pandoc's typst output.
#let blockquote(body) = [
  #set text( size: 0.92em )
  #block(inset: (left: 1.5em, top: 0.2em, bottom: 0.2em))[#body]
]

#let horizontalrule = [
  #line(start: (25%,0%), end: (75%,0%))
]

#let endnote(num, contents) = [
  #stack(dir: ltr, spacing: 3pt, super[#num], contents)
]

#show terms: it => {
  it.children
    .map(child => [
      #strong[#child.term]
      #block(inset: (left: 1.5em, top: -0.4em))[#child.description]
      ])
    .join()
}

// Some quarto-specific definitions.

#show raw.where(block: true): block.with(
    fill: luma(230), 
    width: 100%, 
    inset: 8pt, 
    radius: 2pt
  )

#let block_with_new_content(old_block, new_content) = {
  let d = (:)
  let fields = old_block.fields()
  fields.remove("body")
  if fields.at("below", default: none) != none {
    // TODO: this is a hack because below is a "synthesized element"
    // according to the experts in the typst discord...
    fields.below = fields.below.amount
  }
  return block.with(..fields)(new_content)
}

#let empty(v) = {
  if type(v) == "string" {
    // two dollar signs here because we're technically inside
    // a Pandoc template :grimace:
    v.matches(regex("^\\s*$")).at(0, default: none) != none
  } else if type(v) == "content" {
    if v.at("text", default: none) != none {
      return empty(v.text)
    }
    for child in v.at("children", default: ()) {
      if not empty(child) {
        return false
      }
    }
    return true
  }

}

#show figure: it => {
  if type(it.kind) != "string" {
    return it
  }
  let kind_match = it.kind.matches(regex("^quarto-callout-(.*)")).at(0, default: none)
  if kind_match == none {
    return it
  }
  let kind = kind_match.captures.at(0, default: "other")
  kind = upper(kind.first()) + kind.slice(1)
  // now we pull apart the callout and reassemble it with the crossref name and counter

  // when we cleanup pandoc's emitted code to avoid spaces this will have to change
  let old_callout = it.body.children.at(1).body.children.at(1)
  let old_title_block = old_callout.body.children.at(0)
  let old_title = old_title_block.body.body.children.at(2)

  // TODO use custom separator if available
  let new_title = if empty(old_title) {
    [#kind #it.counter.display()]
  } else {
    [#kind #it.counter.display(): #old_title]
  }

  let new_title_block = block_with_new_content(
    old_title_block, 
    block_with_new_content(
      old_title_block.body, 
      old_title_block.body.body.children.at(0) +
      old_title_block.body.body.children.at(1) +
      new_title))

  block_with_new_content(old_callout,
    new_title_block +
    old_callout.body.children.at(1))
}

#show ref: it => locate(loc => {
  let target = query(it.target, loc).first()
  if it.at("supplement", default: none) == none {
    it
    return
  }

  let sup = it.supplement.text.matches(regex("^45127368-afa1-446a-820f-fc64c546b2c5%(.*)")).at(0, default: none)
  if sup != none {
    let parent_id = sup.captures.first()
    let parent_figure = query(label(parent_id), loc).first()
    let parent_location = parent_figure.location()

    let counters = numbering(
      parent_figure.at("numbering"), 
      ..parent_figure.at("counter").at(parent_location))
      
    let subcounter = numbering(
      target.at("numbering"),
      ..target.at("counter").at(target.location()))
    
    // NOTE there's a nonbreaking space in the block below
    link(target.location(), [#parent_figure.at("supplement") #counters#subcounter])
  } else {
    it
  }
})

// 2023-10-09: #fa-icon("fa-info") is not working, so we'll eval "#fa-info()" instead
#let callout(body: [], title: "Callout", background_color: rgb("#dddddd"), icon: none, icon_color: black) = {
  block(
    breakable: false, 
    fill: background_color, 
    stroke: (paint: icon_color, thickness: 0.5pt, cap: "round"), 
    width: 100%, 
    radius: 2pt,
    block(
      inset: 1pt,
      width: 100%, 
      below: 0pt, 
      block(
        fill: background_color, 
        width: 100%, 
        inset: 8pt)[#text(icon_color, weight: 900)[#icon] #title]) +
      block(
        inset: 1pt, 
        width: 100%, 
        block(fill: white, width: 100%, inset: 8pt, body)))
}



#let article(
  title: none,
  authors: none,
  date: none,
  abstract: none,
  cols: 1,
  margin: (x: 1.25in, y: 1.25in),
  paper: "us-letter",
  lang: "en",
  region: "US",
  font: (),
  fontsize: 11pt,
  sectionnumbering: none,
  toc: false,
  toc_title: none,
  toc_depth: none,
  doc,
) = {
  set page(
    paper: paper,
    margin: margin,
    numbering: "1",
  )
  set par(justify: true)
  set text(lang: lang,
           region: region,
           font: font,
           size: fontsize)
  set heading(numbering: sectionnumbering)

  if title != none {
    align(center)[#block(inset: 2em)[
      #text(weight: "bold", size: 1.5em)[#title]
    ]]
  }

  if authors != none {
    let count = authors.len()
    let ncols = calc.min(count, 3)
    grid(
      columns: (1fr,) * ncols,
      row-gutter: 1.5em,
      ..authors.map(author =>
          align(center)[
            #author.name \
            #author.affiliation \
            #author.email
          ]
      )
    )
  }

  if date != none {
    align(center)[#block(inset: 1em)[
      #date
    ]]
  }

  if abstract != none {
    block(inset: 2em)[
    #text(weight: "semibold")[Abstract] #h(1em) #abstract
    ]
  }

  if toc {
    let title = if toc_title == none {
      auto
    } else {
      toc_title
    }
    block(above: 0em, below: 2em)[
    #outline(
      title: toc_title,
      depth: toc_depth
    );
    ]
  }

  if cols == 1 {
    doc
  } else {
    columns(cols, doc)
  }
}
#show: doc => article(
  title: [Sphincter analysis],
  authors: (
    ( name: [Teddy Groves],
      affiliation: [],
      email: [] ),
    ),
  toc: true,
  toc_title: [Table of contents],
  toc_depth: 3,
  cols: 1,
  doc,
)


= Introduction
<introduction>
This project aimed to model brain blood vessel measurements of mice during a treatment protocol designed to elicit stress responses.

Measurements included:

- Whisker stimulation response \(vessel diameter before and after stimulation)
- Vessel centre and diameter pulsatility
- Red blood cell flow \(i.e.~speed and flux)
- Hypertensive challenge response \(Correlation between blood pressure and diameter under different pressure conditions)

We believed that the mechanisms underlying each kind of measurement were independent, and moreover each measurement required different data filtering choices. We therefore conducted a separate analysis for each measurement type.

Our overall modelling approach broadly followed the recommendations in #cite(<gelmanBayesianWorkflow2020>);. For each analysis, we first constructed a simple mathematical model of the data generating process, then iteratively improved it, taking into account estimated predictive performance in and out of sample, simplicity, interpretability and computational feasibility.

We decided to employ a Bayesian modelling approach primarily because of the availability of non-experimental information, particularly structural information concerning the data making it important to take into partially pool information between categories given the relatively small number of measurements. In a Bayesian context partial pooling can be achieved using a prior distribution on the random effects.

= Overall strategy
<overall-strategy>
Although our project involved several statistical analyses, we used a similar overall strategy in each case. This section describes the aspects of this strategy that were common to all of our analyses.

== Features
<features>
All of our analyses involved a common data structure, with real-valued measurements each with multiple categorical features, namely

- age of the measured mouse \(adult or young)
- identity of the measured mouse
- stage of the treatment protocol when measured
- measured vessel type \(penetrating artery, sphincter, bulb, first order capilary, etc)

== Data processing
<data-processing>
We ignored data from one mouse \(id 310321) that was determined to be an outlier. 310321 is a mouse where we did not see any whisker response, it reacted to angiotensin II, but the BP increase was abrupted for a short while and then re-established. Perhaps due to a clot or a bubble in the venous catheter. This resulted in a biphasic and slow BP increase.

In all of our analyses we assumed that any missing measurements were caused by factors that were unrelated to our main target process, or in other words that the absent measurements were "missing at random". We therefore did not attempt to model the measurement removal process explicitly.

== Modelling approach
<modelling-approach>
All of our models had a common structure, with generalised linear models used to describe information from measurements and multi-level prior distributions used to describe non-experimental information. The modelling choices open to us concerned the following questions:

+ What generalised linear model to use to model measurements?

+ Which interaction effects to estimate?

+ What structure to use for the prior model, and in particular how and to what extent to pool information between categories?

+ What quantitative values to use for our prior model?

+ In cases where a phenomenon of interest was assessed using multiple, potentially related measurements, whether to model the possible relatedness?

In order to answer these questions for each analysis, we started with a simple but plausible model, then iteratively added and removed components as described in #cite(<gelmanBayesianWorkflow2020>);. Our general aim was to achieve a better quantitative and qualitative description of the data generating process while avoiding computational issues. In particular, we focused on the estimated out of sample predictive performance as measured by the estimated leave-one-observation-out log predictive density #cite(<vehtariPracticalBayesianModel2017>) and qualitative agreement between predictive and observed observations in graphical checks.

We address these questions below for each analysis in its corresponding section, providing model comparisons and illustrative results where appropriate.

== Software
<software>
The raw data are found in csv files which are available from our project’s github repository at the following urls:

- #link("https://github.com/teddygroves/sphincter/blob/main/data/raw/hyper_challenge.csv")
- #link("https://github.com/teddygroves/sphincter/blob/main/data/raw/data_sphincter_paper.csv")

For each analysis, we conducted filtering and reshaping operations using the standard scientific Python stack and validated the resulting prepared datasets against custom data models constructed using the Python libraries pydantic #cite(<pydanticdevelopersPydantic2022>) and pandera #cite(<niels_bantilan-proc-scipy-2020>);. These models can be inspected at this url: #link("https://github.com/teddygroves/sphincter/blob/main/sphincter/data_preparation.py");.

Statistical computation was carried out using the probabilistic programming framework Stan #cite(<carpenterStanProbabilisticProgramming2017>) via the interface cmdstanpy #cite(<standevelopmentteamCmdStanPy2022>);.

Analysis and serialisation of posterior samples was carried out using the Bayesian inference library arviz #cite(<kumarArviZUnifiedLibrary2019>);.

Our analysis was orchestrated by the Python package bibat #cite(<bibat>);.

== Validation of statistical computation
<validation-of-statistical-computation>
We validated our statistical computation using standard Hamiltonian Monte Carlo diagnostics, including the improved $hat(R)$ statistic #cite(<vehtariRankNormalizationFoldingLocalization2021>) as well as inspection for post-warmup divergent transitions #cite(<betancourtDiagnosingBiasedInference2017>);, problematic EBFI statistics, tree depth or effective sample size to total sample size ratios. All reported models had improved $hat(R)$ close to 1 and no divergent transitions or other signs of algorithm failure.

== Reproducibility
<reproducibility>
See the repository readme for instructions on reproducing our analysis: #link("https://github.com/teddygroves/sphincter/blob/main/README.md")

= Main findings
<main-findings>
== Whisker stimulation
<whisker-stimulation>
Our analysis of whisker stimulation data indicates that the hypertension and sphincter ablation treatments are associated with lower whisker stimulation response, as measured by log diameter change, compared with the baseline treatment. The effect from whisker stimulation is greater than from hypertension.

Figure @fig-whisker-treatment-effects illustrates this finding by showing the distribution of posterior samples for treatment effects relative to baseline from our best whisker stimulation model.

#figure([
#block[
#grid(columns: 1, gutter: 2em,
)
]
], caption: figure.caption(
position: bottom, 
[
Marginal posterior histograms for treatment effects, relative to the baseline treatment.
]), 
kind: "quarto-float-fig", 
supplement: "Figure", 
)
<fig-whisker-treatment-effects>


Our analysis did not indicate any substantial difference between old and adult mice, or any noticeable vessel type:treatment interaction effects. This can be seen from figure @fig-whisker-small-effects, which shows posterior quantiles for age and vessel type:treatment interaction effects in our model that included both of these.

#figure([
#block[
#grid(columns: 1, gutter: 2em,
)
]
], caption: figure.caption(
position: bottom, 
[
Marginal 2.5%-97.5% posterior intervals for protocol effects
]), 
kind: "quarto-float-fig", 
supplement: "Figure", 
)
<fig-whisker-small-effects>


We found some difference between vessel type effects: sphincters had the greatest relative diameter change in response to whisker stimulation, and bulbs the smallest. Figure @fig-whisker-vessel-type-effects shows these.

#figure([
#block[
#grid(columns: 1, gutter: 2em,
)
]
], caption: figure.caption(
position: bottom, 
[
Marginal 2.5%-97.5% posterior intervals for vessel type effects
]), 
kind: "quarto-float-fig", 
supplement: "Figure", 
)
<fig-whisker-vessel-type-effects>


== Pulsatility
<pulsatility>
Our analysis of vessel centre and diameter pulsatility yielded the following conclusions:

- Adult mice have higher vessel diameter pulsatility than old mice, whereas old mice have slightly higher centre pulsatility.

- Sphincter ablation correlates with increased diameter pulsatility, with no strong interaction effects. On the other hand there is no clear effect of sphincter ablation on centre pulsatility.

@fig-pulsatility-age-effects plots the distribution of age effect differences \(adult minus old) for each measurement type in our final model. This graph shows that, in this model, the age effect for adult mice was higher than for old mice in every single posterior sample: in other words there is a clear trend for older mice to have lower diameter pulsatility. There is a smaller opposite trend for centre pulsatility measurements, but it is not clearly separated from zero, indicating that the direction of the effect is not fully settled.

#figure([
#box(width: 717.0909090909091pt, image("../plots/pulsatility-age-effects.png"))
], caption: figure.caption(
position: bottom, 
[
Posterior distribution of age effect differences for each measurement type.
]), 
kind: "quarto-float-fig", 
supplement: "Figure", 
numbering: "1", 
)
<fig-pulsatility-age-effects>


@fig-pulsatility-treatment-effects shows the distribution of posterior draws for sphincter ablation effects compared with the immediately prior protocol stage \("after hypertension"). The ablation/diameter parameter is greater than the after hypertension/diameter parameter in 98% of posterior samples, whereas there is no clear effect on centre pulsatility.

#figure([
#box(width: 717.0909090909091pt, image("../plots/pulsatility-treatment-effects.png"))
], caption: figure.caption(
position: bottom, 
[
Posterior distribution of treatment effect differences for each measurement type.
]), 
kind: "quarto-float-fig", 
supplement: "Figure", 
numbering: "1", 
)
<fig-pulsatility-treatment-effects>


== Red blood cell flow
<red-blood-cell-flow>
Our main result regarding red blood cell flow is that both RBC speed and flux tend to be higher in adult mice compared with old mice. Figure @fig-flow-age-effects illustrates this finding by plotting the relevant marginal posterior histograms.

#figure([
#box(width: 900.3636363636364pt, image("../plots/flow-age-effects.png"))
], caption: figure.caption(
position: bottom, 
[
Posterior distributions of age effects on red blood cell speed and flux.
]), 
kind: "quarto-float-fig", 
supplement: "Figure", 
numbering: "1", 
)
<fig-flow-age-effects>


We also quantified treatment effects on red blood cell flow, as shown in @fig-flow-treatment-effects:

#figure([
#box(width: 900.3636363636364pt, image("../plots/flow-treatment-effects.png"))
], caption: figure.caption(
position: bottom, 
[
Posterior distributions of treatment effects on red blood cell speed and flux. The nearest baseline for treatment `hyper` is `baseline`, and for treatments `after_ablation` and `hyper2` it is `after_hyper`.
]), 
kind: "quarto-float-fig", 
supplement: "Figure", 
numbering: "1", 
)
<fig-flow-treatment-effects>


== Hypertensive challenge
<hypertensive-challenge>
Our hypertensive challenge data also showed pronounced age and treatment differences, as shown in figure @fig-hypertension-effects. Specifically, we found that, for adult mice, blood pressure and vessel diameter tended to be less correlated, and that the `hyper2` treatment tended to increase pressure-diameter correlation compared with the `hyper1` treatment.

#figure([
#box(width: 736.0pt, image("../plots/hypertension-age-and-treatment.png"))
], caption: figure.caption(
position: bottom, 
[
Posterior distributions of relative age and treatment effects for hypertensive challenge data.
]), 
kind: "quarto-float-fig", 
supplement: "Figure", 
numbering: "1", 
)
<fig-hypertension-effects>


== Vessel density
<vessel-density>
The vessel density dataset had a somewhat different structure to the other data, with no treatments, more vessel types, with clear correlation between measurements corresponding to adjacent vessel types. We therefore used a different statistical approach, with smoothing components for parameters of adjacent vessel types. See REF for more about this model.

Our analysis indicated that the old mice tended to have lower density than the adult mice for capillaries of order 1 to 3 and higher density for capillaries of order 9 to 12, and for ascending venules, as shown in figure @fig-density-effects.

#figure([
#box(width: 516.3636363636364pt, image("../plots/density-effects.png"))
], caption: figure.caption(
position: bottom, 
[
Posterior distributions of differences in age-dependent parameters by vessel type.
]), 
kind: "quarto-float-fig", 
supplement: "Figure", 
numbering: "1", 
)
<fig-density-effects>


= Details of the whisker stimulation analysis
<details-of-the-whisker-stimulation-analysis>
In order to measure how vascular responsiveness changed during our experimental protocol, the diameters of different vessel types were recorded before and during whisker stimulation, at baseline, post-hypertension and post-ablation stages. We aimed to assess statistical relationships between the known factors and the relative change in vessel diameter before and after stimulation.

In particular, we were interested in differences between old and adult mice and in the effect of sphincter ablation.

== Dependent variable
<dependent-variable>
The ratio of the peak compared with the pre-stimulation level for each mouse at each stage, on natural logarithmic scale, also known as the 'log change', was standardised by subtracting the overall mean and dividing by the standard deviation, then treated as a single measurement. This way of the measurements was chosen to facilitate modelling, as log change is a symmetric and additive measure of relative change \(see #cite(<tornqvistHowShouldRelative1985>);).

Note that when the difference between the two values $v 1$ and $v 2$ is far less than 1, the log change $ln frac(v 2, v 1)$ is approximately the same as the more widely used relative difference measure $frac(v 2 - v 1, v 1)$.

== Statistical Models
<statistical-models>
The final model is shown below:

In equation , the term $S T$ indicates the student t distribution, $N$ indicates the normal distribution, $G a m m a$ the gamma distribution and $H N$ the 'half-normal' distribution, i.e.~the normal distribution with support only for non-negative numbers. Subscripts indicate indexes and superscripts indicate parameter labels.

This model has independent effects for treatments \($alpha^(t r e a t m e n t)$), vessel types \($alpha^(v e s s e l)$) and age \($mu$). The treatment and vessel type effects have hierarchical priors, reflecting the need to partially pool information between different treatment and vessel type categories. This structure allows our model to accommodate the full spectrum between different categories being highly heterogenous—in this case the corresponding $tau$ parameter will be large—and on the other hand high similarity, leading to small $tau$ parameters. The student t distribution was chosen to reflect the heavy tails we observed in the data, with the parameter $nu$ controlling the level of heaviness.

The prior standard deviation 0.7 was chosen because it led to what we judged to be a reasonable allocation of prior probability mass over possible data realisations. The prior for the student t degrees of freedom parameter $nu$ was set following the recommendation in #cite(<juarezModelBasedClusteringNonGaussian2010>);.

As well as this model, we also present results from a more complex model that adds vessel type:treatment and age:treatment interaction effects. The full specification of this "big" model is as follows, using the same notation as equation :

== Results
<results>
@fig-whisker-measurements shows the observed log change measurements with colours illustrating the various categorical information. Note that the measurements have different dispersion depending on the treatment, indicating a the need for a model with distributional effects.

#figure([
#block[
#grid(columns: 1, gutter: 2em,
)
]
], caption: figure.caption(
position: bottom, 
[
Raw measurements
]), 
kind: "quarto-float-fig", 
supplement: "Figure", 
)
<fig-whisker-measurements>


@fig-whisker-posterior-check compares the measurements with our model’s posterior predictive distribution. This shows that our model achieved a reasonable fit to the observed data. There is a pattern in the model’s bad predictions, in that these tend to be for higher baseline measurements. However, we judged that this pattern was small enough that for our purposes we could disregard it.

#figure([
#block[
#grid(columns: 1, gutter: 2em,
)
]
], caption: figure.caption(
position: bottom, 
[
Graphical posterior predictive check
]), 
kind: "quarto-float-fig", 
supplement: "Figure", 
)
<fig-whisker-posterior-check>


To back up our finding that there were no important interaction effects, we compared the predictive performance of our final model `whisker-ind` with `whisker-big`, the best-performing model with more interactions. The results are shown below in figure @fig-whisker-loo-compare:

#figure([
#block[
#grid(columns: 1, gutter: 2em,
)
]
], caption: figure.caption(
position: bottom, 
[
Comparison of estimated leave-one-oout log predictive density between the final model `whisker-ind` and the best performing interaction model `whisker-big`.
]), 
kind: "quarto-float-fig", 
supplement: "Figure", 
)
<fig-whisker-loo-compare>


The two models have similar estimated predictive performance, indicating that there is no gain from considering interaction effects in this case.

= Details of the pulsatility analysis
<details-of-the-pulsatility-analysis>
The pulsatility data consisted of fast measurements of diameter and center point for the same mice. These measurements were Fourier-transformed, and the harmonics of the transformed data were interpreted as representing the pulsatility of the measured quantities.

== Dependent variable
<dependent-variable-1>
We used the first harmonic of each transformed time series as a dependent variable. It might have been preferable to aggregate all the available power harmonics, but this would have complicated our measurement model, and in any case power at the subsequent harmonics was typically negligible compared with the first.

== Questions
<questions>
As well as the results reported in the main findings section, we were also interested in these additional questions:

#block[
#strong[Question a] How does blood pressure affect diameter and centre pulsatility?

] <thm-qc>
#block[
#strong[Question b] Do hypertension and sphincter ablation influence diameter and centre pulsatility differently?

] <thm-qd>
== Description of the dataset
<description-of-the-dataset>
As well as the categorical data described above, our pulsatility analysis also took into account measurements of each mouse’s blood pressure at the femoral artery.

The final dataset included 514 joint measurements of diameter and centre pulsatility, calculated as described above. These measurements are shown in @fig-pulsatility-dataset.

#figure([
#block[
#grid(columns: 1, gutter: 2em,
)
]
], caption: figure.caption(
position: bottom, 
[
The modelled measurements, shown in order of the coloured categories.
]), 
kind: "quarto-float-fig", 
supplement: "Figure", 
)
<fig-pulsatility-dataset>


@fig-pressure-data shows the relationship between pressure and the measurements in our dataset for both age categories. The light dots show raw measurements and the darker dots show averages within evenly sized bins.

#figure([
#box(width: 904.7272727272727pt, image("../plots/pressure-data.png"))
], caption: figure.caption(
position: bottom, 
[
Pulsatility measurements plotted against the corresponding pressure measurements and coloured according to age. Darker dots indicate averages within evenly sized pressure bins.
]), 
kind: "quarto-float-fig", 
supplement: "Figure", 
numbering: "1", 
)
<fig-pressure-data>


@fig-diameter-data shows the relationship between diameter and the measurements in our dataset for all vessel type categories. The light dots show raw measurements and the darker dots show averages within evenly sized bins. There is a clear positive relationship between measured absolute diameter and diameter pulsatility, and it is approximately the same for all vessel types.

#figure([
#box(width: 908.3636363636364pt, image("../plots/pulsatility-diameter-data.png"))
], caption: figure.caption(
position: bottom, 
[
Pulsatility measurements plotted against the corresponding diameter measurements and coloured according to vessel type. Darker dots indicate averages within evenly sized pressure bins.
]), 
kind: "quarto-float-fig", 
supplement: "Figure", 
numbering: "1", 
)
<fig-diameter-data>


== Statistical models
<statistical-models-1>
We knew from prior studies that the power harmonics should individually follow exponential distributions \[REFERENCE FOR THIS\]. This consideration motivated the use of exponential generalised linear models for both the centre and diameter pulsatility measurements. In this model, given measurement $y$ and linear predictor $eta$ the measurement probability density is given by this equation:

The log link function was chosen so that linear changes in the term $eta$ induce multiplicative changes in the mean $1 / lambda$ of the measurement distribution, as we believed the effects we wanted to model would be multiplicative.

We compared four different ways of parameterising $eta$ based on the information available about a given measurement, corresponding to three hypotheses about the way the data were generated.

The simplest model, which we labelled "basic", calculates the linear predictor \$ ^{basic}\_{vtad}\$ for an observation with vessel type $v$, treatment $t$, age $a$ and diameter $d$ as follows:

The basic model provided a plausible baseline against which to compare the other models.

Next we constructed a more complex model by extending the basic model with interaction effects, resulting in the following linear predictor:

Next we constructed a model that adds to the basic model parameters that aim to capture possible effects corresponding to the blood pressure measurements. To compensate for collinearity between age and pressure, our "pressure" model does not use the observed pressure as a predictor, but rather the age-normalised pressure, calculated by subtracting the mean for each age category from the observed pressure measurement. The model for the linear predictors \$ ^{pressure}\_{vatdp}\$ with age-normalised pressure measurement $p$ is then

Finally, we made a model that includes a pressure effect but no age-specific parameters from the pressure model. This was to test whether any age effects are due to the collinearity between age and pressure. The pressure-no-age model’s linear predictors $eta_(v a t d p)^(p r e s s u r e med n o med a g e)$ are calculated as shown in equation . Note that, unlike in equation , the $mu$ and $beta^(p r e s s u r e)$ parameters in equation have no age indexes.

In all of our models the $alpha$ parameters were given independent, semi-informative, hierarchical prior distributions to allow for appropriate information sharing. The $beta$ and $mu$ parameters were given independent, semi-informative, non-hierarchical prior distributions.

== Results
<results-1>
We estimated the leave-one-out log predictive density for each model using the method described in #cite(<vehtariPracticalBayesianModel2017>) and implemented in #cite(<kumarArviZUnifiedLibrary2019>);. The results of the comparison are shown below in @fig-pulsatility-elpd-comparison.

#figure([
#box(width: 730.1818181818181pt, image("../plots/pulsatility-elpd-comparison.png"))
], caption: figure.caption(
position: bottom, 
[
Comparison of estimated leave-one-out log predictive density \(ELPD) for our pulsatility models. The main result is that the pressure-no-age and interaction models are clearly worse than the pressure model, as shown by the separation of the relevant grey and dotted lines.
]), 
kind: "quarto-float-fig", 
supplement: "Figure", 
numbering: "1", 
)
<fig-pulsatility-elpd-comparison>


We evaluated our models’ fit to data using prior and posterior predictive checking, with the results for the pressure model shown in @fig-pressure-ppc.

#figure([
#block[
#grid(columns: 1, gutter: 2em,
)
]
], caption: figure.caption(
position: bottom, 
[
Prior and posterior predictive checks for the pressure model.
]), 
kind: "quarto-float-fig", 
supplement: "Figure", 
)
<fig-pressure-ppc>


Inspecting of the interaction model output showed that none of the interaction effect parameters that differed substantially from zero, as can be seen in @fig-pulsatility-interaction-effects.

#figure([
#box(width: 1092.3636363636363pt, image("../plots/pulsatility-interaction-effects.png"))
], caption: figure.caption(
position: bottom, 
[
Marginal posterior quantiles for the unique effects in the interaction model.
]), 
kind: "quarto-float-fig", 
supplement: "Figure", 
numbering: "1", 
)
<fig-pulsatility-interaction-effects>


From this result, together with the worse estimated out of sample predictive performance as shown in @fig-pulsatility-elpd-comparison, we concluded that there were no important interaction effects, so that we could essentially discard the interaction model.

@fig-pulsatility-effects shows the marginal posterior distributions for other effect parameters in all three models. Note that the parameters `b_diameter` are strongly positive for diameter pulsatility in all models and also mostly positive for centre pulsatility. There is also a strong trend for diameter pulsatility to decrease with the order of the vessel and no particular vessel type trend for centre pulsatility.

#figure([
#box(width: 1083.6363636363637pt, image("../plots/pulsatility-effects.png"))
], caption: figure.caption(
position: bottom, 
[
Marginal posterior quantiles for shared model effects.
]), 
kind: "quarto-float-fig", 
supplement: "Figure", 
numbering: "1", 
)
<fig-pulsatility-effects>


== Answers to specific questions
<answers-to-specific-questions>
The poorer estimated out of sample predictive performance of the pressure-no-age model compared with the other models, as shown in @fig-pulsatility-elpd-comparison, indicates that our pressure measurements did not fully explain the observed difference between adult and old mice. It is nonetheless possible that different pressure explains the difference between old and adult mice, but that the pressure measurements did not reflect the true pressure at the measured vessels. This is plausible since the pressure measurements were taken at a different location.

@fig-pulsatility-pressure-effects shows the difference in $beta^(p r e s s u r e)$ parameters for old and adult mice in the pressure model in order to answer @thm-qc. This shows a weak tendency of the pressure effect on diameter pulsatility to be more positive for adult mice than for old mice, and a strong opposite tendency for centre pulsatility. Taking the absolute values into account, the analysis suggests that greater measured pressure is not strongly related to diameter pulsatility and correlates with reduced centre pulsatility for adult mice but not for old mice.

#figure([
#box(width: 717.0909090909091pt, image("../plots/pulsatility-pressure-effects.png"))
], caption: figure.caption(
position: bottom, 
[
Posterior distribution of pressure effect differences for each measurement type.
]), 
kind: "quarto-float-fig", 
supplement: "Figure", 
numbering: "1", 
)
<fig-pulsatility-pressure-effects>


To illustrate the effect of treatments, and specifically sphincter ablation relative to hypertension \(i.e.~to answer @thm-qd) @fig-pulsatility-treatment-effects shows the difference between the effect for each treatment and the baseline treatment effect. There is a clear effect of ablation to increase diameter pulsatility and no clear effects of hypertension on diameter pulsatility or of either treatment on centre pulsatility.

#figure([
#box(width: 717.0909090909091pt, image("../plots/pulsatility-treatment-effects.png"))
], caption: figure.caption(
position: bottom, 
[
Posterior distribution of treatment effect differences for each measurement type.
]), 
kind: "quarto-float-fig", 
supplement: "Figure", 
numbering: "1", 
)
<fig-pulsatility-treatment-effects>


To get an idea about how the effect of sphincter ablation on diameter pulsatility compares quantitatively with the effect of hypertension, we fit the basic model to the full dataset, without excluding measurements from either hypertension treatment. @fig-pulsatility-treatment-effects-full shows the main result from fitting this model: ablation and hypertension had similarly positive effects on diameter pulsatility. Interestingly there is no clear effect from the second hypertension treatment.

#figure([
#box(width: 718.5454545454545pt, image("../plots/pulsatility-treatment-effects-full.png"))
], caption: figure.caption(
position: bottom, 
[
Treatment effect distributions relative to baseline in the basic model when fit to the full dataset including all treatments.
]), 
kind: "quarto-float-fig", 
supplement: "Figure", 
numbering: "1", 
)
<fig-pulsatility-treatment-effects-full>


= Details of the red blood cell flow analysis
<details-of-the-red-blood-cell-flow-analysis>
Our measurements included flow data recording the measured speed and flux of red blood cells through some vessels. This data is interesting because it allows for inference of the local blood pressure, which determines the speed.

We were interested in whether the speed and flux tended to be different between old and adult mice for a given vessel type and treatment, as this would indicate that the pressure would likely be similar as well.

== Data processing
<data-processing-1>
There is a significant missing data issue in this case: both speed and flux measurements were available for only 271 out of 1525 raw measurements. We therefore conducted separate analyses for speed and flux even though we suspected that these two quantities are related.

== Dependent variable
<dependent-variable-2>
We modelled speed and flux measurements on natural logarithmic scale as we expected multiplicative effects and this transformation ensures support on the whole real number line, simplifying modelling.

The resulting measurements are shown in figure @fig-flow-data.

#figure([
#box(width: 1010.1818181818181pt, image("../plots/flow-speed-measurements.png"))

#box(width: 1010.9090909090909pt, image("../plots/flow-flux-measurements.png"))

], caption: figure.caption(
position: bottom, 
[
Red blood cell speed and flux data
]), 
kind: "quarto-float-fig", 
supplement: "Figure", 
numbering: "1", 
)
<fig-flow-data>


From a glance at these graphs it is clear that there were treatment effects on both measurement types, particularly from the hypertension treatments, that there are treatment-related distributional effects, and that both speed and flux reduce as vessel order increases.

=== Statistical models
<statistical-models-2>
As in the whisker case we investigated the results of fitting models with and without interaction effects. Again we found no large or fully resolved interactions and therefore used the smaller model for further analysis.

Our final model had this specification:

We chose the prior standard deviation 0.5 after prior predictive checking to ensure reasonably tight coverage of the observed data.

For investigation of interaction effects we fit another model that extended our final model with a vessel type:treatment interaction effect as follows:

== Results
<results-2>
Our statistical model successfully captured all of these trends, as can be seen from figure @fig-flow-ppc

#figure([
#box(width: 946.9090909090909pt, image("../plots/flow-basic-speed-posterior-predictive.png"))

#box(width: 941.8181818181819pt, image("../plots/flow-basic-flux-posterior-predictive.png"))

], caption: figure.caption(
position: bottom, 
[
Posterior predictive checks for flow models
]), 
kind: "quarto-float-fig", 
supplement: "Figure", 
numbering: "1", 
)
<fig-flow-ppc>


=== Shared parameters
<shared-parameters>
@fig-flow-shared summarises the marginal posterior distributions for parameters that appear in both our final flux and speed models. There is quite a lot of agreement, unsurprisingly given that red blood cell speed and flux are closely related. We conclude from this plot that, given sufficient data, a joint model including both measurement types would be a good topic for future analysis.

It is also interesting to note the main area where our flux and speed models disagree, namely the effect corresponding the vessel type sphincter. According to our model, the sphincter tends to have the lowest RBC speed of all vessels but the highest flux.

#figure([
#box(width: 648.7272727272727pt, image("../plots/flow-shared-parameters.png"))
], caption: figure.caption(
position: bottom, 
[
Posterior distributions of parameters that appear in both our flow and speed models.
]), 
kind: "quarto-float-fig", 
supplement: "Figure", 
numbering: "1", 
)
<fig-flow-shared>


=== Interactions
<interactions>
To test for important interaction effects we fit a model with vessel type:treatment interaction parameters. This model achieved marginally worse loo elpd scores as shown in figure @fig-flow-loo.

#figure([
#box(width: 678.5454545454545pt, image("../plots/flow-loo.png"))
], caption: figure.caption(
position: bottom, 
[
Out of sample predictive performance comparison for red blood cell flow models.
]), 
kind: "quarto-float-fig", 
supplement: "Figure", 
numbering: "1", 
)
<fig-flow-loo>


For completeness the interaction effects are shown in figure @fig-flow-interaction. No effects are clearly separated from zero. The sphincter/ablation effect on RBC speed is notably different from the others. We fit several models with sparsity-inducing priors including the regularised horseshoe #cite(<piironenSparsityInformationRegularization2017>) to see if it was possible to resolve this effect, but were unsuccessful. From this we conclude that any real effect is too small to be easily detected in our dataset.

#figure([
#box(width: 797.8181818181819pt, image("../plots/flow-interaction-parameters.png"))
], caption: figure.caption(
position: bottom, 
[
Interaction effects on red blood cell flow.
]), 
kind: "quarto-float-fig", 
supplement: "Figure", 
numbering: "1", 
)
<fig-flow-interaction>


= Hypertensive challenge
<hypertensive-challenge-1>
== Dependent variable
<dependent-variable-3>
The raw data on hypertension challenge were correlation coefficients relating blood pressure and vessel diameter, which are constrained to lie on the $[- 1 , 1]$ interval. For easier modelling we transformed these by applying an inverse hyperbolic tangent function for use in modelling. The dependent variables then had support on the entire real number line.

The resulting dataset is shown in figure @fig-hypertension-data. The transformed correlation coefficients do not appear extremely dispersed, indicating that standard modelling techniques ought to be able to describe them.

#figure([
#box(width: 1010.1818181818181pt, image("../plots/hypertension-data.png"))
], caption: figure.caption(
separator: "", 
position: bottom, 
[
]), 
kind: "quarto-float-fig", 
supplement: "Figure", 
numbering: "1", 
)
<fig-hypertension-data>


=== Statistical model
<statistical-model>
Our final statistical model had the following form.

This model is different from the others in that we did not partially pool the treatment effects, since there were only two of these in this case. We also allowed the measurement error parameters $sigma$ to vary according to vessel type, since this improved model fit and predictive performance.

As in the other analyses, for investigation of interaction effects we fit another model that extended our final model with a vessel type:treatment interaction effect as follows:

== Results
<results-3>
@fig-hypertension-loo shows that, as in the other cases, including interaction effects did not improve estimated predictive performance.

#figure([
#box(width: 574.5454545454545pt, image("../plots/hypertension-loo.png"))
], caption: figure.caption(
position: bottom, 
[
Comparison of out-of-sample predictive performance of our hypertension models, as measured by estimated leave-one-out expected log predictive density. The two models have similar estimated performance, but the `hypertension-big` model is clearly worse.
]), 
kind: "quarto-float-fig", 
supplement: "Figure", 
numbering: "1", 
)
<fig-hypertension-loo>


@fig-hypertension-parameters shows the marginal distributions for the non-hierarchical parameters in our final model.

#figure([
#box(width: 619.6363636363636pt, image("../plots/hypertension-parameters.png"))
], caption: figure.caption(
position: bottom, 
[
1%-99% posterior intervals for parameters in our final hypertension model.
]), 
kind: "quarto-float-fig", 
supplement: "Figure", 
numbering: "1", 
)
<fig-hypertension-parameters>


@fig-hypertension-predictions shows graphical prior and posterior predictive checks for our final hypertension model. The fit is fairly good, with no obvious systematic pattern in the errors, though slightly more observations lie outside the plotted intervals than might be expected.

#figure([
#box(width: 938.1818181818181pt, image("../plots/hypertension-prior-predictive.png"))
], caption: figure.caption(
position: bottom, 
[
#box(width: 938.1818181818181pt, image("../plots/hypertension-posterior-predictive.png"))
]), 
kind: "quarto-float-fig", 
supplement: "Figure", 
numbering: "1", 
)
<fig-hypertension-predictions>


= Details of the density analysis
<details-of-the-density-analysis>
The density dataset consisted of 144 measurements from five adult and four old mice.

== Dependent variable
<dependent-variable-4>
The dependent variable in this case was vessel density, measured as in length of vessel per unit of volume. These measurements are shown in figure @fig-density-measurements on both natural and logarithmic scales.

#figure([
#box(width: 738.1818181818181pt, image("../plots/density-measurements.png"))
], caption: figure.caption(
position: bottom, 
[
Vessel density measurements
]), 
kind: "quarto-float-fig", 
supplement: "Figure", 
numbering: "1", 
)
<fig-density-measurements>


We noticed several interesting patterns in this data.

First, there is a clear trend for vessel density to increase with vessel order until the cap6 vessel type and then to decrease, with adjacent vessel types tending to have similar densities.

Second, the vessel types `pa` and `av` somewhat buck this trend, with a similar upward deviation in both cases. These vessel types—i.e.~penetrating arterioles and ascending venules—have the common characterstic of being vertically oriented.

Finally, we noticed that the measurements are somewhat more dispersed for higher-order capillaries, especially on log scale.

== Statistical model
<statistical-model-1>
We modelled the measurement process using a linear model on logarithmic scale. In this model, given measurement $y$, linear predictor $hat(y)$ and measurement error parameter $sigma$, the measurement probability density is given by this equation:

We modelled the linear predictor $hat(y)$ as depending on an age-specific mean $mu$, an age and vessel type specific parameter $alpha^(a g e , v e s s e l t y p e)$ and a scalar $alpha^(v e r t)$:

where $v e r t (v)$ is an indicator function with value 1 if v represents a vertical vessel and zero otherwise.

In order to capture the observed smoothness between adjacent vessel types, we used Gaussian random walk priors for the $alpha^(a g e : v e s s e l t y p e)$ parameters for adult mice, and on the differences at each vessel type between adult and old mice:

This approach to smoothing parameters corresponding to ordered categories is essentially the same as that used in #cite(<gaoImprovingMultilevelRegression2019>) to model age effects on voting behaviour. As explained in that paper, the random walk priors allow for information sharing between categories, without the need to pre-specify the functional form of the overall relationship.

The other priors in our model were as follows \(units are on standardised logarithmic scale):

== Results
<results-4>
@fig-density-ppc shows the overall fit of our model to the observed data.

#figure([
#box(width: 738.1818181818181pt, image("../plots/density-ppc.png"))
], caption: figure.caption(
position: bottom, 
[
Posterior predictive check for our final vessel density model, shown on natural and logarithmic scale.
]), 
kind: "quarto-float-fig", 
supplement: "Figure", 
numbering: "1", 
)
<fig-density-ppc>


@fig-density-effects-detail

#figure([
#box(width: 516.3636363636364pt, image("../plots/density-effects.png"))
], caption: figure.caption(
separator: "", 
position: bottom, 
[
]), 
kind: "quarto-float-fig", 
supplement: "Figure", 
numbering: "1", 
)
<fig-density-effects-detail>





#bibliography("bibliography.bib")

