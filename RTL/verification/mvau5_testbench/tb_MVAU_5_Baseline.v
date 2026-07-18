`timescale 1ns / 1ps

module tb_MVAU_5_Baseline;

    // ==========================================
    // 1. 全域時脈與重置
    // ==========================================
    reg ap_clk;
    reg ap_rst_n;

    // ==========================================
    // 2. AXI-Lite 介面 (給 wstrm_0 用，全綁 0)
    // ==========================================
    reg         awvalid = 0, wvalid = 0, arvalid = 0;
    reg  [31:0] awaddr = 0, wdata = 0, araddr = 0;
    reg  [2:0]  awprot = 0, arprot = 0;
    reg  [3:0]  wstrb = 0;
    reg         bready = 1, rready = 1;
    wire        awready, wready, bvalid, arready, rvalid;
    wire [1:0]  bresp, rresp;
    wire [31:0] rdata;

    // ==========================================
    // 3. 內部與外部 AXI-Stream 連線
    // ==========================================
    // wstrm_0 -> MVAU (權重)
    wire [31:0] internal_wstrm_tdata;
    wire        internal_wstrm_tvalid;
    wire        internal_wstrm_tready;

    // TB -> MVAU (輸入特徵圖)
    reg  [31:0] in0_V_TDATA;
    reg         in0_V_TVALID;
    wire        in0_V_TREADY;

    // MVAU -> TB (輸出結果，Baseline 是 8-bit)
    wire [7:0]  out_V_TDATA;
    wire        out_V_TVALID;
    reg         out_V_TREADY;

    // ==========================================
    // 4. 實例化模組
    // ==========================================
    // [A] 權重串流 (wstrm_0)
    StreamingDataflowPartition_1_StreamingDataflowPartition_1_MVAU_hls_5_wstrm_0 wstrm_inst (
        .ap_clk(ap_clk), .ap_rst_n(ap_rst_n),
        .awready(awready), .awvalid(awvalid), .awprot(awprot), .awaddr(awaddr),
        .wready(wready), .wvalid(wvalid), .wdata(wdata), .wstrb(wstrb),
        .bready(bready), .bvalid(bvalid), .bresp(bresp),
        .arready(arready), .arvalid(arvalid), .arprot(arprot), .araddr(araddr),
        .rready(rready), .rvalid(rvalid), .rresp(rresp), .rdata(rdata),
        .m_axis_0_tvalid(internal_wstrm_tvalid), .m_axis_0_tready(internal_wstrm_tready), .m_axis_0_tdata(internal_wstrm_tdata)
    );

    // [B] 神經網路核心 (原始 MVAU_5_0)
    StreamingDataflowPartition_1_StreamingDataflowPartition_1_MVAU_hls_5_0 mvau_inst (
        .ap_clk(ap_clk), .ap_rst_n(ap_rst_n),
        .in0_V_TVALID(in0_V_TVALID), .in0_V_TREADY(in0_V_TREADY), .in0_V_TDATA(in0_V_TDATA),
        .weights_V_TVALID(internal_wstrm_tvalid), .weights_V_TREADY(internal_wstrm_tready), .weights_V_TDATA(internal_wstrm_tdata),
        .out_V_TVALID(out_V_TVALID), .out_V_TREADY(out_V_TREADY), .out_V_TDATA(out_V_TDATA)
    );

    // ==========================================
    // 5. 時脈生成
    // ==========================================
    initial begin
        ap_clk = 0;
        forever #5 ap_clk = ~ap_clk; // 100MHz (10ns period)
    end

    // ==========================================
    // 6. 偷看 Threshold 的準備工作
    // ==========================================
    reg [10:0] thresh_rom [0:255];
    initial begin
        $readmemh("golden_data/StreamingDataflowPartition_1_MVAU_hls_5_Matrix_Vector_Activate_Stream_Batch_threshs_ROM_AUTO_1R.dat", thresh_rom);
    end

    // 追蹤當前的 Channel (從 0 到 255 循環)
    // 並且套用我們確認過 100% 正確的無號擴展
    wire [7:0] current_ch = out_ptr % 256;
    wire signed [31:0] current_threshold = $signed({21'd0, thresh_rom[current_ch]});

    // ==========================================
    // 7. 黃金測資讀取與測試流程
    // ==========================================
    // 宣告陣列存放測資
    reg [31:0] golden_in [0:2591];  // 36 windows * 9 pixels * 8 chunks = 2592
    reg [7:0]  golden_out [0:9215]; // 6 * 6 * 256 = 9216
    
    integer in_ptr = 0;
    integer out_ptr = 0;
    integer cor_cnt = 0;
    integer err_cnt = 0;

    initial begin
        // 讀取檔案
        $readmemh("golden_data/mvau5_baseline_in.dat", golden_in);
        $readmemh("golden_data/mvau5_baseline_expected.dat", golden_out);
        
        ap_rst_n = 0;
        in0_V_TVALID = 0;
        in0_V_TDATA = 0;
        out_V_TREADY = 1; 
        
        #100;
        ap_rst_n = 1;
        #50;
        
        $display("---- System Reset Done. Starting Baseline Data Feed ----");
        in0_V_TVALID = 1;
        
        // 灌入輸入資料
        while (in_ptr < 2592) begin
            in0_V_TDATA = golden_in[in_ptr];
            @(posedge ap_clk);
            if (in0_V_TVALID && in0_V_TREADY) begin
                in_ptr = in_ptr + 1;
            end
        end

        in0_V_TVALID = 0; // 關閉輸入
        
        // 等待剩餘資料消化
        #2000000;
        $display("---- Timeout: Not all outputs received! ----");
        $display("Expected: 9216, Received: %0d", out_ptr);
        $finish;
    end

    // ==========================================
    // 8. 輸出比對與驗證 (包含案發現場分析)
    // ==========================================
    always @(posedge ap_clk) begin
        if (out_V_TVALID && out_V_TREADY) begin
            // 即時比對
            if (out_V_TDATA !== golden_out[out_ptr]) begin
                $display("--------------------------------------------------");
                $display("❌ [錯誤] 序號: %0d (Channel: %0d)", out_ptr, current_ch);
                $display("   -> 硬體輸出: %h | 預期輸出: %h", out_V_TDATA, golden_out[out_ptr]);
                $display("   -> 該通道門檻 (Threshold): %0d", current_threshold);
                $display("--------------------------------------------------");
                err_cnt = err_cnt + 1;
            end
            else begin
                $display("--------------------------------------------------");
                $display("o [正確] 序號: %0d (Channel: %0d)", out_ptr, current_ch);
                $display("   -> 硬體輸出: %h | 預期輸出: %h", out_V_TDATA, golden_out[out_ptr]);
                $display("   -> 該通道門檻 (Threshold): %0d", current_threshold);
                $display("--------------------------------------------------");
                cor_cnt = cor_cnt + 1;
            end
            
            out_ptr = out_ptr + 1;
            
            // 當收到所有預期資料時，結束模擬 (這裡我維持你原本的 256)
            if (out_ptr == 256) begin
                $display("\n========================================");
                if (err_cnt == 0)
                    $display("🎉🎉🎉 驗證通過！Baseline 硬體與軟體 100%% 吻合！");
                else begin
                    $display("⚠️ 驗證失敗，共有 %0d 個錯誤。", err_cnt);
                    $display("⚠️ 驗證成功，共有 %0d 個正確。", cor_cnt);
                end
                $display("========================================");
                $finish;
            end
        end
    end

endmodule