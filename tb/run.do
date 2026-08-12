#===========================================================
# run.do — AXI4 write-channel verification
#===========================================================

quietly set PROJ_DIR "C:/Users/zyado/OneDrive/Desktop/Summer 2026/Hassan Khaled/AXI4_Project"

file mkdir "${PROJ_DIR}/sim_out"
transcript file "${PROJ_DIR}/sim_out/simulation.log"

vlib work
vmap work work

# Interface first, then package (which includes the classes).
vlog "${PROJ_DIR}/axi4_write_if.sv"
vlog "${PROJ_DIR}/axi4_write_pkg.sv"

# DUT with code coverage instrumentation.
vlog +cover=sbceft "${PROJ_DIR}/axi4_memory.v"
vlog +cover=sbceft "${PROJ_DIR}/axi4.v"

vlog "${PROJ_DIR}/tb_top.sv"

vopt +acc +cover=sbceft work.tb_top -o tb_top_opt

vsim -coverage -voptargs=+acc tb_top_opt

add wave *

run -all

# UCDB
coverage save -onexit -assert -directive -cvg -codeAll \
"${PROJ_DIR}/sim_out/axi4_write_coverage.ucdb"

# Overall coverage
coverage report -details \
-output "${PROJ_DIR}/sim_out/overall_coverage_report.txt"

# Functional coverage
coverage report -cvg -details \
-output "${PROJ_DIR}/sim_out/functional_coverage_report.txt"

# Assertion coverage
coverage report -assert -details \
-output "${PROJ_DIR}/sim_out/assertion_coverage_report.txt"

# Code coverage
coverage report -code s -details \
-output "${PROJ_DIR}/sim_out/statement_coverage_report.txt"

coverage report -code b -details \
-output "${PROJ_DIR}/sim_out/branch_coverage_report.txt"

coverage report -code c -details \
-output "${PROJ_DIR}/sim_out/condition_expression_coverage_report.txt"

coverage report -code e -details \
-output "${PROJ_DIR}/sim_out/toggle_enable_coverage_report.txt"

coverage report -code f -details \
-output "${PROJ_DIR}/sim_out/fsm_coverage_report.txt"

coverage report -code t -details \
-output "${PROJ_DIR}/sim_out/toggle_coverage_report.txt"

transcript file ""
