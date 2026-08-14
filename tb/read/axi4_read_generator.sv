package AXI_read_generator_pkg;

  import AXI_read_transaction_pkg::*;

  class AXI_read_generator;

    mailbox #(AXI_read_transaction) gen2driver_mbx;
    mailbox #(int) driver2gen_mbx;

    mailbox #(AXI_read_transaction) gen2scb_mbx;
    mailbox #(int) scb2gen_mbx;

    int unsigned num_of_txns = 200;
    bit done = 0;

    task run_generator();
      AXI_read_transaction txn;
      int token;

      repeat (num_of_txns) begin
        txn = new();

        assert (txn.randomize())
        else $fatal("Generator Randomization Failed!");

        // Hand to driver
        gen2driver_mbx.put(txn);
        driver2gen_mbx.get(token);

        // Hand to scoreboard
        gen2scb_mbx.put(txn);
        scb2gen_mbx.get(token);
      end
      done = 1;
      $display("[%0t][GEN] Generator Finished, %0d transactions sent", $time, num_of_txns);
    endtask

  endclass

endpackage
