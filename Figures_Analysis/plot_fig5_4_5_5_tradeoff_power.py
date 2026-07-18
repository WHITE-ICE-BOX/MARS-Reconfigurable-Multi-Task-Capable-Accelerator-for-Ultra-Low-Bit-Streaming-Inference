#!/usr/bin/env python3
"""Final trade-off set: 4 separate figures.
  {Compact, Throughput} x {LUT resource axis, power axis}
Lines: best pair (dashed), hard-transfer mean (bold), easy-transfer mean (gray).
Edit data below and rerun."""
import matplotlib
matplotlib.use("Agg")
import matplotlib.pyplot as plt

Ms = [1, 2, 3, 4]
HARD = [0.0, 2.84, 3.78, 5.52]     # mean gain, 8 deployed pairs (total >= 3pp)
EASY = [0.0, 0.60, 1.37, 1.53]     # mean gain, other 8 pairs
BEST = [0.0, 6.82, 8.05, 11.33]    # FashionMNIST -> SVHN
BUILDS = {
    "compact":    dict(name="Compact (multi-dataset)",
                       pct=[90.1, 135.0, 179.7, 236.0],
                       w=[1.841, 1.897, 1.915, 1.969]),
    "throughput": dict(name="Throughput (2-dataset)",
                       pct=[137.5, 206.3, 272.7, 352.5],
                       w=[2.135, 2.193, 2.337, 2.468]),
}
C_BEST, C_HARD, C_EASY = "#4a3aa7", "#e34948", "0.55"
MUTED, GRIDC = "#52514e", "#dcdbd7"
plt.rcParams.update({"font.family": "Times New Roman", "font.size": 11,
    "mathtext.fontset": "stix", "axes.linewidth": 1.0,
    "xtick.direction": "in", "ytick.direction": "in"})

def draw(tag, axis):   # axis in {"lut", "power"}
    b = BUILDS[tag]
    if axis == "power":
        return draw_power(tag)
    x = b["pct"]
    MEAN16 = [0.0, 1.73, 2.52, 3.36]   # mean gain, all 20 pairs
    HARD8  = [0.0, 3.05, 4.05, 5.71]   # mean gain, 9 large-gain pairs (>=3pp)
    EASY8  = [0.0, 0.65, 1.27, 1.43]   # mean gain, 11 small-gain pairs
    IMPL_M1 = {"compact": 75.1, "throughput": 78.4}  # post-P&R M=1 (Table 5.16)
    fig, ax = plt.subplots(figsize=(5.6, 4.15), dpi=300)
    ax.axvspan(100, max(x) * 1.25, color="#9a9890", alpha=0.10, zorder=0)
    ax.axvline(100, color=MUTED, ls="--", lw=1.2, zorder=1)
    if tag == "compact":
        ax.text(0.16, 0.97, "beyond XC7Z020 (100% LUT)",
                transform=ax.transAxes, fontsize=8, color=MUTED,
                ha="left", va="top")
    else:
        ax.text(0.30, 0.97, "post-synthesis demand beyond XC7Z020",
                transform=ax.transAxes, fontsize=8, color=MUTED,
                ha="left", va="top")
    # groups
    ax.plot(x, HARD8, "s--", color="#4a3aa7", lw=1.7, ms=5.5, zorder=3,
            label="large-gain transfers (mean, 9 pairs)")
    ax.plot(x, EASY8, "^-", color="0.55", lw=1.7, ms=5.5, zorder=2,
            label="small-gain transfers (mean, 11 pairs)")
    # overall mean, primary
    ax.plot(x, MEAN16, "-", color=C_HARD, lw=3.0, zorder=4,
            label="mean of all 20 pairs")
    ax.plot(x, MEAN16, "o", color=C_HARD, ms=13, zorder=5,
            markeredgecolor="white", markeredgewidth=1.4)
    for xi, yi, m in zip(x, MEAN16, Ms):
        ax.annotate(str(m), (xi, yi), ha="center", va="center",
                    fontsize=8.5, fontweight="bold", color="white", zorder=6)
    for i in range(3):
        d = MEAN16[i+1] - MEAN16[i]
        if i == 0:
            xl = x[0] + 0.75 * (x[1] - x[0])
            yl = 0.68
        else:
            xl = (x[i] + x[i+1]) / 2
            yl = (MEAN16[i] + MEAN16[i+1]) / 2 + 0.5
        ax.text(xl, yl, f"Δ+{d:.2f}", ha="center", va="center",
                fontsize=9.5, fontweight="bold", color=C_HARD, zorder=6)
    # per-step deltas for the large-gain (above its line) and small-gain (below) groups
    for arr, col, dy, va in [(HARD8, "#4a3aa7", 0.46, "bottom"),
                             (EASY8, "0.40", -0.40, "top")]:
        for i in range(3):
            d = arr[i+1] - arr[i]
            xm = (x[i] + x[i+1]) / 2
            ym = (arr[i] + arr[i+1]) / 2 + dy
            ax.text(xm, ym, f"+{d:.2f}", ha="center", va=va,
                    fontsize=9.5, fontweight="bold", color=col, zorder=6)
    # deployed M=1 point after place-and-route (synthesis-stage overstatement)
    ax.plot(IMPL_M1[tag], 0, "o", ms=8, markerfacecolor="white",
            markeredgecolor="black", markeredgewidth=1.3, zorder=5,
            clip_on=False)
    # per-panel placement: clear of y-axis, tick labels, curves and the +3.05 annotation
    if tag == "compact":
        lbl_x, lbl_y, lbl_ha = IMPL_M1[tag] - 8, 2.6, "left"
    else:
        lbl_x, lbl_y, lbl_ha = IMPL_M1[tag] + 5, 1.45, "left"
    ax.annotate(f"deployed M=1\nafter P&R: {IMPL_M1[tag]:.1f}%",
                xy=(IMPL_M1[tag], 0.06), xytext=(lbl_x, lbl_y),
                ha=lbl_ha, va="bottom", fontsize=9, color="black",
                linespacing=1.3, zorder=7,
                bbox=dict(facecolor="white", edgecolor="0.75", lw=0.6,
                          boxstyle="round,pad=0.32", alpha=0.95),
                arrowprops=dict(arrowstyle="-", color="0.45", lw=0.9,
                                shrinkA=2, shrinkB=3))
    ax.set_xlabel("Slice-LUT demand (% of XC7Z020, post-synthesis)")
    ax.set_xlim(min(min(x), IMPL_M1[tag]) - 12, max(x) * 1.12)
    if tag == "throughput":  # force a low tick so the 78.4% P&R marker is clearly framed (match panel a)
        ax.set_xticks([75, 100, 150, 200, 250, 300, 350])
    ax.set_ylabel("Accuracy gain over M=1 (pp)")
    ax.set_ylim(-0.45, 6.3)
    fig.legend(frameon=False, fontsize=7.8, loc="lower center",
               bbox_to_anchor=(0.5, 0.0), ncol=3, columnspacing=0.9,
               handlelength=1.5, handletextpad=0.5)
    ax.grid(True, color=GRIDC, lw=0.6)
    ax.set_axisbelow(True)
    fig.tight_layout(rect=(0, 0.065, 1, 1))
    fig.savefig(f"/home/barkie1/mvau_multibranch_synth/fig16/final_{tag}_lut.png")
    fig.savefig(f"/home/barkie1/mvau_multibranch_synth/fig16/final_{tag}_lut.pdf")
    plt.close(fig)


def draw_power(tag):
    """Power IS the measured quantity: bars of total power per M (near-flat),
    per-step mW deltas above the gaps, mean accuracy gain under each tick."""
    b = BUILDS[tag]
    w = b["w"]
    col = "#2a78d6" if tag == "compact" else "#c98500"
    fig, ax = plt.subplots(figsize=(5.6, 4.15), dpi=300)
    bars = ax.bar(range(4), w, 0.58, color=col, zorder=3)
    for r, wi in zip(bars, w):
        ax.annotate(f"{wi:.3f} W", (r.get_x() + r.get_width()/2, wi),
                    xytext=(0, 4), textcoords="offset points", ha="center",
                    fontsize=9.5, fontweight="bold", color=col)
    STEP_GAIN = [1.73, 0.79, 0.84]   # per-step mean accuracy gain, all 20 pairs
    for i in range(3):
        d = (w[i+1] - w[i]) * 1000
        ax.annotate(f"+{d:.0f} mW", (i + 0.5, max(w) * 1.135),
                    ha="center", fontsize=9, color=MUTED)
        ax.annotate(f"gain +{STEP_GAIN[i]:.2f} pp", (i + 0.5, max(w) * 1.075),
                    ha="center", fontsize=8.5, fontweight="bold", color=C_HARD)
        ax.annotate("", xy=(i + 0.79, max(w) * 1.035),
                    xytext=(i + 0.21, max(w) * 1.035),
                    arrowprops=dict(arrowstyle="->", color=MUTED, lw=0.9))
    total_d = (w[3] - w[0]) * 1000
    ax.annotate(f"full M=1→4 sweep: +{total_d:.0f} mW (+{(w[3]/w[0]-1)*100:.1f}%)",
                (0.5, 0.965), xycoords="axes fraction", ha="center",
                fontsize=10, fontweight="bold", color=col)
    ax.set_xticks(range(4))
    ax.set_xticklabels([f"M={m}" for m in Ms], fontsize=10)
    ax.set_ylabel("Total on-chip power (W, post-synthesis estimate)")
    ax.set_ylim(0, max(w) * 1.32)
    ax.grid(True, axis="y", color=GRIDC, lw=0.6)
    ax.set_axisbelow(True)
    fig.tight_layout()
    fig.savefig(f"/home/barkie1/mvau_multibranch_synth/fig16/final_{tag}_power.png")
    fig.savefig(f"/home/barkie1/mvau_multibranch_synth/fig16/final_{tag}_power.pdf")
    plt.close(fig)


for tag in BUILDS:
    for axis in ("lut", "power"):
        draw(tag, axis)
print("saved 4 finals")
