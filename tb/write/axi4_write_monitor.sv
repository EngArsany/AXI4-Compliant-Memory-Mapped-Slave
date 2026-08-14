//=============================================================
// axi4_write_monitor.sv
//
// Passive B-channel monitor. It waits for the actual BVALID/BREADY
// handshake and records the DUT's BRESP into the transaction object.
//=============================================================

class axi4_write_monitor;

    virtual axi4_write_if.MONITOR vif;

    function new(virtual axi4_write_if.MONITOR vif);
        this.vif = vif;
    endfunction

    task automatic observe_one(axi4_write_txn txn);
        do @(posedge vif.ACLK);
        while (!(vif.BVALID && vif.BREADY));

        txn.act_bresp = vif.BRESP;
    endtask

endclass
