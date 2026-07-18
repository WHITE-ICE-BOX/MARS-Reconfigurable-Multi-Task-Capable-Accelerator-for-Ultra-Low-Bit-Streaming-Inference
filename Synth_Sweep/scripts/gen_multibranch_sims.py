#!/usr/bin/env python3
"""
Generate per-(style, M, site) xsim testbenches + compile lists + run scripts
for the multi-branch adapter sites. Mirrors the verified M=1 flow
(tb_MVAU_1.v + .prj + xvlog/xelab/xsim), but instantiates the generated
multi-branch Super_Wrapper directly (so the sim covers exactly the RTL that
will be synthesized) plus the site's FINN wstrm for the backbone weights.
ROMs are loaded via hierarchical $readmemh from sw/branch_dat (real deployed
SVHN M-branch weights); golden in/expected from sim_data.
"""
import os
import glob
import stat

ROOT = "/home/barkie1/mvau_multibranch_synth"
FIXED_DIR = {
    "compact": "/home/barkie1/mvau_pipeline_runtime_3ds_pe1/mvau_adapter/mvau{n}/mvau{n}_fixed",
    "tp":      "/home/barkie1/mvau_pipeline_runtime/mvau_adapter/mvau{n}/mvau{n}_fixed",
}
IPSRC_DIR = {
    "compact": ROOT + "/compact3ds/m1/mvau_adapter_ip/mvau{n}/ip/src",
    "tp":      ROOT + "/tp2ds/m1/mvau_adapter_ip/mvau{n}/ip/src",
}
GLBL = "/home/barkie1/mvau_pipeline_runtime_3ds_pe1/mvau_adapter/mvau1/xsim_linux/glbl.v"

SITE = {
    1: dict(IN_CH=64,  OUT_CH=64,  HIDDEN=16, UPW=32, K=576),
    2: dict(IN_CH=64,  OUT_CH=128, HIDDEN=16, UPW=32, K=576),
    3: dict(IN_CH=128, OUT_CH=128, HIDDEN=32, UPW=32, K=1152),
    4: dict(IN_CH=128, OUT_CH=256, HIDDEN=32, UPW=32, K=1152),
    5: dict(IN_CH=256, OUT_CH=256, HIDDEN=64, UPW=64, K=2304),
}
PE_TP = {1: 32, 2: 16, 3: 16, 4: 4, 5: 1}
OUTW_TP = {1: 32, 2: 16, 3: 16, 4: 8, 5: 8}
SIMD = 32
NUM_SAMPLES = 10


def gen_tb(style, M, n):
    cfg = SITE[n]
    PE = 1 if style == "compact" else PE_TP[n]
    OUT_CH = cfg["OUT_CH"]
    IN_CHUNKS = cfg["IN_CH"] // SIMD
    WIN = 9 * IN_CHUNKS
    OUT_STEPS = OUT_CH // PE
    OW = 8 if style == "compact" else OUTW_TP[n]
    WW = 32 * PE
    tot_in = NUM_SAMPLES * WIN
    tot_out = NUM_SAMPLES * OUT_STEPS
    scalar = (PE == 1)
    thr_name = "thresh_rom" if scalar else "thresh_mem"
    sgn_name = "adp_sign_rom" if scalar else "sign_mem"
    bd = f"{ROOT}/sw/branch_dat/m{M}/mvau{n}"
    sd = f"{ROOT}/sim_data/{style}/m{M}/mvau{n}"
    B = range(M)

    l = []
    a = l.append
    a("`timescale 1ns / 1ps")
    a(f"// Multi-branch M={M} {style} MVAU{n} full-chain sim (wstrm + Super_Wrapper)")
    a("module tb_multibranch;")
    a(f"    parameter integer TOTAL_INPUT_WORDS  = {tot_in};")
    a(f"    parameter integer TOTAL_OUTPUT_WORDS = {tot_out};")
    a("")
    a("    reg ap_clk = 0;")
    a("    reg ap_rst_n;")
    a("    always #5 ap_clk = ~ap_clk;")
    a("")
    a("    // wstrm AXI-lite tie-off")
    a("    wire awready, wready, bvalid, arready, rvalid;")
    a("    wire [1:0] bresp, rresp;")
    a("    wire [31:0] rdata;")
    a("")
    a(f"    wire [{WW-1}:0] wstrm_tdata;")
    a("    wire wstrm_tvalid, wstrm_tready;")
    a("")
    a(f"    StreamingDataflowPartition_1_StreamingDataflowPartition_1_MVAU_hls_{n}_wstrm_0 wstrm_inst (")
    a("        .ap_clk(ap_clk), .ap_rst_n(ap_rst_n),")
    a("        .awready(awready), .awvalid(1'b0), .awprot(3'b0), .awaddr(32'b0),")
    a("        .wready(wready), .wvalid(1'b0), .wdata(32'b0), .wstrb(4'b0),")
    a("        .bready(1'b1), .bvalid(bvalid), .bresp(bresp),")
    a("        .arready(arready), .arvalid(1'b0), .arprot(3'b0), .araddr(32'b0),")
    a("        .rready(1'b1), .rvalid(rvalid), .rresp(rresp), .rdata(rdata),")
    a("        .m_axis_0_tvalid(wstrm_tvalid), .m_axis_0_tready(wstrm_tready), .m_axis_0_tdata(wstrm_tdata)")
    a("    );")
    a("")
    a("    reg  [31:0] tb_in_tdata;")
    a("    reg         tb_in_tvalid;")
    a("    wire        tb_in_tready;")
    a(f"    wire [{OW-1}:0] tb_out_tdata;")
    a("    wire        tb_out_tvalid;")
    a("    reg         tb_out_tready;")
    a("")
    a(f"    MVAU{n}_Super_Wrapper dut (")
    a("        .ap_clk(ap_clk), .ap_rst_n(ap_rst_n),")
    a("        .in0_V_TDATA(tb_in_tdata), .in0_V_TVALID(tb_in_tvalid), .in0_V_TREADY(tb_in_tready),")
    a("        .weights_V_TDATA(wstrm_tdata), .weights_V_TVALID(wstrm_tvalid), .weights_V_TREADY(wstrm_tready),")
    a("        .out_V_TDATA(tb_out_tdata), .out_V_TVALID(tb_out_tvalid), .out_V_TREADY(tb_out_tready),")
    a("        .cfg_waddr(11'd0), .cfg_wdata(32'd0), .cfg_wen(1'b0)")
    a(");")
    a("")
    a("    // Load branch weights + shared thresholds (real deployed SVHN M-branch data)")
    a("    initial begin")
    a("        #1;")
    # throughput sites 1-4 use wide rom_up rows (OUT_STEPS x PE*32); PE=1 uses narrow
    up_file = "rom_up_load" if PE == 1 else "rom_up_wide"
    for b in B:
        a(f"        $readmemh(\"{bd}/rom_rc_load_b{b}.dat\",      dut.adapter_inst_b{b}.rom_rc);")
        a(f"        $readmemh(\"{bd}/rom_down_load_b{b}.dat\",    dut.adapter_inst_b{b}.rom_down);")
        a(f"        $readmemh(\"{bd}/{up_file}_b{b}.dat\",      dut.adapter_inst_b{b}.rom_up);")
    if PE == 1:
        # tp scalar adder (site 5) bakes constant alphas -> no contrib load
        if style == "compact":
            for b in B:
                a(f"        $readmemh(\"{bd}/contrib_lut_load_b{b}.dat\", dut.adder_thresh_inst.adp_contrib_lut_b{b});")
        a(f"        $readmemh(\"{bd}/thresh_load.dat\", dut.adder_thresh_inst.{thr_name});")
        a(f"        $readmemh(\"{bd}/sign_load.dat\",   dut.adder_thresh_inst.{sgn_name});")
    else:
        # per-PE adder: lane-column thresh/sign (contrib alphas are baked)
        for p in range(PE):
            a(f"        $readmemh(\"{bd}/thresh_lane{p}.dat\", dut.adder_thresh_inst.g_lane[{p}].th_mem);")
            a(f"        $readmemh(\"{bd}/sign_lane{p}.dat\",   dut.adder_thresh_inst.g_lane[{p}].sg_mem);")
    a("    end")
    a("")
    a("    reg [31:0] golden_in  [0:TOTAL_INPUT_WORDS-1];")
    a(f"    reg [{OW-1}:0] golden_out [0:TOTAL_OUTPUT_WORDS-1];")
    a("")
    a("    integer in_ptr  = 0;")
    a("    integer out_ptr = 0;")
    a("    integer err_cnt = 0;")
    a("    integer cor_cnt = 0;")
    a("")
    a("    initial begin")
    a(f"        $readmemh(\"{sd}/in.dat\",       golden_in);")
    a(f"        $readmemh(\"{sd}/expected.dat\", golden_out);")
    a("")
    a("        ap_rst_n      = 0;")
    a("        tb_in_tvalid  = 0;")
    a("        tb_in_tdata   = 0;")
    a("        tb_out_tready = 1;")
    a("        #100; ap_rst_n = 1; #50;")
    a("")
    a("        tb_in_tvalid = 1;")
    a("        while (in_ptr < TOTAL_INPUT_WORDS) begin")
    a("            tb_in_tdata = golden_in[in_ptr];")
    a("            @(posedge ap_clk);")
    a("            #0.1;")
    a("            if (tb_in_tvalid && tb_in_tready) in_ptr = in_ptr + 1;")
    a("        end")
    a("        tb_in_tvalid = 0;")
    a("        tb_in_tdata  = 0;")
    a("")
    a("        #300000;")
    a("        if (out_ptr < TOTAL_OUTPUT_WORDS)")
    a("            $display(\"RESULT: TIMEOUT %0d / %0d outputs\", out_ptr, TOTAL_OUTPUT_WORDS);")
    a("        else if (err_cnt == 0)")
    a("            $display(\"RESULT: PASS %0d / %0d correct\", cor_cnt, TOTAL_OUTPUT_WORDS);")
    a("        else")
    a("            $display(\"RESULT: FAIL %0d errors, %0d correct of %0d\", err_cnt, cor_cnt, TOTAL_OUTPUT_WORDS);")
    a("        $finish;")
    a("    end")
    a("")
    a("    always @(posedge ap_clk) begin")
    a("        if (tb_out_tvalid && tb_out_tready) begin")
    a("            if (tb_out_tdata !== golden_out[out_ptr]) begin")
    a("                err_cnt = err_cnt + 1;")
    a("                if (err_cnt <= 10) $display(\"MISMATCH idx=%0d hw=%h expected=%h\", out_ptr, tb_out_tdata, golden_out[out_ptr]);")
    a("            end else begin")
    a("                cor_cnt = cor_cnt + 1;")
    a("            end")
    a("            out_ptr = out_ptr + 1;")
    a("        end")
    a("    end")
    a("")
    a("endmodule")
    return "\n".join(l) + "\n"


def make_prj(style, M, n, simdir):
    fixed = FIXED_DIR[style].format(n=n)
    ipsrc = IPSRC_DIR[style].format(n=n)
    rtl = f"{ROOT}/rtl/{style}/m{M}/mvau{n}"
    adap_file = "Adapter_Generic.v" if (style == "tp" and n == 5) else f"Adapter_MVAU{n}.v"
    vfiles = [
        f"{ipsrc}/{adap_file}",
        f"{ipsrc}/Simple_FIFO_mvau{n}.v",
        f"{rtl}/Stream_Adder_Threshold_mvau{n}.v",
        f"{rtl}/MVAU{n}_Super_Wrapper.v",
    ]
    # FINN MVAU + wstrm + support files from the verified _fixed dir
    for f in sorted(glob.glob(f"{fixed}/*.v")):
        base = os.path.basename(f)
        # skip duplicate adapter-family files if any leaked into _fixed
        if base.startswith(("Adapter_", "Simple_FIFO", "Stream_", "MVAU")) and "MVAU_hls" not in base:
            continue
        vfiles.append(f)
    svfiles = sorted(glob.glob(f"{fixed}/*.sv"))
    lines = ["verilog xil_defaultlib  \\"]
    for f in vfiles:
        lines.append(f"\"{f}\" \\")
    lines.append("")
    if svfiles:
        lines.append("sv xil_defaultlib  \\")
        for f in svfiles:
            lines.append(f"\"{f}\" \\")
        lines.append("")
    lines.append("verilog xil_defaultlib  \\")
    lines.append(f"\"{simdir}/tb.v\" \\")
    lines.append("")
    lines.append(f"verilog xil_defaultlib \"{GLBL}\"")
    lines.append("nosort")
    return "\n".join(lines) + "\n"


RUN_SH = """#!/bin/bash
# xsim run for {tag}
set -u
source /mnt/ssd/Xilinx/Vivado/2022.2/settings64.sh
cd "$(dirname "$0")"
xvlog -prj tb.prj > xvlog.log 2>&1 || {{ echo "{tag}: XVLOG_FAIL"; exit 1; }}
xelab -debug off -timescale 1ns/1ps xil_defaultlib.tb_multibranch xil_defaultlib.glbl -s tb_sim \\
    > xelab.log 2>&1 || {{ echo "{tag}: XELAB_FAIL"; exit 1; }}
xsim tb_sim -R > xsim.log 2>&1
grep -E "RESULT:" xsim.log || echo "{tag}: NO_RESULT"
"""


def main():
    for style in ("compact", "tp"):
        for M in (1, 2, 3, 4):
            for n in range(1, 6):
                simdir = os.path.join(ROOT, "sim", style, f"m{M}", f"mvau{n}")
                os.makedirs(simdir, exist_ok=True)
                with open(f"{simdir}/tb.v", "w") as f:
                    f.write(gen_tb(style, M, n))
                with open(f"{simdir}/tb.prj", "w") as f:
                    f.write(make_prj(style, M, n, simdir))
                tag = f"{style}_m{M}_mvau{n}"
                with open(f"{simdir}/run.sh", "w") as f:
                    f.write(RUN_SH.format(tag=tag))
                os.chmod(f"{simdir}/run.sh", os.stat(f"{simdir}/run.sh").st_mode | stat.S_IEXEC)
                # copy the MVAU threshs ROM .dat next to the sim (relative readmemh)
                fixed = FIXED_DIR[style].format(n=n)
                for dat in glob.glob(f"{fixed}/*.dat"):
                    dst = os.path.join(simdir, os.path.basename(dat))
                    if not os.path.exists(dst):
                        os.link(dat, dst) if os.stat(dat).st_dev == os.stat(simdir).st_dev else None
                        if not os.path.exists(dst):
                            import shutil
                            shutil.copy(dat, dst)
                print("sim ready:", tag)
    print("SIM GENERATION DONE ->", os.path.join(ROOT, "sim"))


if __name__ == "__main__":
    main()
