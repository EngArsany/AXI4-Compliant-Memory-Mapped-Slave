#===========================================================
# run_all.do — AXI4 READ + WRITE complete verification
#===========================================================

#===========================================================
# Project path
#===========================================================

quietly set PROJ_DIR "C:/Users/zyado/OneDrive/Desktop/Summer 2026/Hassan Khaled/AXI4_Project"

#===========================================================
# Output directory
#===========================================================

file mkdir "${PROJ_DIR}/reports"

# Main simulation transcript
transcript file "${PROJ_DIR}/reports/Main.log"

#===========================================================
# Clean previous compilation
#===========================================================

.main clear

if {[file exists work]} {
    vdel -lib work -all
}

vlib work
vmap work work


#===========================================================
# RTL / DUT
#===========================================================

# AXI4 memory
vlog +cover=sbceft \
    "${PROJ_DIR}/rtl/axi_memory.v"

# AXI4 top/design
vlog +cover=sbceft \
    "${PROJ_DIR}/rtl/axi4.v"


#===========================================================
# SHARED TESTBENCH FILES
#===========================================================

# AXI4 interface
vlog "${PROJ_DIR}/tb/shared/axi4_if.sv"

# Shared reference model
vlog "${PROJ_DIR}/tb/shared/axi4_reference_model.sv"


#===========================================================
# READ TRANSACTION
#===========================================================

vlog "${PROJ_DIR}/tb/read/axi4_read_transaction.sv"


#===========================================================
# WRITE TRANSACTION
#===========================================================

vlog "${PROJ_DIR}/tb/write/axi4_write_transaction.sv"


#===========================================================
# READ ENVIRONMENT
#===========================================================

vlog "${PROJ_DIR}/tb/read/axi4_read_generator.sv"

vlog "${PROJ_DIR}/tb/read/axi4_read_driver.sv"

vlog "${PROJ_DIR}/tb/read/axi4_read_monitor.sv"

vlog "${PROJ_DIR}/tb/read/axi4_read_scoreboard.sv"


#===========================================================
# WRITE ENVIRONMENT
#===========================================================

vlog "${PROJ_DIR}/tb/write/axi4_backdoor_base.sv"

vlog "${PROJ_DIR}/tb/write/axi4_write_generator.sv"

vlog "${PROJ_DIR}/tb/write/axi4_write_driver.sv"

vlog "${PROJ_DIR}/tb/write/axi4_write_monitor.sv"

vlog "${PROJ_DIR}/tb/write/axi4_write_golden_model.sv"

vlog "${PROJ_DIR}/tb/write/axi4_write_scoreboard.sv"

vlog "${PROJ_DIR}/tb/write/axi4_write_coverage.sv"


#===========================================================
# ENVIRONMENT
#===========================================================

vlog "${PROJ_DIR}/tb/env/axi4_env.sv"


#===========================================================
# TOP TESTBENCH
#===========================================================

vlog "${PROJ_DIR}/tb/top/axi4_tb_top.sv"


#===========================================================
# OPTIMIZATION
#===========================================================

vopt +acc +cover=sbceft \
    work.axi4_tb_top \
    -o axi4_tb_top_opt


#===========================================================
# START SIMULATION
#===========================================================

vsim -coverage \
    -voptargs=+acc \
    axi4_tb_top_opt


#===========================================================
# WAVEFORM
#===========================================================

add wave *


#===========================================================
# RUN COMPLETE READ + WRITE TEST
#===========================================================

run -all


#===========================================================
# SAVE UCDB
#===========================================================

coverage save -onexit \
    -assert \
    -directive \
    -cvg \
    -codeAll \
    "${PROJ_DIR}/reports/axi4_all_coverage.ucdb"


#===========================================================
# OVERALL COVERAGE
#===========================================================

coverage report -details \
    -output "${PROJ_DIR}/reports/overall_coverage_report.txt"


#===========================================================
# FUNCTIONAL COVERAGE
#===========================================================

coverage report -cvg -details \
    -output "${PROJ_DIR}/reports/functional_coverage_report.txt"


#===========================================================
# ASSERTION COVERAGE
#===========================================================

coverage report -assert -details \
    -output "${PROJ_DIR}/reports/assertion_coverage_report.txt"


#===========================================================
# STATEMENT COVERAGE
#===========================================================

coverage report -code s -details \
    -output "${PROJ_DIR}/reports/statement_coverage_report.txt"


#===========================================================
# BRANCH COVERAGE
#===========================================================

coverage report -code b -details \
    -output "${PROJ_DIR}/reports/branch_coverage_report.txt"


#===========================================================
# CONDITION / EXPRESSION COVERAGE
#===========================================================

coverage report -code c -details \
    -output "${PROJ_DIR}/reports/condition_expression_coverage_report.txt"


#===========================================================
# TOGGLE ENABLE COVERAGE
#===========================================================

coverage report -code e -details \
    -output "${PROJ_DIR}/reports/toggle_enable_coverage_report.txt"


#===========================================================
# FSM COVERAGE
#===========================================================

coverage report -code f -details \
    -output "${PROJ_DIR}/reports/fsm_coverage_report.txt"


#===========================================================
# TOGGLE COVERAGE
#===========================================================

coverage report -code t -details \
    -output "${PROJ_DIR}/reports/toggle_coverage_report.txt"


#===========================================================
# READ + WRITE OPERATION REPORT
#===========================================================

coverage report -details \
    -output "${PROJ_DIR}/reports/read_write_operations_report.txt"


#===========================================================
# CLOSE TRANSCRIPT
#===========================================================

transcript file ""

puts "==========================================================="
puts " AXI4 READ + WRITE VERIFICATION COMPLETED"
puts "==========================================================="
puts " UCDB:"
puts " reports/axi4_all_coverage.ucdb"
puts ""
puts " Main Log:"
puts " reports/Main.log"
puts ""
puts " Coverage Reports:"
puts " reports/overall_coverage_report.txt"
puts " reports/functional_coverage_report.txt"
puts " reports/assertion_coverage_report.txt"
puts " reports/statement_coverage_report.txt"
puts " reports/branch_coverage_report.txt"
puts " reports/condition_expression_coverage_report.txt"
puts " reports/toggle_enable_coverage_report.txt"
puts " reports/fsm_coverage_report.txt"
puts " reports/toggle_coverage_report.txt"
puts " reports/read_write_operations_report.txt"
puts "==========================================================="