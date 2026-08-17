package AXI_write_coverage_pkg;

  import AXI_write_transaction_pkg::*;

  class axi4_write_coverage;

    axi4_write_txn txn;

    int beat_index;
    int beat_total;
    bit beat_is_first;
    bit beat_is_last;
    bit beat_valid_bit;
    bit [15:0] beat_addr;

    covergroup cg_write;
      option.per_instance = 1;

      cp_awlen: coverpoint txn.awlen {
        bins single_beat = {0};
        bins short_burst = {[1 : 15]};
        bins long_burst = {[16 : 254]};
        bins max_burst = {255};
      }

      cp_awsize: coverpoint txn.awsize {
        bins word_size = {3'b010}; illegal_bins wrong_write_size = !binsof (word_size);
      }

      cp_addr_mode: coverpoint txn.addr_mode {
        bins normal = {ADDR_NORMAL};
        bins near_boundary = {ADDR_NEAR_BOUNDARY};
        bins out_of_range = {ADDR_OUT_OF_RANGE};
        bins unaligned = {ADDR_UNALIGNED};
      }

      cp_aligned: coverpoint txn.awaddr[1:0] {
        bins aligned = {2'b00}; bins unaligned = {[2'b01 : 2'b11]};
      }

      cp_start_region: coverpoint (txn.awaddr >> 8) {
        bins low = {[0 : 7]}; bins mid = {[8 : 14]}; bins near_edge = {15}; bins beyond = default;
      }

      cp_bresp: coverpoint txn.exp_bresp {
        bins okay = {2'b00}; bins slverr = {2'b10}; illegal_bins unreachable = {2'b01, 2'b11};
      }

      cx_len_bresp: cross cp_awlen, cp_bresp;

      cx_size_addr: cross cp_awsize, cp_addr_mode;

      cx_mode_bresp: cross cp_addr_mode, cp_bresp{
        // An address already outside the 4 KB memory cannot be OKAY.
        ignore_bins out_of_range_okay =
                binsof(cp_addr_mode.out_of_range)
                && binsof(cp_bresp.okay);
        ignore_bins unaligned_okay = binsof (cp_addr_mode.unaligned) && binsof (cp_bresp.okay);
      }

      cx_size_bresp: cross cp_awsize, cp_bresp{
        // Non-word AWSIZE is rejected by this 32-bit/no-WSTRB design.
        ignore_bins subword_okay = binsof (cp_awsize.sub_word_size) && binsof (cp_bresp.okay);

        ignore_bins oversize_okay = binsof (cp_awsize.oversize) && binsof (cp_bresp.okay);
      }

    endgroup

    covergroup cg_beat;
      option.per_instance = 1;

      cp_beat_valid: coverpoint beat_valid_bit {bins invalid = {0}; bins valid = {1};}

      cp_beat_position: coverpoint {
        beat_is_first, beat_is_last
      } {
        bins only_beat = {2'b11};
        bins first_only = {2'b10};
        bins last_only = {2'b01};
        bins middle = {2'b00};
      }

      cp_beat_addr_region: coverpoint beat_addr {
        bins low = {[0 : 255]};
        bins mid = {[256 : 767]};
        bins high = {[768 : 1023]};
        bins oob = default;
      }

      cx_valid_position: cross cp_beat_valid, cp_beat_position;
    endgroup

    function new();
      cg_write = new();
      cg_beat  = new();
    endfunction

    function void sample (axi4_write_txn t);
      txn = t;
      cg_write.sample();

      beat_total = t.beat_valid.size();
      for (int i = 0; i < beat_total; i++) begin
        beat_index     = i;
        beat_is_first  = (i == 0);
        beat_is_last   = (i == beat_total - 1);
        beat_valid_bit = t.beat_valid[i];
        beat_addr      = t.beat_word_addr[i];
        cg_beat.sample();
      end
    endfunction

    function real get_coverage();
      return (cg_write.get_coverage() + cg_beat.get_coverage()) / 2.0;
    endfunction

    function real get_burst_coverage();
      return cg_write.get_coverage();
    endfunction

    function real get_beat_coverage();
      return cg_beat.get_coverage();
    endfunction

  endclass
endpackage
