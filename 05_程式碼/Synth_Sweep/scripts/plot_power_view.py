#!/usr/bin/env python3
"""Power trade-off in the same gain-view language (v3 family)."""
import matplotlib
matplotlib.use("Agg")
import matplotlib.pyplot as plt
import numpy as np

Ms = [1, 2, 3, 4]
mean_gain = [0.0, 1.72, 2.58, 3.53]        # mean of 16 deployed pairs (pp)
POWER = {
    "Compact (multi-dataset)":   dict(w=[1.841, 1.897, 1.915, 1.969], c="#2a78d6", mk="o"),
    "Throughput (2-dataset)":    dict(w=[2.135, 2.193, 2.337, 2.468], c="#c98500", mk="s"),
}
INK, MUTED, GRIDC = "#0b0b0b", "#52514e", "#d9d8d4"
plt.rcParams.update({"font.size": 10, "axes.edgecolor": MUTED, "axes.labelcolor": INK,
    "xtick.color": MUTED, "ytick.color": MUTED, "axes.titlesize": 11,
    "font.family": "Times New Roman", "mathtext.fontset": "stix"})

fig, ax = plt.subplots(figsize=(5.8, 4.0), dpi=300)
for name, d in POWER.items():
    ax.plot(d["w"], mean_gain, "-" + d["mk"], color=d["c"], lw=2.4, ms=7.5,
            zorder=3, markerfacecolor=d["c"], markeredgecolor="white",
            markeredgewidth=1.2, label=name)
    for x, y, m in zip(d["w"], mean_gain, Ms):
        ax.annotate(f"M={m}", (x, y), xytext=(0, -15), textcoords="offset points",
                    ha="center", fontsize=8.5, color=d["c"])
# total power cost of the full sweep
ax.annotate("full M=1→4 sweep:\n+0.128 W (+7.0%)", xy=(1.969, 3.53),
            xytext=(1.99, 1.30), fontsize=9, color="#2a78d6",
            arrowprops=dict(arrowstyle="->", color="#2a78d6", lw=1.1))
ax.annotate("full M=1→4 sweep:\n+0.333 W (+15.6%)", xy=(2.468, 3.50),
            xytext=(2.46, 1.30), ha="right", fontsize=9, color="#c98500",
            arrowprops=dict(arrowstyle="->", color="#c98500", lw=1.1))
ax.set_xlabel("Total on-chip power (W, post-synthesis estimate, incl. PS)")
ax.set_ylabel("Mean accuracy gain over M=1 (pp, 16 pairs)")
ax.set_title("Power trade-off: the whole sweep costs a fraction of a watt", loc="left")
ax.set_ylim(-0.5, 4.4)
ax.grid(True, color=GRIDC, lw=0.6, alpha=0.8)
ax.set_axisbelow(True)
ax.legend(frameon=False, fontsize=9, loc="upper left")
for sp in ("top", "right"):
    ax.spines[sp].set_visible(False)
fig.tight_layout()
fig.savefig("mvau_multibranch_synth/fig16/power_view.png")
print("saved power_view")
