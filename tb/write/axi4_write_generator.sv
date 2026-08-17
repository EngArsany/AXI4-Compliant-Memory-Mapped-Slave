//=============================================================
// axi4_write_monitor.sv
//
// Passive B-channel monitor. It waits for the actual BVALID/BREADY
// handshake and records the DUT's BRESP into the transaction object.
//=============================================================



class axi4_write_generator;

  function bit randomize_for_coverage_plan(axi4_write_txn txn, int case_id);

    case (case_id)

      //=================================================
      // Valid word-sized writes
      //=================================================

      0:
      return txn.randomize() with {
        addr_mode == ADDR_NORMAL;
        awlen == 8'd0;
        awsize == 3'b010;
      };

      1:
      return txn.randomize() with {
        addr_mode == ADDR_NORMAL;
        awlen == 8'd1;
        awsize == 3'b010;
      };

      2:
      return txn.randomize() with {
        addr_mode == ADDR_NORMAL;
        awlen == 8'd7;
        awsize == 3'b010;
      };

      3:
      return txn.randomize() with {
        addr_mode == ADDR_NORMAL;
        awlen == 8'd31;
        awsize == 3'b010;
      };

      4:
      return txn.randomize() with {
        addr_mode == ADDR_NORMAL;
        awlen == 8'd255;
        awsize == 3'b010;
      };


      //=================================================
      // Near 4-KB boundary
      //=================================================

      5:
      return txn.randomize() with {
        addr_mode == ADDR_NEAR_BOUNDARY;
        awlen == 8'd0;
        awsize == 3'b010;
      };

      6:
      return txn.randomize() with {
        addr_mode == ADDR_NEAR_BOUNDARY;
        awlen == 8'd1;
        awsize == 3'b010;
      };

      7:
      return txn.randomize() with {
        addr_mode == ADDR_NEAR_BOUNDARY;
        awlen == 8'd7;
        awsize == 3'b010;
      };


      //=================================================
      // Out-of-range addresses
      //=================================================

      8:
      return txn.randomize() with {
        addr_mode == ADDR_OUT_OF_RANGE;
        awlen == 8'd0;
        awsize == 3'b010;
      };

      9:
      return txn.randomize() with {
        addr_mode == ADDR_OUT_OF_RANGE;
        awlen == 8'd1;
        awsize == 3'b010;
      };

      10:
      return txn.randomize() with {
        addr_mode == ADDR_OUT_OF_RANGE;
        awlen == 8'd7;
        awsize == 3'b010;
      };


      //=================================================
      // Invalid AWSIZE
      //=================================================

      11:
      return txn.randomize() with {
        addr_mode == ADDR_NORMAL;
        awlen == 8'd0;
        awsize == 3'b000;
      };

      12:
      return txn.randomize() with {
        addr_mode == ADDR_NORMAL;
        awlen == 8'd1;
        awsize == 3'b001;
      };

      13:
      return txn.randomize() with {
        addr_mode == ADDR_NORMAL;
        awlen == 8'd7;
        awsize == 3'b011;
      };

      14:
      return txn.randomize() with {
        addr_mode == ADDR_NORMAL;
        awlen == 8'd31;
        awsize == 3'b111;
      };


      //=================================================
      // Unaligned word accesses
      //=================================================

      15:
      return txn.randomize() with {
        addr_mode == ADDR_UNALIGNED;
        awlen == 8'd0;
        awsize == 3'b010;
      };

      16:
      return txn.randomize() with {
        addr_mode == ADDR_UNALIGNED;
        awlen == 8'd1;
        awsize == 3'b010;
      };

      17:
      return txn.randomize() with {
        addr_mode == ADDR_UNALIGNED;
        awlen == 8'd7;
        awsize == 3'b010;
      };


      //=================================================
      // Additional valid word bursts
      //=================================================

      18:
      return txn.randomize() with {
        addr_mode == ADDR_NORMAL;
        awlen == 8'd2;
        awsize == 3'b010;
      };

      19:
      return txn.randomize() with {
        addr_mode == ADDR_NORMAL;
        awlen == 8'd15;
        awsize == 3'b010;
      };


      //=================================================
      // Additional near-boundary cases
      //=================================================

      20:
      return txn.randomize() with {
        addr_mode == ADDR_NEAR_BOUNDARY;
        awlen == 8'd2;
        awsize == 3'b010;
      };

      21:
      return txn.randomize() with {
        addr_mode == ADDR_NEAR_BOUNDARY;
        awlen == 8'd15;
        awsize == 3'b010;
      };


      //=================================================
      // Additional out-of-range case
      //=================================================

      22:
      return txn.randomize() with {
        addr_mode == ADDR_OUT_OF_RANGE;
        awlen == 8'd31;
        awsize == 3'b010;
      };


      //=================================================
      // Additional invalid AWSIZE cases
      //=================================================

      23:
      return txn.randomize() with {
        addr_mode == ADDR_NORMAL;
        awlen == 8'd0;
        awsize == 3'b000;
      };

      24:
      return txn.randomize() with {
        addr_mode == ADDR_NORMAL;
        awlen == 8'd0;
        awsize == 3'b001;
      };

      25:
      return txn.randomize() with {
        addr_mode == ADDR_NORMAL;
        awlen == 8'd0;
        awsize == 3'b011;
      };

      26:
      return txn.randomize() with {
        addr_mode == ADDR_NORMAL;
        awlen == 8'd0;
        awsize == 3'b100;
      };


      //=================================================
      // More valid word burst lengths
      //=================================================

      27:
      return txn.randomize() with {
        addr_mode == ADDR_NORMAL;
        awlen == 8'd3;
        awsize == 3'b010;
      };

      28:
      return txn.randomize() with {
        addr_mode == ADDR_NORMAL;
        awlen == 8'd63;
        awsize == 3'b010;
      };

      29:
      return txn.randomize() with {
        addr_mode == ADDR_NORMAL;
        awlen == 8'd127;
        awsize == 3'b010;
      };


      default: return txn.randomize();

    endcase

  endfunction

  task run_generator();
    txn = new();

    if (n < COVERAGE_PLAN_COUNT) begin

      if (!randomize_for_coverage_plan(txn, n)) begin

        $fatal(1, "[ENV] Coverage-plan randomization failed on txn %0d", n);

      end

    end else begin

      if (!txn.randomize()) begin

        $fatal(1, "[ENV] Randomization failed on txn %0d", n);

      end

    end

  endtask
endclass
