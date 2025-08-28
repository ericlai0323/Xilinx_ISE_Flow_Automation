# Project Automation Script for G2
# Created for Xilinx ISE 14.7 environment
# Loads and executes various Tcl procedures to automate project workflows

# Set initial variables
set device_name xc6slx4
set project_name G2_Code
set script_name ise_flow_automation_for_G2
set top_module PANELCTRL
# clkout1 = Product main frequency *2
set clkout1_requested_out_freq 80
# clkout2 = Product main frequency *1.66
set clkout2_requested_out_freq 66.4
# clkout3 = Keep 25
set clkout3_requested_out_freq 25

# Define output filenames
set bit_file ${top_module}.bit
set mcs_file ${top_module}.mcs

# ==========================
# Main Top-Level Procedures
# ==========================
# run_process: Runs the main design flow (synthesis, implementation, bitstream generation)
# Usage: call 'run_process' to execute the standard flow
proc run_process {} {
   global script_name project_name device_name clkout1_requested_out_freq clkout2_requested_out_freq clkout3_requested_out_freq mcs_file bit_file

   puts "\n$script_name: Starting process for project ($project_name)...\n"

   # Open the project file
   if { ! [ open_project ] } {
      return false
   }

   # Set process properties as predefined
   set_process_props

   # Uncomment or comment processes as needed
   # process run "Synthesize"       ;# Synthesis step
   # process run "Translate"        ;# Translate step
   # process run "Map"              ;# Logic mapping
   # process run "Place & Route"    ;# Place and route

   # Run implementation task
   set task "Implement Design"
   if { ! [run_task $task] } {
      puts "$script_name: '$task' failed, check the output."
      project close
      return
   }

   # Generate programming file (bitstream/mcs)
   set task "Generate Programming File"
   if { ! [run_task $task] } {
      puts "$script_name: '$task' failed, check the output."
      project close
      return
   }

   puts "Process completed successfully."
   puts "MCS file: $mcs_file"
   puts "Bit file: $bit_file"
   puts "clkout1_requested_out_freq: $clkout1_requested_out_freq"
   puts "clkout2_requested_out_freq: $clkout2_requested_out_freq"
   puts "clkout3_requested_out_freq: $clkout3_requested_out_freq"
   project close
}

# rebuild_project: Recreates the entire project, sets properties, adds sources, then runs the flow
proc rebuild_project {} {
   global script_name project_name

   project close

   puts "\n$script_name: Rebuilding project ($project_name)...\n"

   # Delete existing project files (.xise, .gise, .ise)
   set proj_exts [list ise xise gise]
   foreach ext $proj_exts {
      set proj_name "${project_name}.$ext"
      if { [file exists $proj_name] } {
         file delete $proj_name
      }
   }

   # Create a new project
   project new $project_name

   # Set project properties and add source files
   set_project_props
   add_source_files
   create_libraries

   puts "$script_name: Project rebuild complete."

   # Run the entire flow
   run_process
}

# ==========================
# Supporting Procedures
# ==========================

# run_task: Executes a specific task/process and checks its status
# Returns true if successful, false otherwise
proc run_task { task } {
   puts "Running '$task'..."
   set result [process run "$task"]
   set status [process get $task status]
   if { ( ( $status != "up_to_date" ) && ( $status != "warnings" ) ) || ! $result } {
      return false
   }
   return true
}

# show_help: Prints usage and options to assist users
proc show_help {} {
   global script_name
   puts ""
   puts "Usage: xtclsh $script_name <options>"
   puts " Or run 'source $script_name' in the Tcl console."
   puts ""
   puts "Options:"
   puts "  run_process        - Set properties and run the entire flow"
   puts "  rebuild_project    - Recreate project and run flow"
   puts "  set_project_props  - Set project parameters (device, speed, etc.)"
   puts "  regenerate_dcm_core- Regenerate DCM core IP"
   puts "  add_source_files   - Add source files to the project"
   puts "  create_libraries   - Define VHDL libraries"
   puts "  set_process_props  - Set flow process parameters"
   puts "  generate_mcs_file  - Generate MCS configuration file"
   puts "  program_spi_flash  - Program MCS to SPI Flash"
   puts "  show_help          - Display this help message"
   puts ""
}

# open_project: Opens the project file if it exists
# Returns true if success, false otherwise
proc open_project {} {
   global script_name project_name
   if { ! [file exists "${project_name}.xise" ] } {
      puts "Project file not found. Please run 'rebuild_project'."
      return false
   }
   project open $project_name
   return true
}

# set_project_props: Sets project parameters such as device, speed, top module
proc set_project_props {} {
   global script_name device_name
   if { ! [ open_project ] } { return false }

   puts "$script_name: Setting project properties..."
   project set family "Spartan6"
   project set device "$device_name"
   project set package "tqg144"
   project set speed "-3"
   project set top_level_module_type "HDL"
   project set synthesis_tool "XST (VHDL/Verilog)"
   project set simulator "Modelsim-SE Mixed"
   project set "Preferred Language" "Verilog"
   project set "Enable Message Filtering" "false"
}

# regenerate_dcm_core: Regenerates the DCM (Digital Clock Manager) core IP
proc regenerate_dcm_core {} {
   global project_name script_name device_name clkout1_requested_out_freq clkout2_requested_out_freq clkout3_requested_out_freq
   puts "$script_name: Regenerating DCM core..."
   set fp [open "../ip_core/DCM.xco" "w"]
   puts $fp {
# BEGIN Project Options
SET addpads = false
SET asysymbol = true
SET busformat = BusFormatAngleBracketNotRipped
SET createndf = false
SET designentry = Verilog
   }
   puts $fp "SET device = $device_name"
   puts $fp {
SET devicefamily = spartan6
SET flowvendor = Other
SET formalverification = false
SET foundationsym = false
SET implementationfiletype = Ngc
SET package = tqg144
SET removerpms = false
SET simulationfiles = Behavioral
SET speedgrade = -3
SET verilogsim = true
SET vhdlsim = false
# END Project Options
# BEGIN Select
SELECT Clocking_Wizard xilinx.com:ip:clk_wiz:3.6
# END Select
# BEGIN Parameters
CSET calc_done=DONE
CSET clk_in_sel_port=CLK_IN_SEL
CSET clk_out1_port=CLK_OUT1
CSET clk_out1_use_fine_ps_gui=false
CSET clk_out2_port=CLK_OUT2
CSET clk_out2_use_fine_ps_gui=false
CSET clk_out3_port=CLK_OUT3
CSET clk_out3_use_fine_ps_gui=false
CSET clk_out4_port=CLK_OUT4
CSET clk_out4_use_fine_ps_gui=false
CSET clk_out5_port=CLK_OUT5
CSET clk_out5_use_fine_ps_gui=false
CSET clk_out6_port=CLK_OUT6
CSET clk_out6_use_fine_ps_gui=false
CSET clk_out7_port=CLK_OUT7
CSET clk_out7_use_fine_ps_gui=false
CSET clk_valid_port=CLK_VALID
CSET clkfb_in_n_port=CLKFB_IN_N
CSET clkfb_in_p_port=CLKFB_IN_P
CSET clkfb_in_port=CLKFB_IN
CSET clkfb_in_signaling=SINGLE
CSET clkfb_out_n_port=CLKFB_OUT_N
CSET clkfb_out_p_port=CLKFB_OUT_P
CSET clkfb_out_port=CLKFB_OUT
CSET clkfb_stopped_port=CLKFB_STOPPED
CSET clkin1_jitter_ps=400.0
CSET clkin1_ui_jitter=0.010
CSET clkin2_jitter_ps=100.0
CSET clkin2_ui_jitter=0.010
   }
   puts $fp "CSET clkout1_drives=BUFG"
   puts $fp "CSET clkout1_requested_duty_cycle=50.000"
   puts $fp "CSET clkout1_requested_out_freq=$clkout1_requested_out_freq"
   puts $fp "CSET clkout1_requested_phase=0.000"
   puts $fp "CSET clkout2_drives=BUFG"
   puts $fp "CSET clkout2_requested_duty_cycle=50.000"
   puts $fp "CSET clkout2_requested_out_freq=$clkout2_requested_out_freq"
   puts $fp "CSET clkout2_requested_phase=0.000"
   puts $fp "CSET clkout2_used=true"
   puts $fp "CSET clkout3_drives=BUFG"
   puts $fp "CSET clkout3_requested_duty_cycle=50.000"
   puts $fp "CSET clkout3_requested_out_freq=$clkout3_requested_out_freq"
   puts $fp "CSET clkout3_requested_phase=0.000"
   puts $fp "CSET clkout3_used=true"
   puts $fp {
CSET clkout4_drives=BUFG
CSET clkout4_requested_duty_cycle=50.000
CSET clkout4_requested_out_freq=100.000
CSET clkout4_requested_phase=0.000
CSET clkout4_used=false
CSET clkout5_drives=BUFG
CSET clkout5_requested_duty_cycle=50.000
CSET clkout5_requested_out_freq=100.000
CSET clkout5_requested_phase=0.000
CSET clkout5_used=false
CSET clkout6_drives=BUFG
CSET clkout6_requested_duty_cycle=50.000
CSET clkout6_requested_out_freq=100.000
CSET clkout6_requested_phase=0.000
CSET clkout6_used=false
CSET clkout7_drives=BUFG
CSET clkout7_requested_duty_cycle=50.000
CSET clkout7_requested_out_freq=100.000
CSET clkout7_requested_phase=0.000
CSET clkout7_used=false
CSET clock_mgr_type=AUTO
CSET component_name=DCM
CSET daddr_port=DADDR
CSET dclk_port=DCLK
CSET dcm_clk_feedback=1X
CSET dcm_clk_out1_port=CLKFX
CSET dcm_clk_out2_port=CLKFX
CSET dcm_clk_out3_port=CLKFX
CSET dcm_clk_out4_port=CLK0
CSET dcm_clk_out5_port=CLK0
CSET dcm_clk_out6_port=CLK0
CSET dcm_clkdv_divide=2.0
CSET dcm_clkfx_divide=1
CSET dcm_clkfx_multiply=4
CSET dcm_clkgen_clk_out1_port=CLKFX
CSET dcm_clkgen_clk_out2_port=CLKFX
CSET dcm_clkgen_clk_out3_port=CLKFX
CSET dcm_clkgen_clkfx_divide=1
CSET dcm_clkgen_clkfx_md_max=0.000
CSET dcm_clkgen_clkfx_multiply=4
CSET dcm_clkgen_clkfxdv_divide=2
CSET dcm_clkgen_clkin_period=10.000
CSET dcm_clkgen_notes=None
CSET dcm_clkgen_spread_spectrum=NONE
CSET dcm_clkgen_startup_wait=false
CSET dcm_clkin_divide_by_2=false
CSET dcm_clkin_period=40.000
CSET dcm_clkout_phase_shift=NONE
CSET dcm_deskew_adjust=SYSTEM_SYNCHRONOUS
CSET dcm_notes=None
CSET dcm_phase_shift=0
CSET dcm_pll_cascade=NONE
CSET dcm_startup_wait=false
CSET den_port=DEN
CSET din_port=DIN
CSET dout_port=DOUT
CSET drdy_port=DRDY
CSET dwe_port=DWE
CSET feedback_source=FDBK_AUTO
CSET in_freq_units=Units_MHz
CSET in_jitter_units=Units_UI
CSET input_clk_stopped_port=INPUT_CLK_STOPPED
CSET jitter_options=UI
CSET jitter_sel=No_Jitter
CSET locked_port=LOCKED
CSET mmcm_bandwidth=OPTIMIZED
CSET mmcm_clkfbout_mult_f=4.000
CSET mmcm_clkfbout_phase=0.000
CSET mmcm_clkfbout_use_fine_ps=false
CSET mmcm_clkin1_period=10.000
CSET mmcm_clkin2_period=10.000
CSET mmcm_clkout0_divide_f=4.000
CSET mmcm_clkout0_duty_cycle=0.500
CSET mmcm_clkout0_phase=0.000
CSET mmcm_clkout0_use_fine_ps=false
CSET mmcm_clkout1_divide=1
CSET mmcm_clkout1_duty_cycle=0.500
CSET mmcm_clkout1_phase=0.000
CSET mmcm_clkout1_use_fine_ps=false
CSET mmcm_clkout2_divide=1
CSET mmcm_clkout2_duty_cycle=0.500
CSET mmcm_clkout2_phase=0.000
CSET mmcm_clkout2_use_fine_ps=false
CSET mmcm_clkout3_divide=1
CSET mmcm_clkout3_duty_cycle=0.500
CSET mmcm_clkout3_phase=0.000
CSET mmcm_clkout3_use_fine_ps=false
CSET mmcm_clkout4_cascade=false
CSET mmcm_clkout4_divide=1
CSET mmcm_clkout4_duty_cycle=0.500
CSET mmcm_clkout4_phase=0.000
CSET mmcm_clkout4_use_fine_ps=false
CSET mmcm_clkout5_divide=1
CSET mmcm_clkout5_duty_cycle=0.500
CSET mmcm_clkout5_phase=0.000
CSET mmcm_clkout5_use_fine_ps=false
CSET mmcm_clkout6_divide=1
CSET mmcm_clkout6_duty_cycle=0.500
CSET mmcm_clkout6_phase=0.000
CSET mmcm_clkout6_use_fine_ps=false
CSET mmcm_clock_hold=false
CSET mmcm_compensation=ZHOLD
CSET mmcm_divclk_divide=1
CSET mmcm_notes=None
CSET mmcm_ref_jitter1=0.010
CSET mmcm_ref_jitter2=0.010
CSET mmcm_startup_wait=false
CSET num_out_clks=3
CSET override_dcm=false
CSET override_dcm_clkgen=false
CSET override_mmcm=false
CSET override_pll=false
CSET platform=nt64
# CSET pll_bandwidth=OPTIMIZED
# CSET pll_clk_feedback=CLKFBOUT
# CSET pll_clkfbout_mult=16
# CSET pll_clkfbout_phase=0.000
# CSET pll_clkin_period=40.0
# CSET pll_clkout0_divide=5
# CSET pll_clkout0_duty_cycle=0.500
# CSET pll_clkout0_phase=0.000
# CSET pll_clkout1_divide=6
# CSET pll_clkout1_duty_cycle=0.500
# CSET pll_clkout1_phase=0.000
# CSET pll_clkout2_divide=16
# CSET pll_clkout2_duty_cycle=0.500
# CSET pll_clkout2_phase=0.000
# CSET pll_clkout3_divide=1
# CSET pll_clkout3_duty_cycle=0.500
# CSET pll_clkout3_phase=0.000
# CSET pll_clkout4_divide=1
# CSET pll_clkout4_duty_cycle=0.500
# CSET pll_clkout4_phase=0.000
# CSET pll_clkout5_divide=1
# CSET pll_clkout5_duty_cycle=0.500
# CSET pll_clkout5_phase=0.000
# CSET pll_compensation=SYSTEM_SYNCHRONOUS
# CSET pll_divclk_divide=1
# CSET pll_notes=None
# CSET pll_ref_jitter=0.010
CSET power_down_port=POWER_DOWN
CSET prim_in_freq=25
CSET prim_in_jitter=0.010
CSET prim_source=No_buffer
CSET primary_port=CLK_IN1
CSET primitive=MMCM
CSET primtype_sel=PLL_BASE
CSET psclk_port=PSCLK
CSET psdone_port=PSDONE
CSET psen_port=PSEN
CSET psincdec_port=PSINCDEC
CSET relative_inclk=REL_PRIMARY
CSET reset_port=RESET
CSET secondary_in_freq=100.000
CSET secondary_in_jitter=0.010
CSET secondary_port=CLK_IN2
CSET secondary_source=Single_ended_clock_capable_pin
CSET ss_mod_freq=250
CSET ss_mode=CENTER_HIGH
CSET status_port=STATUS
CSET summary_strings=empty
CSET use_clk_valid=false
CSET use_clkfb_stopped=false
CSET use_dyn_phase_shift=false
CSET use_dyn_reconfig=false
CSET use_freeze=false
CSET use_freq_synth=true
CSET use_inclk_stopped=false
CSET use_inclk_switchover=false
CSET use_locked=true
CSET use_max_i_jitter=false
CSET use_min_o_jitter=false
CSET use_min_power=false
CSET use_phase_alignment=true
CSET use_power_down=false
CSET use_reset=true
CSET use_spread_spectrum=false
CSET use_spread_spectrum_1=false
CSET use_status=false
# END Parameters
# BEGIN Extra information
MISC pkg_timestamp=2012-05-10T12:44:55Z
# END Extra information
GENERATE
# CRC: 180c5c99
   }
   close $fp

   exec coregen -b "../ip_core/DCM.xco" -p "../ip_core/coregen.cgp"
}

# generate_mcs_file: Creates an MCS configuration file from the bitstream
proc generate_mcs_file {} {
   global project_name script_name top_module bit_file mcs_file
   puts "$script_name: Generating MCS file..."
   exec promgen -w -p mcs -c FF -o ../output/$mcs_file -s 8192 -u 0 $bit_file
}

# program_spi_flash: Programs the MCS file into SPI flash memory using Impact
proc program_spi_flash {} {
   global project_name script_name mcs_file

   puts "$script_name: Programming SPI Flash..."

   # Create a batch command file for Impact
   set fp [open "spi_flash_temp.cmd" "w"]
   puts $fp "setMode -bscan"
   puts $fp "setCable -port auto"
   puts $fp "Identify"
   puts $fp "attachflash -position 1 -spi \"w25q80bv\""
   puts $fp "assignfiletoattachedflash -position 1 -file \"../output/$mcs_file\""
   puts $fp "Program -p 1 -dataWidth 4 -spionly -e -v -loadfpga"
   puts $fp "quit"
   close $fp

   # Execute Impact in batch mode
   exec impact -batch spi_flash_temp.cmd
}

# add_source_files: Adds source files and constraints to the project
proc add_source_files {} {
   global script_name top_module
   if { ! [ open_project ] } { return false }

   puts "$script_name: Adding source files..."

   # Add RTL source files
   xfile add "../rtl/BUTTON.v"
   xfile add "../rtl/COUNTER.v"
   xfile add "../rtl/PANELCTRL.v"
   xfile add "../rtl/PATTERNSEL.v"
   xfile add "../rtl/TIMING.v"

   # Add constraints
   xfile add "../constraint/PINassign_G2.ucf"

   # Add IP core files
   xfile add "../ip_core/DCM.xco"

   # Set top module
   project set top $top_module

   puts "$script_name: Source files added."
}

# create_libraries: Defines VHDL libraries in the project (if needed)
proc create_libraries {} {
   global script_name
   if { ! [ open_project ] } { return false }

   puts "$script_name: Creating libraries..."
   # Define library creation commands here if needed
   project save
}

# set_process_props: Sets various flow process parameters
proc set_process_props {} {
   global script_name top_module
   if { ! [ open_project ] } { return false }

   puts "$script_name: Setting process properties..."

   # Example process parameters:
   project set "Compiled Library Directory" "\$XILINX/<language>/<simulator>"
   project set "Global Optimization" "Off" -process "Map"
   project set "Pack I/O Registers/Latches into IOBs" "Off" -process "Map"
   project set "Place And Route Mode" "Route Only" -process "Place & Route"
   project set "Regenerate Core" "Under Current Project Setting" -process "Regenerate Core"
   project set "Filter Files From Compile Order" "true"
   project set "Last Applied Goal" "Balanced"
   project set "Last Applied Strategy" "Xilinx Default (unlocked)"
   project set "Last Unlock Status" "false"
   project set "Manual Compile Order" "false"
   project set "Placer Effort Level" "High" -process "Map"
   project set "Extra Cost Tables" "0" -process "Map"
   project set "LUT Combining" "Off" -process "Map"
   project set "Combinatorial Logic Optimization" "false" -process "Map"
   project set "Starting Placer Cost Table (1-100)" "1" -process "Map"
   project set "Power Reduction" "Off" -process "Map"
   project set "Report Fastest Path(s) in Each Constraint" "true" -process "Generate Post-Place & Route Static Timing"
   project set "Generate Datasheet Section" "true" -process "Generate Post-Place & Route Static Timing"
   project set "Generate Timegroups Section" "false" -process "Generate Post-Place & Route Static Timing"
   project set "Report Fastest Path(s) in Each Constraint" "true" -process "Generate Post-Map Static Timing"
   project set "Generate Datasheet Section" "true" -process "Generate Post-Map Static Timing"
   project set "Generate Timegroups Section" "false" -process "Generate Post-Map Static Timing"
   project set "Project Description" ""
   project set "Property Specification in Project File" "Store all values"
   project set "Reduce Control Sets" "Auto" -process "Synthesize - XST"
   project set "Shift Register Minimum Size" "2" -process "Synthesize - XST"
   project set "Case Implementation Style" "None" -process "Synthesize - XST"
   project set "RAM Extraction" "true" -process "Synthesize - XST"
   project set "ROM Extraction" "true" -process "Synthesize - XST"
   project set "FSM Encoding Algorithm" "Auto" -process "Synthesize - XST"
   project set "Optimization Goal" "Speed" -process "Synthesize - XST"
   project set "Optimization Effort" "Normal" -process "Synthesize - XST"
   project set "Resource Sharing" "true" -process "Synthesize - XST"
   project set "Shift Register Extraction" "true" -process "Synthesize - XST"
   project set "User Browsed Strategy Files" ""
   project set "VHDL Source Analysis Standard" "VHDL-93"
   project set "Analysis Effort Level" "Standard" -process "Analyze Power Distribution (XPower Analyzer)"
   project set "Analysis Effort Level" "Standard" -process "Generate Text Power Report"
   project set "Input TCL Command Script" "" -process "Generate Text Power Report"
   project set "Load Physical Constraints File" "Default" -process "Analyze Power Distribution (XPower Analyzer)"
   project set "Load Physical Constraints File" "Default" -process "Generate Text Power Report"
   project set "Load Simulation File" "Default" -process "Analyze Power Distribution (XPower Analyzer)"
   project set "Load Simulation File" "Default" -process "Generate Text Power Report"
   project set "Load Setting File" "" -process "Analyze Power Distribution (XPower Analyzer)"
   project set "Load Setting File" "" -process "Generate Text Power Report"
   project set "Setting Output File" "" -process "Generate Text Power Report"
   project set "Produce Verbose Report" "false" -process "Generate Text Power Report"
   project set "Other XPWR Command Line Options" "" -process "Generate Text Power Report"
   project set "Essential Bits" "false" -process "Generate Programming File"
   project set "Other Bitgen Command Line Options" "" -process "Generate Programming File"
   project set "Maximum Signal Name Length" "20" -process "Generate IBIS Model"
   project set "Show All Models" "false" -process "Generate IBIS Model"
   project set "VCCAUX Voltage Level" "2.5V" -process "Generate IBIS Model"
   project set "Disable Detailed Package Model Insertion" "false" -process "Generate IBIS Model"
   project set "Launch SDK after Export" "true" -process "Export Hardware Design To SDK with Bitstream"
   project set "Launch SDK after Export" "true" -process "Export Hardware Design To SDK without Bitstream"
   project set "Target UCF File Name" "" -process "Back-annotate Pin Locations"
   project set "Ignore User Timing Constraints" "false" -process "Map"
   project set "Register Ordering" "4" -process "Map"
   project set "Use RLOC Constraints" "Yes" -process "Map"
   project set "Other Map Command Line Options" "" -process "Map"
   project set "Use LOC Constraints" "true" -process "Translate"
   project set "Other Ngdbuild Command Line Options" "" -process "Translate"
   project set "Use 64-bit PlanAhead on 64-bit Systems" "true" -process "Floorplan Area/IO/Logic (PlanAhead)"
   project set "Use 64-bit PlanAhead on 64-bit Systems" "true" -process "I/O Pin Planning (PlanAhead) - Pre-Synthesis"
   project set "Use 64-bit PlanAhead on 64-bit Systems" "true" -process "I/O Pin Planning (PlanAhead) - Post-Synthesis"
   project set "Ignore User Timing Constraints" "false" -process "Place & Route"
   project set "Other Place & Route Command Line Options" "" -process "Place & Route"
   project set "Use DSP Block" "Auto" -process "Synthesize - XST"
   project set "UserID Code (8 Digit Hexadecimal)" "0xFFFFFFFF" -process "Generate Programming File"
   project set "Configuration Pin Done" "Pull Up" -process "Generate Programming File"
   project set "Enable External Master Clock" "false" -process "Generate Programming File"
   project set "Create ASCII Configuration File" "false" -process "Generate Programming File"
   project set "Create Bit File" "true" -process "Generate Programming File"
   project set "Enable BitStream Compression" "false" -process "Generate Programming File"
   project set "Run Design Rules Checker (DRC)" "true" -process "Generate Programming File"
   project set "Enable Cyclic Redundancy Checking (CRC)" "true" -process "Generate Programming File"
   project set "Create IEEE 1532 Configuration File" "false" -process "Generate Programming File"
   project set "Create ReadBack Data Files" "false" -process "Generate Programming File"
   project set "Configuration Pin Program" "Pull Up" -process "Generate Programming File"
   project set "Place MultiBoot Settings into Bitstream" "false" -process "Generate Programming File"
   project set "Configuration Rate" "26" -process "Generate Programming File"
   project set "Set SPI Configuration Bus Width" "4" -process "Generate Programming File"
   project set "JTAG Pin TCK" "Pull Up" -process "Generate Programming File"
   project set "JTAG Pin TDI" "Pull Up" -process "Generate Programming File"
   project set "JTAG Pin TDO" "Pull Up" -process "Generate Programming File"
   project set "JTAG Pin TMS" "Pull Up" -process "Generate Programming File"
   project set "Unused IOB Pins" "Pull Down" -process "Generate Programming File"
   project set "Watchdog Timer Value" "0xFFFF" -process "Generate Programming File"
   project set "Security" "Enable Readback and Reconfiguration" -process "Generate Programming File"
   project set "FPGA Start-Up Clock" "CCLK" -process "Generate Programming File"
   project set "Done (Output Events)" "Default (4)" -process "Generate Programming File"
   project set "Drive Done Pin High" "false" -process "Generate Programming File"
   project set "Enable Outputs (Output Events)" "Default (5)" -process "Generate Programming File"
   project set "Wait for DCM and PLL Lock (Output Events)" "Default (NoWait)" -process "Generate Programming File"
   project set "Release Write Enable (Output Events)" "Default (6)" -process "Generate Programming File"
   project set "Enable Internal Done Pipe" "false" -process "Generate Programming File"
   project set "Drive Awake Pin During Suspend/Wake Sequence" "false" -process "Generate Programming File"
   project set "Enable Suspend/Wake Global Set/Reset" "false" -process "Generate Programming File"
   project set "Enable Multi-Pin Wake-Up Suspend Mode" "false" -process "Generate Programming File"
   project set "GTS Cycle During Suspend/Wakeup Sequence" "4" -process "Generate Programming File"
   project set "GWE Cycle During Suspend/Wakeup Sequence" "5" -process "Generate Programming File"
   project set "Wakeup Clock" "Startup Clock" -process "Generate Programming File"
   project set "Allow Logic Optimization Across Hierarchy" "false" -process "Map"
   project set "Maximum Compression" "false" -process "Map"
   project set "Generate Detailed MAP Report" "false" -process "Map"
   project set "Map Slice Logic into Unused Block RAMs" "false" -process "Map"
   project set "Perform Timing-Driven Packing and Placement" "false"
   project set "Trim Unconnected Signals" "true" -process "Map"
   project set "Create I/O Pads from Ports" "false" -process "Translate"
   project set "Macro Search Path" "" -process "Translate"
   project set "Netlist Translation Type" "Timestamp" -process "Translate"
   project set "User Rules File for Netlister Launcher" "" -process "Translate"
   project set "Allow Unexpanded Blocks" "false" -process "Translate"
   project set "Allow Unmatched LOC Constraints" "false" -process "Translate"
   project set "Allow Unmatched Timing Group Constraints" "false" -process "Translate"
   project set "Perform Advanced Analysis" "false" -process "Generate Post-Place & Route Static Timing"
   project set "Report Paths by Endpoint" "3" -process "Generate Post-Place & Route Static Timing"
   project set "Report Type" "Verbose Report" -process "Generate Post-Place & Route Static Timing"
   project set "Number of Paths in Error/Verbose Report" "3" -process "Generate Post-Place & Route Static Timing"
   project set "Stamp Timing Model Filename" "" -process "Generate Post-Place & Route Static Timing"
   project set "Report Unconstrained Paths" "" -process "Generate Post-Place & Route Static Timing"
   project set "Perform Advanced Analysis" "false" -process "Generate Post-Map Static Timing"
   project set "Report Paths by Endpoint" "3" -process "Generate Post-Map Static Timing"
   project set "Report Type" "Verbose Report" -process "Generate Post-Map Static Timing"
   project set "Number of Paths in Error/Verbose Report" "3" -process "Generate Post-Map Static Timing"
   project set "Report Unconstrained Paths" "" -process "Generate Post-Map Static Timing"
   project set "Number of Clock Buffers" "16" -process "Synthesize - XST"
   project set "Add I/O Buffers" "true" -process "Synthesize - XST"
   project set "Global Optimization Goal" "AllClockNets" -process "Synthesize - XST"
   project set "Keep Hierarchy" "No" -process "Synthesize - XST"
   project set "Max Fanout" "100000" -process "Synthesize - XST"
   project set "Register Balancing" "No" -process "Synthesize - XST"
   project set "Register Duplication" "true" -process "Synthesize - XST"
   project set "Library for Verilog Sources" "" -process "Synthesize - XST"
   project set "Export Results to XPower Estimator" "" -process "Generate Text Power Report"
   project set "Asynchronous To Synchronous" "false" -process "Synthesize - XST"
   project set "Automatic BRAM Packing" "false" -process "Synthesize - XST"
   project set "BRAM Utilization Ratio" "100" -process "Synthesize - XST"
   project set "Bus Delimiter" "<>" -process "Synthesize - XST"
   project set "Case" "Maintain" -process "Synthesize - XST"
   project set "Cores Search Directories" "" -process "Synthesize - XST"
   project set "Cross Clock Analysis" "false" -process "Synthesize - XST"
   project set "DSP Utilization Ratio" "100" -process "Synthesize - XST"
   project set "Equivalent Register Removal" "true" -process "Synthesize - XST"
   project set "FSM Style" "LUT" -process "Synthesize - XST"
   project set "Generate RTL Schematic" "Yes" -process "Synthesize - XST"
   project set "Generics, Parameters" "" -process "Synthesize - XST"
   project set "Hierarchy Separator" "/" -process "Synthesize - XST"
   project set "HDL INI File" "" -process "Synthesize - XST"
   project set "LUT Combining" "Auto" -process "Synthesize - XST"
   project set "Library Search Order" "" -process "Synthesize - XST"
   project set "Netlist Hierarchy" "As Optimized" -process "Synthesize - XST"
   project set "Optimize Instantiated Primitives" "false" -process "Synthesize - XST"
   project set "Pack I/O Registers into IOBs" "Auto" -process "Synthesize - XST"
   project set "Power Reduction" "false" -process "Synthesize - XST"
   project set "Read Cores" "true" -process "Synthesize - XST"
   project set "Use Clock Enable" "Auto" -process "Synthesize - XST"
   project set "Use Synchronous Reset" "Auto" -process "Synthesize - XST"
   project set "Use Synchronous Set" "Auto" -process "Synthesize - XST"
   project set "Use Synthesis Constraints File" "true" -process "Synthesize - XST"
   project set "Verilog Include Directories" "" -process "Synthesize - XST"
   project set "Verilog Macros" "" -process "Synthesize - XST"
   project set "Work Directory" "D:/YiCheng/RA_Code/C070VAN01_OBA_old_ISE/xst" -process "Synthesize - XST"
   project set "Write Timing Constraints" "false" -process "Synthesize - XST"
   project set "Other XST Command Line Options" "" -process "Synthesize - XST"
   project set "Timing Mode" "Performance Evaluation" -process "Map"
   project set "Generate Asynchronous Delay Report" "false" -process "Place & Route"
   project set "Generate Clock Region Report" "false" -process "Place & Route"
   project set "Generate Post-Place & Route Power Report" "false" -process "Place & Route"
   project set "Generate Post-Place & Route Simulation Model" "false" -process "Place & Route"
   project set "Power Reduction" "false" -process "Place & Route"
   project set "Place & Route Effort Level (Overall)" "High" -process "Place & Route"
   project set "Auto Implementation Compile Order" "true"
   project set "Equivalent Register Removal" "true" -process "Map"
   project set "Placer Extra Effort" "None" -process "Map"
   project set "Power Activity File" "" -process "Map"
   project set "Register Duplication" "Off" -process "Map"
   project set "Generate Constraints Interaction Report" "false" -process "Generate Post-Map Static Timing"
   project set "Synthesis Constraints File" "" -process "Synthesize - XST"
   project set "RAM Style" "Auto" -process "Synthesize - XST"
   project set "Maximum Number of Lines in Report" "1000" -process "Generate Text Power Report"
   project set "MultiBoot: Insert IPROG CMD in the Bitfile" "Enable" -process "Generate Programming File"
   project set "Output File Name" "$top_module" -process "Generate IBIS Model"
   project set "Timing Mode" "Performance Evaluation" -process "Place & Route"
   project set "Create Binary Configuration File" "false" -process "Generate Programming File"
   project set "Enable Debugging of Serial Mode BitStream" "false" -process "Generate Programming File"
   project set "Create Logic Allocation File" "false" -process "Generate Programming File"
   project set "Create Mask File" "false" -process "Generate Programming File"
   project set "Retry Configuration if CRC Error Occurs" "false" -process "Generate Programming File"
   project set "MultiBoot: Starting Address for Next Configuration" "0x00000000" -process "Generate Programming File"
   project set "MultiBoot: Starting Address for Golden Configuration" "0x00000000" -process "Generate Programming File"
   project set "MultiBoot: Use New Mode for Next Configuration" "true" -process "Generate Programming File"
   project set "MultiBoot: User-Defined Register for Failsafe Scheme" "0x0000" -process "Generate Programming File"
   project set "Setup External Master Clock Division" "1" -process "Generate Programming File"
   project set "Allow SelectMAP Pins to Persist" "false" -process "Generate Programming File"
   project set "Mask Pins for Multi-Pin Wake-Up Suspend Mode" "0x00" -process "Generate Programming File"
   project set "Enable Multi-Threading" "2" -process "Map"
   project set "Generate Constraints Interaction Report" "false" -process "Generate Post-Place & Route Static Timing"
   project set "Move First Flip-Flop Stage" "true" -process "Synthesize - XST"
   project set "Move Last Flip-Flop Stage" "true" -process "Synthesize - XST"
   project set "ROM Style" "Auto" -process "Synthesize - XST"
   project set "Safe Implementation" "No" -process "Synthesize - XST"
   project set "Power Activity File" "" -process "Place & Route"
   project set "Extra Effort (Highest PAR level only)" "None" -process "Place & Route"
   project set "MultiBoot: Next Configuration Mode" "001" -process "Generate Programming File"
   project set "Encrypt Bitstream" "false" -process "Generate Programming File"
   project set "Enable Multi-Threading" "4" -process "Place & Route"
   project set "AES Initial Vector" "" -process "Generate Programming File"
   project set "Encrypt Key Select" "BBRAM" -process "Generate Programming File"
   project set "AES Key (Hex String)" "" -process "Generate Programming File"
   project set "Input Encryption Key File" "" -process "Generate Programming File"
   project set "Functional Model Target Language" "Verilog" -process "View HDL Source"
   project set "Change Device Speed To" "-3" -process "Generate Post-Place & Route Static Timing"
   project set "Change Device Speed To" "-3" -process "Generate Post-Map Static Timing"

   puts "$script_name: Process parameters configured."
}

# ==========================
# Script Entry Point
# ==========================
# If no arguments, display help
# If arguments provided, execute corresponding procedures
proc main {} {
   if { [llength $::argv] == 0 } {
      show_help
      return true
   }

   foreach option $::argv {
      switch $option {
         "show_help"           { show_help }
         "run_process"         { run_process }
         "rebuild_project"     { rebuild_project }
         "set_project_props"   { set_project_props }
         "regenerate_dcm_core" { regenerate_dcm_core }
         "add_source_files"    { add_source_files }
         "create_libraries"    { create_libraries }
         "set_process_props"   { set_process_props }
         "generate_mcs_file"   { generate_mcs_file }
         "program_spi_flash"   { program_spi_flash }
         default               { puts "Unrecognized option: $option"; show_help }
      }
   }
}

# If running in interactive mode, display help
if { $tcl_interactive } {
   show_help
} else {
   # Run main in batch mode
   if { [catch {main} result] } {
      puts "$script_name failed: $result"
   }
}
