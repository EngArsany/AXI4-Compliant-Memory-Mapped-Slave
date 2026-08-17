package AXI_write_golden_model_pkg;

  import AXI_write_transaction_pkg::*;
  import AXI_reference_model_pkg::*;

  class axi4_golden_model;

    axi4_reference_model ref_model;

    function void set_reference_model(axi4_reference_model model);
      ref_model = model;
    endfunction

    function void predict(axi4_write_txn txn);

      if (ref_model == null) $fatal("[WRITE_GM] Reference model handle is null.");

      ref_model.apply_write(txn);

    endfunction


    function bit [31:0] get_expected(bit [15:0] word_addr);

      if (ref_model == null) $fatal("[WRITE_GM] Reference model handle is null.");

      return ref_model.get_expected_data(word_addr);

    endfunction

  endclass

endpackage
