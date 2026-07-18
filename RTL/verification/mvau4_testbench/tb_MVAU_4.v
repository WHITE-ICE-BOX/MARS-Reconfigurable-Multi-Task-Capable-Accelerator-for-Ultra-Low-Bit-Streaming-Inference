`timescale 1ns / 1ps

module tb_MVAU_4;

    // ==========================================
    // 0. Test parameters (MVAU4: conv5 5x5->3x3, 10 samples)
    //    Per sample: 9 output pixels * (9 RF positions * 4 SIMD chunks) = 324
    //    Per sample: 9 output pixels * (256ch / PE=4)                   = 576
    // ==========================================
    parameter integer NUM_SAMPLES = 10;
    parameter integer INPUT_WORDS_PER_SAMPLE  = 324;
    parameter integer OUTPUT_WORDS_PER_SAMPLE = 576;
    
    parameter integer TOTAL_INPUT_WORDS  = NUM_SAMPLES * INPUT_WORDS_PER_SAMPLE;
    parameter integer TOTAL_OUTPUT_WORDS = NUM_SAMPLES * OUTPUT_WORDS_PER_SAMPLE;

    // ==========================================
    // 1. 全域時脈與重置
    // ==========================================
    reg ap_clk;
    reg ap_rst_n;

    // ==========================================
    // 2. AXI-Lite 介面 (用於啟動 wstrm_0)
    // ==========================================
    reg         awvalid = 0, wvalid = 0, arvalid = 0;
    reg  [31:0] awaddr  = 0, wdata  = 0, araddr = 0;
    reg  [2:0]  awprot  = 0, arprot = 0;
    reg  [3:0]  wstrb   = 0;
    reg         bready  = 1, rready = 1;
    wire        awready, wready, bvalid, arready, rvalid;
    wire [1:0]  bresp, rresp;
    wire [31:0] rdata;

    task axi_write(input [31:0] addr, input [31:0] data);
        begin
            awaddr = addr; awvalid = 1;
            wdata = data;  wvalid = 1; wstrb = 4'hF;
            @(posedge ap_clk);
            while (!awready || !wready) @(posedge ap_clk);
            awvalid = 0; wvalid = 0;
            while (!bvalid) @(posedge ap_clk);
            bready = 1; @(posedge ap_clk); bready = 0;
        end
    endtask

    // ==========================================
    // 3. 內部 AXI-Stream 連線宣告
    // ==========================================
    reg  [31:0]  tb_in_tdata;
    reg          tb_in_tvalid;
    wire         tb_in_tready;

    wire [31:0]  split_to_mvau_tdata;
    wire         split_to_mvau_tvalid;
    wire         split_to_mvau_tready;

    wire [31:0]  split_to_adapt_tdata;
    wire         split_to_adapt_tvalid;
    wire         split_to_adapt_tready;

    wire [127:0] internal_wstrm_tdata;
    wire         internal_wstrm_tvalid;
    wire         internal_wstrm_tready;

    wire [127:0] mvau_to_add_tdata;
    wire         mvau_to_add_tvalid;
    wire         mvau_to_add_tready;

    wire [31:0]  adapt_to_fifo_tdata;
    wire         adapt_to_fifo_tvalid;
    wire         adapt_to_fifo_tready;

    wire [31:0]  fifo_to_add_tdata;
    wire         fifo_to_add_tvalid;
    wire         fifo_to_add_tready;

    wire [7:0]   tb_out_tdata;
    wire         tb_out_tvalid;
    reg          tb_out_tready;

    // ==========================================
    // 4. 實例化所有模組
    // ==========================================
    Stream_Splitter_mvau4 #(.DATA_WIDTH(32)) splitter_inst (
        .aclk(ap_clk), .aresetn(ap_rst_n),
        .s_axis_tdata(tb_in_tdata), .s_axis_tvalid(tb_in_tvalid), .s_axis_tready(tb_in_tready),
        .m_axis_1_tdata(split_to_mvau_tdata), .m_axis_1_tvalid(split_to_mvau_tvalid), .m_axis_1_tready(split_to_mvau_tready),
        .m_axis_2_tdata(split_to_adapt_tdata), .m_axis_2_tvalid(split_to_adapt_tvalid), .m_axis_2_tready(split_to_adapt_tready)
    );

    StreamingDataflowPartition_1_StreamingDataflowPartition_1_MVAU_hls_4_wstrm_0 wstrm_inst (
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

    StreamingDataflowPartition_1_StreamingDataflowPartition_1_MVAU_hls_4_0 mvau_inst (
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

    Adapter_MVAU4 adapter_inst (
        .aclk(ap_clk), .aresetn(ap_rst_n),
        .s_axis_tdata(split_to_adapt_tdata),
        .s_axis_tvalid(split_to_adapt_tvalid),
        .s_axis_tready(split_to_adapt_tready),
        .m_axis_tdata(adapt_to_fifo_tdata),
        .m_axis_tvalid(adapt_to_fifo_tvalid),
        .m_axis_tready(adapt_to_fifo_tready)
    );

    Simple_FIFO_mvau4 #(.WIDTH(32), .DEPTH_LOG2(6)) fifo_inst (
        .clk(ap_clk), .rst_n(ap_rst_n),
        .s_axis_tdata(adapt_to_fifo_tdata), .s_axis_tvalid(adapt_to_fifo_tvalid), .s_axis_tready(adapt_to_fifo_tready),
        .m_axis_tdata(fifo_to_add_tdata), .m_axis_tvalid(fifo_to_add_tvalid), .m_axis_tready(fifo_to_add_tready)
    );

    Stream_Adder_Threshold_mvau4 adder_thresh_inst (
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
        // 請確保路徑正確
        $readmemh("golden_data/mvau4_in.dat", golden_in);
        $readmemh("golden_data/mvau4_expected.dat", golden_out);

        ap_rst_n      = 0;
        tb_in_tvalid  = 0;
        tb_in_tdata   = 0;
        tb_out_tready = 1;

        #100;
        ap_rst_n = 1;
        #50;

        // memstream auto-starts after reset, no AXI-Lite write needed
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

        // 等待剩餘資料消化
        #2000000;

        if (out_ptr < TOTAL_OUTPUT_WORDS) begin
            $display("---- Timeout: Not all outputs received! Expected: %0d, Received: %0d ----",
                     TOTAL_OUTPUT_WORDS, out_ptr);
            $finish;
        end
    end

    // ==========================================
    // 7. 輸出監控器 (Monitor) 與最終統計
    // ==========================================
    wire [5:0] step = out_ptr % 64; 

    always @(posedge ap_clk) begin
        if (tb_out_tvalid && tb_out_tready) begin
            
            // 只在有錯的時候印出詳細資訊，以免洗版
            if (tb_out_tdata[3:0] !== golden_out[out_ptr][3:0]) begin
                $display("❌ [錯誤] 全域序號: %0d | sample=%0d | ch=%0d~%0d | HW_out: %04b | SW_out: %04b",
                         out_ptr,
                         out_ptr / OUTPUT_WORDS_PER_SAMPLE,
                         step*4, step*4+3,
                         tb_out_tdata[3:0], golden_out[out_ptr][3:0]);
                err_cnt = err_cnt + 1;
            end
            else begin
                cor_cnt = cor_cnt + 1;
            end

            out_ptr = out_ptr + 1;

            // 當收集到所有資料後，印出最終的統計結果
            if (out_ptr == TOTAL_OUTPUT_WORDS) begin
                $display("\n========================================");
                $display("📊 最終測試統計結果");
                $display("========================================");
                $display("   總測試筆數 : %0d 筆", TOTAL_OUTPUT_WORDS);
                $display("   ✅ 正確數量: %0d 筆", cor_cnt);
                $display("   ❌ 錯誤數量: %0d 筆", err_cnt);
                $display("========================================");
                
                if (err_cnt == 0)
                    $display("🎉 PASS: 硬體輸出與預期完全吻合！");
                else
                    $display("⚠️ FAIL: 硬體輸出存在錯誤。");
                    
                $display("========================================");
                $finish;
            end
        end
    end

endmodule