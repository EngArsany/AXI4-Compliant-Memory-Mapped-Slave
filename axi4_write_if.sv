//=============================================================
// axi4_write_if.sv
//
// AXI4 write-channel interface used by the verification environment.
// The read-channel signals are present because the DUT has a combined
// AXI read/write port list; this project exercises the write side only.
//
// The project specification requires modports.  DRIVER and MONITOR
// are therefore kept and are used through virtual-interface handles.
//=============================================================

interface axi4_write_if #(
    parameter ADDR_WIDTH = 16,
    parameter DATA_WIDTH = 32
) (
    input bit ACLK,
    input bit ARESETn
);

    // ---------------- Write Address Channel ----------------
    logic [ADDR_WIDTH-1:0] AWADDR;
    logic [7:0]            AWLEN;
    logic [2:0]            AWSIZE;
    logic                  AWVALID;
    logic                  AWREADY;

    // ---------------- Write Data Channel -------------------
    logic [DATA_WIDTH-1:0] WDATA;
    logic                  WLAST;
    logic                  WVALID;
    logic                  WREADY;

    // ---------------- Write Response Channel ---------------
    logic [1:0]            BRESP;
    logic                  BVALID;
    logic                  BREADY;

    // ---------------- Read Channel -------------------------
    // Present only because the DUT includes the read interface.
    logic [ADDR_WIDTH-1:0] ARADDR;
    logic [7:0]            ARLEN;
    logic [2:0]            ARSIZE;
    logic                  ARVALID;
    logic                  ARREADY;
    logic [DATA_WIDTH-1:0] RDATA;
    logic [1:0]            RRESP;
    logic                  RVALID;
    logic                  RLAST;
    logic                  RREADY;

    // ========================================================
    // Modports required by the project specification.
    // ========================================================

    modport DRIVER (
        input  ACLK,
        input  ARESETn,

        output AWADDR,
        output AWLEN,
        output AWSIZE,
        output AWVALID,
        input  AWREADY,

        output WDATA,
        output WLAST,
        output WVALID,
        input  WREADY,

        input  BRESP,
        input  BVALID,
        output BREADY
    );

    modport MONITOR (
        input ACLK,
        input ARESETn,

        input AWADDR,
        input AWLEN,
        input AWSIZE,
        input AWVALID,
        input AWREADY,

        input WDATA,
        input WLAST,
        input WVALID,
        input WREADY,

        input BRESP,
        input BVALID,
        input BREADY
    );

    // ========================================================
    // Lightweight protocol assertions.
    // These assertions are deliberately based on handshakes that
    // occur in this write-only environment, so they are exercised by
    // every completed transaction rather than depending on random
    // back-pressure that this DUT does not generate.
    // ========================================================

    localparam logic [1:0] RESP_OKAY   = 2'b00;
    localparam logic [1:0] RESP_SLVERR = 2'b10;

    a_aw_payload_known:
        assert property (@(posedge ACLK) disable iff (!ARESETn)
            (AWVALID && AWREADY) |-> !$isunknown({AWADDR, AWLEN, AWSIZE}));

    a_w_payload_known:
        assert property (@(posedge ACLK) disable iff (!ARESETn)
            (WVALID && WREADY) |-> !$isunknown({WDATA, WLAST}));

    a_wlast_requires_wvalid:
        assert property (@(posedge ACLK) disable iff (!ARESETn)
            WLAST |-> WVALID);

    a_bresp_legal:
        assert property (@(posedge ACLK) disable iff (!ARESETn)
            BVALID |-> (BRESP inside {RESP_OKAY, RESP_SLVERR}));

endinterface
