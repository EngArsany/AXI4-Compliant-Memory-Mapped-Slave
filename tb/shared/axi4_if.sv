interface axi4_if #(
    parameter int ADDR_WIDTH = 16,
    parameter int DATA_WIDTH = 32
) (
    input bit ACLK,
    input bit ARESETn
);

  // ---------------- Write Address Channel ----------------
  logic [ADDR_WIDTH-1:0] AWADDR;
  logic [           7:0] AWLEN;
  logic [           2:0] AWSIZE;
  logic                  AWVALID;
  logic                  AWREADY;

  // ---------------- Write Data Channel -------------------
  logic [DATA_WIDTH-1:0] WDATA;
  logic                  WLAST;
  logic                  WVALID;
  logic                  WREADY;

  // ---------------- Write Response Channel ---------------
  logic [           1:0] BRESP;
  logic                  BVALID;
  logic                  BREADY;

  // ---------------- Read Address Channel -----------------
  logic [ADDR_WIDTH-1:0] ARADDR;
  logic [           7:0] ARLEN;
  logic [           2:0] ARSIZE;
  logic                  ARVALID;
  logic                  ARREADY;

  // ---------------- Read Data Channel --------------------
  logic [DATA_WIDTH-1:0] RDATA;
  logic [           1:0] RRESP;
  logic                  RVALID;
  logic                  RLAST;
  logic                  RREADY;


  // ========================================================
  // Driver modport
  // ========================================================

  modport DRIVER(
      input ACLK,
      input ARESETn,

      output AWADDR,
      output AWLEN,
      output AWSIZE,
      output AWVALID,
      input AWREADY,

      output WDATA,
      output WLAST,
      output WVALID,
      input WREADY,

      input BRESP,
      input BVALID,
      output BREADY,

      output ARADDR,
      output ARLEN,
      output ARSIZE,
      output ARVALID,
      input ARREADY,

      input RDATA,
      input RRESP,
      input RLAST,
      input RVALID,
      output RREADY
  );


  // ========================================================
  // Monitor modport
  // ========================================================

  modport MONITOR(
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
      input BREADY,

      input ARADDR,
      input ARLEN,
      input ARSIZE,
      input ARVALID,
      input ARREADY,

      input RDATA,
      input RRESP,
      input RLAST,
      input RVALID,
      input RREADY
  );


  // ========================================================
  // Response encodings
  // ========================================================

  localparam logic [1:0] RESP_OKAY = 2'b00;
  localparam logic [1:0] RESP_SLVERR = 2'b10;


  // ========================================================
  // Write assertions
  // ========================================================

  a_aw_payload_known :
  assert property (@(posedge ACLK) disable iff (!ARESETn) AWVALID && AWREADY |-> !$isunknown(
      {AWADDR, AWLEN, AWSIZE}
  ));


  a_aw_payload_stable :
  assert property (@(posedge ACLK) disable iff (!ARESETn)
            AWVALID && !AWREADY
            |=> AWVALID &&
                $stable(
      {AWADDR, AWLEN, AWSIZE}
  ));


  a_w_payload_known :
  assert property (@(posedge ACLK) disable iff (!ARESETn) WVALID && WREADY |-> !$isunknown(
      {WDATA, WLAST}
  ));


  a_w_payload_stable :
  assert property (@(posedge ACLK) disable iff (!ARESETn) WVALID && !WREADY |=> WVALID && $stable(
      {WDATA, WLAST}
  ));


  a_wlast_requires_wvalid :
  assert property (@(posedge ACLK) disable iff (!ARESETn) WLAST |-> WVALID);


  a_bresp_legal :
  assert property (@(posedge ACLK) disable iff (!ARESETn)
            BVALID |-> (BRESP inside {RESP_OKAY, RESP_SLVERR}));


  a_bresp_stable :
  assert property (@(posedge ACLK) disable iff (!ARESETn) BVALID && !BREADY |=> BVALID && $stable(
      BRESP
  ));


  // ========================================================
  // Read assertions
  // ========================================================

  a_ar_payload_known :
  assert property (@(posedge ACLK) disable iff (!ARESETn) ARVALID && ARREADY |-> !$isunknown(
      {ARADDR, ARLEN, ARSIZE}
  ));


  a_ar_payload_stable :
  assert property (@(posedge ACLK) disable iff (!ARESETn)
            ARVALID && !ARREADY
            |=> ARVALID &&
                $stable(
      {ARADDR, ARLEN, ARSIZE}
  ));


  a_r_payload_known :
  assert property (@(posedge ACLK) disable iff (!ARESETn) RVALID && RREADY |-> !$isunknown(
      {RDATA, RRESP, RLAST}
  ));


  a_r_payload_stable :
  assert property (@(posedge ACLK) disable iff (!ARESETn) RVALID && !RREADY |=> RVALID && $stable(
      {RDATA, RRESP, RLAST}
  ));


  a_rlast_requires_rvalid :
  assert property (@(posedge ACLK) disable iff (!ARESETn) RLAST |-> RVALID);


  a_rresp_legal :
  assert property (@(posedge ACLK) disable iff (!ARESETn)
            RVALID |-> (RRESP inside {RESP_OKAY, RESP_SLVERR}));


endinterface
