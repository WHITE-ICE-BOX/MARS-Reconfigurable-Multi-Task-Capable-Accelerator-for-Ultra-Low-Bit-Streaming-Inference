#!/usr/bin/env python3
"""Draft trade-off figure: (a) accuracy vs LUT utilisation with device capacity
line; (b) marginal accuracy return per +10k LUT. Compact build, synthesis stage.
"""
import matplotlib
matplotlib.use("Agg")
import matplotlib.pyplot as plt

# ---- data (Compact build, Zynq-top post-synthesis; accuracy = thesis deployed) ----
lut_pct = [90.1, 135.0, 179.7, 236.0]          # % of XC7Z020 (53,200 LUTs)
Ms      = [1, 2, 3, 4]
dlut_k  = [23.91, 23.75, 29.95]                 # +LUT per branch step (k)

# deployed-geometry accuracies, CIFAR-10 backbone (thesis Table multi_adapter_contrib)
DATA = {
    "SVHN":         [73.72, 77.16, 78.77, 79.81],
    "FashionMNIST": [80.42, 82.00, 82.82, 83.54],
    "STL10":        [67.46, 67.58, 68.00, 68.06],
    "CINIC10":      [64.80, 65.16, 65.38, 65.45],
}
COLORS = {   # categorical slots 1-4 (validated fixed order)
    "SVHN":         "#2a78d6",
    "FashionMNIST": "#c98500",
    "STL10":        "#1baf7a",
    "CINIC10":      "#4a3aa7",
}
MARKERS = {"SVHN": "o", "FashionMNIST": "s", "STL10": "^", "CINIC10": "D"}

def marginal(acc):
    return [(acc[i+1]-acc[i]) / dlut_k[i] * 10 for i in range(3)]

steps = ["M1→M2", "M2→M3", "M3→M4"]
INK    = "#0b0b0b"
MUTED  = "#52514e"
GRIDC  = "#d9d8d4"

plt.rcParams.update({
    "font.size": 9, "axes.edgecolor": MUTED, "axes.labelcolor": INK,
    "xtick.color": MUTED, "ytick.color": MUTED, "axes.titlesize": 9.5,
    "font.family": "Times New Roman",
    "mathtext.fontset": "stix",
})

power_w = [1.841, 1.897, 1.915, 1.969]        # compact, post-synth vectorless (W)

fig, (ax, bx) = plt.subplots(1, 2, figsize=(7.0, 2.9), dpi=200,
                             gridspec_kw={"width_ratios": [1.25, 1]})

# ---------------- panel (a): accuracy vs LUT ----------------
ax.axvspan(100, 260, color="#9a9890", alpha=0.10, zorder=0)
ax.axvline(100, color=MUTED, ls="--", lw=1.2, zorder=1)
ax.text(103, 84.6, "XC7Z020 capacity\n(100% LUT)", fontsize=7.5, color=MUTED,
        ha="left", va="top")

for name, acc in DATA.items():
    c = COLORS[name]
    ax.plot(lut_pct, acc, "-" + MARKERS[name], color=c, lw=2, ms=5.5, zorder=3,
            markerfacecolor=c, markeredgecolor="white", markeredgewidth=1.1)
    ax.text(lut_pct[-1]+4, acc[-1], name, color=c, fontsize=8,
            fontweight="bold", va="center")

for x, m in zip(lut_pct, Ms):
    ax.annotate(f"M={m}", (x, DATA["SVHN"][Ms.index(m)]),
                textcoords="offset points", xytext=(2, -11),
                fontsize=7.5, color=INK)

ax.set_xlim(80, 300)
ax.set_ylim(63.0, 86.0)
ax.set_xlabel("Slice-LUT demand (% of XC7Z020, post-synthesis)")
ax.set_ylabel("Transfer accuracy (%)")
ax.set_title("(a) Accuracy vs. resource cost (Compact build)", loc="left")
ax.grid(True, color=GRIDC, lw=0.6, alpha=0.8)
ax.set_axisbelow(True)
for s in ("top", "right"):
    ax.spines[s].set_visible(False)

# ---------------- panel (b): marginal return ----------------
xpos = range(len(steps))
w = 0.2
names = list(DATA)
for i, name in enumerate(names):
    vals = marginal(DATA[name])
    bars = bx.bar([x + (i - 1.5) * w for x in xpos], vals, width=w,
                  color=COLORS[name], label=name, zorder=3)
    for r in bars:
        bx.annotate(f"{r.get_height():.2f}",
                    (r.get_x() + r.get_width()/2, r.get_height()),
                    textcoords="offset points", xytext=(0, 2), rotation=90,
                    ha="center", va="bottom", fontsize=6.5, color=INK)
bx.set_xticks(list(xpos))
bx.set_xticklabels(steps)
bx.set_ylabel("Accuracy gain per +10k LUTs (pp)")
bx.set_title("(b) Marginal accuracy return", loc="left")
bx.set_ylim(0, 1.9)
bx.grid(True, axis="y", color=GRIDC, lw=0.6, alpha=0.8)
bx.set_axisbelow(True)
bx.legend(frameon=False, fontsize=7, loc="upper right", ncol=1)
for s in ("top", "right"):
    bx.spines[s].set_visible(False)

fig.tight_layout(w_pad=2.0)
fig.savefig("/home/barkie1/mvau_multibranch_synth/fig_tradeoff.pdf")
fig.savefig("/home/barkie1/mvau_multibranch_synth/fig_tradeoff.png")
print("saved fig_tradeoff.{pdf,png}")
