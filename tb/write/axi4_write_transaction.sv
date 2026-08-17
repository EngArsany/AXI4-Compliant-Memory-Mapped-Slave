package AXI_write_transaction_pkg;

  typedef enum {
    ADDR_NORMAL,
    ADDR_NEAR_BOUNDARY,
    ADDR_OUT_OF_RANGE,
    ADDR_UNALIGNED
  } addr_mode_e;


  class axi4_write_txn;

    // =========================================================
    // AXI write address/control
    // =========================================================

    rand bit         [15:0] awaddr;
    rand bit         [ 7:0] awlen;
    rand bit         [ 2:0] awsize;
    rand addr_mode_e        addr_mode;


    // =========================================================
    // AXI write data
    // =========================================================

    bit              [31:0] wdata         [];


    // =========================================================
    // Expected / actual response
    // =========================================================

    bit              [ 1:0] exp_bresp;
    bit              [ 1:0] act_bresp;


    // =========================================================
    // Additional transaction information
    // =========================================================

    bit              [15:0] beat_word_addr[];
    bit                     beat_valid    [];


    // =========================================================
    // AXI burst length
    //
    // AWLEN = number_of_beats - 1
    // =========================================================

    constraint c_awlen {

      awlen dist {
        0          := 20,
        [ 1 :   7] := 40,
        [ 8 :  31] := 30,
        [32 : 255] := 10
      };

    }


    // =========================================================
    // Transfer size
    //
    // AWSIZE = 2 => 4 bytes/beat
    //
    // Other values are intentionally generated to exercise
    // illegal-transfer handling.
    // =========================================================

    constraint c_awsize {awsize == 3'b010;}


    // =========================================================
    // Address category
    // =========================================================

    constraint c_addr_mode {

      addr_mode dist {
        ADDR_NORMAL        := 50,
        ADDR_NEAR_BOUNDARY := 30,
        ADDR_OUT_OF_RANGE  := 10,
        ADDR_UNALIGNED     := 10
      };

    }


    // =========================================================
    // Address generation
    // =========================================================

    constraint c_awaddr {

      (addr_mode == ADDR_NORMAL) -> awaddr inside {[16'h0000 : 16'h0F00]};

      (addr_mode == ADDR_NEAR_BOUNDARY) -> awaddr inside {[16'h0FA0 : 16'h0FFC]};

      (addr_mode == ADDR_OUT_OF_RANGE) -> awaddr inside {[16'h1000 : 16'hFFFF]};

      (addr_mode != ADDR_UNALIGNED) -> awaddr[1:0] == 2'b00;

      (addr_mode == ADDR_UNALIGNED) -> awaddr[1:0] != 2'b00;

    }


    // =========================================================
    // Post-randomization
    // =========================================================

    function void post_randomize();

      wdata = new[awlen + 1];

      foreach (wdata[i]) wdata[i] = $urandom();


      exp_bresp = 2'b00;
      act_bresp = 2'b00;

    endfunction


    // =========================================================
    // Burst validity
    // =========================================================

    function bit is_valid_burst();

      longint unsigned num_beats;
      longint unsigned bytes_per_beat;
      longint unsigned total_bytes;
      longint unsigned start_address;
      longint unsigned final_byte_address;
      longint unsigned final_word_address;


      num_beats          = longint'(awlen) + 1;
      bytes_per_beat     = 64'(1) << awsize;
      total_bytes        = num_beats * bytes_per_beat;
      start_address      = awaddr;

      final_byte_address = start_address + total_bytes - 1;


      // This design supports only 32-bit transfers.
      if (awsize != 3'b010) return 0;


      // Word alignment is required.
      if (awaddr[1:0] != 2'b00) return 0;


      // Starting address must be inside the 4-KB memory.
      if (start_address >= 4096) return 0;


      // Burst must not cross a 4-KB boundary.
      if ((start_address >> 12) != (final_byte_address >> 12)) return 0;


      // Final accessed word must exist in the memory.
      final_word_address = final_byte_address >> 2;

      if (final_word_address >= 1024) return 0;


      return 1;

    endfunction


    // =========================================================
    // Number of expected write data beats
    // =========================================================

    function int unsigned expected_write_beats();

      return int'(awlen) + 1;

    endfunction


    // =========================================================
    // Debug information
    // =========================================================

    function string convert2string();

      return $sformatf("AWADDR=0x%0h AWLEN=%0d AWSIZE=%0d mode=%s", awaddr, awlen, awsize,
                       addr_mode.name());

    endfunction

  endclass

endpackage
