`timescale 1ns / 1ps

module tb_MVAU_2_Baseline;

    parameter MAX_IN_WORDS  = 200000; 
    parameter MAX_OUT_WORDS = 200000;

    reg ap_clk;
    reg ap_rst_n;

    // AXI-Lite 介面
    reg         awvalid = 0, wvalid = 0, arvalid = 0;
    reg  [31:0] awaddr = 0, wdata = 0, araddr = 0;
    reg  [2:0]  awprot = 0, arprot = 0;
    reg  [3:0]  wstrb = 0;
    reg         bready = 1, rready = 1;
    wire        awready, wready, bvalid, arready, rvalid;
    wire [1:0]  bresp, rresp;
    wire [31:0] rdata;

    // MVAU2 權重頻寬: 512-bit (PE=16 * 32)
    wire [511:0] internal_wstrm_tdata;
    wire         internal_wstrm_tvalid;
    wire         internal_wstrm_tready;

    // 輸入特徵圖: 32-bit
    reg  [31:0]  in0_V_TDATA;
    reg          in0_V_TVALID;
    wire         in0_V_TREADY;

    // 輸出結果: 16-bit
    wire [15:0]  out_V_TDATA;
    wire         out_V_TVALID;
    reg          out_V_TREADY;

    // 實例化 MVAU2 權重串流
    StreamingDataflowPartition_1_StreamingDataflowPartition_1_MVAU_hls_2_wstrm_0 wstrm_inst (
        .ap_clk(ap_clk), .ap_rst_n(ap_rst_n),
        .awready(awready), .awvalid(awvalid), .awprot(awprot), .awaddr(awaddr),
        .wready(wready), .wvalid(wvalid), .wdata(wdata), .wstrb(wstrb),
        .bready(bready), .bvalid(bvalid), .bresp(bresp),
        .arready(arready), .arvalid(arvalid), .arprot(arprot), .araddr(araddr),
        .rready(rready), .rvalid(rvalid), .rresp(rresp), .rdata(rdata),
        .m_axis_0_tvalid(internal_wstrm_tvalid), .m_axis_0_tready(internal_wstrm_tready), .m_axis_0_tdata(internal_wstrm_tdata)
    );

    // 實例化 MVAU2 運算核心
    StreamingDataflowPartition_1_StreamingDataflowPartition_1_MVAU_hls_2_0 mvau_inst (
        .ap_clk(ap_clk), .ap_rst_n(ap_rst_n),
        .in0_V_TVALID(in0_V_TVALID), .in0_V_TREADY(in0_V_TREADY), .in0_V_TDATA(in0_V_TDATA),
        .weights_V_TVALID(internal_wstrm_tvalid), .weights_V_TREADY(internal_wstrm_tready), .weights_V_TDATA(internal_wstrm_tdata),
        .out_V_TVALID(out_V_TVALID), .out_V_TREADY(out_V_TREADY), .out_V_TDATA(out_V_TDATA)
    );

    initial begin
        ap_clk = 0;
        forever #5 ap_clk = ~ap_clk; 
    end

    // MVAU2 Threshold ROM
    reg [9:0] thresh_rom_0  [0:7]; reg [9:0] thresh_rom_1  [0:7];
    reg [9:0] thresh_rom_2  [0:7]; reg [9:0] thresh_rom_3  [0:7];
    reg [9:0] thresh_rom_4  [0:7]; reg [9:0] thresh_rom_5  [0:7];
    reg [9:0] thresh_rom_6  [0:7]; reg [9:0] thresh_rom_7  [0:7];
    reg [9:0] thresh_rom_8  [0:7]; reg [9:0] thresh_rom_9  [0:7];
    reg [9:0] thresh_rom_10 [0:7]; reg [9:0] thresh_rom_11 [0:7];
    reg [9:0] thresh_rom_12 [0:7]; reg [9:0] thresh_rom_13 [0:7];
    reg [9:0] thresh_rom_14 [0:7]; reg [9:0] thresh_rom_15 [0:7];
    
    initial begin
        $readmemh("/home/barkie1/mvau_pipeline/mvau_adapter/mvau2/data/StreamingDataflowPartition_1_MVAU_hls_2_Matrix_Vector_Activate_Stream_Batch_p_ZL7threshs_0_ROM_AUTO_1R.dat", thresh_rom_0);
        $readmemh("/home/barkie1/mvau_pipeline/mvau_adapter/mvau2/data/StreamingDataflowPartition_1_MVAU_hls_2_Matrix_Vector_Activate_Stream_Batch_p_ZL7threshs_1_ROM_AUTO_1R.dat", thresh_rom_1);
        $readmemh("/home/barkie1/mvau_pipeline/mvau_adapter/mvau2/data/StreamingDataflowPartition_1_MVAU_hls_2_Matrix_Vector_Activate_Stream_Batch_p_ZL7threshs_2_ROM_AUTO_1R.dat", thresh_rom_2);
        $readmemh("/home/barkie1/mvau_pipeline/mvau_adapter/mvau2/data/StreamingDataflowPartition_1_MVAU_hls_2_Matrix_Vector_Activate_Stream_Batch_p_ZL7threshs_3_ROM_AUTO_1R.dat", thresh_rom_3);
        $readmemh("/home/barkie1/mvau_pipeline/mvau_adapter/mvau2/data/StreamingDataflowPartition_1_MVAU_hls_2_Matrix_Vector_Activate_Stream_Batch_p_ZL7threshs_4_ROM_AUTO_1R.dat", thresh_rom_4);
        $readmemh("/home/barkie1/mvau_pipeline/mvau_adapter/mvau2/data/StreamingDataflowPartition_1_MVAU_hls_2_Matrix_Vector_Activate_Stream_Batch_p_ZL7threshs_5_ROM_AUTO_1R.dat", thresh_rom_5);
        $readmemh("/home/barkie1/mvau_pipeline/mvau_adapter/mvau2/data/StreamingDataflowPartition_1_MVAU_hls_2_Matrix_Vector_Activate_Stream_Batch_p_ZL7threshs_6_ROM_AUTO_1R.dat", thresh_rom_6);
        $readmemh("/home/barkie1/mvau_pipeline/mvau_adapter/mvau2/data/StreamingDataflowPartition_1_MVAU_hls_2_Matrix_Vector_Activate_Stream_Batch_p_ZL7threshs_7_ROM_AUTO_1R.dat", thresh_rom_7);
        $readmemh("/home/barkie1/mvau_pipeline/mvau_adapter/mvau2/data/StreamingDataflowPartition_1_MVAU_hls_2_Matrix_Vector_Activate_Stream_Batch_p_ZL7threshs_8_ROM_AUTO_1R.dat", thresh_rom_8);
        $readmemh("/home/barkie1/mvau_pipeline/mvau_adapter/mvau2/data/StreamingDataflowPartition_1_MVAU_hls_2_Matrix_Vector_Activate_Stream_Batch_p_ZL7threshs_9_ROM_AUTO_1R.dat", thresh_rom_9);
        $readmemh("/home/barkie1/mvau_pipeline/mvau_adapter/mvau2/data/StreamingDataflowPartition_1_MVAU_hls_2_Matrix_Vector_Activate_Stream_Batch_p_ZL7threshs_10_ROM_AUTO_1R.dat", thresh_rom_10);
        $readmemh("/home/barkie1/mvau_pipeline/mvau_adapter/mvau2/data/StreamingDataflowPartition_1_MVAU_hls_2_Matrix_Vector_Activate_Stream_Batch_p_ZL7threshs_11_ROM_AUTO_1R.dat", thresh_rom_11);
        $readmemh("/home/barkie1/mvau_pipeline/mvau_adapter/mvau2/data/StreamingDataflowPartition_1_MVAU_hls_2_Matrix_Vector_Activate_Stream_Batch_p_ZL7threshs_12_ROM_AUTO_1R.dat", thresh_rom_12);
        $readmemh("/home/barkie1/mvau_pipeline/mvau_adapter/mvau2/data/StreamingDataflowPartition_1_MVAU_hls_2_Matrix_Vector_Activate_Stream_Batch_p_ZL7threshs_13_ROM_AUTO_1R.dat", thresh_rom_13);
        $readmemh("/home/barkie1/mvau_pipeline/mvau_adapter/mvau2/data/StreamingDataflowPartition_1_MVAU_hls_2_Matrix_Vector_Activate_Stream_Batch_p_ZL7threshs_14_ROM_AUTO_1R.dat", thresh_rom_14);
        $readmemh("/home/barkie1/mvau_pipeline/mvau_adapter/mvau2/data/StreamingDataflowPartition_1_MVAU_hls_2_Matrix_Vector_Activate_Stream_Batch_p_ZL7threshs_15_ROM_AUTO_1R.dat", thresh_rom_15);
    end

    wire [2:0] step = out_ptr % 8; 

    // 黃金測資
    reg [31:0] golden_in  [0:MAX_IN_WORDS-1];  
    reg [15:0] golden_out [0:MAX_OUT_WORDS-1]; 
    
    integer in_ptr = 0;
    integer out_ptr = 0;
    integer cor_cnt = 0;
    integer err_cnt = 0;
    integer wait_cnt = 0;

    initial begin
        for (in_ptr = 0; in_ptr < MAX_IN_WORDS; in_ptr = in_ptr + 1) golden_in[in_ptr] = 32'hx;
        for (out_ptr = 0; out_ptr < MAX_OUT_WORDS; out_ptr = out_ptr + 1) golden_out[out_ptr] = 16'hx;

        $readmemh("/home/barkie1/mvau_pipeline/mvau_adapter/mvau2/golden_data/mvau2_baseline_in.dat", golden_in);
        $readmemh("/home/barkie1/mvau_pipeline/mvau_adapter/mvau2/golden_data/mvau2_baseline_expected.dat", golden_out);
        
        in_ptr = 0;
        out_ptr = 0;

        ap_rst_n = 0;
        in0_V_TVALID = 0;
        in0_V_TDATA = 0;
        out_V_TREADY = 1; 
        
        #100;
        ap_rst_n = 1;
        #50;
        
        $display("---- System Reset Done. Starting MVAU2 Baseline Data Feed ----");
        in0_V_TVALID = 1;
        
        while (in_ptr < MAX_IN_WORDS && golden_in[in_ptr] !== 32'hx) begin
            in0_V_TDATA = golden_in[in_ptr];
            @(posedge ap_clk);
            if (in0_V_TVALID && in0_V_TREADY) begin
                in_ptr = in_ptr + 1;
            end
        end

        $display("---- Input Feed Complete. Total %0d Words Sent ----", in_ptr);
        
        // ✨ 改進：灌入 Dummy Data 把卡在 MVAU2 管線最後的資料擠出來
        $display("---- Sending Dummy Data to flush MVAU2 Pipeline... ----");
        wait_cnt = 0;
        while (golden_out[out_ptr] !== 16'hx && wait_cnt < 500000) begin
            in0_V_TDATA = 32'd0; // 持續送有效 0 資料
            @(posedge ap_clk);
            wait_cnt = wait_cnt + 1;
        end
        
        in0_V_TVALID = 0; // 關閉輸入

        // 結算報告
        $display("\n========================================");
        if (wait_cnt >= 500000) begin
            $display("⏳ Timeout: 硬體沒有吐出足夠的資料！(卡在第 %0d 筆)", out_ptr);
        end else begin
            $display("🏁 測資已全數比對完畢！總共比對了 %0d 筆", out_ptr);
        end
        
        $display("----------------------------------------");
        if (err_cnt == 0)
            $display("🎉🎉🎉 驗證通過！MVAU2 Baseline 硬體與軟體 100%% 吻合！");
        else begin
            $display("⚠️ 驗證失敗，共有 %0d 個錯誤。", err_cnt);
            $display("✅ 驗證成功，共有 %0d 個正確。", cor_cnt);
        end
        $display("========================================");
        $finish;
    end

    // 輸出即時比對
    always @(posedge ap_clk) begin
        if (out_V_TVALID && out_V_TREADY) begin
            if (^out_V_TDATA === 1'bx) begin
                $display("⚠️ [警告] 序號: %0d 偵測到未知態 X！", out_ptr);
            end

            // 只有出錯才印詳細資訊
            if (out_V_TDATA[15:0] !== golden_out[out_ptr][15:0]) begin
                $display("--------------------------------------------------");
                $display("❌ [錯誤] 序號: %0d (Channel 群: %0d ~ %0d)", out_ptr, step*16, step*16+15);
                $display("   -> 硬體輸出: %016b | 預期輸出: %016b", out_V_TDATA[15:0], golden_out[out_ptr][15:0]);
                $display("--------------------------------------------------");
                err_cnt = err_cnt + 1;
            end
            else begin
                cor_cnt = cor_cnt + 1;
                if (cor_cnt % 500 == 0) begin
                    $display("🟢 [進度回報] 目前已成功比對 %0d 筆資料...", cor_cnt);
                end
            end
            
            out_ptr = out_ptr + 1;
        end
    end

endmodule
