# refresh_stitch_ip.tcl -- after adapter IPs are repackaged, refresh a variant's
# stitch project (upgrade IPs, regenerate BD) and re-export the whole partition
# as the StreamingDataflowPartition_1 IP (recipe = rebuild_after_lut_fix STEP 2).
# Usage: vivado -mode batch -source refresh_stitch_ip.tcl -tclargs <variant_dir>
set VAR_DIR    [lindex $argv 0]
set STITCH_DIR ${VAR_DIR}/vivado_stitch_proj

open_project ${STITCH_DIR}/finn_vivado_stitch_proj.xpr
update_ip_catalog -rebuild

set locked [get_ips -filter {IS_LOCKED == 1}]
if {[llength $locked] > 0} {
    puts "Upgrading locked IPs: $locked"
    foreach ip $locked { upgrade_ip $ip }
}

set bd_file [get_files */StreamingDataflowPartition_1.bd]
open_bd_design $bd_file
save_bd_design
validate_bd_design

# ensure normal OOC-per-IP mode for packaging (global mode may have been set)
catch {set_property synth_checkpoint_mode Hierarchical $bd_file}

generate_target {all} $bd_file -force
update_compile_order -fileset sources_1

set stitch_ip_dir ${STITCH_DIR}/ip
ipx::package_project \
    -root_dir   ${stitch_ip_dir} \
    -vendor     xilinx_finn \
    -library    finn \
    -taxonomy   /UserIP \
    -import_files \
    -set_current true \
    -force

set core [ipx::current_core]
set_property name         "StreamingDataflowPartition_1" $core
set_property display_name "StreamingDataflowPartition_1" $core
set_property version      1.0 $core

foreach bus {s_axis_0 m_axis_0 s_axilite_cfg} {
    catch {ipx::associate_bus_interfaces -busif $bus -clock ap_clk $core}
}
catch {
    set clk_if [ipx::get_bus_interfaces ap_clk -of_objects $core]
    if {[llength $clk_if] > 0} {
        set p [ipx::add_bus_parameter ASSOCIATED_RESET $clk_if]
        set_property value ap_rst_n $p
    }
}
catch {
    set axi_if [ipx::get_bus_interfaces s_axilite_cfg -of_objects $core]
    # only add a memory map if the packager did not auto-create one
    # (a second address block breaks assign_bd_address in the zynq BD)
    if {[llength $axi_if] > 0 && [llength [ipx::get_memory_maps -of_objects $core]] == 0} {
        set mem_map [ipx::add_memory_map s_axilite_cfg $core]
        set_property slave_memory_map_ref s_axilite_cfg $axi_if
        set seg [ipx::add_address_block Reg $mem_map]
        set_property range 65536 $seg
        set_property width 32 $seg
    }
}

ipx::create_xgui_files $core
ipx::update_checksums  $core
ipx::save_core         $core
puts "STITCH IP EXPORTED to ${stitch_ip_dir}"
close_project
exit 0
