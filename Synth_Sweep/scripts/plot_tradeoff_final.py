#!/usr/bin/env python3
"""Full trade-off: accuracy gain vs LUT cost, power annotated per point.
y = mean gain of hard transfers (8 deployed pairs, total gain >= 3pp).
Two curves = Compact / Throughput builds. Edit data, rerun."""
import matplotlib
matplotlib.use("Agg")
import matplotlib.pyplot as plt
import numpy as np

Ms = [1, 2, 3, 4]
# mean accuracy gain over M=1 (pp): hard transfers (8 pairs) / easy (8 pairs)
HARD = [0.0, 2.84, 3.78, 5.52]
EASY = [0.0, 0.60, 1.37, 1.53]
BUILDS = {
    "Compact (multi-dataset)":  dict(pct=[90.1, 135.0, 179.7, 236.0],
                                     w=[1.841, 1.897, 1.915, 1.969],
                                     c="#2a78d6", mk="o"),
    "Throughput (2-dataset)":   dict(pct=[137.5, 206.3, 272.7, 352.5],
                                     w=[2.135, 2.193, 2.337, 2.468],
                                     c="#c98500", mk="s"),
}
INK, MUTED, GRIDC = "#0b0b0b", "#52514e", "#dcdbd7"
plt.rcParams.update({"font.family": "Times New Roman", "font.size": 11,
    "mathtext.fontset": "stix", "axes.linewidth": 1.0,
    "xtick.direction": "in", "ytick.direction": "in"})

fig, ax = plt.subplots(figsize=(6.4, 4.4), dpi=300)
ax.axvspan(100, 400, color="#9a9890", alpha=0.10, zorder=0)
ax.axvline(100, color=MUTED, ls="--", lw=1.2, zorder=1)
ax.text(103, 6.35, "beyond XC7Z020 (100% LUT)", fontsize=8.5, color=MUTED, va="top")

for name, b in BUILDS.items():
    ax.plot(b["pct"], HARD, "-" + b["mk"], color=b["c"], lw=2.6, ms=8, zorder=4,
            markerfacecolor=b["c"], markeredgecolor="white", markeredgewidth=1.2,
            label=name)
    for x, y, m, w in zip(b["pct"], HARD, Ms, b["w"]):
        if name.startswith("Compact"):
            dx, dy, ha = -6, -26, "center"
            if m == 2: dx, dy, ha = -34, -8, "center"
        else:
            dx, dy, ha = 0, 10, "center"
            if m == 1: dx, dy, ha = 30, -6, "left"
        ax.annotate(f"M={m}\n{w:.2f} W", (x, y), xytext=(dx, dy),
                    textcoords="offset points", ha=ha, fontsize=8,
                    color=b["c"], linespacing=1.1)
# easy transfers reference (compact axis), flat
ax.plot(BUILDS["Compact (multi-dataset)"]["pct"], EASY, "^-", color="0.62",
        lw=1.6, ms=5, zorder=2, label="easy transfers (mean of 8 pairs)")

ax.set_xlim(75, 400)
ax.set_ylim(-0.6, 6.6)
ax.set_xlabel("Slice-LUT demand (% of XC7Z020, post-synthesis)")
ax.set_ylabel("Accuracy gain over M=1 (pp)\nhard transfers, mean of 8 deployed pairs")
ax.legend(frameon=False, fontsize=9, loc="lower right")
ax.grid(True, color=GRIDC, lw=0.6)
ax.set_axisbelow(True)
fig.tight_layout()
fig.savefig("/home/barkie1/mvau_multibranch_synth/fig16/tradeoff_final.png")
fig.savefig("/home/barkie1/mvau_multibranch_synth/fig16/tradeoff_final.pdf")
print("saved tradeoff_final")
