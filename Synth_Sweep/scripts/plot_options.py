#!/usr/bin/env python3
"""Ten structurally different presentations of the M1-M4 cost-performance
trade-off (deployed-geometry accuracy, compact-build synthesis cost)."""
import matplotlib
matplotlib.use("Agg")
import matplotlib.pyplot as plt
import numpy as np

OUT = "mvau_multibranch_synth/fig_opts"
import os
os.makedirs(OUT, exist_ok=True)

lut_k   = np.array([47.931, 71.841, 95.593, 125.538])
lut_pct = lut_k / 53.2 * 100 / 10  # /10 later; compute properly below
lut_pct = np.array([90.1, 135.0, 179.7, 236.0])
power_w = np.array([1.841, 1.897, 1.915, 1.969])
Ms = [1, 2, 3, 4]
DATA = {
    "SVHN":         np.array([73.72, 77.16, 78.77, 79.81]),
    "FashionMNIST": np.array([80.42, 82.00, 82.82, 83.54]),
    "STL10":        np.array([67.46, 67.58, 68.00, 68.06]),
    "CINIC10":      np.array([64.80, 65.16, 65.38, 65.45]),
}
C = {"SVHN": "#2a78d6", "FashionMNIST": "#c98500",
     "STL10": "#1baf7a", "CINIC10": "#4a3aa7"}
MK = {"SVHN": "o", "FashionMNIST": "s", "STL10": "^", "CINIC10": "D"}
INK, MUTED, GRIDC = "#0b0b0b", "#52514e", "#dcdbd7"
MAIN = ["SVHN", "FashionMNIST"]

plt.rcParams.update({
    "font.size": 9, "axes.edgecolor": MUTED, "axes.labelcolor": INK,
    "xtick.color": MUTED, "ytick.color": MUTED, "axes.titlesize": 10,
    "font.family": "Times New Roman", "mathtext.fontset": "stix",
})

def cum_cp(acc):   # pp per +10k LUT relative to M=1
    return [(acc[i] - acc[0]) / (lut_k[i] - lut_k[0]) * 10 for i in (1, 2, 3)]

def newfig(w=5.4, h=3.4):
    f, a = plt.subplots(figsize=(w, h), dpi=200)
    a.set_axisbelow(True)
    for sp in ("top", "right"):
        a.spines[sp].set_visible(False)
    return f, a

def save(f, n):
    f.tight_layout()
    f.savefig(f"{OUT}/option{n:02d}.png")
    plt.close(f)
    print("option", n)

# ---------------- Option 1: Pareto + iso-CP rays from M=1 ----------------
f, a = newfig(5.8, 3.6)
a.axvline(100, color=MUTED, ls="--", lw=1)
a.text(101, 84.8, "XC7Z020 limit", fontsize=7, color=MUTED)
x0, y0 = lut_pct[0], DATA["SVHN"][0]
for slope_pp10k, style in [(1.44, "-"), (0.7, "--"), (0.35, ":")]:
    xs = np.linspace(x0, 300, 10)
    ys = y0 + (xs - x0) * 53.2 / 100 / 10 * slope_pp10k
    a.plot(xs, ys, style, color="#b9b7b0", lw=1, zorder=1)
    a.annotate(f"{slope_pp10k} pp/10k LUT", (295, y0 + (295-x0)*53.2/1000*slope_pp10k),
               fontsize=6.5, color=MUTED, ha="right", va="bottom")
for nme in MAIN:
    a.plot(lut_pct, DATA[nme], MK[nme], color=C[nme], ms=8, zorder=3,
           markeredgecolor="white", markeredgewidth=1.2, label=nme)
    for x, y, m in zip(lut_pct, DATA[nme], Ms):
        a.annotate(f"M{m}", (x, y), xytext=(0, 8), textcoords="offset points",
                   ha="center", fontsize=7.5, color=C[nme])
a.set_xlim(80, 305); a.set_ylim(72, 86)
a.set_xlabel("LUT demand (% of XC7Z020)"); a.set_ylabel("Accuracy (%)")
a.set_title("Option 1 — Pareto points + iso-CP reference rays", loc="left")
a.grid(True, color=GRIDC, lw=0.5); a.legend(frameon=False, fontsize=8, loc="lower right")
save(f, 1)

# ---------------- Option 2: CP efficiency curve vs M ----------------
f, a = newfig()
a.axvspan(1.75, 2.25, color="#1baf7a", alpha=0.12)
a.text(2, 1.62, "sweet spot", ha="center", fontsize=8.5, color="#0e7a52")
for nme in MAIN:
    v = cum_cp(DATA[nme])
    a.plot([2, 3, 4], v, "-" + MK[nme], color=C[nme], lw=2, ms=7,
           markeredgecolor="white", markeredgewidth=1.1, label=nme)
    for x, y in zip([2, 3, 4], v):
        a.annotate(f"{y:.2f}", (x, y), xytext=(0, 7), textcoords="offset points",
                   ha="center", fontsize=7.5, color=C[nme])
a.set_xticks([2, 3, 4]); a.set_xticklabels(["M=2", "M=3", "M=4"])
a.set_ylim(0, 1.8)
a.set_ylabel("CP: accuracy gain per +10k LUTs (pp)")
a.set_title("Option 2 — CP efficiency curve (peak = best)", loc="left")
a.grid(True, color=GRIDC, lw=0.5); a.legend(frameon=False, fontsize=8)
save(f, 2)

# ---------------- Option 3: price of +1pp (inverse CP) ----------------
f, a = newfig()
price_s = [(lut_k[i] - lut_k[0]) / (DATA["SVHN"][i] - DATA["SVHN"][0]) for i in (1, 2, 3)]
price_f = [(lut_k[i] - lut_k[0]) / (DATA["FashionMNIST"][i] - DATA["FashionMNIST"][0]) for i in (1, 2, 3)]
x = np.arange(3); w = 0.38
b1 = a.bar(x - w/2, price_s, w, color=C["SVHN"], label="SVHN")
b2 = a.bar(x + w/2, price_f, w, color=C["FashionMNIST"], label="FashionMNIST")
for bars in (b1, b2):
    for r in bars:
        a.annotate(f"{r.get_height():.1f}k", (r.get_x()+r.get_width()/2, r.get_height()),
                   xytext=(0, 2), textcoords="offset points", ha="center", fontsize=7.5)
a.set_xticks(x); a.set_xticklabels(["M=2", "M=3", "M=4"])
a.set_ylabel("LUTs paid per +1 pp accuracy (k)")
a.set_title("Option 3 — the price of one point keeps rising", loc="left")
a.grid(True, axis="y", color=GRIDC, lw=0.5); a.legend(frameon=False, fontsize=8, loc="upper left")
save(f, 3)

# ---------------- Option 4: % of gain captured vs % cost paid ----------------
f, a = newfig(5.8, 3.5)
gain = (DATA["SVHN"] - DATA["SVHN"][0]) / (DATA["SVHN"][3] - DATA["SVHN"][0]) * 100
cost = (lut_k - lut_k[0]) / (lut_k[3] - lut_k[0]) * 100
a.plot(Ms, gain, "-o", color=C["SVHN"], lw=2.2, ms=7, label="accuracy gain captured (%)",
       markeredgecolor="white", markeredgewidth=1.1)
a.plot(Ms, cost, "-s", color="#e34948", lw=2.2, ms=7, label="extra LUT cost paid (%)",
       markeredgecolor="white", markeredgewidth=1.1)
a.fill_between(Ms, gain, cost, where=gain >= cost, color="#1baf7a", alpha=0.15)
a.annotate("M=2: 57% of the gain\nfor 31% of the cost", xy=(2, 56.5), xytext=(2.5, 30),
           fontsize=8.5, color="#0e7a52",
           arrowprops=dict(arrowstyle="->", color="#0e7a52", lw=1.1))
for x, y in zip(Ms, gain):
    a.annotate(f"{y:.0f}%", (x, y), xytext=(0, 7), textcoords="offset points",
               ha="center", fontsize=7.5, color=C["SVHN"])
a.set_xticks(Ms); a.set_xticklabels([f"M={m}" for m in Ms])
a.set_ylabel("% of M=4 total (SVHN)")
a.set_title("Option 4 — gain captured vs. cost paid", loc="left")
a.grid(True, color=GRIDC, lw=0.5); a.legend(frameon=False, fontsize=8, loc="upper left")
save(f, 4)

# ---------------- Option 5: variable-width waterfall (area = cost) ----------------
f, a = newfig(5.8, 3.5)
acc = DATA["SVHN"]
for i in range(3):
    x0b, x1b = lut_k[i], lut_k[i+1]
    a.fill_between([x0b, x1b], acc[i], acc[i+1], step=None,
                   color=C["SVHN"], alpha=0.25 + 0.02*i)
    a.plot([x0b, x1b], [acc[i], acc[i+1]], "-", color=C["SVHN"], lw=2.4)
    a.annotate(f"+{acc[i+1]-acc[i]:.2f} pp\nfor +{lut_k[i+1]-lut_k[i]:.1f}k LUT",
               ((x0b+x1b)/2, (acc[i]+acc[i+1])/2 - 0.9), ha="center",
               fontsize=7.5, color=INK)
a.plot(lut_k, acc, "o", color=C["SVHN"], ms=7, markeredgecolor="white", markeredgewidth=1.1, zorder=3)
for x, y, m in zip(lut_k, acc, Ms):
    a.annotate(f"M={m}", (x, y), xytext=(0, 8), textcoords="offset points",
               ha="center", fontsize=8, color=INK)
a.axvline(53.2, color="#e34948", ls="--", lw=1.2)
a.text(54, 74.0, "XC7Z020\n(53.2k LUTs)", fontsize=7.5, color="#e34948")
a.set_xlabel("Slice LUTs (k, post-synthesis)"); a.set_ylabel("SVHN accuracy (%)")
a.set_title("Option 5 — each step: what you pay vs. what you get (SVHN)", loc="left")
a.grid(True, color=GRIDC, lw=0.5)
save(f, 5)

# ---------------- Option 6: mirrored bars (gain up, cost down) ----------------
f, a = newfig(5.6, 3.6)
steps = ["M1→M2", "M2→M3", "M3→M4"]
dacc = np.diff(DATA["SVHN"]); dlut = np.diff(lut_k)
x = np.arange(3)
a.bar(x, dacc, 0.55, color=C["SVHN"], label="accuracy gained (pp, SVHN)")
a.bar(x, -dlut/10, 0.55, color="#9a9890", label="LUTs paid (×10k)")
for xi, v in zip(x, dacc):
    a.annotate(f"+{v:.2f} pp", (xi, v), xytext=(0, 3), textcoords="offset points",
               ha="center", fontsize=8, color=C["SVHN"])
for xi, v in zip(x, dlut):
    a.annotate(f"−{v:.1f}k LUT", (xi, -v/10), xytext=(0, -11), textcoords="offset points",
               ha="center", fontsize=8, color=MUTED)
a.axhline(0, color=INK, lw=0.8)
a.set_xticks(x); a.set_xticklabels(steps)
a.set_yticks([])
a.set_title("Option 6 — shrinking gain, constant price (per step)", loc="left")
a.legend(frameon=False, fontsize=8, loc="lower left")
a.set_ylim(-3.6, 4.2)
save(f, 6)

# ---------------- Option 7: marginal gain vs marginal cost plane ----------------
f, a = newfig(5.6, 3.6)
for nme in MAIN:
    dacc = np.diff(DATA[nme]); dlut = np.diff(lut_k)
    for i, (dx, dy) in enumerate(zip(dlut, dacc)):
        a.scatter(dx, dy, s=90, color=C[nme], marker=MK[nme], zorder=3,
                  edgecolor="white", linewidth=1.1)
        a.annotate(f"M{i+1}→{i+2}", (dx, dy), xytext=(6, 4),
                   textcoords="offset points", fontsize=7.5, color=C[nme])
xs = np.linspace(20, 33, 5)
for cpv in (0.5, 1.0, 1.5):
    a.plot(xs, xs/10*cpv, "--", color="#c9c7c0", lw=0.9, zorder=1)
    a.annotate(f"CP={cpv}", (32.6, 32.6/10*cpv), fontsize=6.5, color=MUTED, va="bottom", ha="right")
a.set_xlabel("marginal cost: extra LUTs (k)"); a.set_ylabel("marginal gain (pp)")
a.set_title("Option 7 — every step drifts to worse CP (down-right)", loc="left")
a.grid(True, color=GRIDC, lw=0.5)
sv = plt.Line2D([], [], marker="o", ls="", color=C["SVHN"], label="SVHN")
fa = plt.Line2D([], [], marker="s", ls="", color=C["FashionMNIST"], label="FashionMNIST")
a.legend(handles=[sv, fa], frameon=False, fontsize=8, loc="upper left")
save(f, 7)

# ---------------- Option 8: scorecard heat-table ----------------
f, a = newfig(6.4, 3.0)
cols = ["SVHN\nacc (%)", "Fashion\nacc (%)", "LUT\n(% dev.)", "Power\n(W)", "CP vs M=1\n(pp/10k LUT)"]
rows = [f"M={m}" for m in Ms]
cpv = [np.nan] + cum_cp(DATA["SVHN"])
cells = np.array([
    [DATA["SVHN"][i], DATA["FashionMNIST"][i], lut_pct[i], power_w[i], cpv[i]]
    for i in range(4)])
norm = np.zeros_like(cells)
for j in range(cells.shape[1]):
    col = cells[:, j]
    good_high = j in (0, 1, 4)
    v = col.copy()
    if not good_high: v = -v
    vmin, vmax = np.nanmin(v), np.nanmax(v)
    norm[:, j] = (v - vmin) / (vmax - vmin + 1e-9)
a.imshow(norm, cmap="Greens", vmin=-0.3, vmax=1.6, aspect="auto")
for i in range(4):
    for j in range(5):
        val = cells[i, j]
        txt = "—" if np.isnan(val) else (f"{val:.2f}" if j in (3, 4) else f"{val:.1f}")
        a.text(j, i, txt, ha="center", va="center", fontsize=9, color=INK)
a.add_patch(plt.Rectangle((-0.5, 0.5), 5, 1, fill=False, edgecolor="#e34948", lw=2))
a.text(4.62, 1, "← best CP", color="#e34948", fontsize=8.5, va="center")
a.set_xticks(range(5)); a.set_xticklabels(cols, fontsize=7.5)
a.set_yticks(range(4)); a.set_yticklabels(rows)
a.set_title("Option 8 — scorecard: greener = better, M=2 row wins CP", loc="left")
a.tick_params(length=0)
for sp in a.spines.values(): sp.set_visible(False)
save(f, 8)

# ---------------- Option 9: dumbbell (dots bunch up after M=2) ----------------
f, a = newfig(6.0, 3.2)
names = list(DATA)
shade = {1: 0.35, 2: 0.6, 3: 0.8, 4: 1.0}
for yi, nme in enumerate(names):
    acc = DATA[nme]
    a.plot([acc[0], acc[-1]], [yi, yi], "-", color="#d6d4cf", lw=3, zorder=1)
    for m, v in zip(Ms, acc):
        a.scatter(v, yi, s=110*shade[m], color=C[nme], alpha=shade[m], zorder=3,
                  edgecolor="white", linewidth=1.0)
        if yi == 0:
            a.annotate(f"M{m}", (v, yi), xytext=(0, 12), textcoords="offset points",
                       ha="center", fontsize=7.5, color=INK)
    a.annotate(f"+{acc[-1]-acc[0]:.1f} pp total, +162% LUT", (acc[-1]+0.4, yi),
               fontsize=7.5, color=MUTED, va="center")
a.set_yticks(range(4)); a.set_yticklabels(names)
a.set_xlabel("Accuracy (%)  (dot size/darkness = branch count M)")
a.set_xlim(62, 92)
a.set_title("Option 9 — dots bunch up after M=2: later branches buy little", loc="left")
a.grid(True, axis="x", color=GRIDC, lw=0.5)
save(f, 9)

# ---------------- Option 10: small multiples (one mini panel per M) ----------------
f, axs = plt.subplots(1, 4, figsize=(7.6, 3.0), dpi=200, sharey=True)
for i, (m, axm) in enumerate(zip(Ms, axs)):
    gains = [DATA[n][i] - DATA[n][0] for n in MAIN]
    axm.bar([0, 1], gains, 0.6, color=[C[n] for n in MAIN])
    axm.set_title(f"M={m}\n{lut_pct[i]:.0f}% LUT, {power_w[i]:.2f} W",
                  fontsize=8.5)
    axm.set_xticks([0, 1]); axm.set_xticklabels(["SVHN", "Fash."], fontsize=7.5)
    axm.grid(True, axis="y", color=GRIDC, lw=0.5)
    axm.set_axisbelow(True)
    for sp in ("top", "right"): axm.spines[sp].set_visible(False)
    if lut_pct[i] > 100:
        axm.text(0.5, 0.95, "> device", transform=axm.transAxes, ha="center",
                 fontsize=7.5, color="#e34948")
    for xi, g in enumerate(gains):
        axm.annotate(f"+{g:.1f}", (xi, g), xytext=(0, 2), textcoords="offset points",
                     ha="center", fontsize=7.5)
axs[0].set_ylabel("accuracy gain vs M=1 (pp)")
f.suptitle("Option 10 — small multiples: gain vs its cost, one panel per M", x=0.02, ha="left", fontsize=10)
save(f, 10)
PYEOF_MARKER_UNUSED = None
