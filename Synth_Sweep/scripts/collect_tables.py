#!/usr/bin/env python3
"""
Build the two deliverable tables:
  Table A: FPGA resources  — M=1 rows = original published post-implementation
           numbers (thesis Table 5.11); M=2/3/4 rows = new Zynq-top
           post-synthesis numbers (this experiment).
  Table B: Power           — M=1 rows = original published numbers (thesis
           Table 5.12); M=2/3/4 = Vivado vectorless power on the post-synth
           Zynq-top netlist (incl. PS).
Outputs Markdown (tables.md) + LaTeX (tables.tex).
"""
import os
import re

ROOT = "mvau_multibranch_synth"
DEV = dict(LUT=53200, FF=106400, BRAM=140, DSP=220, SLICE=13300)

# Original published M=1 numbers (post-implementation, thesis Tables 5.11/5.12)
ORIG = {
    "tp2ds": dict(slice=13272, lut=41729, ff=53285, bram=99, dsp=0,
                  total=2.215, dynamic=2.046, static=0.168),
    "compact3ds": dict(slice=12957, lut=39967, ff=40926, bram=84, dsp=0,
                       total=1.802, dynamic=1.649, static=0.153),
}


def parse_util(path):
    if not os.path.exists(path):
        return None
    txt = open(path).read()
    d = {}
    pats = {
        "LUT":    r"^\|\s*(?:Slice|CLB) LUTs\*?\s*\|\s*([\d.]+)",
        "LUTMEM": r"^\|\s*LUT as Memory\s*\|\s*([\d.]+)",
        "FF":     r"^\|\s*(?:Slice|CLB) Registers\s*\|\s*([\d.]+)",
        "BRAM":   r"^\|\s*Block RAM Tile\s*\|\s*([\d.]+)",
        "DSP":    r"^\|\s*DSPs\s*\|\s*([\d.]+)",
    }
    for k, p in pats.items():
        m = re.search(p, txt, re.M)
        d[k] = float(m.group(1)) if m else None
    return d


def parse_power(path):
    if not os.path.exists(path):
        return None
    txt = open(path).read()
    d = {}
    for k, p in {
        "total":   r"Total On-Chip Power \(W\)\s*\|\s*([\d.]+)",
        "dynamic": r"^\| Dynamic \(W\)\s*\|\s*([\d.]+)",
        "static":  r"Device Static \(W\)\s*\|\s*([\d.]+)",
    }.items():
        m = re.search(p, txt, re.M)
        d[k] = float(m.group(1)) if m else None
    return d


def main():
    rows = []
    for style, label in (("tp2ds", "MARS (Throughput, 2-dataset)"),
                         ("compact3ds", "MARS (Compact, multi-dataset)")):
        for M in (1, 2, 3, 4):
            if M == 1:
                o = ORIG[style]
                rows.append(dict(style=label, M=1, orig=True,
                                 lut=o["lut"], ff=o["ff"], bram=o["bram"],
                                 dsp=o["dsp"], slice=o["slice"], lutmem=None,
                                 total=o["total"], dynamic=o["dynamic"],
                                 static=o["static"]))
                # same-flow synthesis M=1 row
                v1 = "m1fix" if style == "tp2ds" else "m1gen"
                rg = f"{ROOT}/{style}/{v1}/reports_top"
                u = parse_util(f"{rg}/utilization_synth.rpt")
                p = parse_power(f"{rg}/power_synth.rpt")
                if u:
                    rows.append(dict(style=label, M=1, orig=False,
                                     lut=u["LUT"], ff=u["FF"], bram=u["BRAM"],
                                     dsp=u["DSP"], lutmem=u["LUTMEM"], slice=None,
                                     total=p and p["total"],
                                     dynamic=p and p["dynamic"],
                                     static=p and p["static"]))
                continue
            rg = f"{ROOT}/{style}/m{M}/reports_top"
            u = parse_util(f"{rg}/utilization_synth.rpt")
            p = parse_power(f"{rg}/power_synth.rpt")
            rows.append(dict(style=label, M=M, orig=False,
                             lut=u and u["LUT"], ff=u and u["FF"],
                             bram=u and u["BRAM"], dsp=u and u["DSP"],
                             lutmem=u and u["LUTMEM"], slice=None,
                             total=p and p["total"], dynamic=p and p["dynamic"],
                             static=p and p["static"]))

    md = []
    md.append("## Table A — FPGA resources, XC7Z020 (Zynq top / top_wrapper)")
    md.append("M=1 = original published post-implementation build; "
              "M=2–4 = post-synthesis (same FINN Zynq flow & synth strategy; "
              "implementation not run — designs exceed the device).\n")
    md.append("| Build | M | Stage | Occupied Slices | Slice LUTs | FF | BRAM | DSP |")
    md.append("|---|---|---|---|---|---|---|---|")
    for r in rows:
        if r["lut"] is None:
            md.append(f"| {r['style']} | {r['M']} | -- | -- | -- | -- | -- | -- |")
            continue
        stage = "post-impl (orig.)" if r["orig"] else "post-synth"
        sl = f"{r['slice']:,} ({100*r['slice']/DEV['SLICE']:.2f}%)" if r["slice"] else "n/a†"
        md.append("| {} | {} | {} | {} | {:,} ({:.2f}%) | {:,} ({:.2f}%) | {:g} ({:.2f}%) | {:g} |".format(
            r["style"], r["M"], stage, sl,
            int(r["lut"]), 100*r["lut"]/DEV["LUT"],
            int(r["ff"]), 100*r["ff"]/DEV["FF"],
            r["bram"], 100*r["bram"]/DEV["BRAM"], r["dsp"]))
    md.append("")
    md.append("† occupied-slice count only exists after placement; "
              "not defined at the synthesis stage.")
    md.append("")
    md.append("## Table B — Power (W)")
    md.append("M=1 = original published (post-impl); M=2–4 = Vivado vectorless "
              "estimate on the post-synthesis Zynq-top netlist (incl. PS), 100 MHz.\n")
    md.append("| Build | M | Stage | Total (W) | Dynamic (W) | Static (W) |")
    md.append("|---|---|---|---|---|---|")
    for r in rows:
        if r["total"] is None:
            md.append(f"| {r['style']} | {r['M']} | -- | -- | -- | -- |")
            continue
        stage = "post-impl (orig.)" if r["orig"] else "post-synth"
        md.append("| {} | {} | {} | {:.3f} | {:.3f} | {:.3f} |".format(
            r["style"], r["M"], stage, r["total"], r["dynamic"], r["static"]))

    out = "\n".join(md) + "\n"
    with open(f"{ROOT}/tables.md", "w") as f:
        f.write(out)

    # ---- LaTeX ----
    tex = []
    tex.append("% Table A — resources (M=1 post-impl originals; M=2-4 post-synth)")
    tex.append(r"\begin{table}[H]")
    tex.append(r"\centering")
    tex.append(r"\caption{FPGA resource scaling of multi-branch MARS builds on XC7Z020.}")
    tex.append(r"\label{tab:multibranch_resources}")
    tex.append(r"\renewcommand{\arraystretch}{1.2}%")
    tex.append(r"\resizebox{\linewidth}{!}{%")
    tex.append(r"\begin{tabular}{clc rrrr}")
    tex.append(r"\toprule")
    tex.append(r"\textbf{Build} & \textbf{M} & \textbf{Stage} & \textbf{Occ.\ Slices} & \textbf{Slice LUTs} & \textbf{FF} & \textbf{BRAM} \\")
    tex.append(r"\midrule")
    prev = None
    for r in rows:
        if r["lut"] is None:
            continue
        if prev and prev != r["style"]:
            tex.append(r"\midrule")
        prev = r["style"]
        stage = "impl." if r["orig"] else "synth."
        sl = "{:,} ({:.1f}\\%)".format(r["slice"], 100*r["slice"]/DEV["SLICE"]) if r["slice"] else "---"
        tex.append("{} & {} & {} & {} & {:,} ({:.1f}\\%) & {:,} ({:.1f}\\%) & {:g} ({:.1f}\\%) \\\\".format(
            r["style"], r["M"], stage, sl,
            int(r["lut"]), 100*r["lut"]/DEV["LUT"],
            int(r["ff"]), 100*r["ff"]/DEV["FF"],
            r["bram"], 100*r["bram"]/DEV["BRAM"]).replace(",", "{,}"))
    tex.append(r"\bottomrule")
    tex.append(r"\end{tabular}%")
    tex.append(r"}")
    tex.append(r"\end{table}")
    tex.append("")
    tex.append("% Table B — power")
    tex.append(r"\begin{table}[H]")
    tex.append(r"\centering")
    tex.append(r"\caption{Power scaling of multi-branch MARS builds (Vivado estimates).}")
    tex.append(r"\label{tab:multibranch_power}")
    tex.append(r"\begin{tabular}{clc rrr}")
    tex.append(r"\toprule")
    tex.append(r"\textbf{Build} & \textbf{M} & \textbf{Stage} & \textbf{Total (W)} & \textbf{Dyn.\ (W)} & \textbf{Stat.\ (W)} \\")
    tex.append(r"\midrule")
    prev = None
    for r in rows:
        if r["total"] is None:
            continue
        if prev and prev != r["style"]:
            tex.append(r"\midrule")
        prev = r["style"]
        stage = "impl." if r["orig"] else "synth."
        tex.append("{} & {} & {} & {:.3f} & {:.3f} & {:.3f} \\\\".format(
            r["style"], r["M"], stage, r["total"], r["dynamic"], r["static"]))
    tex.append(r"\bottomrule")
    tex.append(r"\end{tabular}")
    tex.append(r"\end{table}")
    with open(f"{ROOT}/tables.tex", "w") as f:
        f.write("\n".join(tex) + "\n")

    print(out)
    print("LaTeX ->", f"{ROOT}/tables.tex")


if __name__ == "__main__":
    main()
