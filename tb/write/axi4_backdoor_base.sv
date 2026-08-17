//=============================================================
// axi4_backdoor_base.sv
//
// Abstract base for backdoor DUT-memory access.
//
// Why this exists: this is a write-only environment (no read
// channel), so the scoreboard cannot verify what actually landed in
// memory by issuing an AXI read. Instead it reads the DUT's internal
// memory array directly ("backdoor" access) via a hierarchical
// reference. axi4_write_env only depends on this abstract interface;
// the concrete implementation (which knows the actual instance path,
// e.g. dut.mem_inst.memory) is provided by tb_top.sv. This keeps the
// environment reusable even if the DUT instance name/path changes.
//=============================================================
package AXI_backdoor_pkg;
  virtual class axi4_backdoor_base;
    pure virtual function bit [31:0] read(bit [9:0] word_addr);
  endclass
endpackage
