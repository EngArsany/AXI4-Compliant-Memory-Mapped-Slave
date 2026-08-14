package AXI_read_transaction_pkg;

  class AXI_read_transaction;
    rand bit areset_n;
    rand bit [15:0] araddr;
    rand bit [7:0] arlen;
    static bit [2:0] arsize = 2;  // 4 Bytes as specified
    bit arvalid;
    bit arready;

    bit [31:0] rdata;
    bit [1:0] rresp;
    bit rlast;
    bit rvalid;
    bit rready;

    rand addr_mode_e addr_mode;

    constraint reset_c {
      areset_n dist {
        1 :/ 95,
        0 :/ 5
      };
    }

    constraint addr_mode_c {
      addr_mode dist {
        ADDR_NORMAL        := 50,
        ADDR_NEAR_BOUNDARY := 30,
        ADDR_OUT_OF_RANGE  := 10,
        ADDR_UNALIGNED     := 10
      };
    }

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
        [256 : 4095] := 10,
        [4096 : 65535] := 10
      };
    }

    function new();

    endfunction





  endclass

endpackage
