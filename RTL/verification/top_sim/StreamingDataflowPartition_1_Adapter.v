// AUTO-GENERATED from StreamingDataflowPartition_1.v by patch_stitch_adapter.py
// * top renamed      -> StreamingDataflowPartition_1_Adapter
// * StreamingDataflowPartition_1_StreamingDataflowPartition_1_MVAU_hls_1_0 -> MVAU1_Super_Wrapper
// * StreamingDataflowPartition_1_StreamingDataflowPartition_1_MVAU_hls_2_0 -> MVAU2_Super_Wrapper
// * StreamingDataflowPartition_1_StreamingDataflowPartition_1_MVAU_hls_3_0 -> MVAU3_Super_Wrapper
// * StreamingDataflowPartition_1_StreamingDataflowPartition_1_MVAU_hls_4_0 -> MVAU4_Super_Wrapper
// * StreamingDataflowPartition_1_StreamingDataflowPartition_1_MVAU_hls_5_0 -> MVAU5_Super_Wrapper
// source: /home/barkie1/mvau_pipeline/finn/finn_pipeline_adapter/vivado_stitch_proj_hv26s5y4/ip/src/StreamingDataflowPartition_1.v

//Copyright 1986-2022 Xilinx, Inc. All Rights Reserved.
//--------------------------------------------------------------------------------
//Tool Version: Vivado v.2022.2 (lin64) Build 3671981 Fri Oct 14 04:59:54 MDT 2022
//Date        : Tue Apr 14 15:48:43 2026
//Host        : finn_dev_barkie1 running 64-bit Ubuntu 22.04.1 LTS
//Command     : generate_target StreamingDataflowPartition_1.bd
//Design      : StreamingDataflowPartition_1
//Purpose     : IP block netlist
//--------------------------------------------------------------------------------
`timescale 1 ps / 1 ps

(* CORE_GENERATION_INFO = "StreamingDataflowPartition_1,IP_Integrator,{x_ipVendor=xilinx.com,x_ipLibrary=BlockDiagram,x_ipName=StreamingDataflowPartition_1,x_ipVersion=1.00.a,x_ipLanguage=VERILOG,numBlks=55,numReposBlks=46,numNonXlnxBlks=9,numHierBlks=9,maxHierDepth=1,numSysgenBlks=0,numHlsBlks=12,numHdlrefBlks=25,numPkgbdBlks=0,bdsource=USER,synth_mode=OOC_per_IP}" *) (* HW_HANDOFF = "StreamingDataflowPartition_1.hwdef" *) 
module StreamingDataflowPartition_1_Adapter
   (ap_clk,
    ap_rst_n,
    m_axis_0_tdata,
    m_axis_0_tready,
    m_axis_0_tvalid,
    s_axis_0_tdata,
    s_axis_0_tready,
    s_axis_0_tvalid);
  (* X_INTERFACE_INFO = "xilinx.com:signal:clock:1.0 CLK.AP_CLK CLK" *) (* X_INTERFACE_PARAMETER = "XIL_INTERFACENAME CLK.AP_CLK, ASSOCIATED_BUSIF s_axis_0:m_axis_0, ASSOCIATED_RESET ap_rst_n, CLK_DOMAIN StreamingDataflowPartition_1_ap_clk_0, FREQ_HZ 100000000, FREQ_TOLERANCE_HZ 0, INSERT_VIP 0, PHASE 0.0" *) input ap_clk;
  (* X_INTERFACE_INFO = "xilinx.com:signal:reset:1.0 RST.AP_RST_N RST" *) (* X_INTERFACE_PARAMETER = "XIL_INTERFACENAME RST.AP_RST_N, INSERT_VIP 0, POLARITY ACTIVE_LOW" *) input ap_rst_n;
  (* X_INTERFACE_INFO = "xilinx.com:interface:axis:1.0 m_axis_0 " *) (* X_INTERFACE_PARAMETER = "XIL_INTERFACENAME m_axis_0, CLK_DOMAIN StreamingDataflowPartition_1_ap_clk_0, FREQ_HZ 100000000, HAS_TKEEP 0, HAS_TLAST 0, HAS_TREADY 1, HAS_TSTRB 0, INSERT_VIP 0, LAYERED_METADATA undef, PHASE 0.0, TDATA_NUM_BYTES 1, TDEST_WIDTH 0, TID_WIDTH 0, TUSER_WIDTH 0" *) output [7:0]m_axis_0_tdata;
  (* X_INTERFACE_INFO = "xilinx.com:interface:axis:1.0 m_axis_0 " *) input m_axis_0_tready;
  (* X_INTERFACE_INFO = "xilinx.com:interface:axis:1.0 m_axis_0 " *) output m_axis_0_tvalid;
  (* X_INTERFACE_INFO = "xilinx.com:interface:axis:1.0 s_axis_0 " *) (* X_INTERFACE_PARAMETER = "XIL_INTERFACENAME s_axis_0, CLK_DOMAIN StreamingDataflowPartition_1_ap_clk_0, FREQ_HZ 100000000, HAS_TKEEP 0, HAS_TLAST 0, HAS_TREADY 1, HAS_TSTRB 0, INSERT_VIP 0, LAYERED_METADATA undef, PHASE 0.0, TDATA_NUM_BYTES 1, TDEST_WIDTH 0, TID_WIDTH 0, TUSER_WIDTH 0" *) input [7:0]s_axis_0_tdata;
  (* X_INTERFACE_INFO = "xilinx.com:interface:axis:1.0 s_axis_0 " *) output s_axis_0_tready;
  (* X_INTERFACE_INFO = "xilinx.com:interface:axis:1.0 s_axis_0 " *) input s_axis_0_tvalid;

  wire [23:0]StreamingDataflowPartition_1_ConvolutionInputGenerator_rtl_0_out_V_TDATA;
  wire StreamingDataflowPartition_1_ConvolutionInputGenerator_rtl_0_out_V_TREADY;
  wire StreamingDataflowPartition_1_ConvolutionInputGenerator_rtl_0_out_V_TVALID;
  wire [31:0]StreamingDataflowPartition_1_ConvolutionInputGenerator_rtl_1_out_V_TDATA;
  wire StreamingDataflowPartition_1_ConvolutionInputGenerator_rtl_1_out_V_TREADY;
  wire StreamingDataflowPartition_1_ConvolutionInputGenerator_rtl_1_out_V_TVALID;
  wire [31:0]StreamingDataflowPartition_1_ConvolutionInputGenerator_rtl_2_out_V_TDATA;
  wire StreamingDataflowPartition_1_ConvolutionInputGenerator_rtl_2_out_V_TREADY;
  wire StreamingDataflowPartition_1_ConvolutionInputGenerator_rtl_2_out_V_TVALID;
  wire [31:0]StreamingDataflowPartition_1_ConvolutionInputGenerator_rtl_3_out_V_TDATA;
  wire StreamingDataflowPartition_1_ConvolutionInputGenerator_rtl_3_out_V_TREADY;
  wire StreamingDataflowPartition_1_ConvolutionInputGenerator_rtl_3_out_V_TVALID;
  wire [31:0]StreamingDataflowPartition_1_ConvolutionInputGenerator_rtl_4_out_V_TDATA;
  wire StreamingDataflowPartition_1_ConvolutionInputGenerator_rtl_4_out_V_TREADY;
  wire StreamingDataflowPartition_1_ConvolutionInputGenerator_rtl_4_out_V_TVALID;
  wire [31:0]StreamingDataflowPartition_1_ConvolutionInputGenerator_rtl_5_out_V_TDATA;
  wire StreamingDataflowPartition_1_ConvolutionInputGenerator_rtl_5_out_V_TREADY;
  wire StreamingDataflowPartition_1_ConvolutionInputGenerator_rtl_5_out_V_TVALID;
  wire [7:0]StreamingDataflowPartition_1_LabelSelect_hls_0_out_V_TDATA;
  wire StreamingDataflowPartition_1_LabelSelect_hls_0_out_V_TREADY;
  wire StreamingDataflowPartition_1_LabelSelect_hls_0_out_V_TVALID;
  wire [15:0]StreamingDataflowPartition_1_MVAU_hls_0_out_V_TDATA;
  wire StreamingDataflowPartition_1_MVAU_hls_0_out_V_TREADY;
  wire StreamingDataflowPartition_1_MVAU_hls_0_out_V_TVALID;
  wire [31:0]StreamingDataflowPartition_1_MVAU_hls_1_out_V_TDATA;
  wire StreamingDataflowPartition_1_MVAU_hls_1_out_V_TREADY;
  wire StreamingDataflowPartition_1_MVAU_hls_1_out_V_TVALID;
  wire [15:0]StreamingDataflowPartition_1_MVAU_hls_2_out_V_TDATA;
  wire StreamingDataflowPartition_1_MVAU_hls_2_out_V_TREADY;
  wire StreamingDataflowPartition_1_MVAU_hls_2_out_V_TVALID;
  wire [15:0]StreamingDataflowPartition_1_MVAU_hls_3_out_V_TDATA;
  wire StreamingDataflowPartition_1_MVAU_hls_3_out_V_TREADY;
  wire StreamingDataflowPartition_1_MVAU_hls_3_out_V_TVALID;
  wire [7:0]StreamingDataflowPartition_1_MVAU_hls_4_out_V_TDATA;
  wire StreamingDataflowPartition_1_MVAU_hls_4_out_V_TREADY;
  wire StreamingDataflowPartition_1_MVAU_hls_4_out_V_TVALID;
  wire [7:0]StreamingDataflowPartition_1_MVAU_hls_5_out_V_TDATA;
  wire StreamingDataflowPartition_1_MVAU_hls_5_out_V_TREADY;
  wire StreamingDataflowPartition_1_MVAU_hls_5_out_V_TVALID;
  wire [7:0]StreamingDataflowPartition_1_MVAU_hls_6_out_V_TDATA;
  wire StreamingDataflowPartition_1_MVAU_hls_6_out_V_TREADY;
  wire StreamingDataflowPartition_1_MVAU_hls_6_out_V_TVALID;
  wire [7:0]StreamingDataflowPartition_1_MVAU_hls_7_out_V_TDATA;
  wire StreamingDataflowPartition_1_MVAU_hls_7_out_V_TREADY;
  wire StreamingDataflowPartition_1_MVAU_hls_7_out_V_TVALID;
  wire [159:0]StreamingDataflowPartition_1_MVAU_hls_8_out_V_TDATA;
  wire StreamingDataflowPartition_1_MVAU_hls_8_out_V_TREADY;
  wire StreamingDataflowPartition_1_MVAU_hls_8_out_V_TVALID;
  wire [23:0]StreamingDataflowPartition_1_StreamingDataWidthConverter_rtl_0_out_V_TDATA;
  wire StreamingDataflowPartition_1_StreamingDataWidthConverter_rtl_0_out_V_TREADY;
  wire StreamingDataflowPartition_1_StreamingDataWidthConverter_rtl_0_out_V_TVALID;
  wire [31:0]StreamingDataflowPartition_1_StreamingDataWidthConverter_rtl_10_out_V_TDATA;
  wire StreamingDataflowPartition_1_StreamingDataWidthConverter_rtl_10_out_V_TREADY;
  wire StreamingDataflowPartition_1_StreamingDataWidthConverter_rtl_10_out_V_TVALID;
  wire [31:0]StreamingDataflowPartition_1_StreamingDataWidthConverter_rtl_1_out_V_TDATA;
  wire StreamingDataflowPartition_1_StreamingDataWidthConverter_rtl_1_out_V_TREADY;
  wire StreamingDataflowPartition_1_StreamingDataWidthConverter_rtl_1_out_V_TVALID;
  wire [63:0]StreamingDataflowPartition_1_StreamingDataWidthConverter_rtl_2_out_V_TDATA;
  wire StreamingDataflowPartition_1_StreamingDataWidthConverter_rtl_2_out_V_TREADY;
  wire StreamingDataflowPartition_1_StreamingDataWidthConverter_rtl_2_out_V_TVALID;
  wire [31:0]StreamingDataflowPartition_1_StreamingDataWidthConverter_rtl_3_out_V_TDATA;
  wire StreamingDataflowPartition_1_StreamingDataWidthConverter_rtl_3_out_V_TREADY;
  wire StreamingDataflowPartition_1_StreamingDataWidthConverter_rtl_3_out_V_TVALID;
  wire [31:0]StreamingDataflowPartition_1_StreamingDataWidthConverter_rtl_4_out_V_TDATA;
  wire StreamingDataflowPartition_1_StreamingDataWidthConverter_rtl_4_out_V_TREADY;
  wire StreamingDataflowPartition_1_StreamingDataWidthConverter_rtl_4_out_V_TVALID;
  wire [127:0]StreamingDataflowPartition_1_StreamingDataWidthConverter_rtl_5_out_V_TDATA;
  wire StreamingDataflowPartition_1_StreamingDataWidthConverter_rtl_5_out_V_TREADY;
  wire StreamingDataflowPartition_1_StreamingDataWidthConverter_rtl_5_out_V_TVALID;
  wire [31:0]StreamingDataflowPartition_1_StreamingDataWidthConverter_rtl_6_out_V_TDATA;
  wire StreamingDataflowPartition_1_StreamingDataWidthConverter_rtl_6_out_V_TREADY;
  wire StreamingDataflowPartition_1_StreamingDataWidthConverter_rtl_6_out_V_TVALID;
  wire [31:0]StreamingDataflowPartition_1_StreamingDataWidthConverter_rtl_7_out_V_TDATA;
  wire StreamingDataflowPartition_1_StreamingDataWidthConverter_rtl_7_out_V_TREADY;
  wire StreamingDataflowPartition_1_StreamingDataWidthConverter_rtl_7_out_V_TVALID;
  wire [7:0]StreamingDataflowPartition_1_StreamingDataWidthConverter_rtl_8_out_V_TDATA;
  wire StreamingDataflowPartition_1_StreamingDataWidthConverter_rtl_8_out_V_TREADY;
  wire StreamingDataflowPartition_1_StreamingDataWidthConverter_rtl_8_out_V_TVALID;
  wire [7:0]StreamingDataflowPartition_1_StreamingDataWidthConverter_rtl_9_out_V_TDATA;
  wire StreamingDataflowPartition_1_StreamingDataWidthConverter_rtl_9_out_V_TREADY;
  wire StreamingDataflowPartition_1_StreamingDataWidthConverter_rtl_9_out_V_TVALID;
  wire [23:0]StreamingDataflowPartition_1_StreamingFIFO_rtl_0_out_V_TDATA;
  wire StreamingDataflowPartition_1_StreamingFIFO_rtl_0_out_V_TREADY;
  wire StreamingDataflowPartition_1_StreamingFIFO_rtl_0_out_V_TVALID;
  wire [31:0]StreamingDataflowPartition_1_StreamingFIFO_rtl_1_out_V_TDATA;
  wire StreamingDataflowPartition_1_StreamingFIFO_rtl_1_out_V_TREADY;
  wire StreamingDataflowPartition_1_StreamingFIFO_rtl_1_out_V_TVALID;
  wire [31:0]StreamingDataflowPartition_1_StreamingFIFO_rtl_2_out_V_TDATA;
  wire StreamingDataflowPartition_1_StreamingFIFO_rtl_2_out_V_TREADY;
  wire StreamingDataflowPartition_1_StreamingFIFO_rtl_2_out_V_TVALID;
  wire [31:0]StreamingDataflowPartition_1_StreamingFIFO_rtl_3_out_V_TDATA;
  wire StreamingDataflowPartition_1_StreamingFIFO_rtl_3_out_V_TREADY;
  wire StreamingDataflowPartition_1_StreamingFIFO_rtl_3_out_V_TVALID;
  wire [31:0]StreamingDataflowPartition_1_StreamingFIFO_rtl_4_out_V_TDATA;
  wire StreamingDataflowPartition_1_StreamingFIFO_rtl_4_out_V_TREADY;
  wire StreamingDataflowPartition_1_StreamingFIFO_rtl_4_out_V_TVALID;
  wire [7:0]StreamingDataflowPartition_1_StreamingFIFO_rtl_5_out_V_TDATA;
  wire StreamingDataflowPartition_1_StreamingFIFO_rtl_5_out_V_TREADY;
  wire StreamingDataflowPartition_1_StreamingFIFO_rtl_5_out_V_TVALID;
  wire [7:0]StreamingDataflowPartition_1_StreamingFIFO_rtl_6_out_V_TDATA;
  wire StreamingDataflowPartition_1_StreamingFIFO_rtl_6_out_V_TREADY;
  wire StreamingDataflowPartition_1_StreamingFIFO_rtl_6_out_V_TVALID;
  wire [63:0]StreamingDataflowPartition_1_StreamingMaxPool_hls_0_out_V_TDATA;
  wire StreamingDataflowPartition_1_StreamingMaxPool_hls_0_out_V_TREADY;
  wire StreamingDataflowPartition_1_StreamingMaxPool_hls_0_out_V_TVALID;
  wire [127:0]StreamingDataflowPartition_1_StreamingMaxPool_hls_1_out_V_TDATA;
  wire StreamingDataflowPartition_1_StreamingMaxPool_hls_1_out_V_TREADY;
  wire StreamingDataflowPartition_1_StreamingMaxPool_hls_1_out_V_TVALID;
  wire [7:0]StreamingDataflowPartition_1_Thresholding_rtl_0_out_V_TDATA;
  wire StreamingDataflowPartition_1_Thresholding_rtl_0_out_V_TREADY;
  wire StreamingDataflowPartition_1_Thresholding_rtl_0_out_V_TVALID;
  wire ap_clk_0_1;
  wire ap_rst_n_0_1;
  wire [7:0]in0_V_0_1_TDATA;
  wire in0_V_0_1_TREADY;
  wire in0_V_0_1_TVALID;

  assign StreamingDataflowPartition_1_LabelSelect_hls_0_out_V_TREADY = m_axis_0_tready;
  assign ap_clk_0_1 = ap_clk;
  assign ap_rst_n_0_1 = ap_rst_n;
  assign in0_V_0_1_TDATA = s_axis_0_tdata[7:0];
  assign in0_V_0_1_TVALID = s_axis_0_tvalid;
  assign m_axis_0_tdata[7:0] = StreamingDataflowPartition_1_LabelSelect_hls_0_out_V_TDATA;
  assign m_axis_0_tvalid = StreamingDataflowPartition_1_LabelSelect_hls_0_out_V_TVALID;
  assign s_axis_0_tready = in0_V_0_1_TREADY;
  StreamingDataflowPartition_1_StreamingDataflowPartition_1_ConvolutionInputGenerator_rtl_0_0 StreamingDataflowPartition_1_ConvolutionInputGenerator_rtl_0
       (.ap_clk(ap_clk_0_1),
        .ap_rst_n(ap_rst_n_0_1),
        .in0_V_TDATA(StreamingDataflowPartition_1_StreamingDataWidthConverter_rtl_0_out_V_TDATA),
        .in0_V_TREADY(StreamingDataflowPartition_1_StreamingDataWidthConverter_rtl_0_out_V_TREADY),
        .in0_V_TVALID(StreamingDataflowPartition_1_StreamingDataWidthConverter_rtl_0_out_V_TVALID),
        .out_V_TDATA(StreamingDataflowPartition_1_ConvolutionInputGenerator_rtl_0_out_V_TDATA),
        .out_V_TREADY(StreamingDataflowPartition_1_ConvolutionInputGenerator_rtl_0_out_V_TREADY),
        .out_V_TVALID(StreamingDataflowPartition_1_ConvolutionInputGenerator_rtl_0_out_V_TVALID));
  StreamingDataflowPartition_1_StreamingDataflowPartition_1_ConvolutionInputGenerator_rtl_1_0 StreamingDataflowPartition_1_ConvolutionInputGenerator_rtl_1
       (.ap_clk(ap_clk_0_1),
        .ap_rst_n(ap_rst_n_0_1),
        .in0_V_TDATA(StreamingDataflowPartition_1_StreamingDataWidthConverter_rtl_1_out_V_TDATA),
        .in0_V_TREADY(StreamingDataflowPartition_1_StreamingDataWidthConverter_rtl_1_out_V_TREADY),
        .in0_V_TVALID(StreamingDataflowPartition_1_StreamingDataWidthConverter_rtl_1_out_V_TVALID),
        .out_V_TDATA(StreamingDataflowPartition_1_ConvolutionInputGenerator_rtl_1_out_V_TDATA),
        .out_V_TREADY(StreamingDataflowPartition_1_ConvolutionInputGenerator_rtl_1_out_V_TREADY),
        .out_V_TVALID(StreamingDataflowPartition_1_ConvolutionInputGenerator_rtl_1_out_V_TVALID));
  StreamingDataflowPartition_1_StreamingDataflowPartition_1_ConvolutionInputGenerator_rtl_2_0 StreamingDataflowPartition_1_ConvolutionInputGenerator_rtl_2
       (.ap_clk(ap_clk_0_1),
        .ap_rst_n(ap_rst_n_0_1),
        .in0_V_TDATA(StreamingDataflowPartition_1_StreamingDataWidthConverter_rtl_3_out_V_TDATA),
        .in0_V_TREADY(StreamingDataflowPartition_1_StreamingDataWidthConverter_rtl_3_out_V_TREADY),
        .in0_V_TVALID(StreamingDataflowPartition_1_StreamingDataWidthConverter_rtl_3_out_V_TVALID),
        .out_V_TDATA(StreamingDataflowPartition_1_ConvolutionInputGenerator_rtl_2_out_V_TDATA),
        .out_V_TREADY(StreamingDataflowPartition_1_ConvolutionInputGenerator_rtl_2_out_V_TREADY),
        .out_V_TVALID(StreamingDataflowPartition_1_ConvolutionInputGenerator_rtl_2_out_V_TVALID));
  StreamingDataflowPartition_1_StreamingDataflowPartition_1_ConvolutionInputGenerator_rtl_3_0 StreamingDataflowPartition_1_ConvolutionInputGenerator_rtl_3
       (.ap_clk(ap_clk_0_1),
        .ap_rst_n(ap_rst_n_0_1),
        .in0_V_TDATA(StreamingDataflowPartition_1_StreamingDataWidthConverter_rtl_4_out_V_TDATA),
        .in0_V_TREADY(StreamingDataflowPartition_1_StreamingDataWidthConverter_rtl_4_out_V_TREADY),
        .in0_V_TVALID(StreamingDataflowPartition_1_StreamingDataWidthConverter_rtl_4_out_V_TVALID),
        .out_V_TDATA(StreamingDataflowPartition_1_ConvolutionInputGenerator_rtl_3_out_V_TDATA),
        .out_V_TREADY(StreamingDataflowPartition_1_ConvolutionInputGenerator_rtl_3_out_V_TREADY),
        .out_V_TVALID(StreamingDataflowPartition_1_ConvolutionInputGenerator_rtl_3_out_V_TVALID));
  StreamingDataflowPartition_1_StreamingDataflowPartition_1_ConvolutionInputGenerator_rtl_4_0 StreamingDataflowPartition_1_ConvolutionInputGenerator_rtl_4
       (.ap_clk(ap_clk_0_1),
        .ap_rst_n(ap_rst_n_0_1),
        .in0_V_TDATA(StreamingDataflowPartition_1_StreamingDataWidthConverter_rtl_6_out_V_TDATA),
        .in0_V_TREADY(StreamingDataflowPartition_1_StreamingDataWidthConverter_rtl_6_out_V_TREADY),
        .in0_V_TVALID(StreamingDataflowPartition_1_StreamingDataWidthConverter_rtl_6_out_V_TVALID),
        .out_V_TDATA(StreamingDataflowPartition_1_ConvolutionInputGenerator_rtl_4_out_V_TDATA),
        .out_V_TREADY(StreamingDataflowPartition_1_ConvolutionInputGenerator_rtl_4_out_V_TREADY),
        .out_V_TVALID(StreamingDataflowPartition_1_ConvolutionInputGenerator_rtl_4_out_V_TVALID));
  StreamingDataflowPartition_1_StreamingDataflowPartition_1_ConvolutionInputGenerator_rtl_5_0 StreamingDataflowPartition_1_ConvolutionInputGenerator_rtl_5
       (.ap_clk(ap_clk_0_1),
        .ap_rst_n(ap_rst_n_0_1),
        .in0_V_TDATA(StreamingDataflowPartition_1_StreamingDataWidthConverter_rtl_7_out_V_TDATA),
        .in0_V_TREADY(StreamingDataflowPartition_1_StreamingDataWidthConverter_rtl_7_out_V_TREADY),
        .in0_V_TVALID(StreamingDataflowPartition_1_StreamingDataWidthConverter_rtl_7_out_V_TVALID),
        .out_V_TDATA(StreamingDataflowPartition_1_ConvolutionInputGenerator_rtl_5_out_V_TDATA),
        .out_V_TREADY(StreamingDataflowPartition_1_ConvolutionInputGenerator_rtl_5_out_V_TREADY),
        .out_V_TVALID(StreamingDataflowPartition_1_ConvolutionInputGenerator_rtl_5_out_V_TVALID));
  StreamingDataflowPartition_1_StreamingDataflowPartition_1_LabelSelect_hls_0_0 StreamingDataflowPartition_1_LabelSelect_hls_0
       (.ap_clk(ap_clk_0_1),
        .ap_rst_n(ap_rst_n_0_1),
        .in0_V_TDATA(StreamingDataflowPartition_1_StreamingDataWidthConverter_rtl_10_out_V_TDATA),
        .in0_V_TREADY(StreamingDataflowPartition_1_StreamingDataWidthConverter_rtl_10_out_V_TREADY),
        .in0_V_TVALID(StreamingDataflowPartition_1_StreamingDataWidthConverter_rtl_10_out_V_TVALID),
        .out_V_TDATA(StreamingDataflowPartition_1_LabelSelect_hls_0_out_V_TDATA),
        .out_V_TREADY(StreamingDataflowPartition_1_LabelSelect_hls_0_out_V_TREADY),
        .out_V_TVALID(StreamingDataflowPartition_1_LabelSelect_hls_0_out_V_TVALID));
  StreamingDataflowPartition_1_MVAU_hls_0_imp_BWPU8W StreamingDataflowPartition_1_MVAU_hls_0
       (.ap_clk(ap_clk_0_1),
        .ap_rst_n(ap_rst_n_0_1),
        .in0_V_tdata(StreamingDataflowPartition_1_StreamingFIFO_rtl_0_out_V_TDATA),
        .in0_V_tready(StreamingDataflowPartition_1_StreamingFIFO_rtl_0_out_V_TREADY),
        .in0_V_tvalid(StreamingDataflowPartition_1_StreamingFIFO_rtl_0_out_V_TVALID),
        .out_V_tdata(StreamingDataflowPartition_1_MVAU_hls_0_out_V_TDATA),
        .out_V_tready(StreamingDataflowPartition_1_MVAU_hls_0_out_V_TREADY),
        .out_V_tvalid(StreamingDataflowPartition_1_MVAU_hls_0_out_V_TVALID));
  StreamingDataflowPartition_1_MVAU_hls_1_imp_KIE98K StreamingDataflowPartition_1_MVAU_hls_1
       (.ap_clk(ap_clk_0_1),
        .ap_rst_n(ap_rst_n_0_1),
        .in0_V_tdata(StreamingDataflowPartition_1_StreamingFIFO_rtl_1_out_V_TDATA),
        .in0_V_tready(StreamingDataflowPartition_1_StreamingFIFO_rtl_1_out_V_TREADY),
        .in0_V_tvalid(StreamingDataflowPartition_1_StreamingFIFO_rtl_1_out_V_TVALID),
        .out_V_tdata(StreamingDataflowPartition_1_MVAU_hls_1_out_V_TDATA),
        .out_V_tready(StreamingDataflowPartition_1_MVAU_hls_1_out_V_TREADY),
        .out_V_tvalid(StreamingDataflowPartition_1_MVAU_hls_1_out_V_TVALID));
  StreamingDataflowPartition_1_MVAU_hls_2_imp_1TQ8MQW StreamingDataflowPartition_1_MVAU_hls_2
       (.ap_clk(ap_clk_0_1),
        .ap_rst_n(ap_rst_n_0_1),
        .in0_V_tdata(StreamingDataflowPartition_1_StreamingFIFO_rtl_2_out_V_TDATA),
        .in0_V_tready(StreamingDataflowPartition_1_StreamingFIFO_rtl_2_out_V_TREADY),
        .in0_V_tvalid(StreamingDataflowPartition_1_StreamingFIFO_rtl_2_out_V_TVALID),
        .out_V_tdata(StreamingDataflowPartition_1_MVAU_hls_2_out_V_TDATA),
        .out_V_tready(StreamingDataflowPartition_1_MVAU_hls_2_out_V_TREADY),
        .out_V_tvalid(StreamingDataflowPartition_1_MVAU_hls_2_out_V_TVALID));
  StreamingDataflowPartition_1_MVAU_hls_3_imp_13XA618 StreamingDataflowPartition_1_MVAU_hls_3
       (.ap_clk(ap_clk_0_1),
        .ap_rst_n(ap_rst_n_0_1),
        .in0_V_tdata(StreamingDataflowPartition_1_StreamingFIFO_rtl_3_out_V_TDATA),
        .in0_V_tready(StreamingDataflowPartition_1_StreamingFIFO_rtl_3_out_V_TREADY),
        .in0_V_tvalid(StreamingDataflowPartition_1_StreamingFIFO_rtl_3_out_V_TVALID),
        .out_V_tdata(StreamingDataflowPartition_1_MVAU_hls_3_out_V_TDATA),
        .out_V_tready(StreamingDataflowPartition_1_MVAU_hls_3_out_V_TREADY),
        .out_V_tvalid(StreamingDataflowPartition_1_MVAU_hls_3_out_V_TVALID));
  StreamingDataflowPartition_1_MVAU_hls_4_imp_YTTEI9 StreamingDataflowPartition_1_MVAU_hls_4
       (.ap_clk(ap_clk_0_1),
        .ap_rst_n(ap_rst_n_0_1),
        .in0_V_tdata(StreamingDataflowPartition_1_StreamingFIFO_rtl_4_out_V_TDATA),
        .in0_V_tready(StreamingDataflowPartition_1_StreamingFIFO_rtl_4_out_V_TREADY),
        .in0_V_tvalid(StreamingDataflowPartition_1_StreamingFIFO_rtl_4_out_V_TVALID),
        .out_V_tdata(StreamingDataflowPartition_1_MVAU_hls_4_out_V_TDATA),
        .out_V_tready(StreamingDataflowPartition_1_MVAU_hls_4_out_V_TREADY),
        .out_V_tvalid(StreamingDataflowPartition_1_MVAU_hls_4_out_V_TVALID));
  StreamingDataflowPartition_1_MVAU_hls_5_imp_8GQNPX StreamingDataflowPartition_1_MVAU_hls_5
       (.ap_clk(ap_clk_0_1),
        .ap_rst_n(ap_rst_n_0_1),
        .in0_V_tdata(StreamingDataflowPartition_1_ConvolutionInputGenerator_rtl_5_out_V_TDATA),
        .in0_V_tready(StreamingDataflowPartition_1_ConvolutionInputGenerator_rtl_5_out_V_TREADY),
        .in0_V_tvalid(StreamingDataflowPartition_1_ConvolutionInputGenerator_rtl_5_out_V_TVALID),
        .out_V_tdata(StreamingDataflowPartition_1_MVAU_hls_5_out_V_TDATA),
        .out_V_tready(StreamingDataflowPartition_1_MVAU_hls_5_out_V_TREADY),
        .out_V_tvalid(StreamingDataflowPartition_1_MVAU_hls_5_out_V_TVALID));
  StreamingDataflowPartition_1_MVAU_hls_6_imp_1G1A9YX StreamingDataflowPartition_1_MVAU_hls_6
       (.ap_clk(ap_clk_0_1),
        .ap_rst_n(ap_rst_n_0_1),
        .in0_V_tdata(StreamingDataflowPartition_1_StreamingDataWidthConverter_rtl_8_out_V_TDATA),
        .in0_V_tready(StreamingDataflowPartition_1_StreamingDataWidthConverter_rtl_8_out_V_TREADY),
        .in0_V_tvalid(StreamingDataflowPartition_1_StreamingDataWidthConverter_rtl_8_out_V_TVALID),
        .out_V_tdata(StreamingDataflowPartition_1_MVAU_hls_6_out_V_TDATA),
        .out_V_tready(StreamingDataflowPartition_1_MVAU_hls_6_out_V_TREADY),
        .out_V_tvalid(StreamingDataflowPartition_1_MVAU_hls_6_out_V_TVALID));
  StreamingDataflowPartition_1_MVAU_hls_7_imp_1O336XP StreamingDataflowPartition_1_MVAU_hls_7
       (.ap_clk(ap_clk_0_1),
        .ap_rst_n(ap_rst_n_0_1),
        .in0_V_tdata(StreamingDataflowPartition_1_StreamingFIFO_rtl_5_out_V_TDATA),
        .in0_V_tready(StreamingDataflowPartition_1_StreamingFIFO_rtl_5_out_V_TREADY),
        .in0_V_tvalid(StreamingDataflowPartition_1_StreamingFIFO_rtl_5_out_V_TVALID),
        .out_V_tdata(StreamingDataflowPartition_1_MVAU_hls_7_out_V_TDATA),
        .out_V_tready(StreamingDataflowPartition_1_MVAU_hls_7_out_V_TREADY),
        .out_V_tvalid(StreamingDataflowPartition_1_MVAU_hls_7_out_V_TVALID));
  StreamingDataflowPartition_1_MVAU_hls_8_imp_10OO4HU StreamingDataflowPartition_1_MVAU_hls_8
       (.ap_clk(ap_clk_0_1),
        .ap_rst_n(ap_rst_n_0_1),
        .in0_V_tdata(StreamingDataflowPartition_1_StreamingFIFO_rtl_6_out_V_TDATA),
        .in0_V_tready(StreamingDataflowPartition_1_StreamingFIFO_rtl_6_out_V_TREADY),
        .in0_V_tvalid(StreamingDataflowPartition_1_StreamingFIFO_rtl_6_out_V_TVALID),
        .out_V_tdata(StreamingDataflowPartition_1_MVAU_hls_8_out_V_TDATA),
        .out_V_tready(StreamingDataflowPartition_1_MVAU_hls_8_out_V_TREADY),
        .out_V_tvalid(StreamingDataflowPartition_1_MVAU_hls_8_out_V_TVALID));
  StreamingDataflowPartition_1_StreamingDataflowPartition_1_StreamingDataWidthConverter_rtl_0_0 StreamingDataflowPartition_1_StreamingDataWidthConverter_rtl_0
       (.ap_clk(ap_clk_0_1),
        .ap_rst_n(ap_rst_n_0_1),
        .in0_V_TDATA(StreamingDataflowPartition_1_Thresholding_rtl_0_out_V_TDATA),
        .in0_V_TREADY(StreamingDataflowPartition_1_Thresholding_rtl_0_out_V_TREADY),
        .in0_V_TVALID(StreamingDataflowPartition_1_Thresholding_rtl_0_out_V_TVALID),
        .out_V_TDATA(StreamingDataflowPartition_1_StreamingDataWidthConverter_rtl_0_out_V_TDATA),
        .out_V_TREADY(StreamingDataflowPartition_1_StreamingDataWidthConverter_rtl_0_out_V_TREADY),
        .out_V_TVALID(StreamingDataflowPartition_1_StreamingDataWidthConverter_rtl_0_out_V_TVALID));
  StreamingDataflowPartition_1_StreamingDataflowPartition_1_StreamingDataWidthConverter_rtl_1_0 StreamingDataflowPartition_1_StreamingDataWidthConverter_rtl_1
       (.ap_clk(ap_clk_0_1),
        .ap_rst_n(ap_rst_n_0_1),
        .in0_V_TDATA(StreamingDataflowPartition_1_MVAU_hls_0_out_V_TDATA),
        .in0_V_TREADY(StreamingDataflowPartition_1_MVAU_hls_0_out_V_TREADY),
        .in0_V_TVALID(StreamingDataflowPartition_1_MVAU_hls_0_out_V_TVALID),
        .out_V_TDATA(StreamingDataflowPartition_1_StreamingDataWidthConverter_rtl_1_out_V_TDATA),
        .out_V_TREADY(StreamingDataflowPartition_1_StreamingDataWidthConverter_rtl_1_out_V_TREADY),
        .out_V_TVALID(StreamingDataflowPartition_1_StreamingDataWidthConverter_rtl_1_out_V_TVALID));
  StreamingDataflowPartition_1_StreamingDataflowPartition_1_StreamingDataWidthConverter_rtl_10_0 StreamingDataflowPartition_1_StreamingDataWidthConverter_rtl_10
       (.ap_clk(ap_clk_0_1),
        .ap_rst_n(ap_rst_n_0_1),
        .in0_V_TDATA(StreamingDataflowPartition_1_MVAU_hls_8_out_V_TDATA),
        .in0_V_TREADY(StreamingDataflowPartition_1_MVAU_hls_8_out_V_TREADY),
        .in0_V_TVALID(StreamingDataflowPartition_1_MVAU_hls_8_out_V_TVALID),
        .out_V_TDATA(StreamingDataflowPartition_1_StreamingDataWidthConverter_rtl_10_out_V_TDATA),
        .out_V_TREADY(StreamingDataflowPartition_1_StreamingDataWidthConverter_rtl_10_out_V_TREADY),
        .out_V_TVALID(StreamingDataflowPartition_1_StreamingDataWidthConverter_rtl_10_out_V_TVALID));
  StreamingDataflowPartition_1_StreamingDataflowPartition_1_StreamingDataWidthConverter_rtl_2_0 StreamingDataflowPartition_1_StreamingDataWidthConverter_rtl_2
       (.ap_clk(ap_clk_0_1),
        .ap_rst_n(ap_rst_n_0_1),
        .in0_V_TDATA(StreamingDataflowPartition_1_MVAU_hls_1_out_V_TDATA),
        .in0_V_TREADY(StreamingDataflowPartition_1_MVAU_hls_1_out_V_TREADY),
        .in0_V_TVALID(StreamingDataflowPartition_1_MVAU_hls_1_out_V_TVALID),
        .out_V_TDATA(StreamingDataflowPartition_1_StreamingDataWidthConverter_rtl_2_out_V_TDATA),
        .out_V_TREADY(StreamingDataflowPartition_1_StreamingDataWidthConverter_rtl_2_out_V_TREADY),
        .out_V_TVALID(StreamingDataflowPartition_1_StreamingDataWidthConverter_rtl_2_out_V_TVALID));
  StreamingDataflowPartition_1_StreamingDataflowPartition_1_StreamingDataWidthConverter_rtl_3_0 StreamingDataflowPartition_1_StreamingDataWidthConverter_rtl_3
       (.ap_clk(ap_clk_0_1),
        .ap_rst_n(ap_rst_n_0_1),
        .in0_V_TDATA(StreamingDataflowPartition_1_StreamingMaxPool_hls_0_out_V_TDATA),
        .in0_V_TREADY(StreamingDataflowPartition_1_StreamingMaxPool_hls_0_out_V_TREADY),
        .in0_V_TVALID(StreamingDataflowPartition_1_StreamingMaxPool_hls_0_out_V_TVALID),
        .out_V_TDATA(StreamingDataflowPartition_1_StreamingDataWidthConverter_rtl_3_out_V_TDATA),
        .out_V_TREADY(StreamingDataflowPartition_1_StreamingDataWidthConverter_rtl_3_out_V_TREADY),
        .out_V_TVALID(StreamingDataflowPartition_1_StreamingDataWidthConverter_rtl_3_out_V_TVALID));
  StreamingDataflowPartition_1_StreamingDataflowPartition_1_StreamingDataWidthConverter_rtl_4_0 StreamingDataflowPartition_1_StreamingDataWidthConverter_rtl_4
       (.ap_clk(ap_clk_0_1),
        .ap_rst_n(ap_rst_n_0_1),
        .in0_V_TDATA(StreamingDataflowPartition_1_MVAU_hls_2_out_V_TDATA),
        .in0_V_TREADY(StreamingDataflowPartition_1_MVAU_hls_2_out_V_TREADY),
        .in0_V_TVALID(StreamingDataflowPartition_1_MVAU_hls_2_out_V_TVALID),
        .out_V_TDATA(StreamingDataflowPartition_1_StreamingDataWidthConverter_rtl_4_out_V_TDATA),
        .out_V_TREADY(StreamingDataflowPartition_1_StreamingDataWidthConverter_rtl_4_out_V_TREADY),
        .out_V_TVALID(StreamingDataflowPartition_1_StreamingDataWidthConverter_rtl_4_out_V_TVALID));
  StreamingDataflowPartition_1_StreamingDataflowPartition_1_StreamingDataWidthConverter_rtl_5_0 StreamingDataflowPartition_1_StreamingDataWidthConverter_rtl_5
       (.ap_clk(ap_clk_0_1),
        .ap_rst_n(ap_rst_n_0_1),
        .in0_V_TDATA(StreamingDataflowPartition_1_MVAU_hls_3_out_V_TDATA),
        .in0_V_TREADY(StreamingDataflowPartition_1_MVAU_hls_3_out_V_TREADY),
        .in0_V_TVALID(StreamingDataflowPartition_1_MVAU_hls_3_out_V_TVALID),
        .out_V_TDATA(StreamingDataflowPartition_1_StreamingDataWidthConverter_rtl_5_out_V_TDATA),
        .out_V_TREADY(StreamingDataflowPartition_1_StreamingDataWidthConverter_rtl_5_out_V_TREADY),
        .out_V_TVALID(StreamingDataflowPartition_1_StreamingDataWidthConverter_rtl_5_out_V_TVALID));
  StreamingDataflowPartition_1_StreamingDataflowPartition_1_StreamingDataWidthConverter_rtl_6_0 StreamingDataflowPartition_1_StreamingDataWidthConverter_rtl_6
       (.ap_clk(ap_clk_0_1),
        .ap_rst_n(ap_rst_n_0_1),
        .in0_V_TDATA(StreamingDataflowPartition_1_StreamingMaxPool_hls_1_out_V_TDATA),
        .in0_V_TREADY(StreamingDataflowPartition_1_StreamingMaxPool_hls_1_out_V_TREADY),
        .in0_V_TVALID(StreamingDataflowPartition_1_StreamingMaxPool_hls_1_out_V_TVALID),
        .out_V_TDATA(StreamingDataflowPartition_1_StreamingDataWidthConverter_rtl_6_out_V_TDATA),
        .out_V_TREADY(StreamingDataflowPartition_1_StreamingDataWidthConverter_rtl_6_out_V_TREADY),
        .out_V_TVALID(StreamingDataflowPartition_1_StreamingDataWidthConverter_rtl_6_out_V_TVALID));
  StreamingDataflowPartition_1_StreamingDataflowPartition_1_StreamingDataWidthConverter_rtl_7_0 StreamingDataflowPartition_1_StreamingDataWidthConverter_rtl_7
       (.ap_clk(ap_clk_0_1),
        .ap_rst_n(ap_rst_n_0_1),
        .in0_V_TDATA(StreamingDataflowPartition_1_MVAU_hls_4_out_V_TDATA),
        .in0_V_TREADY(StreamingDataflowPartition_1_MVAU_hls_4_out_V_TREADY),
        .in0_V_TVALID(StreamingDataflowPartition_1_MVAU_hls_4_out_V_TVALID),
        .out_V_TDATA(StreamingDataflowPartition_1_StreamingDataWidthConverter_rtl_7_out_V_TDATA),
        .out_V_TREADY(StreamingDataflowPartition_1_StreamingDataWidthConverter_rtl_7_out_V_TREADY),
        .out_V_TVALID(StreamingDataflowPartition_1_StreamingDataWidthConverter_rtl_7_out_V_TVALID));
  StreamingDataflowPartition_1_StreamingDataflowPartition_1_StreamingDataWidthConverter_rtl_8_0 StreamingDataflowPartition_1_StreamingDataWidthConverter_rtl_8
       (.ap_clk(ap_clk_0_1),
        .ap_rst_n(ap_rst_n_0_1),
        .in0_V_TDATA(StreamingDataflowPartition_1_MVAU_hls_5_out_V_TDATA),
        .in0_V_TREADY(StreamingDataflowPartition_1_MVAU_hls_5_out_V_TREADY),
        .in0_V_TVALID(StreamingDataflowPartition_1_MVAU_hls_5_out_V_TVALID),
        .out_V_TDATA(StreamingDataflowPartition_1_StreamingDataWidthConverter_rtl_8_out_V_TDATA),
        .out_V_TREADY(StreamingDataflowPartition_1_StreamingDataWidthConverter_rtl_8_out_V_TREADY),
        .out_V_TVALID(StreamingDataflowPartition_1_StreamingDataWidthConverter_rtl_8_out_V_TVALID));
  StreamingDataflowPartition_1_StreamingDataflowPartition_1_StreamingDataWidthConverter_rtl_9_0 StreamingDataflowPartition_1_StreamingDataWidthConverter_rtl_9
       (.ap_clk(ap_clk_0_1),
        .ap_rst_n(ap_rst_n_0_1),
        .in0_V_TDATA(StreamingDataflowPartition_1_MVAU_hls_6_out_V_TDATA),
        .in0_V_TREADY(StreamingDataflowPartition_1_MVAU_hls_6_out_V_TREADY),
        .in0_V_TVALID(StreamingDataflowPartition_1_MVAU_hls_6_out_V_TVALID),
        .out_V_TDATA(StreamingDataflowPartition_1_StreamingDataWidthConverter_rtl_9_out_V_TDATA),
        .out_V_TREADY(StreamingDataflowPartition_1_StreamingDataWidthConverter_rtl_9_out_V_TREADY),
        .out_V_TVALID(StreamingDataflowPartition_1_StreamingDataWidthConverter_rtl_9_out_V_TVALID));
  StreamingDataflowPartition_1_StreamingDataflowPartition_1_StreamingFIFO_rtl_0_0 StreamingDataflowPartition_1_StreamingFIFO_rtl_0
       (.ap_clk(ap_clk_0_1),
        .ap_rst_n(ap_rst_n_0_1),
        .in0_V_TDATA(StreamingDataflowPartition_1_ConvolutionInputGenerator_rtl_0_out_V_TDATA),
        .in0_V_TREADY(StreamingDataflowPartition_1_ConvolutionInputGenerator_rtl_0_out_V_TREADY),
        .in0_V_TVALID(StreamingDataflowPartition_1_ConvolutionInputGenerator_rtl_0_out_V_TVALID),
        .out_V_TDATA(StreamingDataflowPartition_1_StreamingFIFO_rtl_0_out_V_TDATA),
        .out_V_TREADY(StreamingDataflowPartition_1_StreamingFIFO_rtl_0_out_V_TREADY),
        .out_V_TVALID(StreamingDataflowPartition_1_StreamingFIFO_rtl_0_out_V_TVALID));
  StreamingDataflowPartition_1_StreamingDataflowPartition_1_StreamingFIFO_rtl_1_0 StreamingDataflowPartition_1_StreamingFIFO_rtl_1
       (.ap_clk(ap_clk_0_1),
        .ap_rst_n(ap_rst_n_0_1),
        .in0_V_TDATA(StreamingDataflowPartition_1_ConvolutionInputGenerator_rtl_1_out_V_TDATA),
        .in0_V_TREADY(StreamingDataflowPartition_1_ConvolutionInputGenerator_rtl_1_out_V_TREADY),
        .in0_V_TVALID(StreamingDataflowPartition_1_ConvolutionInputGenerator_rtl_1_out_V_TVALID),
        .out_V_TDATA(StreamingDataflowPartition_1_StreamingFIFO_rtl_1_out_V_TDATA),
        .out_V_TREADY(StreamingDataflowPartition_1_StreamingFIFO_rtl_1_out_V_TREADY),
        .out_V_TVALID(StreamingDataflowPartition_1_StreamingFIFO_rtl_1_out_V_TVALID));
  StreamingDataflowPartition_1_StreamingDataflowPartition_1_StreamingFIFO_rtl_2_0 StreamingDataflowPartition_1_StreamingFIFO_rtl_2
       (.ap_clk(ap_clk_0_1),
        .ap_rst_n(ap_rst_n_0_1),
        .in0_V_TDATA(StreamingDataflowPartition_1_ConvolutionInputGenerator_rtl_2_out_V_TDATA),
        .in0_V_TREADY(StreamingDataflowPartition_1_ConvolutionInputGenerator_rtl_2_out_V_TREADY),
        .in0_V_TVALID(StreamingDataflowPartition_1_ConvolutionInputGenerator_rtl_2_out_V_TVALID),
        .out_V_TDATA(StreamingDataflowPartition_1_StreamingFIFO_rtl_2_out_V_TDATA),
        .out_V_TREADY(StreamingDataflowPartition_1_StreamingFIFO_rtl_2_out_V_TREADY),
        .out_V_TVALID(StreamingDataflowPartition_1_StreamingFIFO_rtl_2_out_V_TVALID));
  StreamingDataflowPartition_1_StreamingDataflowPartition_1_StreamingFIFO_rtl_3_0 StreamingDataflowPartition_1_StreamingFIFO_rtl_3
       (.ap_clk(ap_clk_0_1),
        .ap_rst_n(ap_rst_n_0_1),
        .in0_V_TDATA(StreamingDataflowPartition_1_ConvolutionInputGenerator_rtl_3_out_V_TDATA),
        .in0_V_TREADY(StreamingDataflowPartition_1_ConvolutionInputGenerator_rtl_3_out_V_TREADY),
        .in0_V_TVALID(StreamingDataflowPartition_1_ConvolutionInputGenerator_rtl_3_out_V_TVALID),
        .out_V_TDATA(StreamingDataflowPartition_1_StreamingFIFO_rtl_3_out_V_TDATA),
        .out_V_TREADY(StreamingDataflowPartition_1_StreamingFIFO_rtl_3_out_V_TREADY),
        .out_V_TVALID(StreamingDataflowPartition_1_StreamingFIFO_rtl_3_out_V_TVALID));
  StreamingDataflowPartition_1_StreamingDataflowPartition_1_StreamingFIFO_rtl_4_0 StreamingDataflowPartition_1_StreamingFIFO_rtl_4
       (.ap_clk(ap_clk_0_1),
        .ap_rst_n(ap_rst_n_0_1),
        .in0_V_TDATA(StreamingDataflowPartition_1_ConvolutionInputGenerator_rtl_4_out_V_TDATA),
        .in0_V_TREADY(StreamingDataflowPartition_1_ConvolutionInputGenerator_rtl_4_out_V_TREADY),
        .in0_V_TVALID(StreamingDataflowPartition_1_ConvolutionInputGenerator_rtl_4_out_V_TVALID),
        .out_V_TDATA(StreamingDataflowPartition_1_StreamingFIFO_rtl_4_out_V_TDATA),
        .out_V_TREADY(StreamingDataflowPartition_1_StreamingFIFO_rtl_4_out_V_TREADY),
        .out_V_TVALID(StreamingDataflowPartition_1_StreamingFIFO_rtl_4_out_V_TVALID));
  StreamingDataflowPartition_1_StreamingDataflowPartition_1_StreamingFIFO_rtl_5_0 StreamingDataflowPartition_1_StreamingFIFO_rtl_5
       (.ap_clk(ap_clk_0_1),
        .ap_rst_n(ap_rst_n_0_1),
        .in0_V_TDATA(StreamingDataflowPartition_1_StreamingDataWidthConverter_rtl_9_out_V_TDATA),
        .in0_V_TREADY(StreamingDataflowPartition_1_StreamingDataWidthConverter_rtl_9_out_V_TREADY),
        .in0_V_TVALID(StreamingDataflowPartition_1_StreamingDataWidthConverter_rtl_9_out_V_TVALID),
        .out_V_TDATA(StreamingDataflowPartition_1_StreamingFIFO_rtl_5_out_V_TDATA),
        .out_V_TREADY(StreamingDataflowPartition_1_StreamingFIFO_rtl_5_out_V_TREADY),
        .out_V_TVALID(StreamingDataflowPartition_1_StreamingFIFO_rtl_5_out_V_TVALID));
  StreamingDataflowPartition_1_StreamingDataflowPartition_1_StreamingFIFO_rtl_6_0 StreamingDataflowPartition_1_StreamingFIFO_rtl_6
       (.ap_clk(ap_clk_0_1),
        .ap_rst_n(ap_rst_n_0_1),
        .in0_V_TDATA(StreamingDataflowPartition_1_MVAU_hls_7_out_V_TDATA),
        .in0_V_TREADY(StreamingDataflowPartition_1_MVAU_hls_7_out_V_TREADY),
        .in0_V_TVALID(StreamingDataflowPartition_1_MVAU_hls_7_out_V_TVALID),
        .out_V_TDATA(StreamingDataflowPartition_1_StreamingFIFO_rtl_6_out_V_TDATA),
        .out_V_TREADY(StreamingDataflowPartition_1_StreamingFIFO_rtl_6_out_V_TREADY),
        .out_V_TVALID(StreamingDataflowPartition_1_StreamingFIFO_rtl_6_out_V_TVALID));
  StreamingDataflowPartition_1_StreamingDataflowPartition_1_StreamingMaxPool_hls_0_0 StreamingDataflowPartition_1_StreamingMaxPool_hls_0
       (.ap_clk(ap_clk_0_1),
        .ap_rst_n(ap_rst_n_0_1),
        .in0_V_TDATA(StreamingDataflowPartition_1_StreamingDataWidthConverter_rtl_2_out_V_TDATA),
        .in0_V_TREADY(StreamingDataflowPartition_1_StreamingDataWidthConverter_rtl_2_out_V_TREADY),
        .in0_V_TVALID(StreamingDataflowPartition_1_StreamingDataWidthConverter_rtl_2_out_V_TVALID),
        .out_V_TDATA(StreamingDataflowPartition_1_StreamingMaxPool_hls_0_out_V_TDATA),
        .out_V_TREADY(StreamingDataflowPartition_1_StreamingMaxPool_hls_0_out_V_TREADY),
        .out_V_TVALID(StreamingDataflowPartition_1_StreamingMaxPool_hls_0_out_V_TVALID));
  StreamingDataflowPartition_1_StreamingDataflowPartition_1_StreamingMaxPool_hls_1_0 StreamingDataflowPartition_1_StreamingMaxPool_hls_1
       (.ap_clk(ap_clk_0_1),
        .ap_rst_n(ap_rst_n_0_1),
        .in0_V_TDATA(StreamingDataflowPartition_1_StreamingDataWidthConverter_rtl_5_out_V_TDATA),
        .in0_V_TREADY(StreamingDataflowPartition_1_StreamingDataWidthConverter_rtl_5_out_V_TREADY),
        .in0_V_TVALID(StreamingDataflowPartition_1_StreamingDataWidthConverter_rtl_5_out_V_TVALID),
        .out_V_TDATA(StreamingDataflowPartition_1_StreamingMaxPool_hls_1_out_V_TDATA),
        .out_V_TREADY(StreamingDataflowPartition_1_StreamingMaxPool_hls_1_out_V_TREADY),
        .out_V_TVALID(StreamingDataflowPartition_1_StreamingMaxPool_hls_1_out_V_TVALID));
  StreamingDataflowPartition_1_StreamingDataflowPartition_1_Thresholding_rtl_0_0 StreamingDataflowPartition_1_Thresholding_rtl_0
       (.ap_clk(ap_clk_0_1),
        .ap_rst_n(ap_rst_n_0_1),
        .in0_V_TDATA(in0_V_0_1_TDATA),
        .in0_V_TREADY(in0_V_0_1_TREADY),
        .in0_V_TVALID(in0_V_0_1_TVALID),
        .out_V_TDATA(StreamingDataflowPartition_1_Thresholding_rtl_0_out_V_TDATA),
        .out_V_TREADY(StreamingDataflowPartition_1_Thresholding_rtl_0_out_V_TREADY),
        .out_V_TVALID(StreamingDataflowPartition_1_Thresholding_rtl_0_out_V_TVALID),
        .s_axilite_ARADDR({1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0}),
        .s_axilite_ARVALID(1'b0),
        .s_axilite_AWADDR({1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0}),
        .s_axilite_AWVALID(1'b0),
        .s_axilite_BREADY(1'b0),
        .s_axilite_RREADY(1'b0),
        .s_axilite_WDATA({1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0}),
        .s_axilite_WSTRB({1'b1,1'b1,1'b1,1'b1}),
        .s_axilite_WVALID(1'b0));
endmodule

module StreamingDataflowPartition_1_MVAU_hls_0_imp_BWPU8W
   (ap_clk,
    ap_rst_n,
    in0_V_tdata,
    in0_V_tready,
    in0_V_tvalid,
    out_V_tdata,
    out_V_tready,
    out_V_tvalid);
  input ap_clk;
  input ap_rst_n;
  input [23:0]in0_V_tdata;
  output in0_V_tready;
  input in0_V_tvalid;
  output [15:0]out_V_tdata;
  input out_V_tready;
  output out_V_tvalid;

  wire [15:0]StreamingDataflowPartition_1_MVAU_hls_0_out_V_TDATA;
  wire StreamingDataflowPartition_1_MVAU_hls_0_out_V_TREADY;
  wire StreamingDataflowPartition_1_MVAU_hls_0_out_V_TVALID;
  wire [47:0]StreamingDataflowPartition_1_MVAU_hls_0_wstrm_m_axis_0_TDATA;
  wire StreamingDataflowPartition_1_MVAU_hls_0_wstrm_m_axis_0_TREADY;
  wire StreamingDataflowPartition_1_MVAU_hls_0_wstrm_m_axis_0_TVALID;
  wire ap_clk_1;
  wire ap_rst_n_1;
  wire [23:0]in0_V_1_TDATA;
  wire in0_V_1_TREADY;
  wire in0_V_1_TVALID;

  assign StreamingDataflowPartition_1_MVAU_hls_0_out_V_TREADY = out_V_tready;
  assign ap_clk_1 = ap_clk;
  assign ap_rst_n_1 = ap_rst_n;
  assign in0_V_1_TDATA = in0_V_tdata[23:0];
  assign in0_V_1_TVALID = in0_V_tvalid;
  assign in0_V_tready = in0_V_1_TREADY;
  assign out_V_tdata[15:0] = StreamingDataflowPartition_1_MVAU_hls_0_out_V_TDATA;
  assign out_V_tvalid = StreamingDataflowPartition_1_MVAU_hls_0_out_V_TVALID;
  StreamingDataflowPartition_1_StreamingDataflowPartition_1_MVAU_hls_0_0 StreamingDataflowPartition_1_MVAU_hls_0
       (.ap_clk(ap_clk_1),
        .ap_rst_n(ap_rst_n_1),
        .in0_V_TDATA(in0_V_1_TDATA),
        .in0_V_TREADY(in0_V_1_TREADY),
        .in0_V_TVALID(in0_V_1_TVALID),
        .out_V_TDATA(StreamingDataflowPartition_1_MVAU_hls_0_out_V_TDATA),
        .out_V_TREADY(StreamingDataflowPartition_1_MVAU_hls_0_out_V_TREADY),
        .out_V_TVALID(StreamingDataflowPartition_1_MVAU_hls_0_out_V_TVALID),
        .weights_V_TDATA(StreamingDataflowPartition_1_MVAU_hls_0_wstrm_m_axis_0_TDATA),
        .weights_V_TREADY(StreamingDataflowPartition_1_MVAU_hls_0_wstrm_m_axis_0_TREADY),
        .weights_V_TVALID(StreamingDataflowPartition_1_MVAU_hls_0_wstrm_m_axis_0_TVALID));
  StreamingDataflowPartition_1_StreamingDataflowPartition_1_MVAU_hls_0_wstrm_0 StreamingDataflowPartition_1_MVAU_hls_0_wstrm
       (.ap_clk(ap_clk_1),
        .ap_rst_n(ap_rst_n_1),
        .araddr({1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0}),
        .arprot({1'b0,1'b0,1'b0}),
        .arvalid(1'b0),
        .awaddr({1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0}),
        .awprot({1'b0,1'b0,1'b0}),
        .awvalid(1'b0),
        .bready(1'b0),
        .m_axis_0_tdata(StreamingDataflowPartition_1_MVAU_hls_0_wstrm_m_axis_0_TDATA),
        .m_axis_0_tready(StreamingDataflowPartition_1_MVAU_hls_0_wstrm_m_axis_0_TREADY),
        .m_axis_0_tvalid(StreamingDataflowPartition_1_MVAU_hls_0_wstrm_m_axis_0_TVALID),
        .rready(1'b0),
        .wdata({1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0}),
        .wstrb({1'b1,1'b1,1'b1,1'b1}),
        .wvalid(1'b0));
endmodule

module StreamingDataflowPartition_1_MVAU_hls_1_imp_KIE98K
   (ap_clk,
    ap_rst_n,
    in0_V_tdata,
    in0_V_tready,
    in0_V_tvalid,
    out_V_tdata,
    out_V_tready,
    out_V_tvalid);
  input ap_clk;
  input ap_rst_n;
  input [31:0]in0_V_tdata;
  output in0_V_tready;
  input in0_V_tvalid;
  output [31:0]out_V_tdata;
  input out_V_tready;
  output out_V_tvalid;

  wire [31:0]StreamingDataflowPartition_1_MVAU_hls_1_out_V_TDATA;
  wire StreamingDataflowPartition_1_MVAU_hls_1_out_V_TREADY;
  wire StreamingDataflowPartition_1_MVAU_hls_1_out_V_TVALID;
  wire [1023:0]StreamingDataflowPartition_1_MVAU_hls_1_wstrm_m_axis_0_TDATA;
  wire StreamingDataflowPartition_1_MVAU_hls_1_wstrm_m_axis_0_TREADY;
  wire StreamingDataflowPartition_1_MVAU_hls_1_wstrm_m_axis_0_TVALID;
  wire ap_clk_1;
  wire ap_rst_n_1;
  wire [31:0]in0_V_1_TDATA;
  wire in0_V_1_TREADY;
  wire in0_V_1_TVALID;

  assign StreamingDataflowPartition_1_MVAU_hls_1_out_V_TREADY = out_V_tready;
  assign ap_clk_1 = ap_clk;
  assign ap_rst_n_1 = ap_rst_n;
  assign in0_V_1_TDATA = in0_V_tdata[31:0];
  assign in0_V_1_TVALID = in0_V_tvalid;
  assign in0_V_tready = in0_V_1_TREADY;
  assign out_V_tdata[31:0] = StreamingDataflowPartition_1_MVAU_hls_1_out_V_TDATA;
  assign out_V_tvalid = StreamingDataflowPartition_1_MVAU_hls_1_out_V_TVALID;
  MVAU1_Super_Wrapper StreamingDataflowPartition_1_MVAU_hls_1
       (.ap_clk(ap_clk_1),
        .ap_rst_n(ap_rst_n_1),
        .in0_V_TDATA(in0_V_1_TDATA),
        .in0_V_TREADY(in0_V_1_TREADY),
        .in0_V_TVALID(in0_V_1_TVALID),
        .out_V_TDATA(StreamingDataflowPartition_1_MVAU_hls_1_out_V_TDATA),
        .out_V_TREADY(StreamingDataflowPartition_1_MVAU_hls_1_out_V_TREADY),
        .out_V_TVALID(StreamingDataflowPartition_1_MVAU_hls_1_out_V_TVALID),
        .weights_V_TDATA(StreamingDataflowPartition_1_MVAU_hls_1_wstrm_m_axis_0_TDATA),
        .weights_V_TREADY(StreamingDataflowPartition_1_MVAU_hls_1_wstrm_m_axis_0_TREADY),
        .weights_V_TVALID(StreamingDataflowPartition_1_MVAU_hls_1_wstrm_m_axis_0_TVALID));
  StreamingDataflowPartition_1_StreamingDataflowPartition_1_MVAU_hls_1_wstrm_0 StreamingDataflowPartition_1_MVAU_hls_1_wstrm
       (.ap_clk(ap_clk_1),
        .ap_rst_n(ap_rst_n_1),
        .araddr({1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0}),
        .arprot({1'b0,1'b0,1'b0}),
        .arvalid(1'b0),
        .awaddr({1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0}),
        .awprot({1'b0,1'b0,1'b0}),
        .awvalid(1'b0),
        .bready(1'b0),
        .m_axis_0_tdata(StreamingDataflowPartition_1_MVAU_hls_1_wstrm_m_axis_0_TDATA),
        .m_axis_0_tready(StreamingDataflowPartition_1_MVAU_hls_1_wstrm_m_axis_0_TREADY),
        .m_axis_0_tvalid(StreamingDataflowPartition_1_MVAU_hls_1_wstrm_m_axis_0_TVALID),
        .rready(1'b0),
        .wdata({1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0}),
        .wstrb({1'b1,1'b1,1'b1,1'b1}),
        .wvalid(1'b0));
endmodule

module StreamingDataflowPartition_1_MVAU_hls_2_imp_1TQ8MQW
   (ap_clk,
    ap_rst_n,
    in0_V_tdata,
    in0_V_tready,
    in0_V_tvalid,
    out_V_tdata,
    out_V_tready,
    out_V_tvalid);
  input ap_clk;
  input ap_rst_n;
  input [31:0]in0_V_tdata;
  output in0_V_tready;
  input in0_V_tvalid;
  output [15:0]out_V_tdata;
  input out_V_tready;
  output out_V_tvalid;

  wire [15:0]StreamingDataflowPartition_1_MVAU_hls_2_out_V_TDATA;
  wire StreamingDataflowPartition_1_MVAU_hls_2_out_V_TREADY;
  wire StreamingDataflowPartition_1_MVAU_hls_2_out_V_TVALID;
  wire [511:0]StreamingDataflowPartition_1_MVAU_hls_2_wstrm_m_axis_0_TDATA;
  wire StreamingDataflowPartition_1_MVAU_hls_2_wstrm_m_axis_0_TREADY;
  wire StreamingDataflowPartition_1_MVAU_hls_2_wstrm_m_axis_0_TVALID;
  wire ap_clk_1;
  wire ap_rst_n_1;
  wire [31:0]in0_V_1_TDATA;
  wire in0_V_1_TREADY;
  wire in0_V_1_TVALID;

  assign StreamingDataflowPartition_1_MVAU_hls_2_out_V_TREADY = out_V_tready;
  assign ap_clk_1 = ap_clk;
  assign ap_rst_n_1 = ap_rst_n;
  assign in0_V_1_TDATA = in0_V_tdata[31:0];
  assign in0_V_1_TVALID = in0_V_tvalid;
  assign in0_V_tready = in0_V_1_TREADY;
  assign out_V_tdata[15:0] = StreamingDataflowPartition_1_MVAU_hls_2_out_V_TDATA;
  assign out_V_tvalid = StreamingDataflowPartition_1_MVAU_hls_2_out_V_TVALID;
  MVAU2_Super_Wrapper StreamingDataflowPartition_1_MVAU_hls_2
       (.ap_clk(ap_clk_1),
        .ap_rst_n(ap_rst_n_1),
        .in0_V_TDATA(in0_V_1_TDATA),
        .in0_V_TREADY(in0_V_1_TREADY),
        .in0_V_TVALID(in0_V_1_TVALID),
        .out_V_TDATA(StreamingDataflowPartition_1_MVAU_hls_2_out_V_TDATA),
        .out_V_TREADY(StreamingDataflowPartition_1_MVAU_hls_2_out_V_TREADY),
        .out_V_TVALID(StreamingDataflowPartition_1_MVAU_hls_2_out_V_TVALID),
        .weights_V_TDATA(StreamingDataflowPartition_1_MVAU_hls_2_wstrm_m_axis_0_TDATA),
        .weights_V_TREADY(StreamingDataflowPartition_1_MVAU_hls_2_wstrm_m_axis_0_TREADY),
        .weights_V_TVALID(StreamingDataflowPartition_1_MVAU_hls_2_wstrm_m_axis_0_TVALID));
  StreamingDataflowPartition_1_StreamingDataflowPartition_1_MVAU_hls_2_wstrm_0 StreamingDataflowPartition_1_MVAU_hls_2_wstrm
       (.ap_clk(ap_clk_1),
        .ap_rst_n(ap_rst_n_1),
        .araddr({1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0}),
        .arprot({1'b0,1'b0,1'b0}),
        .arvalid(1'b0),
        .awaddr({1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0}),
        .awprot({1'b0,1'b0,1'b0}),
        .awvalid(1'b0),
        .bready(1'b0),
        .m_axis_0_tdata(StreamingDataflowPartition_1_MVAU_hls_2_wstrm_m_axis_0_TDATA),
        .m_axis_0_tready(StreamingDataflowPartition_1_MVAU_hls_2_wstrm_m_axis_0_TREADY),
        .m_axis_0_tvalid(StreamingDataflowPartition_1_MVAU_hls_2_wstrm_m_axis_0_TVALID),
        .rready(1'b0),
        .wdata({1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0}),
        .wstrb({1'b1,1'b1,1'b1,1'b1}),
        .wvalid(1'b0));
endmodule

module StreamingDataflowPartition_1_MVAU_hls_3_imp_13XA618
   (ap_clk,
    ap_rst_n,
    in0_V_tdata,
    in0_V_tready,
    in0_V_tvalid,
    out_V_tdata,
    out_V_tready,
    out_V_tvalid);
  input ap_clk;
  input ap_rst_n;
  input [31:0]in0_V_tdata;
  output in0_V_tready;
  input in0_V_tvalid;
  output [15:0]out_V_tdata;
  input out_V_tready;
  output out_V_tvalid;

  wire [15:0]StreamingDataflowPartition_1_MVAU_hls_3_out_V_TDATA;
  wire StreamingDataflowPartition_1_MVAU_hls_3_out_V_TREADY;
  wire StreamingDataflowPartition_1_MVAU_hls_3_out_V_TVALID;
  wire [511:0]StreamingDataflowPartition_1_MVAU_hls_3_wstrm_m_axis_0_TDATA;
  wire StreamingDataflowPartition_1_MVAU_hls_3_wstrm_m_axis_0_TREADY;
  wire StreamingDataflowPartition_1_MVAU_hls_3_wstrm_m_axis_0_TVALID;
  wire ap_clk_1;
  wire ap_rst_n_1;
  wire [31:0]in0_V_1_TDATA;
  wire in0_V_1_TREADY;
  wire in0_V_1_TVALID;

  assign StreamingDataflowPartition_1_MVAU_hls_3_out_V_TREADY = out_V_tready;
  assign ap_clk_1 = ap_clk;
  assign ap_rst_n_1 = ap_rst_n;
  assign in0_V_1_TDATA = in0_V_tdata[31:0];
  assign in0_V_1_TVALID = in0_V_tvalid;
  assign in0_V_tready = in0_V_1_TREADY;
  assign out_V_tdata[15:0] = StreamingDataflowPartition_1_MVAU_hls_3_out_V_TDATA;
  assign out_V_tvalid = StreamingDataflowPartition_1_MVAU_hls_3_out_V_TVALID;
  MVAU3_Super_Wrapper StreamingDataflowPartition_1_MVAU_hls_3
       (.ap_clk(ap_clk_1),
        .ap_rst_n(ap_rst_n_1),
        .in0_V_TDATA(in0_V_1_TDATA),
        .in0_V_TREADY(in0_V_1_TREADY),
        .in0_V_TVALID(in0_V_1_TVALID),
        .out_V_TDATA(StreamingDataflowPartition_1_MVAU_hls_3_out_V_TDATA),
        .out_V_TREADY(StreamingDataflowPartition_1_MVAU_hls_3_out_V_TREADY),
        .out_V_TVALID(StreamingDataflowPartition_1_MVAU_hls_3_out_V_TVALID),
        .weights_V_TDATA(StreamingDataflowPartition_1_MVAU_hls_3_wstrm_m_axis_0_TDATA),
        .weights_V_TREADY(StreamingDataflowPartition_1_MVAU_hls_3_wstrm_m_axis_0_TREADY),
        .weights_V_TVALID(StreamingDataflowPartition_1_MVAU_hls_3_wstrm_m_axis_0_TVALID));
  StreamingDataflowPartition_1_StreamingDataflowPartition_1_MVAU_hls_3_wstrm_0 StreamingDataflowPartition_1_MVAU_hls_3_wstrm
       (.ap_clk(ap_clk_1),
        .ap_rst_n(ap_rst_n_1),
        .araddr({1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0}),
        .arprot({1'b0,1'b0,1'b0}),
        .arvalid(1'b0),
        .awaddr({1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0}),
        .awprot({1'b0,1'b0,1'b0}),
        .awvalid(1'b0),
        .bready(1'b0),
        .m_axis_0_tdata(StreamingDataflowPartition_1_MVAU_hls_3_wstrm_m_axis_0_TDATA),
        .m_axis_0_tready(StreamingDataflowPartition_1_MVAU_hls_3_wstrm_m_axis_0_TREADY),
        .m_axis_0_tvalid(StreamingDataflowPartition_1_MVAU_hls_3_wstrm_m_axis_0_TVALID),
        .rready(1'b0),
        .wdata({1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0}),
        .wstrb({1'b1,1'b1,1'b1,1'b1}),
        .wvalid(1'b0));
endmodule

module StreamingDataflowPartition_1_MVAU_hls_4_imp_YTTEI9
   (ap_clk,
    ap_rst_n,
    in0_V_tdata,
    in0_V_tready,
    in0_V_tvalid,
    out_V_tdata,
    out_V_tready,
    out_V_tvalid);
  input ap_clk;
  input ap_rst_n;
  input [31:0]in0_V_tdata;
  output in0_V_tready;
  input in0_V_tvalid;
  output [7:0]out_V_tdata;
  input out_V_tready;
  output out_V_tvalid;

  wire [7:0]StreamingDataflowPartition_1_MVAU_hls_4_out_V_TDATA;
  wire StreamingDataflowPartition_1_MVAU_hls_4_out_V_TREADY;
  wire StreamingDataflowPartition_1_MVAU_hls_4_out_V_TVALID;
  wire [127:0]StreamingDataflowPartition_1_MVAU_hls_4_wstrm_m_axis_0_TDATA;
  wire StreamingDataflowPartition_1_MVAU_hls_4_wstrm_m_axis_0_TREADY;
  wire StreamingDataflowPartition_1_MVAU_hls_4_wstrm_m_axis_0_TVALID;
  wire ap_clk_1;
  wire ap_rst_n_1;
  wire [31:0]in0_V_1_TDATA;
  wire in0_V_1_TREADY;
  wire in0_V_1_TVALID;

  assign StreamingDataflowPartition_1_MVAU_hls_4_out_V_TREADY = out_V_tready;
  assign ap_clk_1 = ap_clk;
  assign ap_rst_n_1 = ap_rst_n;
  assign in0_V_1_TDATA = in0_V_tdata[31:0];
  assign in0_V_1_TVALID = in0_V_tvalid;
  assign in0_V_tready = in0_V_1_TREADY;
  assign out_V_tdata[7:0] = StreamingDataflowPartition_1_MVAU_hls_4_out_V_TDATA;
  assign out_V_tvalid = StreamingDataflowPartition_1_MVAU_hls_4_out_V_TVALID;
  MVAU4_Super_Wrapper StreamingDataflowPartition_1_MVAU_hls_4
       (.ap_clk(ap_clk_1),
        .ap_rst_n(ap_rst_n_1),
        .in0_V_TDATA(in0_V_1_TDATA),
        .in0_V_TREADY(in0_V_1_TREADY),
        .in0_V_TVALID(in0_V_1_TVALID),
        .out_V_TDATA(StreamingDataflowPartition_1_MVAU_hls_4_out_V_TDATA),
        .out_V_TREADY(StreamingDataflowPartition_1_MVAU_hls_4_out_V_TREADY),
        .out_V_TVALID(StreamingDataflowPartition_1_MVAU_hls_4_out_V_TVALID),
        .weights_V_TDATA(StreamingDataflowPartition_1_MVAU_hls_4_wstrm_m_axis_0_TDATA),
        .weights_V_TREADY(StreamingDataflowPartition_1_MVAU_hls_4_wstrm_m_axis_0_TREADY),
        .weights_V_TVALID(StreamingDataflowPartition_1_MVAU_hls_4_wstrm_m_axis_0_TVALID));
  StreamingDataflowPartition_1_StreamingDataflowPartition_1_MVAU_hls_4_wstrm_0 StreamingDataflowPartition_1_MVAU_hls_4_wstrm
       (.ap_clk(ap_clk_1),
        .ap_rst_n(ap_rst_n_1),
        .araddr({1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0}),
        .arprot({1'b0,1'b0,1'b0}),
        .arvalid(1'b0),
        .awaddr({1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0}),
        .awprot({1'b0,1'b0,1'b0}),
        .awvalid(1'b0),
        .bready(1'b0),
        .m_axis_0_tdata(StreamingDataflowPartition_1_MVAU_hls_4_wstrm_m_axis_0_TDATA),
        .m_axis_0_tready(StreamingDataflowPartition_1_MVAU_hls_4_wstrm_m_axis_0_TREADY),
        .m_axis_0_tvalid(StreamingDataflowPartition_1_MVAU_hls_4_wstrm_m_axis_0_TVALID),
        .rready(1'b0),
        .wdata({1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0}),
        .wstrb({1'b1,1'b1,1'b1,1'b1}),
        .wvalid(1'b0));
endmodule

module StreamingDataflowPartition_1_MVAU_hls_5_imp_8GQNPX
   (ap_clk,
    ap_rst_n,
    in0_V_tdata,
    in0_V_tready,
    in0_V_tvalid,
    out_V_tdata,
    out_V_tready,
    out_V_tvalid);
  input ap_clk;
  input ap_rst_n;
  input [31:0]in0_V_tdata;
  output in0_V_tready;
  input in0_V_tvalid;
  output [7:0]out_V_tdata;
  input out_V_tready;
  output out_V_tvalid;

  wire [7:0]StreamingDataflowPartition_1_MVAU_hls_5_out_V_TDATA;
  wire StreamingDataflowPartition_1_MVAU_hls_5_out_V_TREADY;
  wire StreamingDataflowPartition_1_MVAU_hls_5_out_V_TVALID;
  wire [31:0]StreamingDataflowPartition_1_MVAU_hls_5_wstrm_m_axis_0_TDATA;
  wire StreamingDataflowPartition_1_MVAU_hls_5_wstrm_m_axis_0_TREADY;
  wire StreamingDataflowPartition_1_MVAU_hls_5_wstrm_m_axis_0_TVALID;
  wire ap_clk_1;
  wire ap_rst_n_1;
  wire [31:0]in0_V_1_TDATA;
  wire in0_V_1_TREADY;
  wire in0_V_1_TVALID;

  assign StreamingDataflowPartition_1_MVAU_hls_5_out_V_TREADY = out_V_tready;
  assign ap_clk_1 = ap_clk;
  assign ap_rst_n_1 = ap_rst_n;
  assign in0_V_1_TDATA = in0_V_tdata[31:0];
  assign in0_V_1_TVALID = in0_V_tvalid;
  assign in0_V_tready = in0_V_1_TREADY;
  assign out_V_tdata[7:0] = StreamingDataflowPartition_1_MVAU_hls_5_out_V_TDATA;
  assign out_V_tvalid = StreamingDataflowPartition_1_MVAU_hls_5_out_V_TVALID;
  MVAU5_Super_Wrapper StreamingDataflowPartition_1_MVAU_hls_5
       (.ap_clk(ap_clk_1),
        .ap_rst_n(ap_rst_n_1),
        .in0_V_TDATA(in0_V_1_TDATA),
        .in0_V_TREADY(in0_V_1_TREADY),
        .in0_V_TVALID(in0_V_1_TVALID),
        .out_V_TDATA(StreamingDataflowPartition_1_MVAU_hls_5_out_V_TDATA),
        .out_V_TREADY(StreamingDataflowPartition_1_MVAU_hls_5_out_V_TREADY),
        .out_V_TVALID(StreamingDataflowPartition_1_MVAU_hls_5_out_V_TVALID),
        .weights_V_TDATA(StreamingDataflowPartition_1_MVAU_hls_5_wstrm_m_axis_0_TDATA),
        .weights_V_TREADY(StreamingDataflowPartition_1_MVAU_hls_5_wstrm_m_axis_0_TREADY),
        .weights_V_TVALID(StreamingDataflowPartition_1_MVAU_hls_5_wstrm_m_axis_0_TVALID));
  StreamingDataflowPartition_1_StreamingDataflowPartition_1_MVAU_hls_5_wstrm_0 StreamingDataflowPartition_1_MVAU_hls_5_wstrm
       (.ap_clk(ap_clk_1),
        .ap_rst_n(ap_rst_n_1),
        .araddr({1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0}),
        .arprot({1'b0,1'b0,1'b0}),
        .arvalid(1'b0),
        .awaddr({1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0}),
        .awprot({1'b0,1'b0,1'b0}),
        .awvalid(1'b0),
        .bready(1'b0),
        .m_axis_0_tdata(StreamingDataflowPartition_1_MVAU_hls_5_wstrm_m_axis_0_TDATA),
        .m_axis_0_tready(StreamingDataflowPartition_1_MVAU_hls_5_wstrm_m_axis_0_TREADY),
        .m_axis_0_tvalid(StreamingDataflowPartition_1_MVAU_hls_5_wstrm_m_axis_0_TVALID),
        .rready(1'b0),
        .wdata({1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0}),
        .wstrb({1'b1,1'b1,1'b1,1'b1}),
        .wvalid(1'b0));
endmodule

module StreamingDataflowPartition_1_MVAU_hls_6_imp_1G1A9YX
   (ap_clk,
    ap_rst_n,
    in0_V_tdata,
    in0_V_tready,
    in0_V_tvalid,
    out_V_tdata,
    out_V_tready,
    out_V_tvalid);
  input ap_clk;
  input ap_rst_n;
  input [7:0]in0_V_tdata;
  output in0_V_tready;
  input in0_V_tvalid;
  output [7:0]out_V_tdata;
  input out_V_tready;
  output out_V_tvalid;

  wire [7:0]StreamingDataflowPartition_1_MVAU_hls_6_out_V_TDATA;
  wire StreamingDataflowPartition_1_MVAU_hls_6_out_V_TREADY;
  wire StreamingDataflowPartition_1_MVAU_hls_6_out_V_TVALID;
  wire [7:0]StreamingDataflowPartition_1_MVAU_hls_6_wstrm_m_axis_0_TDATA;
  wire StreamingDataflowPartition_1_MVAU_hls_6_wstrm_m_axis_0_TREADY;
  wire StreamingDataflowPartition_1_MVAU_hls_6_wstrm_m_axis_0_TVALID;
  wire ap_clk_1;
  wire ap_rst_n_1;
  wire [7:0]in0_V_1_TDATA;
  wire in0_V_1_TREADY;
  wire in0_V_1_TVALID;

  assign StreamingDataflowPartition_1_MVAU_hls_6_out_V_TREADY = out_V_tready;
  assign ap_clk_1 = ap_clk;
  assign ap_rst_n_1 = ap_rst_n;
  assign in0_V_1_TDATA = in0_V_tdata[7:0];
  assign in0_V_1_TVALID = in0_V_tvalid;
  assign in0_V_tready = in0_V_1_TREADY;
  assign out_V_tdata[7:0] = StreamingDataflowPartition_1_MVAU_hls_6_out_V_TDATA;
  assign out_V_tvalid = StreamingDataflowPartition_1_MVAU_hls_6_out_V_TVALID;
  StreamingDataflowPartition_1_StreamingDataflowPartition_1_MVAU_hls_6_0 StreamingDataflowPartition_1_MVAU_hls_6
       (.ap_clk(ap_clk_1),
        .ap_rst_n(ap_rst_n_1),
        .in0_V_TDATA(in0_V_1_TDATA),
        .in0_V_TREADY(in0_V_1_TREADY),
        .in0_V_TVALID(in0_V_1_TVALID),
        .out_V_TDATA(StreamingDataflowPartition_1_MVAU_hls_6_out_V_TDATA),
        .out_V_TREADY(StreamingDataflowPartition_1_MVAU_hls_6_out_V_TREADY),
        .out_V_TVALID(StreamingDataflowPartition_1_MVAU_hls_6_out_V_TVALID),
        .weights_V_TDATA(StreamingDataflowPartition_1_MVAU_hls_6_wstrm_m_axis_0_TDATA),
        .weights_V_TREADY(StreamingDataflowPartition_1_MVAU_hls_6_wstrm_m_axis_0_TREADY),
        .weights_V_TVALID(StreamingDataflowPartition_1_MVAU_hls_6_wstrm_m_axis_0_TVALID));
  StreamingDataflowPartition_1_StreamingDataflowPartition_1_MVAU_hls_6_wstrm_0 StreamingDataflowPartition_1_MVAU_hls_6_wstrm
       (.ap_clk(ap_clk_1),
        .ap_rst_n(ap_rst_n_1),
        .araddr({1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0}),
        .arprot({1'b0,1'b0,1'b0}),
        .arvalid(1'b0),
        .awaddr({1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0}),
        .awprot({1'b0,1'b0,1'b0}),
        .awvalid(1'b0),
        .bready(1'b0),
        .m_axis_0_tdata(StreamingDataflowPartition_1_MVAU_hls_6_wstrm_m_axis_0_TDATA),
        .m_axis_0_tready(StreamingDataflowPartition_1_MVAU_hls_6_wstrm_m_axis_0_TREADY),
        .m_axis_0_tvalid(StreamingDataflowPartition_1_MVAU_hls_6_wstrm_m_axis_0_TVALID),
        .rready(1'b0),
        .wdata({1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0}),
        .wstrb({1'b1,1'b1,1'b1,1'b1}),
        .wvalid(1'b0));
endmodule

module StreamingDataflowPartition_1_MVAU_hls_7_imp_1O336XP
   (ap_clk,
    ap_rst_n,
    in0_V_tdata,
    in0_V_tready,
    in0_V_tvalid,
    out_V_tdata,
    out_V_tready,
    out_V_tvalid);
  input ap_clk;
  input ap_rst_n;
  input [7:0]in0_V_tdata;
  output in0_V_tready;
  input in0_V_tvalid;
  output [7:0]out_V_tdata;
  input out_V_tready;
  output out_V_tvalid;

  wire [7:0]StreamingDataflowPartition_1_MVAU_hls_7_out_V_TDATA;
  wire StreamingDataflowPartition_1_MVAU_hls_7_out_V_TREADY;
  wire StreamingDataflowPartition_1_MVAU_hls_7_out_V_TVALID;
  wire [7:0]StreamingDataflowPartition_1_MVAU_hls_7_wstrm_m_axis_0_TDATA;
  wire StreamingDataflowPartition_1_MVAU_hls_7_wstrm_m_axis_0_TREADY;
  wire StreamingDataflowPartition_1_MVAU_hls_7_wstrm_m_axis_0_TVALID;
  wire ap_clk_1;
  wire ap_rst_n_1;
  wire [7:0]in0_V_1_TDATA;
  wire in0_V_1_TREADY;
  wire in0_V_1_TVALID;

  assign StreamingDataflowPartition_1_MVAU_hls_7_out_V_TREADY = out_V_tready;
  assign ap_clk_1 = ap_clk;
  assign ap_rst_n_1 = ap_rst_n;
  assign in0_V_1_TDATA = in0_V_tdata[7:0];
  assign in0_V_1_TVALID = in0_V_tvalid;
  assign in0_V_tready = in0_V_1_TREADY;
  assign out_V_tdata[7:0] = StreamingDataflowPartition_1_MVAU_hls_7_out_V_TDATA;
  assign out_V_tvalid = StreamingDataflowPartition_1_MVAU_hls_7_out_V_TVALID;
  StreamingDataflowPartition_1_StreamingDataflowPartition_1_MVAU_hls_7_0 StreamingDataflowPartition_1_MVAU_hls_7
       (.ap_clk(ap_clk_1),
        .ap_rst_n(ap_rst_n_1),
        .in0_V_TDATA(in0_V_1_TDATA),
        .in0_V_TREADY(in0_V_1_TREADY),
        .in0_V_TVALID(in0_V_1_TVALID),
        .out_V_TDATA(StreamingDataflowPartition_1_MVAU_hls_7_out_V_TDATA),
        .out_V_TREADY(StreamingDataflowPartition_1_MVAU_hls_7_out_V_TREADY),
        .out_V_TVALID(StreamingDataflowPartition_1_MVAU_hls_7_out_V_TVALID),
        .weights_V_TDATA(StreamingDataflowPartition_1_MVAU_hls_7_wstrm_m_axis_0_TDATA),
        .weights_V_TREADY(StreamingDataflowPartition_1_MVAU_hls_7_wstrm_m_axis_0_TREADY),
        .weights_V_TVALID(StreamingDataflowPartition_1_MVAU_hls_7_wstrm_m_axis_0_TVALID));
  StreamingDataflowPartition_1_StreamingDataflowPartition_1_MVAU_hls_7_wstrm_0 StreamingDataflowPartition_1_MVAU_hls_7_wstrm
       (.ap_clk(ap_clk_1),
        .ap_rst_n(ap_rst_n_1),
        .araddr({1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0}),
        .arprot({1'b0,1'b0,1'b0}),
        .arvalid(1'b0),
        .awaddr({1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0}),
        .awprot({1'b0,1'b0,1'b0}),
        .awvalid(1'b0),
        .bready(1'b0),
        .m_axis_0_tdata(StreamingDataflowPartition_1_MVAU_hls_7_wstrm_m_axis_0_TDATA),
        .m_axis_0_tready(StreamingDataflowPartition_1_MVAU_hls_7_wstrm_m_axis_0_TREADY),
        .m_axis_0_tvalid(StreamingDataflowPartition_1_MVAU_hls_7_wstrm_m_axis_0_TVALID),
        .rready(1'b0),
        .wdata({1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0}),
        .wstrb({1'b1,1'b1,1'b1,1'b1}),
        .wvalid(1'b0));
endmodule

module StreamingDataflowPartition_1_MVAU_hls_8_imp_10OO4HU
   (ap_clk,
    ap_rst_n,
    in0_V_tdata,
    in0_V_tready,
    in0_V_tvalid,
    out_V_tdata,
    out_V_tready,
    out_V_tvalid);
  input ap_clk;
  input ap_rst_n;
  input [7:0]in0_V_tdata;
  output in0_V_tready;
  input in0_V_tvalid;
  output [159:0]out_V_tdata;
  input out_V_tready;
  output out_V_tvalid;

  wire [159:0]StreamingDataflowPartition_1_MVAU_hls_8_out_V_TDATA;
  wire StreamingDataflowPartition_1_MVAU_hls_8_out_V_TREADY;
  wire StreamingDataflowPartition_1_MVAU_hls_8_out_V_TVALID;
  wire [7:0]StreamingDataflowPartition_1_MVAU_hls_8_wstrm_m_axis_0_TDATA;
  wire StreamingDataflowPartition_1_MVAU_hls_8_wstrm_m_axis_0_TREADY;
  wire StreamingDataflowPartition_1_MVAU_hls_8_wstrm_m_axis_0_TVALID;
  wire ap_clk_1;
  wire ap_rst_n_1;
  wire [7:0]in0_V_1_TDATA;
  wire in0_V_1_TREADY;
  wire in0_V_1_TVALID;

  assign StreamingDataflowPartition_1_MVAU_hls_8_out_V_TREADY = out_V_tready;
  assign ap_clk_1 = ap_clk;
  assign ap_rst_n_1 = ap_rst_n;
  assign in0_V_1_TDATA = in0_V_tdata[7:0];
  assign in0_V_1_TVALID = in0_V_tvalid;
  assign in0_V_tready = in0_V_1_TREADY;
  assign out_V_tdata[159:0] = StreamingDataflowPartition_1_MVAU_hls_8_out_V_TDATA;
  assign out_V_tvalid = StreamingDataflowPartition_1_MVAU_hls_8_out_V_TVALID;
  StreamingDataflowPartition_1_StreamingDataflowPartition_1_MVAU_hls_8_0 StreamingDataflowPartition_1_MVAU_hls_8
       (.ap_clk(ap_clk_1),
        .ap_rst_n(ap_rst_n_1),
        .in0_V_TDATA(in0_V_1_TDATA),
        .in0_V_TREADY(in0_V_1_TREADY),
        .in0_V_TVALID(in0_V_1_TVALID),
        .out_V_TDATA(StreamingDataflowPartition_1_MVAU_hls_8_out_V_TDATA),
        .out_V_TREADY(StreamingDataflowPartition_1_MVAU_hls_8_out_V_TREADY),
        .out_V_TVALID(StreamingDataflowPartition_1_MVAU_hls_8_out_V_TVALID),
        .weights_V_TDATA(StreamingDataflowPartition_1_MVAU_hls_8_wstrm_m_axis_0_TDATA),
        .weights_V_TREADY(StreamingDataflowPartition_1_MVAU_hls_8_wstrm_m_axis_0_TREADY),
        .weights_V_TVALID(StreamingDataflowPartition_1_MVAU_hls_8_wstrm_m_axis_0_TVALID));
  StreamingDataflowPartition_1_StreamingDataflowPartition_1_MVAU_hls_8_wstrm_0 StreamingDataflowPartition_1_MVAU_hls_8_wstrm
       (.ap_clk(ap_clk_1),
        .ap_rst_n(ap_rst_n_1),
        .araddr({1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0}),
        .arprot({1'b0,1'b0,1'b0}),
        .arvalid(1'b0),
        .awaddr({1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0}),
        .awprot({1'b0,1'b0,1'b0}),
        .awvalid(1'b0),
        .bready(1'b0),
        .m_axis_0_tdata(StreamingDataflowPartition_1_MVAU_hls_8_wstrm_m_axis_0_TDATA),
        .m_axis_0_tready(StreamingDataflowPartition_1_MVAU_hls_8_wstrm_m_axis_0_TREADY),
        .m_axis_0_tvalid(StreamingDataflowPartition_1_MVAU_hls_8_wstrm_m_axis_0_TVALID),
        .rready(1'b0),
        .wdata({1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0}),
        .wstrb({1'b1,1'b1,1'b1,1'b1}),
        .wvalid(1'b0));
endmodule
