# Duration reproduction under memory pressure

**Modeling the roles of visual memory load in duration encoding and reproduction**

Xuelian Zang¹,², Xiuna Zhu², Jiao Wu¹, Fredrik Allenmark², Stefan Glasauer³, Hermann J. Müller², Zhuanghua Shi²

¹ Center for Cognition and Brain Disorders, Affiliated Hospital of Hangzhou Normal University, 310015, China
² General and Experimental Psychology, Department of Psychology, LMU Munich, 80802, Germany
³ Institut für Medizintechnologie, Brandenburgische Technische Universität Cottbus-Senftenberg, 03046, Cottbus

## Abstract

Duration estimates are often biased by sampled context, resulting in the central-tendency effect, with short durations being overestimated and long durations underestimated. While most studies of this bias have focused on the integration of sensory input with prior information, they often overlook potential impacts of cognitive load. In this study, we investigated how (visual) duration estimation is influenced by concurrent visual working-memory load, focusing on how memory load during the encoding phase, reproduction phase, or both, impacts this process. Across five experiments, participants performed dual-task conditions: reproducing a target duration (primary task) while memorizing a variable set of color patches (secondary task). Memory load during encoding consistently shortened reproductions and led to a stronger central-tendency effect, whereas memory load during reproduction lengthened reproductions. To interpret these opposing effects, we developed a hierarchical Bayesian model incorporating attention-sharing, which accurately captured how memory load alters duration reproductions depending on the phase of interference. The model also suggests that the encoding phase is critical to observed central tendency modulation by memory loads. Our findings reveal phase-specific effects of cognitive load on time perception and suggest broader implications for magnitude perception under cognitive load. 

**Keywords:** time perception, dual-task performance, attention-sharing, cognitive/memory load, Bayesian integration, central-tendency effect

## Repository Structure

```
├── data/                          # Experimental data and model results
│   ├── AllValidData.csv          # Combined experimental data from all five experiments
│   ├── Baseline/                 # Baseline model (NULL) results
│   ├── EncodingOnly/             # Encoding-only model results
│   ├── ReproductionOnly/         # Reproduction-only model results
│   ├── Both/                     # Both stages model results (deprecated)
│   ├── FreeParameters/           # Full model with all free parameters
│   ├── Experimentwise/           # Experiment-specific constraint models
│   └── model_comparison_results/ # Cross-model comparison outputs
├── analysis/                      # Analysis scripts and outputs
│   ├── wm_models.qmd             # Main Bayesian modeling notebook (PyMC)
│   ├── WM_time_Rpr_2025.Rmd      # Behavioral analysis and statistics
│   ├── color_similarity_analysis.qmd     # Color similarity analysis
│   ├── mytheme.R                 # Custom plotting themes and functions
│   └── figures/                  # Generated plots and visualizations
│       ├── encoding.png          # Encoding stage illustration
│       ├── reproduction.png      # Reproduction stage illustration
│       └── model_comparison_heatmap.png  # Model comparison visualization
└── README.md                     # This file
```

## Experimental Design

This study employs a systematic dual-task paradigm examining the interaction between visual working memory demands and duration reproduction across five experiments:

### Experiments Overview
- **Experiment 1 (Baseline)**: No temporal overlap between tasks - control condition
- **Experiment 2 (Encoding)**: Memory load during duration encoding phase
- **Experiment 3 (Reproduction)**: Memory load during duration reproduction phase
- **Experiment 4 (Both)**: Memory load during both encoding and reproduction
- **Experiment 5 (Both_gap)**: Both phases with additional retention interval (gap) manipulation

### Key Manipulations
- **Memory Load**: 1, 3, or 5 color patches to remember
- **Duration Range**: 0.5 to 1.7 seconds (5 levels)
- **Color Task**: Change detection with continuous color wheel sampling
- **Temporal Overlap**: Systematic variation across experiments

### Primary Measures
- **Central Tendency Index (CTI)**: Slope of reproduction error vs. physical duration
- **Mean Bias**: Overall tendency to over- or under-reproduce durations
- **Coefficient of Variation (CV)**: Duration-normalized variability measure
- **Memory Accuracy**: Color change detection performance

## Key Findings

1. **Selective Memory Load Effects**: Central tendency effects increased only when memory load occurred during duration encoding, not reproduction
2. **Dissociable Mechanisms**: Different memory load placements produced distinct patterns of duration bias
3. **Domain-Specific Interference**: Color similarity manipulations affected memory accuracy but not duration reproduction, ruling out general dual-task difficulty explanations
4. **Bayesian Model Success**: Hierarchical model with attention-sharing parameters successfully predicted all observed patterns

## Statistical Analysis

### Main Analysis Pipeline
1. **Behavioral Data Processing**: Trial-level cleaning and subject-level aggregation
2. **Mixed-Effects Modeling**: Hierarchical analysis across experiments and conditions
3. **Central Tendency Quantification**: Individual slope calculations via linear regression
4. **Color Similarity Analysis**: Systematic examination of task difficulty confounds
5. **Bayesian Model Fitting**: PyMC-based hierarchical modeling with attention parameters
6. **Model Comparison**: LOO-CV (Leave-One-Out Cross-Validation) for model selection

### Key Statistical Techniques
- Repeated-measures ANOVA with Greenhouse-Geisser corrections
- Linear mixed-effects models for cross-experimental comparisons
- Bayesian hierarchical modeling with PyMC3/PyMC
- Model comparison using LOO and Pareto-k diagnostics
- Post-hoc comparisons with Bonferroni correction
- Effect size quantification (Cohen's d, partial eta-squared)

## Model Architecture

The hierarchical Bayesian model incorporates three key stages:

### 1. Duration Encoding
- **Logarithmic sensory measure**: $S = \log(D) + \epsilon$ (consistent with scalar property)
- **Memory load on encoding mean**: $\mu_{wm} = \log(D) - k_s\log(M)$
- **Memory load on encoding variance**: $\sigma_{wm}^2 = \sigma_s^2(1 + l_s \cdot \log(M))$
- **Gap effect** (Exp5 only): $\sigma_{wm}^2 = \sigma_s^2(1 + l_s \cdot \log(M + T_{gap} - 1))$

### 2. Bayesian Integration
- **Posterior estimation**: Weighted integration of sensory measure and prior
- **Weight calculation**: $w_p = \frac{1/\sigma_{prior}^2}{1/\sigma_{wm}^2 + 1/\sigma_{prior}^2}$
- **Posterior mean**: $\mu'_{post} = (1-w_p)\mu_{wm} + w_p\mu_{prior}$

### 3. Duration Reproduction
- **Elapsed time monitoring**: Memory load causes loss of temporal "clock ticks"
- **Reproduced duration**: $\mu_r = e^{\mu'_{post} + k_r\log(M) + \sigma_{post}^2/2}$
- **Non-temporal noise**: $\sigma_{observed}^2 = \sigma_r^2 + \sigma_{non-temporal}^2/D$

### Model Parameters
- **$k_s$**: Encoding mean - working memory effect on perceived duration
- **$l_s$**: Encoding variance - working memory effect on sensory noise
- **$k_r$**: Reproduction mean - working memory effect on elapsed time monitoring
- **Gap effect**: Retention interval impact on encoding variance (Exp5)

### Model Variants
- **NULL**: All parameters fixed to 0 (no memory load effects)
- **EncodingOnly**: $k_s$ and $l_s$ free, $k_r$ = 0
- **ReproductionOnly**: $k_r$ free, $k_s$ and $l_s$ = 0
- **FreeParameters**: All parameters free across all experiments
- **Experimentwise**: Parameters constrained according to each experiment's design

## Reproducibility

### Requirements

**Python Environment** (for Bayesian modeling):
- Python 3.8+
- PyMC3 or PyMC (latest)
- ArviZ (for model diagnostics and comparison)
- NumPy, Pandas, Matplotlib, Seaborn
- Jupyter or Quarto for running notebooks

**R Environment** (for behavioral analysis):
- R 4.0+
- Required packages: tidyverse, lme4, afex, emmeans, ggplot2
- RStan (for legacy Stan models, if needed)

### Running the Analysis

1. **Behavioral Analysis**: Run `analysis/WM_time_Rpr_2025.Rmd` for descriptive statistics and ANOVA
2. **Bayesian Modeling**: Execute `analysis/wm_models.qmd` for complete model fitting and comparison
3. **Color Analysis**: Run `analysis/color_similarity_analysis.qmd` for control analyses

The main modeling notebook (`wm_models.qmd`) will:
- Load and preprocess all experimental data
- Fit all model variants to each experiment
- Compute LOO cross-validation for model comparison
- Generate visualization figures for parameters and model fits

### Data Availability

All experimental data are available in `data/AllValidData.csv`. Model results (traces, parameters, predictions) are saved in experiment-specific subdirectories under `data/`.

## Citation

If you use this data or code, please cite:

```
Zang, X., Zhu, X., Allenmark, F., Wu, J., Glasauer, S., Müller, H. J., & Shi, Z. (2025).
Duration reproduction under memory pressure: Modeling the roles of visual memory load in duration encoding and reproduction. [Journal details pending]
```
