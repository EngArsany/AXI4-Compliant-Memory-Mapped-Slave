//=============================================================
// axi4_backdoor_base.sv
//TEST FILE ONLY
//=============================================================
package AXI_backdoor_pkg;
  virtual class axi4_backdoor_base;
    pure virtual function bit [31:0] read(bit [9:0] word_addr);
  endclass
endpackage
