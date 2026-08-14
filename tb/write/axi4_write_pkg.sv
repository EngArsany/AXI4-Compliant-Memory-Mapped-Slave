//=============================================================
// axi4_write_pkg.sv
//
// Bundles all environment classes into one package. Order matters:
// each `include must come after the class(es) it depends on.
//=============================================================

package axi4_write_pkg;

    `include "axi4_write_txn.sv"        // no dependencies
    `include "axi4_backdoor_base.sv"    // no dependencies
    `include "axi4_golden_model.sv"     // uses axi4_write_txn
    `include "axi4_write_scoreboard.sv" // uses axi4_golden_model, axi4_write_txn
    `include "axi4_write_coverage.sv"   // uses axi4_write_txn
    `include "axi4_write_driver.sv"     // uses axi4_write_txn (needs the interface type too - see note below)
    `include "axi4_write_monitor.sv"    // uses axi4_write_txn
    `include "axi4_write_env.sv"        // uses everything above

endpackage

// NOTE on interface visibility: axi4_write_driver.sv and
// axi4_write_monitor.sv reference `virtual axi4_write_if.DRIVER` /
// `.MONITOR`. Interfaces are compiled at the $unit / global scope in
// SystemVerilog, not inside packages, so as long as axi4_write_if.sv
// is compiled (elaborated) anywhere in the same simulation - e.g.
// listed in your filelist before this package - the virtual interface
// type is visible here without an explicit import. This is standard
// practice for non-UVM SV testbenches; if you later port this to
// UVM, wrap the interface handles in `uvm_config_db` instead.
