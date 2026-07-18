# opt_report.tcl -- open an already-synthesized stitch project, run opt_design,
# dump post-opt utilization + power (fair cross-config numbers; no place needed).
# Usage: vivado -mode batch -source opt_report.tcl -tclargs <proj_dir> <out_dir>
set PROJ_DIR [lindex $argv 0]
set OUT_DIR  [lindex $argv 1]
file mkdir $OUT_DIR

open_project ${PROJ_DIR}/finn_vivado_stitch_proj.xpr
open_run synth_1

# 100 MHz clock (deployed frequency) so report_power is meaningful;
# stitch projects carry no user constraints of their own.
set clkports [get_ports -quiet -filter {DIRECTION == IN} *clk*]
if {[llength $clkports] > 0 && [llength [get_clocks -quiet]] == 0} {
    create_clock -period 10.000 -name sysclk $clkports
    puts "CREATED 100MHz clock on: $clkports"
}

# The FINN MVAU_hls_0 OOC netlist carries dangling LUT input pins (a stale-
# trimming artifact) that make opt_design DRC error out (Opt 31-67). Tie any
# dangling used LUT input pins to GND before opt.
set lutcells [get_cells -hier -quiet -filter {PRIMITIVE_GROUP == LUT}]
set dangling [get_pins -quiet -of $lutcells -filter {DIRECTION == IN && IS_CONNECTED == 0}]
if {[llength $dangling] > 0} {
    puts "TYING [llength $dangling] dangling LUT input pin(s) to GND: [lrange $dangling 0 9] ..."
    set gnd_cell [create_cell -reference GND tie_gnd_fix_cell]
    set gnd_net  [create_net tie_gnd_fix_net]
    connect_net -net $gnd_net -objects [get_pins tie_gnd_fix_cell/G]
    connect_net -net $gnd_net -objects $dangling
} else {
    puts "NO dangling LUT input pins found."
}

# same directive as the original deployed build flow
opt_design -directive Explore

report_utilization                 -file ${OUT_DIR}/utilization_opt.rpt
report_utilization -hierarchical -hierarchical_depth 3 -file ${OUT_DIR}/utilization_opt_hier.rpt
report_power                       -file ${OUT_DIR}/power_opt.rpt
report_timing_summary -max_paths 3 -file ${OUT_DIR}/timing_opt.rpt
puts "OPT REPORTS WRITTEN TO ${OUT_DIR}"
close_project
exit 0
