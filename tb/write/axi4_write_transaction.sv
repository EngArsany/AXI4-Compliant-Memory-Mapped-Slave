package AXI_write_transaction_pkg;

  typedef enum {
    ADDR_NORMAL,
    ADDR_NEAR_BOUNDARY,
    ADDR_OUT_OF_RANGE,
    ADDR_UNALIGNED
  } addr_mode_e;

  class axi4_write_txn;

    rand bit         [15:0] awaddr;
    rand bit         [ 7:0] awlen;
    rand bit         [ 2:0] awsize;
    rand addr_mode_e        addr_mode;

    bit              [31:0] wdata         [];

    bit              [ 1:0] exp_bresp;
    bit              [15:0] beat_word_addr[];
    bit                     beat_valid    [];

    bit              [ 1:0] act_bresp;

    // AWLEN+1 transfers, as specified by the project document.
    constraint c_awlen {
      awlen dist {
        0          := 20,
        [ 1 :   7] := 40,
        [ 8 :  31] := 30,
        [32 : 255] := 10
      };
    }

    // 32-bit data path: AWSIZE=2 is the supported transfer size.
    // Other sizes are intentionally generated as illegal/error cases
    // so the testbench covers the design's documented handling.
    constraint c_awsize {
      awsize dist {
        3'b010            := 70,
        3'b000            := 10,
        3'b001            := 10,
        [3'b011 : 3'b111] := 10
      };
    }

    constraint c_addr_mode {
      addr_mode dist {
        ADDR_NORMAL        := 50,
        ADDR_NEAR_BOUNDARY := 30,
        ADDR_OUT_OF_RANGE  := 10,
        ADDR_UNALIGNED     := 10
      };
    }

    constraint c_awaddr {
      (addr_mode == ADDR_NORMAL) -> awaddr inside {[16'h0000 : 16'h0F00]};

      (addr_mode == ADDR_NEAR_BOUNDARY) -> awaddr inside {[16'h0FA0 : 16'h0FFC]};

      (addr_mode == ADDR_OUT_OF_RANGE) -> awaddr inside {[16'h1000 : 16'hFFFF]};

      (addr_mode != ADDR_UNALIGNED) -> awaddr[1:0] == 2'b00;

      (addr_mode == ADDR_UNALIGNED) -> awaddr[1:0] != 2'b00;
    }

    function void post_randomize();
      wdata = new[awlen + 1];
      foreach (wdata[i]) wdata[i] = $urandom();

      act_bresp = 2'b00;
    endfunction

    function string convert2string();
      return $sformatf("AWADDR=0x%0h AWLEN=%0d AWSIZE=%0d mode=%s", awaddr, awlen, awsize,
                       addr_mode.name());
    endfunction

  endclass
endpackage
