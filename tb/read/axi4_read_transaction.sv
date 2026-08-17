package AXI_read_transaction_pkg;


  class AXI_read_transaction;

    rand bit [15:0] araddr;
    rand bit [ 7:0] arlen;
    rand bit [ 2:0] arsize;


    bit      [31:0] rdata  [$];
    bit      [ 1:0] rresp  [$];
    bit             rlast;


    localparam bit [2:0] WORD_SIZE = 3'b010;


    constraint c_arlen {

      arlen dist {
        8'd0             := 20,
        [ 8'd1 :   8'd7] := 40,
        [ 8'd8 :  8'd31] := 30,
        [8'd32 : 8'd255] := 10
      };

    }


    constraint c_arsize {arsize == WORD_SIZE;}


    constraint c_araddr {

      araddr dist {
        [16'h0000 : 16'h00FF] := 10,
        [16'h0100 : 16'h0EFF] := 10,
        [16'h0F00 : 16'h0FFF] := 10,
        [16'h1000 : 16'hFFFF] := 5
      };

    }


    // ========================================================
    // Burst validity
    // ========================================================

    function bit is_valid_burst();

      int unsigned num_beats;
      int unsigned bytes_per_beat;
      longint unsigned start_addr;
      longint unsigned total_bytes;
      longint unsigned final_byte_addr;


      num_beats       = int'(arlen) + 1;
      bytes_per_beat  = 1 << arsize;
      start_addr      = araddr;
      total_bytes     = num_beats * bytes_per_beat;
      final_byte_addr = start_addr + total_bytes - 1;


      if (arsize != WORD_SIZE) return 0;

      if (araddr[1:0] != 2'b00) return 0;

      if (start_addr >= 4096) return 0;

      if ((start_addr >> 12) != (final_byte_addr >> 12)) return 0;

      if ((final_byte_addr >> 2) >= 1024) return 0;

      return 1;

    endfunction


    // ========================================================
    // Expected number of R-channel transfers
    // ========================================================

    function int unsigned expected_r_beats();

      if (is_valid_burst()) return int'(arlen) + 1;

      return 1;

    endfunction


    function void display_info();

      $display("ARADDR = 0x%08h | ARLEN = %0d | ARSIZE = %0d", araddr, arlen, arsize);

      $display("RDATA  = %p", rdata);
      $display("RRESP  = %p", rresp);
      $display("RLAST  = %0b", rlast);

    endfunction

  endclass

endpackage
