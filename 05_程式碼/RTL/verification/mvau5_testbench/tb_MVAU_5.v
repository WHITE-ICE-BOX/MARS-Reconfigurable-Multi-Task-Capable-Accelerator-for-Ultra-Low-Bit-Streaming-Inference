`timescale 1ns / 1ps

module tb_MVAU_5;

    // ==========================================
    // 0. 測試參數
    // ==========================================
    parameter integer NUM_SAMPLES = 10;
    parameter integer INPUT_WORDS_PER_SAMPLE  = 72;
    parameter integer OUTPUT_WORDS_PER_SAMPLE = 256;
    parameter integer TOTAL_INPUT_WORDS  = NUM_SAMPLES * INPUT_WORDS_PER_SAMPLE;
    parameter integer TOTAL_OUTPUT_WORDS = NUM_SAMPLES * OUTPUT_WORDS_PER_SAMPLE;

    // ==========================================
    // 1. 全域時脈與重置
    // ==========================================
    reg ap_clk;
    reg ap_rst_n;

    // ==========================================
    // 2. AXI-Lite 介面 (給 wstrm_0 用，全綁 0)
    // ==========================================
    reg         awvalid = 0, wvalid = 0, arvalid = 0;
    reg  [31:0] awaddr  = 0, wdata  = 0, araddr = 0;
    reg  [2:0]  awprot  = 0, arprot = 0;
    reg  [3:0]  wstrb   = 0;
    reg         bready  = 1, rready = 1;
    wire        awready, wready, bvalid, arready, rvalid;
    wire [1:0]  bresp, rresp;
    wire [31:0] rdata;

    // ==========================================
    // 3. 內部 AXI-Stream 連線宣告
    // ==========================================
    // Testbench -> Splitter
    reg  [31:0] tb_in_tdata;
    reg         tb_in_tvalid;
    wire        tb_in_tready;

    // Splitter -> MVAU
    wire [31:0] split_to_mvau_tdata;
    wire        split_to_mvau_tvalid;
    wire        split_to_mvau_tready;

    // Splitter -> Adapter
    wire [31:0] split_to_adapt_tdata;
    wire        split_to_adapt_tvalid;
    wire        split_to_adapt_tready;

    // wstrm_0 -> MVAU (權重)
    wire [31:0] internal_wstrm_tdata;
    wire        internal_wstrm_tvalid;
    wire        internal_wstrm_tready;

    // MVAU -> Adder
    wire [31:0] mvau_to_add_tdata;
    wire        mvau_to_add_tvalid;
    wire        mvau_to_add_tready;

    // Adapter -> FIFO
    wire [7:0]  adapt_to_fifo_tdata;
    wire        adapt_to_fifo_tvalid;
    wire        adapt_to_fifo_tready;

    // FIFO -> Adder
    wire [7:0]  fifo_to_add_tdata;
    wire        fifo_to_add_tvalid;
    wire        fifo_to_add_tready;

    // Adder -> Testbench
    wire [7:0]  tb_out_tdata;
    wire        tb_out_tvalid;
    reg         tb_out_tready;

    // ==========================================
    // 4. 實例化所有模組
    // ==========================================
    Stream_Splitter_mvau5 #(.DATA_WIDTH(32)) splitter_inst (
        .aclk(ap_clk), .aresetn(ap_rst_n),
        .s_axis_tdata(tb_in_tdata), .s_axis_tvalid(tb_in_tvalid), .s_axis_tready(tb_in_tready),
        .m_axis_1_tdata(split_to_mvau_tdata), .m_axis_1_tvalid(split_to_mvau_tvalid), .m_axis_1_tready(split_to_mvau_tready),
        .m_axis_2_tdata(split_to_adapt_tdata), .m_axis_2_tvalid(split_to_adapt_tvalid), .m_axis_2_tready(split_to_adapt_tready)
    );

    StreamingDataflowPartition_1_StreamingDataflowPartition_1_MVAU_hls_5_wstrm_0 wstrm_inst (
        .ap_clk(ap_clk), .ap_rst_n(ap_rst_n),
        .awready(awready), .awvalid(awvalid), .awprot(awprot), .awaddr(awaddr),
        .wready(wready), .wvalid(wvalid), .wdata(wdata), .wstrb(wstrb),
        .bready(bready), .bvalid(bvalid), .bresp(bresp),
        .arready(arready), .arvalid(arvalid), .arprot(arprot), .araddr(araddr),
        .rready(rready), .rvalid(rvalid), .rresp(rresp), .rdata(rdata),
        .m_axis_0_tvalid(internal_wstrm_tvalid),
        .m_axis_0_tready(internal_wstrm_tready),
        .m_axis_0_tdata(internal_wstrm_tdata)
    );

    StreamingDataflowPartition_1_StreamingDataflowPartition_1_MVAU_hls_5_0 mvau_inst (
        .ap_clk(ap_clk), .ap_rst_n(ap_rst_n),
        .in0_V_TVALID(split_to_mvau_tvalid),
        .in0_V_TREADY(split_to_mvau_tready),
        .in0_V_TDATA(split_to_mvau_tdata),
        .weights_V_TVALID(internal_wstrm_tvalid),
        .weights_V_TREADY(internal_wstrm_tready),
        .weights_V_TDATA(internal_wstrm_tdata),
        .out_V_TVALID(mvau_to_add_tvalid),
        .out_V_TREADY(mvau_to_add_tready),
        .out_V_TDATA(mvau_to_add_tdata)
    );

    Adapter_Generic adapter_inst (
        .aclk(ap_clk), .aresetn(ap_rst_n),
        .s_axis_tdata(split_to_adapt_tdata),
        .s_axis_tvalid(split_to_adapt_tvalid),
        .s_axis_tready(split_to_adapt_tready),
        .m_axis_tdata(adapt_to_fifo_tdata),
        .m_axis_tvalid(adapt_to_fifo_tvalid),
        .m_axis_tready(adapt_to_fifo_tready)
    );

    Simple_FIFO_mvau5 #(.WIDTH(8), .DEPTH_LOG2(6)) fifo_inst (
        .clk(ap_clk), .rst_n(ap_rst_n),
        .s_axis_tdata(adapt_to_fifo_tdata), .s_axis_tvalid(adapt_to_fifo_tvalid), .s_axis_tready(adapt_to_fifo_tready),
        .m_axis_tdata(fifo_to_add_tdata), .m_axis_tvalid(fifo_to_add_tvalid), .m_axis_tready(fifo_to_add_tready)
    );

    Stream_Adder_Threshold_mvau5 adder_thresh_inst (
        .aclk(ap_clk), .aresetn(ap_rst_n),
        .s_axis_1_tdata(mvau_to_add_tdata), .s_axis_1_tvalid(mvau_to_add_tvalid), .s_axis_1_tready(mvau_to_add_tready),
        .s_axis_2_tdata(fifo_to_add_tdata), .s_axis_2_tvalid(fifo_to_add_tvalid), .s_axis_2_tready(fifo_to_add_tready),
        .m_axis_tdata(tb_out_tdata), .m_axis_tvalid(tb_out_tvalid), .m_axis_tready(tb_out_tready)
    );

    // ==========================================
    // 5. 時脈與重置生成
    // ==========================================
    initial begin
        ap_clk = 0;
        forever #5 ap_clk = ~ap_clk; // 100MHz
    end

    // ==========================================
    // 6. 讀取測資與測試流程
    // ==========================================
    reg [31:0] golden_in  [0:TOTAL_INPUT_WORDS-1];
    reg [7:0]  golden_out [0:TOTAL_OUTPUT_WORDS-1];

    integer in_ptr  = 0;
    integer out_ptr = 0;
    integer err_cnt = 0;
    integer cor_cnt = 0;

    initial begin
        $readmemh("golden_data/mvau5_in.dat", golden_in);
        $readmemh("golden_data/mvau5_expected.dat", golden_out);

        ap_rst_n      = 0;
        tb_in_tvalid  = 0;
        tb_in_tdata   = 0;
        tb_out_tready = 1;

        #100;
        ap_rst_n = 1;
        #50;

        $display("---- System Reset Done. Starting Adapter Subsystem Data Feed ----");
        $display("---- NUM_SAMPLES = %0d ----", NUM_SAMPLES);
        $display("---- TOTAL_INPUT_WORDS = %0d ----", TOTAL_INPUT_WORDS);
        $display("---- TOTAL_OUTPUT_WORDS = %0d ----", TOTAL_OUTPUT_WORDS);

        tb_in_tvalid = 1;

        while (in_ptr < TOTAL_INPUT_WORDS) begin
            tb_in_tdata = golden_in[in_ptr];
            @(posedge ap_clk);
            if (tb_in_tvalid && tb_in_tready) begin
                in_ptr = in_ptr + 1;
            end
        end

        tb_in_tvalid = 0;
        tb_in_tdata  = 0;

        #20000000;
        if (out_ptr < TOTAL_OUTPUT_WORDS) begin
            $display("---- Timeout: Not all outputs received! Expected: %0d, Received: %0d ----",
                     TOTAL_OUTPUT_WORDS, out_ptr);
            $finish;
        end
    end

    // ==========================================
    // 7. 輸出監控器 (Monitor)
    // ==========================================
    always @(posedge ap_clk) begin
        if (tb_out_tvalid && tb_out_tready) begin
            $display("--------------------------------------------------");

            if (tb_out_tdata !== golden_out[out_ptr]) begin
                $display("❌ [錯誤] 全域序號: %0d | sample=%0d | ch=%0d | HW_out: %h | SW_out: %h",
                         out_ptr,
                         out_ptr / OUTPUT_WORDS_PER_SAMPLE,
                         out_ptr % OUTPUT_WORDS_PER_SAMPLE,
                         tb_out_tdata, golden_out[out_ptr]);
                err_cnt = err_cnt + 1;
            end
            else begin
                $display("o [正確] 全域序號: %0d | sample=%0d | ch=%0d | HW_out: %h | SW_out: %h",
                         out_ptr,
                         out_ptr / OUTPUT_WORDS_PER_SAMPLE,
                         out_ptr % OUTPUT_WORDS_PER_SAMPLE,
                         tb_out_tdata, golden_out[out_ptr]);
                cor_cnt = cor_cnt + 1;
            end

            // ======================================
            // Adder debug
            // ======================================
            $display("   [Adder_Debug]");
            $display("   -> ch_cnt                  : %0d", adder_thresh_inst.dbg_ch_cnt);
            $display("   -> MVAU value              : %0d", adder_thresh_inst.dbg_mvau_pop);
            $display("   -> Adapter popcount        : %0d", adder_thresh_inst.dbg_adp_pop);
            $display("   -> Adapter raw             : %0d", adder_thresh_inst.dbg_adp_raw);
            $display("   -> Adapter contribution    : %0d", adder_thresh_inst.dbg_adp_contribution);
            $display("   -> Total pop               : %0d", adder_thresh_inst.dbg_total_pop);
            $display("   -> Threshold               : %0d", adder_thresh_inst.dbg_threshold);
            $display("   -> Result bit              : %0d", adder_thresh_inst.dbg_result_bit);

            // ======================================
            // Adapter debug
            // 若你的 Adapter_Generic 沒有這些 dbg_*，就先保持註解
            // ======================================
            /*
            $display("   [Adapter_Debug]");
            $display("   -> dbg_cycle_cnt           : %0d", adapter_inst.dbg_cycle_cnt);
            $display("   -> dbg_out_index_cur       : %0d", adapter_inst.dbg_out_index_cur);
            $display("   -> dbg_popcount_cur        : %0d", adapter_inst.dbg_popcount_cur);
            $display("   -> dbg_dot64_cur           : %0d", adapter_inst.dbg_dot64_cur);
            $display("   -> dbg_hidden_act          : %h", adapter_inst.dbg_hidden_act);
            $display("   -> dbg_hidden_act_used     : %h", adapter_inst.dbg_hidden_act_used);
            $display("   -> dbg_up_word_used        : %h", adapter_inst.dbg_up_word_used);
            */

            $display("--------------------------------------------------");

            out_ptr = out_ptr + 1;

            if (out_ptr == TOTAL_OUTPUT_WORDS) begin
                $display("\n========================================");
                if (err_cnt == 0)
                    $display("PASS: Adapter + MVAU output matches golden data.");
                else begin
                    $display("FAIL: mismatch count = %0d", err_cnt);
                    $display("PASS count           = %0d", cor_cnt);
                end
                $display("========================================");
                $finish;
            end
        end
    end

endmodule