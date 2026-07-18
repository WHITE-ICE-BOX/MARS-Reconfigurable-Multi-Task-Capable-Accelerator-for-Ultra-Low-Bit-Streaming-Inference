#!/usr/bin/env python3
"""Trade-off figure v4 - one message: M=2 has the best cost-performance.
(a) context: accuracy saturates while LUT cost grows linearly (capacity line)
(b) answer:  CP(M) = cumulative accuracy gain over M=1 per 10k extra LUTs,
             maximised at M=2 on every target that benefits.
Compact build, synthesis stage; deployed-geometry accuracies (CIFAR-10 backbone).
"""
import matplotlib
matplotlib.use("Agg")
import matplotlib.pyplot as plt

lut_pct = [90.1, 135.0, 179.7, 236.0]          # % of XC7Z020
lut_k   = [47.931, 71.841, 95.593, 125.538]    # absolute kLUT
Ms      = [1, 2, 3, 4]

DATA = {   # deployed-geometry accuracy, CIFAR-10 backbone
    "SVHN":         [73.72, 77.16, 78.77, 79.81],
    "FashionMNIST": [80.42, 82.00, 82.82, 83.54],
    "STL10":        [67.46, 67.58, 68.00, 68.06],
    "CINIC10":      [64.80, 65.16, 65.38, 65.45],
}
MAIN   = ["SVHN", "FashionMNIST"]
COLORS = {"SVHN": "#2a78d6", "FashionMNIST": "#c98500",
          "STL10": "#9a9890", "CINIC10": "#9a9890"}
MARKERS = {"SVHN": "o", "FashionMNIST": "s", "STL10": "^", "CINIC10": "D"}

def cp(acc):
    """cumulative pp gained over M=1 per +10k LUTs"""
    return [(acc[i] - acc[0]) / (lut_k[i] - lut_k[0]) * 10 for i in (1, 2, 3)]

INK, MUTED, GRIDC = "#0b0b0b", "#52514e", "#d9d8d4"
plt.rcParams.update({
    "font.size": 9, "axes.edgecolor": MUTED, "axes.labelcolor": INK,
    "xtick.color": MUTED, "ytick.color": MUTED, "axes.titlesize": 9.5,
    "font.family": "Times New Roman", "mathtext.fontset": "stix",
})

fig, (ax, bx) = plt.subplots(1, 2, figsize=(7.2, 3.0), dpi=200,
                             gridspec_kw={"width_ratios": [1.15, 1]})

# ---- (a) context: saturation vs linear cost ----
ax.axvspan(100, 300, color="#9a9890", alpha=0.10, zorder=0)
ax.axvline(100, color=MUTED, ls="--", lw=1.2, zorder=1)
ax.text(104, 85.4, "beyond XC7Z020", fontsize=7.5, color=MUTED, ha="left", va="top")

for name in ("STL10", "CINIC10"):
    ax.plot(lut_pct, DATA[name], "-" + MARKERS[name], color=COLORS[name],
            lw=1.2, ms=4, zorder=2, alpha=0.9)
    ax.text(lut_pct[-1] + 4, DATA[name][-1], name, color=MUTED, fontsize=7.5,
            va="center")
for name in MAIN:
    c = COLORS[name]
    ax.plot(lut_pct, DATA[name], "-" + MARKERS[name], color=c, lw=2.2, ms=6,
            zorder=3, markerfacecolor=c, markeredgecolor="white",
            markeredgewidth=1.2)
    ax.text(lut_pct[-1] + 4, DATA[name][-1], name, color=c, fontsize=8.5,
            fontweight="bold", va="center")

for x, m in zip(lut_pct, Ms):
    ax.annotate(f"M={m}", (x, DATA["SVHN"][m - 1]), textcoords="offset points",
                xytext=(1, -12), fontsize=7.5, color=INK)

ax.annotate("steepest gain:\nM=1$\\rightarrow$2", xy=(112, 75.6),
            xytext=(150, 71.5), fontsize=8, color=COLORS["SVHN"],
            arrowprops=dict(arrowstyle="->", color=COLORS["SVHN"], lw=1.2))
ax.annotate("little gain on easy-transfer targets:\nbranches not worth the area",
            xy=(165, 70.2), fontsize=7.5, color=MUTED, ha="center")

ax.set_xlim(80, 305)
ax.set_ylim(63.0, 86.0)
ax.set_xlabel("Slice-LUT demand (% of XC7Z020, post-synthesis)")
ax.set_ylabel("Transfer accuracy (%)")
ax.set_title("(a) Accuracy saturates while cost grows linearly", loc="left")
ax.grid(True, color=GRIDC, lw=0.6, alpha=0.8)
ax.set_axisbelow(True)
for sp in ("top", "right"):
    ax.spines[sp].set_visible(False)

# ---- (b) answer: CP is maximised at M=2 ----
xpos = [0, 1, 2]
w = 0.38
for i, name in enumerate(MAIN):
    vals = cp(DATA[name])
    bars = bx.bar([x + (i - 0.5) * w for x in xpos], vals, width=w,
                  color=COLORS[name], label=name, zorder=3)
    for r, v in zip(bars, vals):
        bx.annotate(f"{v:.2f}", (r.get_x() + r.get_width() / 2, v),
                    textcoords="offset points", xytext=(0, 2),
                    ha="center", fontsize=7.5, color=INK)

best = cp(DATA["SVHN"])[0]
bx.annotate("* best CP", xy=(0 - w / 2, best + 0.14), ha="center", fontsize=9,
            color=COLORS["SVHN"], fontweight="bold")

bx.set_xticks(xpos)
bx.set_xticklabels(["M=2", "M=3", "M=4"])
bx.set_xlabel("Branch count (vs. M=1 baseline)")
bx.set_ylabel("Accuracy gain per +10k LUTs (pp)")
bx.set_title("(b) Cost-performance peaks at M=2", loc="left")
bx.set_ylim(0, 1.8)
bx.grid(True, axis="y", color=GRIDC, lw=0.6, alpha=0.8)
bx.set_axisbelow(True)
bx.legend(frameon=False, fontsize=8, loc="upper right")
for sp in ("top", "right"):
    bx.spines[sp].set_visible(False)

fig.tight_layout(w_pad=2.0)
fig.savefig("/home/barkie1/mvau_multibranch_synth/fig_tradeoff_v4.pdf")
fig.savefig("/home/barkie1/mvau_multibranch_synth/fig_tradeoff_v4.png")
print("saved v4")
