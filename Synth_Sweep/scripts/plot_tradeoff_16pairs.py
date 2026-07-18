#!/usr/bin/env python3
"""16-pair (4 backbones x 4 targets) deployed-geometry multi-branch trade-off.
All data embedded below — edit and rerun to restyle.
Outputs 4 separate PNGs (compact/throughput x curves/marginal-summary).
"""
import matplotlib
matplotlib.use("Agg")
import matplotlib.pyplot as plt
import numpy as np

OUT = "/home/barkie1/mvau_multibranch_synth/fig16"
import os
os.makedirs(OUT, exist_ok=True)

Ms = [1, 2, 3, 4]

# deployed-geometry accuracies (M=1..4, RC): ACC[backbone][target]
ACC = {
    "CIFAR-10": {   # thesis Table (multi_adapter_contrib)
        "SVHN":         [73.72, 77.16, 78.77, 79.81],
        "FashionMNIST": [80.42, 82.00, 82.82, 83.54],
        "STL10":        [67.46, 67.58, 68.00, 68.06],
        "CINIC10":      [64.80, 65.16, 65.38, 65.45],
    },
    "SVHN": {       # A6000 svhn_configA_cross
        "CIFAR-10":     [43.18, 45.13, 46.93, 48.37],
        "FashionMNIST": [78.51, 79.76, 80.56, 81.89],
        "STL10":        [34.41, 34.60, 35.45, 35.10],
        "CINIC10":      [33.59, 35.21, 34.29, 38.03],
    },
    "STL10": {      # A6000 stl10_configA_cross
        "CIFAR-10":     [66.65, 67.90, 68.74, 68.79],
        "FashionMNIST": [81.48, 82.96, 83.58, 84.19],
        "SVHN":         [68.15, 73.18, 74.17, 75.65],
        "CINIC10":      [54.26, 55.33, 56.17, 56.56],
    },
    "FashionMNIST": {  # A6000 fashionmnist_configA_cross
        "CIFAR-10":     [33.63, 34.67, 35.84, 36.76],
        "STL10":        [32.64, 32.29, 33.64, 34.11],
        "SVHN":         [51.37, 58.19, 59.42, 62.70],
        "CINIC10":      [27.75, 28.37, 29.55, 29.56],
    },
}

BUILDS = {
    "compact":    dict(label="Compact (multi-dataset)",
                       pct=[90.1, 135.0, 179.7, 236.0],
                       k=[47.931, 71.841, 95.593, 125.538]),
    "throughput": dict(label="Throughput (2-dataset)",
                       pct=[137.5, 206.3, 272.7, 352.5],
                       k=[73.169, 109.731, 145.061, 187.521]),
}

C = {"SVHN": "#2a78d6", "FashionMNIST": "#c98500", "STL10": "#1baf7a",
     "CINIC10": "#4a3aa7", "CIFAR-10": "#e34948"}
MK = {"SVHN": "o", "FashionMNIST": "s", "STL10": "^", "CINIC10": "D",
      "CIFAR-10": "v"}

INK, MUTED, GRIDC = "#0b0b0b", "#52514e", "#d9d8d4"
plt.rcParams.update({
    "font.size": 9, "axes.edgecolor": MUTED, "axes.labelcolor": INK,
    "xtick.color": MUTED, "ytick.color": MUTED, "axes.titlesize": 9.5,
    "font.family": "Times New Roman", "mathtext.fontset": "stix",
})


def curves(tag):
    bd = BUILDS[tag]
    pct = bd["pct"]
    # tight x-range so the M1->M2 slope is visually dominant
    x_lo = pct[0] - 0.06 * (pct[-1] - pct[0])
    x_hi = pct[-1] + 0.16 * (pct[-1] - pct[0])
    fig, axs = plt.subplots(2, 2, figsize=(6.6, 6.2), dpi=300)
    for axm, (src, tgts) in zip(axs.flat, ACC.items()):
        axm.axvspan(100, x_hi, color="#9a9890", alpha=0.10, zorder=0)
        axm.axvline(100, color=MUTED, ls="--", lw=1.1, zorder=1)
        for tgt, acc in tgts.items():
            c = C[tgt]
            axm.plot(pct, acc, "-" + MK[tgt], color=c, lw=1.9, ms=4.5, zorder=3,
                     markerfacecolor=c, markeredgecolor="white",
                     markeredgewidth=0.9)
            axm.annotate(f"+{acc[3]-acc[0]:.1f}", (pct[-1] + 4, acc[-1]),
                         fontsize=7, color=c, va="center")
        axm.set_title(f"backbone: {src}", loc="left", fontsize=9)
        axm.set_xlim(x_lo, x_hi)
        axm.grid(True, color=GRIDC, lw=0.5, alpha=0.8)
        axm.set_axisbelow(True)
        axm.set_xlabel("Slice-LUT demand (% of XC7Z020)", fontsize=8)
        axm.set_ylabel("Accuracy (%)", fontsize=8)
        for sp in ("top", "right"):
            axm.spines[sp].set_visible(False)
    handles = [plt.Line2D([], [], color=C[t], marker=MK[t], ls="-",
                          markeredgecolor="white", label=t)
               for t in ("CIFAR-10", "SVHN", "FashionMNIST", "STL10", "CINIC10")]
    fig.legend(handles=handles, ncol=5, frameon=False, fontsize=8,
               loc="lower center", bbox_to_anchor=(0.5, -0.005))
    fig.suptitle(f"{bd['label']}: accuracy vs. cost, 16 transfer pairs "
                 "(deployed geometry; label = total gain M1→M4, pp)",
                 x=0.02, ha="left", fontsize=10)
    fig.tight_layout(rect=(0, 0.035, 1, 0.97))
    fig.savefig(f"{OUT}/{tag}_curves16.png")
    plt.close(fig)


def marginal_summary(tag):
    bd = BUILDS[tag]
    dk = np.diff(bd["k"])
    steps = ["M1→M2", "M2→M3", "M3→M4"]
    fig, ax = plt.subplots(figsize=(5.6, 3.4), dpi=300)
    rng = np.random.default_rng(7)
    means = []
    for j in range(3):
        vals = []
        for src, tgts in ACC.items():
            for tgt, acc in tgts.items():
                vals.append((acc[j + 1] - acc[j]) / dk[j] * 10)
        vals = np.array(vals)
        means.append(vals.mean())
        x = j + rng.uniform(-0.13, 0.13, len(vals))
        ax.scatter(x, vals, s=26, color="#9ec5f4", edgecolor="#2a78d6",
                   linewidth=0.7, zorder=3)
    ax.plot(range(3), means, "-o", color="#e34948", lw=2, ms=7, zorder=4,
            markeredgecolor="white", markeredgewidth=1.1, label="mean of 16 pairs")
    for j, m in enumerate(means):
        ax.annotate(f"{m:.2f}", (j, m), xytext=(10, 4),
                    textcoords="offset points", fontsize=8.5, color="#e34948")
    ax.set_xticks(range(3))
    ax.set_xticklabels(steps)
    ax.set_ylabel("Accuracy gain per +10k LUTs (pp)")
    ax.set_title(f"{bd['label']}: marginal return across 16 transfer pairs",
                 loc="left")
    ax.grid(True, axis="y", color=GRIDC, lw=0.5, alpha=0.8)
    ax.set_axisbelow(True)
    ax.axhline(0, color=MUTED, lw=0.8)
    ax.legend(frameon=False, fontsize=8)
    for sp in ("top", "right"):
        ax.spines[sp].set_visible(False)
    fig.tight_layout()
    fig.savefig(f"{OUT}/{tag}_marginal16.png")
    plt.close(fig)


for tag in BUILDS:
    curves(tag)
    marginal_summary(tag)
print("done ->", OUT)
