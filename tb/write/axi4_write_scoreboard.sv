package AXI_write_scoreboard_pkg;

  import AXI_write_transaction_pkg::*;
   import AXI_write_coverage_pkg::*; 

  class axi4_write_scoreboard;

    // =========================================================
    // Expected transactions from the golden model
    // =========================================================

    mailbox #(axi4_write_txn) gm2scb_mbx;
    mailbox #(int)            scb2gm_mbx;


    // =========================================================
    // Actual transactions from the monitor
    // =========================================================

    mailbox #(axi4_write_txn) monitor2scb_mbx;
    mailbox #(int)            scb2monitor_mbx;
    mailbox #(int)            scb2gen_mbx;

    axi4_write_coverage        write_cov;      
    // =========================================================
    // Statistics
    // =========================================================

    int unsigned              num_checked;
    int unsigned              num_bresp_errors;


    // =========================================================
    // Constructor
    // =========================================================

    function new();

      num_checked      = 0;
      num_bresp_errors = 0;

    endfunction


    // =========================================================
    // Main scoreboard process
    // =========================================================

    task automatic run_scoreboard();

      axi4_write_txn expected_txn;
      axi4_write_txn actual_txn;

      forever begin

        // -----------------------------------------------------
        // Get the expected transaction from the golden model.
        // -----------------------------------------------------
        gm2scb_mbx.get(expected_txn);

        scb2gm_mbx.put(1);


        // -----------------------------------------------------
        // Get the actual transaction from the monitor.
        // -----------------------------------------------------
        monitor2scb_mbx.get(actual_txn);



        // -----------------------------------------------------
        // Compare expected vs actual.
        // -----------------------------------------------------

        check_transaction(expected_txn, actual_txn);
        scb2monitor_mbx.put(1);

        scb2gen_mbx.put(1);

      end

    endtask


    // =========================================================
    // Check complete write transaction
    // =========================================================

    task automatic check_transaction(axi4_write_txn expected_txn, axi4_write_txn actual_txn);

      num_checked++;

      check_bresp(expected_txn, actual_txn);
      write_cov.sample(expected_txn);          

    endtask


    // =========================================================
    // Check BRESP
    // =========================================================

    function automatic void check_bresp(axi4_write_txn expected_txn, axi4_write_txn actual_txn);

      if (actual_txn.act_bresp !== expected_txn.exp_bresp) begin

        num_bresp_errors++;

        $error("[WRITE_SCB] BRESP MISMATCH %s expected=%0b actual=%0b",
               expected_txn.convert2string(), expected_txn.exp_bresp, actual_txn.act_bresp);

      end else begin

        $display("[WRITE_SCB] BRESP OK %s bresp=%0b", expected_txn.convert2string(),
                 actual_txn.act_bresp);

      end

    endfunction


    // =========================================================
    // Final report
    // =========================================================

    function void report();

      $display("=================================================");
      $display("             WRITE SCOREBOARD SUMMARY");
      $display("=================================================");
      $display("Transactions checked : %0d", num_checked);
      $display("BRESP errors         : %0d", num_bresp_errors);
      $display("=================================================");


      if (num_bresp_errors != 0) begin

        $error("[WRITE_SCB] Verification failures detected.");

      end else begin

        $display("[WRITE_SCB] All checks passed.");

      end

    endfunction

  endclass

endpackage
