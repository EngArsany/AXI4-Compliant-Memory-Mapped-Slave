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


    function automatic bit is_valid_burst(bit [15:0] start_addr, bit [7:0] burst_len,
                                          bit [2:0] burst_size);

      int unsigned num_beats;
      int unsigned stride;
      int unsigned total_bytes;
      int unsigned last_byte_offset;

      num_beats = int'(burst_len) + 1;
      stride    = 1 << burst_size;

      // Only 32-bit transfers are supported.
      if (burst_size != WORD_SIZE) return 0;

      // Address must be word aligned.
      if (start_addr[1:0] != 2'b00) return 0;

      // Starting address must be inside the memory.
      if ((start_addr >> 2) >= MEMORY_DEPTH) return 0;

      total_bytes = num_beats * stride;

      // Check whether the burst crosses a 4-KB boundary.
      last_byte_offset = int'({1'b0, start_addr[11:0]}) + total_bytes - 1;

      if (last_byte_offset > 12'hFFF) return 0;

      // Check the final accessed word.
      if (((start_addr + ((num_beats - 1) * stride)) >> 2) >= MEMORY_DEPTH) return 0;

      return 1;

    endfunction


    function void apply_write(axi4_write_txn txn);

      int unsigned        num_beats;
      int unsigned        stride;
      bit                 burst_valid;
      bit          [15:0] beat_addr;

      num_beats          = int'(txn.awlen) + 1;
      stride             = 1 << txn.awsize;

      burst_valid        = is_valid_burst(txn.awaddr, txn.awlen, txn.awsize);

      txn.beat_word_addr = new[num_beats];
      txn.beat_valid     = new[num_beats];

      beat_addr          = txn.awaddr;

      for (int i = 0; i < num_beats; i++) begin

        txn.beat_word_addr[i] = beat_addr >> 2;

        txn.beat_valid[i] = burst_valid;

        if (burst_valid) begin
          expected_mem[beat_addr>>2] = txn.wdata[i];
        end

        beat_addr = beat_addr + stride;

      end

      txn.exp_bresp = burst_valid ? OKAY : SLVERR;

    endfunction


    function void predict_read(AXI_read_transaction txn);

      int unsigned        num_beats;
      int unsigned        stride;
      bit                 burst_valid;
      bit          [15:0] beat_addr;

      txn.rdata.delete();
      txn.rresp.delete();

      num_beats = int'(txn.arlen) + 1;
      stride    = 1 << txn.arsize;

      burst_valid = is_valid_burst(
          txn.araddr,
          txn.arlen,
          txn.arsize
      );

      if (!burst_valid) begin

        txn.rdata.push_back(32'h0000_0000);
        txn.rresp.push_back(SLVERR);
        txn.rlast = 1'b1;

        return;

      end

      beat_addr = txn.araddr;

      for (int i = 0; i < num_beats; i++) begin

        txn.rdata.push_back(expected_mem[beat_addr>>2]);

        txn.rresp.push_back(OKAY);

        beat_addr = beat_addr + stride;

      end

      txn.rlast = 1'b1;

    endfunction


    function bit [31:0] get_expected_data(bit [15:0] word_addr);

      if (word_addr < MEMORY_DEPTH) return expected_mem[word_addr];

      return 32'h0000_0000;

    endfunction

  endclass

endpackage
