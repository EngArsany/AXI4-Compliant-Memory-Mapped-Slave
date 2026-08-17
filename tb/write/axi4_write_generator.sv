package AXI_write_generator_pkg;

  import AXI_write_transaction_pkg::*;


  class axi4_write_generator;

    // =========================================================
    // Mailboxes
    // =========================================================

    mailbox #(axi4_write_txn) gen2driver_mbx;
    mailbox #(int)            driver2gen_mbx;

    mailbox #(axi4_write_txn) gen2scb_mbx;
    mailbox #(int)            scb2gen_mbx;


    // =========================================================
    // Configuration
    // =========================================================

    int unsigned              num_of_txns        = 200;
    int unsigned              num_of_direct_txns = 30;

    bit                       done               = 0;


    // =========================================================
    // Directed test-case generation
    // =========================================================

    function bit generate_directed_test_cases(axi4_write_txn txn, int case_id);

      case (case_id)

        // -----------------------------------------------------
        // Valid word-sized writes
        // -----------------------------------------------------

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


        // -----------------------------------------------------
        // Near 4-KB boundary
        // -----------------------------------------------------

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


        // -----------------------------------------------------
        // Out-of-range addresses
        // -----------------------------------------------------

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


        // -----------------------------------------------------
        // Invalid AWSIZE
        // -----------------------------------------------------

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


        // -----------------------------------------------------
        // Unaligned word accesses
        // -----------------------------------------------------

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


        // -----------------------------------------------------
        // Additional valid bursts
        // -----------------------------------------------------

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


        // -----------------------------------------------------
        // Additional boundary cases
        // -----------------------------------------------------

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


        // -----------------------------------------------------
        // Additional out-of-range case
        // -----------------------------------------------------

        22:
        return txn.randomize() with {
          addr_mode == ADDR_OUT_OF_RANGE;
          awlen == 8'd31;
          awsize == 3'b010;
        };


        // -----------------------------------------------------
        // Additional invalid AWSIZE cases
        // -----------------------------------------------------

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


        // -----------------------------------------------------
        // More valid burst lengths
        // -----------------------------------------------------

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


    // =========================================================
    // Generate one transaction
    // =========================================================

    task generate_transaction(int case_id = -1);

      axi4_write_txn txn;
      int token;


      txn = new();


      if (case_id >= 0) begin

        if (!generate_directed_test_cases(txn, case_id)) begin

          $fatal(1, "[WRITE_GEN] Directed randomization failed for case %0d", case_id);

        end

      end else begin

        if (!txn.randomize()) begin

          $fatal(1, "[WRITE_GEN] Randomization failed.");

        end

      end


      // Send transaction to driver.
      gen2driver_mbx.put(txn);


      // Wait for driver to complete the transaction.
      $display("[WRITE_GEN] Waiting for driver completion");
      driver2gen_mbx.get(token);
      $display("[WRITE_GEN] Driver completed transaction");


      // Send the completed expected transaction to the
      // golden-model
      gen2scb_mbx.put(txn);


      // Wait until the scoreboard path consumes it.
      $display("[WRITE_GEN] Waiting for scoreboard");
      scb2gen_mbx.get(token);
      $display("[WRITE_GEN] Scoreboard completed transaction");

    endtask


    // =========================================================
    // Generate configured transaction sequence
    // =========================================================

    task run_generator();

      int unsigned directed_count;


      directed_count = (num_of_direct_txns < num_of_txns) ? num_of_direct_txns : num_of_txns;


      // Directed cases first.
      for (int i = 0; i < directed_count; i++) begin

        generate_transaction(i);

      end


      // Remaining transactions are constrained-random.
      for (int i = directed_count; i < num_of_txns; i++) begin

        generate_transaction();

      end


      done = 1;


      $display("[%0t][WRITE_GEN] Generator Finished, %0d transactions sent", $time, num_of_txns);

    endtask

  endclass

endpackage
