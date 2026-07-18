#!/usr/bin/env python3
"""Draft: trade-off with BOTH builds (rows) x (acc-vs-LUT, marginal bars)."""
import matplotlib
matplotlib.use("Agg")
import matplotlib.pyplot as plt
import numpy as np

Ms = [1, 2, 3, 4]
DATA = {
    "SVHN":         [73.72, 77.16, 78.77, 79.81],
    "FashionMNIST": [80.42, 82.00, 82.82, 83.54],
    "STL10":        [67.46, 67.58, 68.00, 68.06],
    "CINIC10":      [64.80, 65.16, 65.38, 65.45],
}
C = {"SVHN": "#2a78d6", "FashionMNIST": "#c98500",
     "STL10": "#1baf7a", "CINIC10": "#4a3aa7"}
MK = {"SVHN": "o", "FashionMNIST": "s", "STL10": "^", "CINIC10": "D"}
BUILDS = {
    "Compact (multi-dataset)":    dict(pct=[90.1, 135.0, 179.7, 236.0],
                                       k=[47.931, 71.841, 95.593, 125.538]),
    "Throughput (2-dataset)":     dict(pct=[137.5, 206.3, 272.7, 352.5],
                                       k=[73.169, 109.731, 145.061, 187.521]),
}
INK, MUTED, GRIDC = "#0b0b0b", "#52514e", "#dcdbd7"
plt.rcParams.update({
    "font.size": 9, "axes.edgecolor": MUTED, "axes.labelcolor": INK,
    "xtick.color": MUTED, "ytick.color": MUTED, "axes.titlesize": 9.5,
    "font.family": "Times New Roman", "mathtext.fontset": "stix",
})

fig, axs = plt.subplots(2, 2, figsize=(7.4, 5.8), dpi=300,
                        gridspec_kw={"width_ratios": [1.25, 1]})
steps = ["M1→M2", "M2→M3", "M3→M4"]
for row, (bname, bd) in enumerate(BUILDS.items()):
    ax, bx = axs[row]
    pct, k = bd["pct"], bd["k"]
    ax.axvspan(100, 380, color="#9a9890", alpha=0.10, zorder=0)
    ax.axvline(100, color=MUTED, ls="--", lw=1.2, zorder=1)
    if row == 0:
        ax.text(104, 85.2, "XC7Z020 capacity (100% LUT)", fontsize=7, color=MUTED, va="top")
    for name, acc in DATA.items():
        ax.plot(pct, acc, "-" + MK[name], color=C[name], lw=2, ms=5, zorder=3,
                markerfacecolor=C[name], markeredgecolor="white", markeredgewidth=1.0)
        ax.text(pct[-1] + 5, acc[-1], name, color=C[name], fontsize=7.5,
                fontweight="bold", va="center")
    for x, m in zip(pct, Ms):
        ax.annotate(f"M={m}", (x, DATA["SVHN"][m - 1]), textcoords="offset points",
                    xytext=(1, -11), fontsize=7, color=INK)
    ax.set_xlim(80, 420)
    ax.set_ylim(63.0, 86.0)
    ax.set_xlabel("Slice-LUT demand (% of XC7Z020, post-synthesis)")
    ax.set_ylabel("Transfer accuracy (%)")
    ax.set_title(f"({'ac'[row]}) {bname}: accuracy vs. cost", loc="left")
    ax.grid(True, color=GRIDC, lw=0.6, alpha=0.8)
    ax.set_axisbelow(True)
    for sp in ("top", "right"):
        ax.spines[sp].set_visible(False)

    xpos = np.arange(3)
    w = 0.2
    dk = np.diff(k)
    for i, name in enumerate(DATA):
        vals = [ (DATA[name][j+1]-DATA[name][j]) / dk[j] * 10 for j in range(3)]
        bars = bx.bar(xpos + (i - 1.5) * w, vals, width=w, color=C[name],
                      label=name if row == 0 else None, zorder=3)
        for r in bars:
            bx.annotate(f"{r.get_height():.2f}",
                        (r.get_x() + r.get_width()/2, r.get_height()),
                        textcoords="offset points", xytext=(0, 2), rotation=90,
                        ha="center", va="bottom", fontsize=6, color=INK)
    bx.set_xticks(xpos); bx.set_xticklabels(steps)
    bx.set_ylabel("Gain per +10k LUTs (pp)")
    bx.set_title(f"({'bd'[row]}) {bname.split(' ')[0]}: marginal return", loc="left")
    bx.set_ylim(0, 1.9)
    bx.grid(True, axis="y", color=GRIDC, lw=0.6, alpha=0.8)
    bx.set_axisbelow(True)
    if row == 0:
        bx.legend(frameon=False, fontsize=6.5, loc="upper right")
    for sp in ("top", "right"):
        bx.spines[sp].set_visible(False)

fig.tight_layout(w_pad=2.0, h_pad=2.4)
fig.savefig("/home/barkie1/mvau_multibranch_synth/fig_2builds.png")
print("saved")
