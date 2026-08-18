package AXI_reference_model_pkg;

  import AXI_write_transaction_pkg::*;
  import AXI_read_transaction_pkg::*;

  class axi4_reference_model;

    localparam int MEMORY_DEPTH = 1024;
    localparam bit [2:0] WORD_SIZE = 3'b010;
    localparam bit [1:0] OKAY = 2'b00;
    localparam bit [1:0] SLVERR = 2'b10;

    bit [31:0] expected_mem[MEMORY_DEPTH];

    function new();
      reset();
    endfunction

    function void reset();
      foreach (expected_mem[i]) expected_mem[i] = 32'h0000_0000;
    endfunction

    // ========================================================
    // Common AXI burst validity check
    // ========================================================
    function automatic bit is_valid_burst(bit [15:0] start_addr, bit [7:0] burst_len,
                                          bit [2:0] burst_size);
      longint unsigned num_beats;
      longint unsigned bytes_per_beat;
      longint unsigned total_bytes;
      longint unsigned start_address;
      longint unsigned final_byte_address;
      longint unsigned final_word_address;

      num_beats      = longint'(burst_len) + 1;
      bytes_per_beat = 64'(1) << burst_size;
      total_bytes    = num_beats * bytes_per_beat;
      start_address  = start_addr;

      // This design supports only 32-bit transfers.
      if (burst_size != WORD_SIZE) return 0;

      // The memory is word-addressable.
      if (start_addr[1:0] != 2'b00) return 0;

      // The first byte must be inside the 4-KB memory.
      if (start_address >= 4096) return 0;

      // AXI burst must not cross a 4-KB boundary.
      final_byte_address = start_address + total_bytes - 1;
      if ((start_address >> 12) != (final_byte_address >> 12)) return 0;

      // The final accessed word must exist in the memory.
      final_word_address = final_byte_address >> 2;
      if (final_word_address >= MEMORY_DEPTH) return 0;

      return 1;
    endfunction

    // ========================================================
    // Apply a write transaction to the expected memory
    // ========================================================
    function void apply_write(axi4_write_txn txn);
      bit burst_valid;
      int unsigned num_beats;

      txn.compute_beat_info();

      burst_valid = is_valid_burst(txn.awaddr, txn.awlen, txn.awsize);
      num_beats   = int'(txn.awlen) + 1;

      for (int i = 0; i < num_beats; i++) begin
        if (txn.beat_valid[i]) expected_mem[txn.beat_word_addr[i]] = txn.wdata[i];
      end

      txn.exp_bresp = burst_valid ? OKAY : SLVERR;
    endfunction

    // ========================================================
    // Predict a read transaction – now pushes RLAST per beat
    // ========================================================
    function void predict_read(AXI_read_transaction txn);
      int unsigned     num_beats;
      int unsigned     bytes_per_beat;
      bit              burst_valid;
      longint unsigned beat_addr;

      // Clear output queues
      txn.rdata.delete();
      txn.rresp.delete();
      txn.rlast.delete();

      num_beats      = int'(txn.arlen) + 1;
      bytes_per_beat = 1 << txn.arsize;

      burst_valid    = is_valid_burst(txn.araddr, txn.arlen, txn.arsize);

      // Invalid burst: single SLVERR beat
      if (!burst_valid) begin
        txn.rdata.push_back(32'h0000_0000);
        txn.rresp.push_back(SLVERR);
        txn.rlast.push_back(1'b1);
        return;
      end

      // Valid burst: one beat per transfer
      beat_addr = txn.araddr;
      for (int i = 0; i < num_beats; i++) begin
        txn.rdata.push_back(expected_mem[beat_addr>>2]);
        txn.rresp.push_back(OKAY);
        // RLAST is 1 on the last beat, 0 otherwise
        txn.rlast.push_back((i == num_beats - 1) ? 1'b1 : 1'b0);
        beat_addr += bytes_per_beat;
      end
    endfunction

    // ========================================================
    // Backdoor expected-memory access
    // ========================================================
    function bit [31:0] get_expected_data(bit [15:0] word_addr);
      if (word_addr < MEMORY_DEPTH) return expected_mem[word_addr];
      return 32'h0000_0000;
    endfunction

  endclass

endpackage
