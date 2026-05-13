# PAIRS — Phase Artifact Reduction Using Interpolation And Re-Sampling

> A multirate preprocessing wrapper for phase vocoder pitch shifting that reduces spectral artifacts without modifying the vocoder's internal logic.
<p align="center">
  <img src="assets/banner.png" alt="Project Banner" width="100%">
</p>

[![MATLAB](https://img.shields.io/badge/MATLAB-R2022b%2B-blue?logo=mathworks)](https://www.mathworks.com/)
[![License](https://img.shields.io/badge/License-MIT-green)](LICENSE)
[![Institution](https://img.shields.io/badge/Sathyabama%20Institute-ECE-orange)](https://www.sathyabama.ac.in/)
[![Status](https://img.shields.io/badge/Paper-Under%20Review%20(IEEE)-yellow)]()

---

## Overview

Phase vocoder (PV)-based pitch shifting generates intermodulation distortion (IMD) that produces spectral smearing, phasiness, and transient degradation — especially beyond ±2 semitones. PAIRS eliminates a portion of this distortion through a four-stage multirate pipeline operating **entirely upstream** of the vocoder, requiring zero modifications to the PV itself.

**Core idea:** Upsampling before PV processing extends the spectral workspace, causing a fraction of IMD to migrate into an empty *sacrificial band* above the original Nyquist frequency. The mandatory anti-aliasing filter — which any decimation system must apply — then scrubs this distortion selectively and for free.

```
x[n] @ fs  →  Upsample ×2  →  Phase Vocoder @ 2·fs  →  Anti-alias LPF  →  Downsample ×2  →  y[n] @ fs
```

---

## Key Results

| Metric | Result |
|---|---|
| TIR > 1.0 (PAIRS preserves transient) | **11 / 17** real recordings |
| Peak TIR (Piano, −3 st) | **1.47** |
| LSD improvement over Std PV | **4 / 6** synthesized signal classes |
| Computational overhead vs Raw PV | **~8%** (vs ~485% for Zero-Padded PV) |
| LSD regressions at ±3–±4 semitones | **Zero** across all 5 instrument classes |
| Wilcoxon test (PAIRS vs LPF-only) | W=3636, Z=2.12, **p=0.034** (exploratory) |

---

## Repository Structure

```
PAIRS/
├── matlab/
│   ├── pairs_pitch_shift.m       # Main PAIRS wrapper function
│   ├── phase_vocoder.m           # Phase vocoder with spectral peak locking
│   ├── compute_lsd.m             # Log Spectral Distance metric
│   ├── compute_tir.m             # Transient Integrity Ratio metric
│   ├── compute_phase_coherence.m # Inter-frame phase coherence (Δcoh)
│   ├── run_synthesized_eval.m    # Batch LSD evaluation on synthesized corpus
│   ├── run_real_recordings_eval.m# TIR + Δcoh + LSD on RWC recordings
│   └── demo.m                    # Quick demo: load audio → pitch shift → compare
├── docs/
│   └── PAIRS_project_report.pdf  # Full project report (Sathyabama, April 2026)
├── results/
│   └── (place generated .mat / .csv result files here)
├── README.md
└── LICENSE
```

---

## Algorithm

PAIRS executes four sequential stages:

| Stage | Operation | Parameters |
|---|---|---|
| 1 – Upsample | Polyphase FIR interpolation ×2 | Kaiser window, β=8, order P=64 |
| 2 – PV @ 2·fs | Phase Vocoder with spectral peak locking | N=2048, H=512, Hann window |
| 3 – Anti-alias LPF | 64th-order FIR lowpass | Normalised cutoff ωc = π/L = π/2 |
| 4 – Downsample | Decimate ×2 | Output rate restored to original fs |

**Why does it work?**
- The polyphase interpolation filter restricts signal energy strictly to `[0, fs/2]`
- The sacrificial band `[fs/2, 2·fs/2]` is left empty after upsampling
- The PV generates IMD at the elevated rate; a portion migrates into the sacrificial band
- The mandatory anti-aliasing LPF removes sacrificial-band IMD before decimation

**Why can't you move the PV after downsampling?**  
The Noble Identity (which allows LTI filtering to commute with a downsampler) does **not** apply to the PV because the PV is a nonlinear system. The PV must execute at the elevated rate.

---

## Requirements

- MATLAB R2022b or later
- Signal Processing Toolbox
- Audio Toolbox
- Statistics and Machine Learning Toolbox (for Wilcoxon test)

---

## Quick Start

```matlab
% Load any mono audio file
[x, fs] = audioread('your_audio.wav');
if size(x, 2) > 1, x = mean(x, 2); end  % convert to mono

% Pitch shift up 4 semitones using PAIRS
y_pairs = pairs_pitch_shift(x, fs, 4);

% Compare with raw phase vocoder
y_raw = phase_vocoder(x, fs, 4);

% Play and compare
sound(x, fs);        pause(length(x)/fs + 0.5);
sound(y_raw, fs);    pause(length(x)/fs + 0.5);
sound(y_pairs, fs);

% Write outputs
audiowrite('output_raw.wav',   y_raw,   fs);
audiowrite('output_pairs.wav', y_pairs, fs);
```

Or run the full demo:
```matlab
cd matlab
demo
```

---

## Evaluation Metrics

**Log Spectral Distance (LSD)** — spectral fidelity to an ideal reference (lower = better):
```
LSD = (1/K) · Σ_k [10·log10(S_ref[k] / S_est[k])]²
```

**Transient Integrity Ratio (TIR)** — transient preservation relative to Std PV (> 1.0 = PAIRS wins):
```
TIR = RMS_err(Std PV) / RMS_err(PAIRS)   [at ±25 ms around signal peak]
```

**Inter-frame Phase Coherence Gain (Δcoh)** — phase stability improvement over Std PV (> 0 = PAIRS wins):
```
Δcoh = mean_coh(PAIRS) − mean_coh(Std PV)
coherence per frame = |E[exp(j·Δφ)]|  across frequency bins
```

---

## Limitations

- No measurable LSD benefit for Guitar and Voice at L=2 (steady-state tonal signals)
- Benefit diminishes beyond ±4 semitones; one LSD regression observed at Piano +6 st (−1.02 dB)
- TIR is unreliable for soft-attack signal classes (flute, sustained vocal)
- No perceptual listening test (MUSHRA) conducted — computational metrics only
- Formal ablation (2× PV without anti-alias LPF) is pending

---

## Citation

If you use PAIRS in your work, please cite:

```
K. Siva Srinivas, K. Keshav, K. Lokesh, S. Kishore Vikhram, Lakshmi Srinivasan K, S. Karthikeyan,
"Phase Artifact Reduction Using Interpolation And Re-Sampling (PAIRS),"
Sathyabama Institute of Science and Technology, April 2026.
[IEEE paper under review]
```

---

## Authors

**K. Siva Srinivas** · K. Keshav · K. Lokesh · S. Kishore Vikhram · Lakshmi Srinivasan K · S. Karthikeyan

Department of Electronics and Communication Engineering  
Sathyabama Institute of Science and Technology, Chennai  
Internal Guide: Dr. V. Balamurugan

---

## License

MIT License — see [LICENSE](LICENSE) for details.
