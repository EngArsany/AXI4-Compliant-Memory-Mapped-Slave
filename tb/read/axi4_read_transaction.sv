package AXI_read_transaction_pkg;

  class AXI_read_transaction;
    rand bit [15:0] araddr;
    rand bit [7:0] arlen;
    static bit [2:0] arsize = 2;  // 4 Bytes as specified

    bit [31:0] rdata[$];
    bit [1:0] rresp[$];
    bit rlast;

    int total_addresses = (arlen + 1) * arsize;

    constraint rlength_c {
      arlen dist {
        [  1 :  63] := 10,
        [ 64 : 127] := 10,
        [127 : 255] := 10
      };
      soft arlen != 0;  // Soft to be overridden later
    }

    constraint addr_c {
      araddr dist {
        [0 : 7] := 10,
        [8 : 255] := 10,
        [256 : 4095] := 10
      };

      araddr <= 4096 - total_addresses;  // To keep bounds in check
    }

    function void display_info();
      $display("ARADDR = 0x%08h | ARLEN = %0d | ARSIZE = %0d", araddr, arlen, arsize);
      $display("RDATA  = %p", rdata);
      $display("RRESP  = %p", rresp);

    endfunction

  endclass

endpackage
