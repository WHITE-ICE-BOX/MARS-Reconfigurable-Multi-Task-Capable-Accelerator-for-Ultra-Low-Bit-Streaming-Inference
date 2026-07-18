`timescale 1ns / 1ps

module tb_MVAU_2;

    parameter MAX_IN_WORDS  = 200000; 
    parameter MAX_OUT_WORDS = 200000;

    reg ap_clk;
    reg ap_rst_n;

    // AXI-Lite 介面 (給 wstrm 用)
    reg         awvalid = 0, wvalid = 0, arvalid = 0;
    reg  [31:0] awaddr = 0, wdata = 0, araddr = 0;
    reg  [2:0]  awprot = 0, arprot = 0;
    reg  [3:0]  wstrb = 0;
    reg         bready = 1, rready = 1;
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

    // --- 連線宣告 ---
    reg  [31:0]  tb_in_tdata;
    reg          tb_in_tvalid;
    wire         tb_in_tready;

    wire [31:0]  split_to_mvau_tdata;
    wire         split_to_mvau_tvalid;
    wire         split_to_mvau_tready;

    wire [31:0]  split_to_adapt_tdata;
    wire         split_to_adapt_tvalid;
    wire         split_to_adapt_tready;

    wire [511:0] internal_wstrm_tdata;
    wire         internal_wstrm_tvalid;
    wire         internal_wstrm_tready;

    wire [511:0] mvau_to_add_tdata;
    wire         mvau_to_add_tvalid;
    wire         mvau_to_add_tready;

    wire [127:0] adapt_to_fifo_tdata;
    wire         adapt_to_fifo_tvalid;
    wire         adapt_to_fifo_tready;

    wire [127:0] fifo_to_add_tdata;
    wire         fifo_to_add_tvalid;
    wire         fifo_to_add_tready;

    wire [15:0]  tb_out_tdata;
    wire         tb_out_tvalid;
    reg          tb_out_tready;

    // --- 模組實例化 ---
    Stream_Splitter_mvau2 #(.DATA_WIDTH(32)) splitter_inst (
        .aclk(ap_clk), .aresetn(ap_rst_n),
        .s_axis_tdata(tb_in_tdata), .s_axis_tvalid(tb_in_tvalid), .s_axis_tready(tb_in_tready),
        .m_axis_1_tdata(split_to_mvau_tdata), .m_axis_1_tvalid(split_to_mvau_tvalid), .m_axis_1_tready(split_to_mvau_tready),
        .m_axis_2_tdata(split_to_adapt_tdata), .m_axis_2_tvalid(split_to_adapt_tvalid), .m_axis_2_tready(split_to_adapt_tready)
    );

    // ✨ 換成 MVAU_hls_2 的 wstrm
    StreamingDataflowPartition_1_StreamingDataflowPartition_1_MVAU_hls_2_wstrm_0 wstrm_inst (
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

    // ✨ 換成 MVAU_hls_2_0
    StreamingDataflowPartition_1_StreamingDataflowPartition_1_MVAU_hls_2_0 mvau_inst (
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

    // ✨ 換成 Adapter_MVAU2
    Adapter_MVAU2 adapter_inst (
        .aclk(ap_clk), .aresetn(ap_rst_n),
        .s_axis_tdata(split_to_adapt_tdata),
        .s_axis_tvalid(split_to_adapt_tvalid),
        .s_axis_tready(split_to_adapt_tready),
        .m_axis_tdata(adapt_to_fifo_tdata),
        .m_axis_tvalid(adapt_to_fifo_tvalid),
        .m_axis_tready(adapt_to_fifo_tready)
    );

    Simple_FIFO_mvau2 #(.WIDTH(128), .DEPTH_LOG2(6)) fifo_inst (
        .clk(ap_clk), .rst_n(ap_rst_n),
        .s_axis_tdata(adapt_to_fifo_tdata), .s_axis_tvalid(adapt_to_fifo_tvalid), .s_axis_tready(adapt_to_fifo_tready),
        .m_axis_tdata(fifo_to_add_tdata), .m_axis_tvalid(fifo_to_add_tvalid), .m_axis_tready(fifo_to_add_tready)
    );

    // Stream_Adder_Threshold_mvau2 已經在你修改好的 MVAU2 資料夾下，這裡直接例化
    Stream_Adder_Threshold_mvau2 adder_thresh_inst (
        .aclk(ap_clk), .aresetn(ap_rst_n),
        .s_axis_1_tdata(mvau_to_add_tdata), .s_axis_1_tvalid(mvau_to_add_tvalid), .s_axis_1_tready(mvau_to_add_tready),
        .s_axis_2_tdata(fifo_to_add_tdata), .s_axis_2_tvalid(fifo_to_add_tvalid), .s_axis_2_tready(fifo_to_add_tready),
        .m_axis_tdata(tb_out_tdata), .m_axis_tvalid(tb_out_tvalid), .m_axis_tready(tb_out_tready)
    );

    initial begin
        ap_clk = 0;
        forever #5 ap_clk = ~ap_clk; 
    end

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

        // ✨ 路徑換成 mvau2 (pw1)
        $readmemh("/home/barkie1/mvau_pipeline/mvau_adapter/mvau2/golden_data/mvau2_in.dat", golden_in);
        $readmemh("/home/barkie1/mvau_pipeline/mvau_adapter/mvau2/golden_data/mvau2_expected.dat", golden_out);
        
        in_ptr = 0; out_ptr = 0;

        ap_rst_n = 0; tb_in_tvalid = 0; tb_in_tdata = 0; tb_out_tready = 1; 
        
        #100; ap_rst_n = 1; #50;
        
        $display("---- System Reset Done. Starting Adapter Subsystem Data Feed (MVAU2) ----");
        tb_in_tvalid = 1;
        
        while (in_ptr < MAX_IN_WORDS && golden_in[in_ptr] !== 32'hx) begin
            tb_in_tdata = golden_in[in_ptr];
            @(posedge ap_clk);
            if (tb_in_tvalid && tb_in_tready) in_ptr = in_ptr + 1;
        end

        $display("---- Input Feed Complete. Total %0d Words Sent ----", in_ptr);
        
        // 灌入 Dummy Data 把卡在管線最後的資料擠出來
        $display("---- Sending Dummy Data to flush MVAU2 Pipeline... ----");
        tb_in_tdata = 32'd0;
        wait_cnt = 0;
        
        // ✨ Timeout 時間稍微放寬，對應 11520 筆資料
        while (golden_out[out_ptr] !== 16'hx && wait_cnt < 1000000) begin
            @(posedge ap_clk);
            wait_cnt = wait_cnt + 1;
        end
        
        tb_in_tvalid = 0;

        $display("\n========================================");
        if (wait_cnt >= 1000000) $display("⏳ Timeout: 硬體沒有吐出足夠的資料！(卡在第 %0d 筆)", out_ptr);
        else                     $display("🏁 測資已全數比對完畢！總共比對了 %0d 筆", out_ptr);
        
        $display("----------------------------------------");
        if (err_cnt == 0) $display("🎉🎉🎉 驗證通過！MVAU2 Adapter 融合後硬體與軟體 100%% 吻合！");
        else begin
            $display("⚠️ 驗證失敗，共有 %0d 個錯誤。", err_cnt);
            $display("✅ 驗證成功，共有 %0d 個正確。", cor_cnt);
        end
        $display("========================================");
        $finish;
    end

    wire [2:0] step = out_ptr % 8; 

    always @(posedge ap_clk) begin
        if (tb_out_tvalid && tb_out_tready) begin
            if (tb_out_tdata[15:0] !== golden_out[out_ptr][15:0]) begin
                $display("--------------------------------------------------");
                $display("❌ [錯誤] 序號: %0d (Channel 群: %0d ~ %0d)", out_ptr, step*16, step*16+15);
                $display("   -> 硬體輸出: %016b | 預期輸出: %016b", tb_out_tdata[15:0], golden_out[out_ptr][15:0]);
                $display("--------------------------------------------------");
                err_cnt = err_cnt + 1;
            end
            else begin
                cor_cnt = cor_cnt + 1;
                if (cor_cnt % 1000 == 0) $display("🟢 [進度回報] 目前已成功比對 %0d 筆資料...", cor_cnt);
            end
            out_ptr = out_ptr + 1;
        end
    end

endmodule
