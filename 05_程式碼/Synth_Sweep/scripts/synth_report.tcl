# synth_report.tcl -- open a stitch project, synthesize accelerator, dump util+power
# Usage: vivado -mode batch -source synth_report.tcl -tclargs <proj_dir> <out_dir>
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

# Regenerate BD targets
set bd_file [get_files */StreamingDataflowPartition_1.bd]
open_bd_design $bd_file
# report_ip_status for the record
report_ip_status -file ${OUT_DIR}/ip_status.rpt
generate_target {synthesis} $bd_file
update_compile_order -fileset sources_1

# Reset ALL synthesis runs (incl. OOC) to avoid stale-cache gotcha, then synth
foreach run [get_runs -filter {IS_SYNTHESIS}] { reset_run $run }
launch_runs synth_1 -jobs 8
wait_on_run synth_1
set st [get_property STATUS [get_runs synth_1]]
puts "SYNTH STATUS: $st"
if {$st ne "synth_design Complete!"} { puts "ERROR: synthesis failed"; exit 1 }

open_run synth_1
report_utilization                 -file ${OUT_DIR}/utilization_synth.rpt
report_utilization -hierarchical -hierarchical_depth 3 -file ${OUT_DIR}/utilization_hier.rpt
report_power                       -file ${OUT_DIR}/power_synth.rpt
report_timing_summary -max_paths 5 -file ${OUT_DIR}/timing_synth.rpt
puts "REPORTS WRITTEN TO ${OUT_DIR}"
close_project
exit 0
