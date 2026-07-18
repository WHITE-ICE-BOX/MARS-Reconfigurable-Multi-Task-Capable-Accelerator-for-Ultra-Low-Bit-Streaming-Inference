# synth_global_report.tcl -- GLOBAL (non-OOC) synthesis of the stitched BD,
# then opt_design, dumping post-synth and post-opt utilization + power.
# Uniform flow for all M=1..4 variants of both build styles.
# Usage: vivado -mode batch -source synth_global_report.tcl -tclargs <proj_dir> <out_dir>
set PROJ_DIR [lindex $argv 0]
set OUT_DIR  [lindex $argv 1]
file mkdir $OUT_DIR

open_project ${PROJ_DIR}/finn_vivado_stitch_proj.xpr
update_ip_catalog -rebuild

# Upgrade any locked/out-of-date IPs (needed after adapter IP repackaging)
set locked [get_ips -filter {IS_LOCKED == 1}]
if {[llength $locked] > 0} {
    puts "Upgrading locked IPs: $locked"
    foreach ip $locked { upgrade_ip $ip }
}

set bd_file [get_files */StreamingDataflowPartition_1.bd]
open_bd_design $bd_file
report_ip_status -file ${OUT_DIR}/ip_status.rpt

# GLOBAL synthesis: no per-IP OOC checkpoints (avoids stale OOC netlists and
# lets synth optimize across module boundaries, matching the deployed flow's
# effective post-opt netlist much more closely).
set_property synth_checkpoint_mode None $bd_file
generate_target -force {synthesis} $bd_file
update_compile_order -fileset sources_1

foreach run [get_runs -filter {IS_SYNTHESIS}] { reset_run $run }
launch_runs synth_1 -jobs 8
wait_on_run synth_1
set st [get_property STATUS [get_runs synth_1]]
puts "SYNTH STATUS: $st"
if {$st ne "synth_design Complete!"} { puts "ERROR: synthesis failed"; exit 1 }

open_run synth_1

# 100 MHz clock (deployed frequency) so report_power is meaningful.
set clkports [get_ports -quiet -filter {DIRECTION == IN} *clk*]
if {[llength $clkports] > 0 && [llength [get_clocks -quiet]] == 0} {
    create_clock -period 10.000 -name sysclk $clkports
    puts "CREATED 100MHz clock on: $clkports"
}

report_utilization                 -file ${OUT_DIR}/utilization_synth.rpt
report_utilization -hierarchical -hierarchical_depth 3 -file ${OUT_DIR}/utilization_synth_hier.rpt
report_power                       -file ${OUT_DIR}/power_synth.rpt

# opt_design (first step of implementation; no placement needed)
opt_design -directive Explore

report_utilization                 -file ${OUT_DIR}/utilization_opt.rpt
report_utilization -hierarchical -hierarchical_depth 3 -file ${OUT_DIR}/utilization_opt_hier.rpt
report_power                       -file ${OUT_DIR}/power_opt.rpt
report_timing_summary -max_paths 3 -file ${OUT_DIR}/timing_opt.rpt
puts "ALL REPORTS WRITTEN TO ${OUT_DIR}"
close_project
exit 0
