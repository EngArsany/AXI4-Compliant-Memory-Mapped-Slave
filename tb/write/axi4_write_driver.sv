class axi4_write_driver;

  virtual axi4_if.DRIVER    vif;

  mailbox #(axi4_write_txn) gen2driver_mbx;
  mailbox #(int)            driver2gen_mbx;

  task automatic reset_signals();
    vif.AWADDR  = '0;
    vif.AWLEN   = '0;
    vif.AWSIZE  = '0;
    vif.AWVALID = 1'b0;

    vif.WDATA   = '0;
    vif.WLAST   = 1'b0;
    vif.WVALID  = 1'b0;

    vif.BREADY  = 1'b0;
  endtask

  task automatic run_driver();

    axi4_write_txn txn;

    reset_signals();

    forever begin

      // Wait for the next transaction from the generator.
      gen2driver_mbx.get(txn);

      // =================================================
      // WRITE ADDRESS CHANNEL
      // =================================================

      @(negedge vif.ACLK);

      vif.AWADDR  = txn.awaddr;
      vif.AWLEN   = txn.awlen;
      vif.AWSIZE  = txn.awsize;
      vif.AWVALID = 1'b1;

      // Hold AWVALID and payload until handshake.
      do begin
        @(posedge vif.ACLK);
      end while (!vif.AWREADY);

      @(negedge vif.ACLK);
      vif.AWVALID = 1'b0;

      // =================================================
      // WRITE DATA CHANNEL
      // =================================================

      for (int i = 0; i <= txn.awlen; i++) begin

        @(negedge vif.ACLK);

        vif.WDATA  = txn.wdata[i];
        vif.WLAST  = (i == txn.awlen);
        vif.WVALID = 1'b1;

        // Hold WVALID, WDATA and WLAST until handshake.
        do begin
          @(posedge vif.ACLK);
        end while (!vif.WREADY);
      end

      @(negedge vif.ACLK);

      vif.WVALID = 1'b0;
      vif.WLAST  = 1'b0;
      vif.WDATA  = '0;

      // =================================================
      // WRITE RESPONSE CHANNEL
      // =================================================

      @(negedge vif.ACLK);

      vif.BREADY = 1'b1;

      // Wait for BVALID/BREADY handshake.
      do begin
        @(posedge vif.ACLK);
      end while (!vif.BVALID);

      @(negedge vif.ACLK);

      vif.BREADY = 1'b0;

      // Tell generator that this transaction completed.
      if (driver2gen_mbx != null) driver2gen_mbx.put(1);

    end

  endtask

endclass
