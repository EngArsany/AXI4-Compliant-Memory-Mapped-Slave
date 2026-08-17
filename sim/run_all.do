#===========================================================
# AXI4 COMPLETE REGRESSION
# READ + WRITE
#===========================================================

#===========================================================
# PROJECT PATH
#===========================================================

quietly set PROJ_DIR "C:/Users/zyado/OneDrive/Desktop/Summer 2026/Hassan Khaled/AXI4_Project"
quietly set OUT_DIR  "${PROJ_DIR}/sim_out"

file mkdir "${OUT_DIR}"

transcript file "${OUT_DIR}/Main.log"


#===========================================================
# CLEAN WORK LIBRARY
#===========================================================

if {[file exists work]} {
    vdel -lib work -all
}

vlib work
vmap work work


#===========================================================
# RTL / DUT
#===========================================================

puts "==========================================================="
puts " Compiling RTL"
puts "==========================================================="

vlog -sv +cover=sbceft \
    "${PROJ_DIR}/rtl/axi_memory.v"

vlog -sv +cover=sbceft \
    "${PROJ_DIR}/rtl/axi4.v"


#===========================================================
# SHARED INTERFACE
#===========================================================

puts "==========================================================="
puts " Compiling AXI interface"
puts "==========================================================="

vlog -sv \
    "${PROJ_DIR}/tb/shared/axi4_if.sv"


#===========================================================
# READ TRANSACTION PACKAGE
#
# MUST be compiled before anything importing:
# AXI_read_transaction_pkg
#===========================================================

puts "==========================================================="
puts " Compiling READ transaction package"
puts "==========================================================="

vlog -sv \
    "${PROJ_DIR}/tb/read/axi4_read_transaction.sv"


#===========================================================
# WRITE TRANSACTION PACKAGE
#
# MUST be compiled before:
# axi4_reference_model.sv
#
# because reference model imports:
# AXI_write_transaction_pkg
#===========================================================

puts "==========================================================="
puts " Compiling WRITE transaction package"
puts "==========================================================="

vlog -sv \
    "${PROJ_DIR}/tb/write/axi4_write_transaction.sv"


#===========================================================
# READ FUNCTIONAL COVERAGE
#
# AXI_read_scoreboard imports:
# AXI_read_coverage_pkg
#
# Therefore compile it before the scoreboard.
#===========================================================

puts "==========================================================="
puts " Compiling READ functional coverage"
puts "==========================================================="

vlog -sv \
    "${PROJ_DIR}/tb/read/axi4_read_coverage.sv"


#===========================================================
# SHARED REFERENCE MODEL
#
# IMPORTANT:
#
# axi4_reference_model.sv imports:
#
#   AXI_write_transaction_pkg
#   AXI_read_transaction_pkg
#
# Both packages have already been compiled above.
#===========================================================

puts "==========================================================="
puts " Compiling AXI reference model"
puts "==========================================================="

vlog -sv \
    "${PROJ_DIR}/tb/shared/axi4_reference_model.sv"


#===========================================================
# READ GENERATOR
#===========================================================

puts "==========================================================="
puts " Compiling READ generator"
puts "==========================================================="

vlog -sv \
    "${PROJ_DIR}/tb/read/axi4_read_generator.sv"


#===========================================================
# READ DRIVER
#===========================================================

puts "==========================================================="
puts " Compiling READ driver"
puts "==========================================================="

vlog -sv \
    "${PROJ_DIR}/tb/read/axi4_read_driver.sv"


#===========================================================
# READ MONITOR
#===========================================================

puts "==========================================================="
puts " Compiling READ monitor"
puts "==========================================================="

vlog -sv \
    "${PROJ_DIR}/tb/read/axi4_read_monitor.sv"


#===========================================================
# READ SCOREBOARD
#===========================================================

puts "==========================================================="
puts " Compiling READ scoreboard"
puts "==========================================================="

vlog -sv \
    "${PROJ_DIR}/tb/read/axi4_read_scoreboard.sv"


#===========================================================
# WRITE BACKDOOR
#===========================================================

puts "==========================================================="
puts " Compiling WRITE backdoor"
puts "==========================================================="

vlog -sv \
    "${PROJ_DIR}/tb/write/axi4_backdoor_base.sv"


#===========================================================
# WRITE GENERATOR
#===========================================================

puts "==========================================================="
puts " Compiling WRITE generator"
puts "==========================================================="

vlog -sv \
    "${PROJ_DIR}/tb/write/axi4_write_generator.sv"


#===========================================================
# WRITE DRIVER
#===========================================================

puts "==========================================================="
puts " Compiling WRITE driver"
puts "==========================================================="

vlog -sv \
    "${PROJ_DIR}/tb/write/axi4_write_driver.sv"


#===========================================================
# WRITE MONITOR
#===========================================================

puts "==========================================================="
puts " Compiling WRITE monitor"
puts "==========================================================="

vlog -sv \
    "${PROJ_DIR}/tb/write/axi4_write_monitor.sv"


#===========================================================
# WRITE GOLDEN MODEL
#===========================================================

puts "==========================================================="
puts " Compiling WRITE golden model"
puts "==========================================================="

vlog -sv \
    "${PROJ_DIR}/tb/write/axi4_write_golden_model.sv"


#===========================================================
# WRITE FUNCTIONAL COVERAGE
#
# MUST be compiled before axi4_write_scoreboard.sv, since the
# scoreboard now imports AXI_write_coverage_pkg and declares
# a write_cov handle of type axi4_write_coverage.
#===========================================================

puts "==========================================================="
puts " Compiling WRITE functional coverage"
puts "==========================================================="

vlog -sv \
    "${PROJ_DIR}/tb/write/axi4_write_coverage.sv"


#===========================================================
# WRITE SCOREBOARD
#===========================================================

puts "==========================================================="
puts " Compiling WRITE scoreboard"
puts "==========================================================="

vlog -sv \
    "${PROJ_DIR}/tb/write/axi4_write_scoreboard.sv"


#===========================================================
# ENVIRONMENT
#===========================================================

puts "==========================================================="
puts " Compiling AXI environment"
puts "==========================================================="

vlog -sv \
    "${PROJ_DIR}/tb/env/axi4_env.sv"


#===========================================================
# TOP TESTBENCH
#===========================================================

puts "==========================================================="
puts " Compiling TB top"
puts "==========================================================="

vlog -sv +cover=sbceft \
    "${PROJ_DIR}/tb/top/axi4_tb_top.sv"


#===========================================================
# OPTIMIZATION
#===========================================================

puts "==========================================================="
puts " Optimizing simulation"
puts "==========================================================="

vopt +acc +cover=sbceft \
    work.tb_top \
    -o tb_top_opt


#===========================================================
# START SIMULATION
#===========================================================

puts "==========================================================="
puts " Starting simulation"
puts "==========================================================="

vsim -coverage \
    -voptargs=+acc \
    tb_top_opt


#===========================================================
# WAVES
#===========================================================

add wave *


#===========================================================
# RUN COMPLETE READ + WRITE REGRESSION
#===========================================================

puts "==========================================================="
puts " Running READ + WRITE regression"
puts "==========================================================="

run -all


#===========================================================
# SAVE COMBINED UCDB
#===========================================================

puts "==========================================================="
puts " Saving coverage database"
puts "==========================================================="

coverage save \
    -onexit \
    -assert \
    -directive \
    -cvg \
    -codeAll \
    "${OUT_DIR}/axi4_all_coverage.ucdb"


#===========================================================
# OVERALL COVERAGE
#===========================================================

puts "Generating overall coverage report..."

coverage report \
    -details \
    -output "${OUT_DIR}/overall_coverage_report.txt"


#===========================================================
# FUNCTIONAL COVERAGE
#===========================================================

puts "Generating functional coverage report..."

coverage report \
    -cvg \
    -details \
    -output "${OUT_DIR}/functional_coverage_report.txt"


#===========================================================
# ASSERTION COVERAGE
#===========================================================

puts "Generating assertion coverage report..."

coverage report \
    -assert \
    -details \
    -output "${OUT_DIR}/assertion_coverage_report.txt"


#===========================================================
# STATEMENT COVERAGE
#===========================================================

puts "Generating statement coverage report..."

coverage report \
    -code s \
    -details \
    -output "${OUT_DIR}/statement_coverage_report.txt"


#===========================================================
# BRANCH COVERAGE
#===========================================================

puts "Generating branch coverage report..."

coverage report \
    -code b \
    -details \
    -output "${OUT_DIR}/branch_coverage_report.txt"


#===========================================================
# CONDITION / EXPRESSION COVERAGE
#===========================================================

puts "Generating condition/expression coverage report..."

coverage report \
    -code c \
    -details \
    -output "${OUT_DIR}/condition_expression_coverage_report.txt"


#===========================================================
# TOGGLE ENABLE COVERAGE
#===========================================================

puts "Generating toggle-enable coverage report..."

coverage report \
    -code e \
    -details \
    -output "${OUT_DIR}/toggle_enable_coverage_report.txt"


#===========================================================
# FSM COVERAGE
#===========================================================

puts "Generating FSM coverage report..."

coverage report \
    -code f \
    -details \
    -output "${OUT_DIR}/fsm_coverage_report.txt"


#===========================================================
# TOGGLE COVERAGE
#===========================================================

puts "Generating toggle coverage report..."

coverage report \
    -code t \
    -details \
    -output "${OUT_DIR}/toggle_coverage_report.txt"


#===========================================================
# FINAL MESSAGE
#===========================================================

puts ""
puts "==========================================================="
puts " AXI4 READ + WRITE REGRESSION COMPLETED"
puts "==========================================================="
puts ""
puts "Output directory:"
puts "${OUT_DIR}"
puts ""
puts "Main log:"
puts "${OUT_DIR}/Main.log"
puts ""
puts "Coverage database:"
puts "${OUT_DIR}/axi4_all_coverage.ucdb"
puts ""
puts "Coverage reports:"
puts "  overall_coverage_report.txt"
puts "  functional_coverage_report.txt"
puts "  assertion_coverage_report.txt"
puts "  statement_coverage_report.txt"
puts "  branch_coverage_report.txt"
puts "  condition_expression_coverage_report.txt"
puts "  toggle_enable_coverage_report.txt"
puts "  fsm_coverage_report.txt"
puts "  toggle_coverage_report.txt"
puts ""
puts "==========================================================="


#===========================================================
# CLOSE TRANSCRIPT
#===========================================================

transcript file ""