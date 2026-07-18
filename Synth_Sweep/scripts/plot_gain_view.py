#!/usr/bin/env python3
"""Gain-view trade-off (v3): all 16 pairs start at 0; slope M1->M2 dominates.
Edit data below and rerun."""
import matplotlib
matplotlib.use("Agg")
import matplotlib.pyplot as plt
import numpy as np

Ms = [1, 2, 3, 4]
ACC = {
    "CIFAR-10": {"SVHN": [73.72, 77.16, 78.77, 79.81], "FashionMNIST": [80.42, 82.00, 82.82, 83.54],
                 "STL10": [67.46, 67.58, 68.00, 68.06], "CINIC10": [64.80, 65.16, 65.38, 65.45]},
    "SVHN": {"CIFAR-10": [43.18, 45.13, 46.93, 48.37], "FashionMNIST": [78.51, 79.76, 80.56, 81.89],
             "STL10": [34.41, 34.60, 35.45, 35.10], "CINIC10": [33.59, 35.21, 34.29, 38.03]},
    "STL10": {"CIFAR-10": [66.65, 67.90, 68.74, 68.79], "FashionMNIST": [81.48, 82.96, 83.58, 84.19],
              "SVHN": [68.15, 73.18, 74.17, 75.65], "CINIC10": [54.26, 55.33, 56.17, 56.56]},
    "FashionMNIST": {"CIFAR-10": [33.63, 34.67, 35.84, 36.76], "STL10": [32.64, 32.29, 33.64, 34.11],
                     "SVHN": [51.37, 58.19, 59.42, 62.70], "CINIC10": [27.75, 28.37, 29.55, 29.56]},
}
BB_C = {"CIFAR-10": "#2a78d6", "SVHN": "#c98500", "STL10": "#1baf7a", "FashionMNIST": "#4a3aa7"}
INK, MUTED, GRIDC = "#0b0b0b", "#52514e", "#d9d8d4"
plt.rcParams.update({"font.size": 10, "axes.edgecolor": MUTED, "axes.labelcolor": INK,
    "xtick.color": MUTED, "ytick.color": MUTED, "axes.titlesize": 11,
    "font.family": "Times New Roman", "mathtext.fontset": "stix"})

# ---------- Fig 1: gain view ----------
fig, ax = plt.subplots(figsize=(5.6, 4.2), dpi=300)
gains_all = []
for src, tgts in ACC.items():
    for tgt, acc in tgts.items():
        gains_all.append([a - acc[0] for a in acc])
gains_all = np.array(gains_all)
mean_g = gains_all.mean(axis=0)
lo, hi = gains_all.min(axis=0), gains_all.max(axis=0)

# range band of the 16 pairs
ax.fill_between(Ms, lo, hi, color="#9ec5f4", alpha=0.35, zorder=1,
                label="range of 16 transfer pairs")
# best case, dashed
best = gains_all[np.argmax(gains_all[:, 3])]
ax.plot(Ms, best, "--", color="#4a3aa7", lw=1.6, zorder=3,
        label="best pair (FashionMNIST→SVHN)")
ax.annotate("+11.3", (4, best[3]), xytext=(6, 0), textcoords="offset points",
            fontsize=9, color="#4a3aa7", va="center", fontweight="bold")
# mean
ax.plot(Ms, mean_g, "-o", color="#e34948", lw=3, ms=8, zorder=5,
        markeredgecolor="white", markeredgewidth=1.3, label="mean of 16 pairs")
for x, y in zip(Ms[1:], mean_g[1:]):
    ax.annotate(f"+{y:.1f}", (x, y), xytext=(0, -17), textcoords="offset points",
                ha="center", fontsize=10, color="#e34948", fontweight="bold")
ax.set_xticks(Ms)
ax.set_xticklabels(["M=1", "M=2", "M=3", "M=4"])
ax.set_xlim(0.92, 4.35)
ax.set_ylim(-1.2, 12.5)
ax.set_xlabel("Branch count M   (each extra branch: +24–30k LUTs Compact / +35–42k Throughput)")
ax.set_ylabel("Accuracy gain over M=1 (pp)")
ax.set_title("Multi-branch gain, 16 transfer pairs (deployed geometry)", loc="left")
ax.grid(True, color=GRIDC, lw=0.6, alpha=0.8)
ax.set_axisbelow(True)
ax.legend(frameon=False, fontsize=8.5, loc="upper left")
for sp in ("top", "right"):
    ax.spines[sp].set_visible(False)
fig.tight_layout()
fig.savefig("/home/barkie1/mvau_multibranch_synth/fig16/gain_view.png")
plt.close(fig)

# ---------- Fig 2: raw per-step gain bars + cost labels ----------
fig, ax = plt.subplots(figsize=(5.2, 3.6), dpi=300)
step_g = np.diff(gains_all, axis=1)          # (16,3) raw pp per step
means = step_g.mean(axis=0)
rng = np.random.default_rng(7)
for j in range(3):
    x = j + rng.uniform(-0.16, 0.16, step_g.shape[0])
    ax.scatter(x, step_g[:, j], s=30, color="#9ec5f4", edgecolor="#2a78d6",
               linewidth=0.8, zorder=3)
ax.bar(range(3), means, 0.55, color="#2a78d6", alpha=0.25, zorder=2)
for j, m in enumerate(means):
    ax.annotate(f"mean +{m:.2f} pp", (j, m), xytext=(0, 6), textcoords="offset points",
                ha="center", fontsize=10, color="#e34948", fontweight="bold")
ax.axhline(0, color=MUTED, lw=0.8)
ax.set_xticks(range(3))
ax.set_xticklabels(["M1→M2\n(+23.9k LUT)", "M2→M3\n(+23.8k LUT)", "M3→M4\n(+29.9k LUT)"])
ax.set_ylabel("Accuracy gained in this step (pp)")
ax.set_title("Per-step gain shrinks while per-step cost stays flat", loc="left")
ax.grid(True, axis="y", color=GRIDC, lw=0.6, alpha=0.8)
ax.set_axisbelow(True)
for sp in ("top", "right"):
    ax.spines[sp].set_visible(False)
fig.tight_layout()
fig.savefig("/home/barkie1/mvau_multibranch_synth/fig16/step_gain.png")
plt.close(fig)
print("saved gain_view + step_gain")
