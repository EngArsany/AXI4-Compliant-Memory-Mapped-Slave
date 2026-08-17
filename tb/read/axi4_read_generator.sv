package AXI_read_generator_pkg;

  import AXI_read_transaction_pkg::*;

  class AXI_read_generator;

    // Mailboxes
    mailbox #(AXI_read_transaction) gen2driver_mbx;
    mailbox #(int)                  driver2gen_mbx;

    mailbox #(AXI_read_transaction) gen2scb_mbx;
    mailbox #(int)                  scb2gen_mbx;


    // Configuration
    int unsigned                    num_of_txns     = 200;
    bit                             done            = 0;


    task generate_transaction();

      AXI_read_transaction txn;
      int token;

      txn = new();
      assert (txn.randomize())
      else $fatal(1, "[READ_GEN] Randomization failed.");

      gen2driver_mbx.put(txn);
      driver2gen_mbx.get(token);

      gen2scb_mbx.put(txn);
      scb2gen_mbx.get(token);

    endtask


    task run_generator();

      for (int i = 0; i < num_of_txns; i++) begin

        generate_transaction();

      end

      done = 1;
      $display("[%0t][READ_GEN] Generator Finished, %0d transactions sent", $time, num_of_txns);
    endtask

  endclass

endpackage
