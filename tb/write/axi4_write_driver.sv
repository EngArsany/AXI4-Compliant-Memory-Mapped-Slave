//=============================================================
// axi4_write_driver.sv
//
// AXI4 write master driver for one outstanding burst at a time.
//
// Timing rule used here:
//   - Drive payload/VALID on the falling edge.
//   - Observe READY/VALID handshakes on the following rising edge.
//
// This avoids the #1step clocking-block race that caused the original
// environment to leave WVALID asserted after the DUT had already
// entered W_RESP.
//=============================================================

class axi4_write_driver;

    virtual axi4_if.DRIVER vif;

    function new(virtual axi4_if.DRIVER vif);
        this.vif = vif;
    endfunction

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

    task automatic drive_one(axi4_write_txn txn);

        // =====================================================
        // AW CHANNEL
        // =====================================================
        @(negedge vif.ACLK);

        vif.AWADDR  = txn.awaddr;
        vif.AWLEN   = txn.awlen;
        vif.AWSIZE  = txn.awsize;
        vif.AWVALID = 1'b1;

        // Transfer occurs only when AWVALID && AWREADY are both high.
        do @(posedge vif.ACLK);
        while (!(vif.AWVALID && vif.AWREADY));

        @(negedge vif.ACLK);
        vif.AWVALID = 1'b0;

        // =====================================================
        // W CHANNEL
        // =====================================================
        // AXI burst has AWLEN+1 transfers, exactly as stated by the
        // project specification.
        for (int i = 0; i <= txn.awlen; i++) begin
            @(negedge vif.ACLK);

            vif.WDATA  = txn.wdata[i];
            vif.WLAST  = (i == txn.awlen);
            vif.WVALID = 1'b1;

            do @(posedge vif.ACLK);
            while (!(vif.WVALID && vif.WREADY));
        end

        @(negedge vif.ACLK);
        vif.WVALID = 1'b0;
        vif.WLAST  = 1'b0;

        // =====================================================
        // B CHANNEL
        // =====================================================
        @(negedge vif.ACLK);
        vif.BREADY = 1'b1;

        do @(posedge vif.ACLK);
        while (!(vif.BVALID && vif.BREADY));

        @(negedge vif.ACLK);
        vif.BREADY = 1'b0;

    endtask

endclass
