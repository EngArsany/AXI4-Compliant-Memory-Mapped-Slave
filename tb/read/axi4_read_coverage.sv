package AXI_read_coverage_pkg;

  // ==========================================================
  // READ COVERGROUP
  // ==========================================================
  covergroup cg_read with function sample (
      bit [15:0] araddr,
      bit [7:0] arlen,
      bit [2:0] arsize,
      bit valid_burst,
      bit [1:0] first_rresp,
      bit [31:0] first_rdata,
      bit rlast,
      int unsigned actual_beats
  );

    // ADDRESS REGION
    cp_addr_region: coverpoint araddr {
      bins region_0 = {[16'h0000 : 16'h00FF]};
      bins region_1 = {[16'h0100 : 16'h0EFF]};
      bins region_last = {[16'h0F00 : 16'h0FFF]};
      bins out_of_mem = {[16'h1000 : 16'hFFFF]};
    }

    // ADDRESS ALIGNMENT
    cp_alignment: coverpoint araddr[1:0] {
      bins aligned = {2'b00};
      bins unaligned_01 = {2'b01};
      bins unaligned_10 = {2'b10};
      bins unaligned_11 = {2'b11};
    }

    // BURST LENGTH
    cp_len: coverpoint arlen {
      bins one_beat = {8'd0};
      bins short_burst = {[8'd1 : 8'd7]};
      bins medium_burst = {[8'd8 : 8'd31]};
      bins long_burst = {[8'd32 : 8'd127]};
      bins extended_burst = {[8'd128 : 8'd253]};
      bins max_minus_one = {8'd254};
      bins max_burst = {8'd255};
    }

    // TRANSFER SIZE
    cp_size: coverpoint arsize {
      bins word_size = {3'd2}; illegal_bins wrong_read_size = default;
    }

    // BURST VALIDITY
    cp_validity: coverpoint valid_burst {
      bins valid_burst = {1'b1}; bins invalid_burst = {1'b0};
    }

    // READ RESPONSE – use illegal_bins for architecturally impossible codes
    cp_response: coverpoint first_rresp {
      bins okay_response = {2'b00};
      bins slverr_response = {2'b10};
      illegal_bins unreachable = {2'b01, 2'b11};
    }

    // READ DATA
    cp_data: coverpoint first_rdata {
      bins zero_data = {32'h0000_0000}; bins nonzero_data = default;
    }

    // RLAST – sampled per beat, so a single bit is fine
    cp_rlast: coverpoint rlast {
      bins rlast_asserted = {1'b1}; bins rlast_deasserted = {1'b0};
    }

    // ACTUAL NUMBER OF BEATS (per transaction)
    cp_beats: coverpoint actual_beats {
      bins one_beat_count = {1};
      bins short_beat_count = {[2 : 8]};
      bins medium_beat_count = {[9 : 32]};
      bins long_beat_count = {[33 : 128]};
      bins extended_beat_count = {[129 : 255]};
      bins maximum_beat_count = {256};
    }

    // ========================================================
    // CROSSES – with structural exclusions
    // ========================================================

    valid_x_len: cross cp_validity, cp_len;

    valid_x_addr: cross cp_validity, cp_addr_region{
      ignore_bins valid_out_of_mem =
        binsof(cp_validity.valid_burst) && binsof(cp_addr_region.out_of_mem);
    }

    valid_x_size: cross cp_validity, cp_size{
      ignore_bins valid_nonword = binsof (cp_validity.valid_burst) && !binsof (cp_size.word_size);
    }

    valid_x_resp: cross cp_validity, cp_response{
      ignore_bins valid_slverr =
        binsof(cp_validity.valid_burst) && binsof(cp_response.slverr_response);
    }

    valid_x_align: cross cp_validity, cp_alignment{
      // A valid AXI burst requires word‑aligned start addres
      ignore_bins valid_unaligned =
    binsof(cp_validity.valid_burst) && !binsof(cp_alignment.aligned);
    }

    size_x_resp: cross cp_size, cp_response{
      // Only 32‑bit (word) transfers can receive OKAY
      ignore_bins nonword_okay = !binsof (cp_size.word_size) && binsof (cp_response.okay_response);
    }

    len_x_resp: cross cp_len, cp_response;

  endgroup

  // ==========================================================
  // COVERAGE WRAPPER CLASS
  // ==========================================================
  class AXI_read_coverage;

    cg_read cov;

    function new();
      cov = new();
    endfunction

    function void sample_txn(bit [15:0] araddr, bit [7:0] arlen, bit [2:0] arsize, bit valid_burst,
                             bit [1:0] first_rresp, bit [31:0] first_rdata, bit rlast,
                             int unsigned actual_beats);
      cov.sample(araddr, arlen, arsize, valid_burst, first_rresp, first_rdata, rlast, actual_beats);
    endfunction

    function real get_coverage();
      return cov.get_coverage();
    endfunction

  endclass

endpackage
