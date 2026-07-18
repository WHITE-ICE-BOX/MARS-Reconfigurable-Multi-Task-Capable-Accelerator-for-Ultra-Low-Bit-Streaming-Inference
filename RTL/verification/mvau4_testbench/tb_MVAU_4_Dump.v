`timescale 1ns / 1ps

module tb_MVAU_4_Dump;

    parameter integer NUM_SAMPLES = 10;
    parameter integer INPUT_WORDS_PER_SAMPLE  = 324;
    parameter integer OUTPUT_WORDS_PER_SAMPLE = 576;
    parameter integer TOTAL_INPUT_WORDS  = NUM_SAMPLES * INPUT_WORDS_PER_SAMPLE;
    parameter integer TOTAL_OUTPUT_WORDS = NUM_SAMPLES * OUTPUT_WORDS_PER_SAMPLE;

    reg ap_clk;
    reg ap_rst_n;

    reg         awvalid = 0, wvalid = 0, arvalid = 0;
    reg  [31:0] awaddr  = 0, wdata  = 0, araddr = 0;
    reg  [2:0]  awprot  = 0, arprot = 0;
    reg  [3:0]  wstrb   = 0;
    reg         bready  = 1, rready = 1;
    wire        awready, wready, bvalid, arready, rvalid;
    wire [1:0]  bresp, rresp;
    wire [31:0] rdata;

    reg  [31:0]  tb_in_tdata;
    reg          tb_in_tvalid;
    wire         tb_in_tready;

    wire [31:0]  split_to_mvau_tdata, split_to_adapt_tdata;
    wire         split_to_mvau_tvalid, split_to_adapt_tvalid;
    wire         split_to_mvau_tready, split_to_adapt_tready;

    wire [127:0] internal_wstrm_tdata;
    wire         internal_wstrm_tvalid, internal_wstrm_tready;

    wire [127:0] mvau_to_add_tdata;
    wire         mvau_to_add_tvalid, mvau_to_add_tready;

    wire [31:0]  adapt_to_fifo_tdata, fifo_to_add_tdata;
    wire         adapt_to_fifo_tvalid, adapt_to_fifo_tready;
    wire         fifo_to_add_tvalid, fifo_to_add_tready;

    wire [7:0]   tb_out_tdata;
    wire         tb_out_tvalid;
    reg          tb_out_tready;

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
        .m_axis_0_tvalid(internal_wstrm_tvalid), .m_axis_0_tready(internal_wstrm_tready), .m_axis_0_tdata(internal_wstrm_tdata)
    );

    StreamingDataflowPartition_1_StreamingDataflowPartition_1_MVAU_hls_4_0 mvau_inst (
        .ap_clk(ap_clk), .ap_rst_n(ap_rst_n),
        .in0_V_TVALID(split_to_mvau_tvalid), .in0_V_TREADY(split_to_mvau_tready), .in0_V_TDATA(split_to_mvau_tdata),
        .weights_V_TVALID(internal_wstrm_tvalid), .weights_V_TREADY(internal_wstrm_tready), .weights_V_TDATA(internal_wstrm_tdata),
        .out_V_TVALID(mvau_to_add_tvalid), .out_V_TREADY(mvau_to_add_tready), .out_V_TDATA(mvau_to_add_tdata)
    );

    Adapter_MVAU4 adapter_inst (
        .aclk(ap_clk), .aresetn(ap_rst_n),
        .s_axis_tdata(split_to_adapt_tdata), .s_axis_tvalid(split_to_adapt_tvalid), .s_axis_tready(split_to_adapt_tready),
        .m_axis_tdata(adapt_to_fifo_tdata), .m_axis_tvalid(adapt_to_fifo_tvalid), .m_axis_tready(adapt_to_fifo_tready)
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

    initial begin ap_clk = 0; forever #5 ap_clk = ~ap_clk; end

    reg [31:0] golden_in [0:TOTAL_INPUT_WORDS-1];
    integer in_ptr = 0;
    integer out_ptr = 0;
    integer dump_file;

    initial begin
        $readmemh("golden_data/mvau4_in.dat", golden_in);
        dump_file = $fopen("golden_data/mvau4_adapter_hw_dump.dat", "w");
        in_ptr = 0;

        ap_rst_n = 0; tb_in_tvalid = 0; tb_in_tdata = 0; tb_out_tready = 1;
        #100; ap_rst_n = 1; #50;

        $display("---- Adapter Dump MVAU4: Starting Data Feed ----");
        tb_in_tvalid = 1;
        while (in_ptr < TOTAL_INPUT_WORDS) begin
            tb_in_tdata = golden_in[in_ptr];
            @(posedge ap_clk);
            if (tb_in_tvalid && tb_in_tready) in_ptr = in_ptr + 1;
        end
        tb_in_tvalid = 0;
        $display("---- Input Complete: %0d words ----", in_ptr);

        #2000000;
        $display("---- Timeout. Outputs: %0d ----", out_ptr);
        $fclose(dump_file);
        $finish;
    end

    always @(posedge ap_clk) begin
        if (tb_out_tvalid && tb_out_tready) begin
            $fwrite(dump_file, "%02x\n", tb_out_tdata);
            out_ptr = out_ptr + 1;
            if (out_ptr == TOTAL_OUTPUT_WORDS) begin
                $display("---- All %0d outputs captured ----", TOTAL_OUTPUT_WORDS);
                $fclose(dump_file);
                $finish;
            end
        end
    end
endmodule
