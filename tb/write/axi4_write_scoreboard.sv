package AXI_write_scoreboard_pkg;

  import AXI_write_transaction_pkg::*;
  import AXI_backdoor_pkg::*;

  class axi4_write_scoreboard;

    // Expected transactions produced by the golden model.
    mailbox #(axi4_write_txn) gm2scb_mbx;
    mailbox #(int) scb2gm_mbx;

    // Actual transactions produced by the write monitor.
    mailbox #(axi4_write_txn) monitor2scb_mbx;
    mailbox #(int) scb2monitor_mbx;

    mailbox #(axi4_write_txn) gen2scb_mbx;
    mailbox #(int) scb2gen_mbx;

    // Backdoor access to DUT memory.
    axi4_backdoor_base bd;

    int unsigned num_checked;
    int unsigned num_bresp_errors;
    int unsigned num_data_errors;
    int token;

    function new();
      num_checked      = 0;
      num_bresp_errors = 0;
      num_data_errors  = 0;

    endfunction


    task automatic run_scoreboard();

      axi4_write_txn expected_txn;
      axi4_write_txn actual_txn;

      forever begin

        // Only one write burst is outstanding, so the order
        // of expected and actual transactions is identical.
        gm2scb_mbx.get(expected_txn);
        scb2gm_mbx.put(token);

        monitor2scb_mbx.get(actual_txn);
        scb2monitor_mbx.put(token);

        check_transaction(expected_txn, actual_txn);

      end

    endtask


    task automatic check_transaction(axi4_write_txn expected_txn, axi4_write_txn actual_txn);

      num_checked++;

      check_bresp(expected_txn, actual_txn);
      check_memory(expected_txn);

    endtask


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


    function automatic void check_memory(axi4_write_txn txn);

      bit [31:0] actual_data;
      bit [31:0] expected_data;

      for (int i = 0; i < txn.wdata.size(); i++) begin

        // Invalid beats must not modify memory, so there is
        // nothing to check here yet. The golden model already
        // defines which beats are expected to be written.
        if (!txn.beat_valid[i]) continue;

        actual_data   = bd.read(txn.beat_word_addr[i]);
        expected_data = txn.wdata[i];

        if (actual_data !== expected_data) begin

          num_data_errors++;

          $error(
              "[WRITE_SCB] DATA MISMATCH %s beat=%0d " + "addr=0x%0h expected=0x%0h actual=0x%0h",
              txn.convert2string(), i, txn.beat_word_addr[i], expected_data, actual_data);

        end

      end

    endfunction


    function void report();

      $display("=================================================");
      $display("             WRITE SCOREBOARD SUMMARY");
      $display("=================================================");
      $display("Transactions checked : %0d", num_checked);
      $display("BRESP errors         : %0d", num_bresp_errors);
      $display("Data errors          : %0d", num_data_errors);
      $display("=================================================");

      if ((num_bresp_errors != 0) || (num_data_errors != 0)) begin

        $error("[WRITE_SCB] Verification failures detected.");

      end else begin

        $display("[WRITE_SCB] All checks passed.");

      end

    endfunction

  endclass
endpackage
