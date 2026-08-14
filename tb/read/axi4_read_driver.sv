package AXI_read_driver_pkg;
  import AXI_read_transaction_pkg::*;

  class AXI_read_driver;

    virtual axi4_write_if.DRIVER vif;

    mailbox #(AXI_read_transaction) gen2driver_mbx;
    mailbox #(int) driver2gen_mbx;

    task run_driver;
      AXI_read_transaction tx;

      forever begin
        gen2driver_mbx.get(txn);

        @(negedge vif.ACLK);
        vif.ARADDR  = txn.araddr;
        vif.ARESETn = txn.areset_n;
        vif.ARLEN   = txn.arlen;
        vif.ARSIZE  = txn.arsize;
        vif.ARVALID = txn.arvalid;
        vif.ARREADY = txn.arready;
        vif.RDATA   = txn.rdata;
        vif.RRESP   = txn.rresp;
        vif.RLAST   = txn.rlast;
        vif.RVALID  = txn.rvalid;
        vif.RREADY  = txn.rready;


        driver2gen_mbx.put(1);  // got transaction

      end

    endtask

  endclass
  
endpackage
