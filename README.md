# Duration reproduction under memory pressure

**Modeling the roles of visual memory load in duration encoding and reproduction**

Xuelian Zang¹,², Xiuna Zhu², Fredrik Allenmark², Jiao Wu¹, Stefan Glasauer³, Hermann J. Müller², Zhuanghua Shi²

¹ Center for Cognition and Brain Disorders, Affiliated Hospital of Hangzhou Normal University, 310015, China
² General and Experimental Psychology, Department of Psychology, LMU Munich, 80802, Germany
³ Institut für Medizintechnologie, Brandenburgische Technische Universität Cottbus-Senftenberg, 03046, Cottbus

## Abstract

Duration estimates are often biased by the sampled statistical context, yielding the classical central-tendency effect, i.e., short durations are over- and long duration underestimated. Most studies of the central-tendency bias have primarily focused on the integration of the sensory measure and the prior information, without considering any cognitive limits. Here, we investigated the impact of cognitive (visual working-memory) load on duration estimation in the duration encoding and reproduction stages. In five experiments, observers had to perform a dual, attention-sharing task: reproducing a given duration (primary) and memorizing a variable set of color patches (secondary). We found an increase in memory load (i.e., set size) during the duration-encoding stage to increase the central-tendency bias, while shortening the reproduced duration in general; in contrast, increasing the load during the reproduction stage prolonged the reproduced duration, without influencing the central tendency. By integrating an attentional-sharing account into a hierarchical Bayesian model, we were able to predict both the general over- and underestimation and the central-tendency effects observed in all experiments. The model suggests that memory pressure during the encoding stage increases the sensory noise, which elevates the central-tendency effect. In contrast, memory pressure during the reproduction stage only influences the monitoring of elapsed time, leading to a general duration over-reproduction without impacting the central tendency.

**Keywords:** time perception, dual-task performance, attention-sharing, cognitive/memory load, Bayesian integration, central-tendency effect

## Repository Structure

```
├── data/                          # Experimental data files
│   ├── Exp1_Encoding.csv         # Experiment 1: Memory load during duration encoding
│   ├── Exp2_Reproduction.csv     # Experiment 2: Memory load during duration reproduction
│   ├── Exp3_Baseline.csv         # Experiment 3: No temporal overlap (baseline)
│   ├── Exp4_Both.csv             # Experiment 4: Memory load during both stages
│   ├── Exp5_BothGap.csv          # Experiment 5: Both stages with temporal gap
│   └── Readme.txt                # Data structure documentation
├── analysis/                      # Analysis scripts and outputs
│   ├── WM_time_Rpr_2025.Rmd      # Main statistical analysis notebook
│   ├── 0.runRstanModel.Rmd       # Bayesian model fitting script
│   ├── 1.rstan_gap_report.Rmd    # Gap condition model reporting
│   ├── color_similarity_analysis.qmd     # Color similarity analysis
│   ├── mytheme.R                 # Custom plotting themes and functions
│   ├── figures/                  # Generated plots and visualizations
│   ├── modelrlt/                 # Model fitting results
│   └── RStanCode/                # Stan model files and outputs
└── README.md                     # This file
```

## Experimental Design

This study employs a systematic dual-task paradigm examining the interaction between visual working memory demands and duration reproduction across five experiments:

### Experiments Overview
- **Experiment 1 (Encoding)**: Memory load during duration encoding phase
- **Experiment 2 (Reproduction)**: Memory load during duration reproduction phase
- **Experiment 3 (Baseline)**: No temporal overlap between tasks
- **Experiment 4 (Both)**: Memory load during both encoding and reproduction
- **Experiment 5 (BothGap)**: Both phases with additional temporal gap manipulation

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
5. **Bayesian Model Fitting**: Stan-based hierarchical modeling with attention parameters

### Key Statistical Techniques
- Repeated-measures ANOVA with Greenhouse-Geisser corrections
- Linear mixed-effects models for cross-experimental comparisons
- Bayesian hierarchical modeling with RStan
- Post-hoc comparisons with Bonferroni correction
- Effect size quantification (Cohen's d, partial eta-squared)

## Model Architecture

The hierarchical Bayesian model incorporates:
- **Attention-sharing parameters**: ks, ls, ts, kr for encoding/reproduction stages
- **Sensory noise modulation**: Memory load effects on duration perception precision
- **Prior integration**: Context-dependent weighting of statistical expectations
- **Individual differences**: Subject-level parameter estimation
- **Logarithmic encoding**: Consistent with Weber's law for temporal perception


## Citation

If you use this data or code, please cite:

```
Zang, X., Zhu, X., Allenmark, F., Wu, J., Glasauer, S., Müller, H. J., & Shi, Z. (2025).
Duration reproduction under memory pressure: Modeling the roles of visual memory load
in duration encoding and reproduction. [Journal details pending]
```
