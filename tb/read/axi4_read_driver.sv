package AXI_read_driver_pkg;
  import AXI_read_transaction_pkg::*;

  class AXI_read_driver;

    virtual axi4_write_if.DRIVER vif;

    mailbox #(AXI_read_transaction) gen2driver_mbx;
    mailbox #(int) driver2gen_mbx;


    task assert_signal(ref bit signal);
      @(negedge vif.ACLK);
      signal = 1;
    endtask

    task deassert_signal(ref bit signal);
      @(negedge vif.ACLK);
      signal = 0;
    endtask


    task run_driver();
      AXI_read_transaction txn;
      vif.ARSIZE = 3'd2;

      forever begin
        gen2driver_mbx.get(txn);

        @(negedge vif.ACLK);
        vif.ARADDR <= txn.araddr;
        vif.ARLEN  <= txn.arlen;
        vif.ARSIZE <= txn.arsize;

        // Perform handshake
        assert_signal(vif.ARVALID);
        do begin
          @(negedge vif.ACLK);
        end while (!vif.ARREADY);  // Wait until ARREADY is asserted
        deassert_signal(vif.ARVALID);

        // Receive Data
        assert_signal(vif.RREADY);  // Assert RREADY to start receiving data
        do begin
          @(negedge vif.ACLK);
        end while (!(vif.RVALID && vif.RLAST));  // Wait until ARREADY is asserted
        deassert_signal(vif.RREADY);

        driver2gen_mbx.put(1);  // got transaction

      end

    endtask

  endclass

endpackage
