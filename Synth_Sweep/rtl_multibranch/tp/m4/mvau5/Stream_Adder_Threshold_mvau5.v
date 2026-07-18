`timescale 1ns / 1ps

// Stream_Adder_Threshold_mvau5 — multi-branch M=4, PE=1 (tp).
// total_q8 = ((pol ? K-pop : pop) << 8) + sum_b contrib_b ; out = (>=thr) ^ pol
(* use_dsp = "no" *)
module Stream_Adder_Threshold_mvau5 (
    input  wire                  aclk,
    input  wire                  aresetn,

    input  wire [31:0]           s_axis_1_tdata,
    input  wire                  s_axis_1_tvalid,
    output wire                  s_axis_1_tready,

    input  wire [7:0]            s_axis_2_b0_tdata,
    input  wire                  s_axis_2_b0_tvalid,
    output wire                  s_axis_2_b0_tready,

    input  wire [7:0]            s_axis_2_b1_tdata,
    input  wire                  s_axis_2_b1_tvalid,
    output wire                  s_axis_2_b1_tready,

    input  wire [7:0]            s_axis_2_b2_tdata,
    input  wire                  s_axis_2_b2_tvalid,
    output wire                  s_axis_2_b2_tready,

    input  wire [7:0]            s_axis_2_b3_tdata,
    input  wire                  s_axis_2_b3_tvalid,
    output wire                  s_axis_2_b3_tready,

    output reg                   m_axis_tdata,
    output reg                   m_axis_tvalid,
    input  wire                  m_axis_tready,

    input  wire [10:0]           cfg_waddr,
    input  wire [31:0]           cfg_wdata,
    input  wire                  cfg_wen,
    input  wire [1:0]            branch_sel,
    input  wire                  adapter_enable
);
    parameter OUT_CH = 256;
    parameter K_TOTAL = 2304;

    (* ram_style = "distributed" *) reg signed [31:0] thresh_rom   [0:OUT_CH-1];
    (* ram_style = "distributed" *) reg               adp_sign_rom [0:OUT_CH-1];
    localparam signed [31:0] CONTRIB_OFFSET = 32;
    localparam signed [31:0] ALPHA_Q8_B0 = 537;  // baked from checkpoint
    localparam signed [31:0] ALPHA_Q8_B1 = 546;  // baked from checkpoint
    localparam signed [31:0] ALPHA_Q8_B2 = 538;  // baked from checkpoint
    localparam signed [31:0] ALPHA_Q8_B3 = 560;  // baked from checkpoint

    localparam CFG_THRESH_BASE = 11'd1152;
    localparam CFG_SIGN_BASE   = 11'd1408;
    localparam CFG_LUT_BASE    = 11'd1664;

    always @(posedge aclk) begin
        if (cfg_wen) begin
            if (cfg_waddr >= CFG_THRESH_BASE && cfg_waddr < CFG_THRESH_BASE + OUT_CH)
                thresh_rom[cfg_waddr - CFG_THRESH_BASE] <= $signed(cfg_wdata);
            if (cfg_waddr >= CFG_SIGN_BASE && cfg_waddr < CFG_SIGN_BASE + OUT_CH)
                adp_sign_rom[cfg_waddr - CFG_SIGN_BASE] <= cfg_wdata[0];
        end
    end

    reg [$clog2(OUT_CH)-1:0] ch_cnt;
    wire stall = m_axis_tvalid && !m_axis_tready;
    wire all_br_valid = s_axis_2_b0_tvalid && s_axis_2_b1_tvalid && s_axis_2_b2_tvalid && s_axis_2_b3_tvalid;
    wire in_fire = s_axis_1_tvalid && all_br_valid && !stall;
    assign s_axis_1_tready = !stall && all_br_valid;
    assign s_axis_2_b0_tready = !stall && s_axis_1_tvalid && s_axis_2_b1_tvalid && s_axis_2_b2_tvalid && s_axis_2_b3_tvalid;
    assign s_axis_2_b1_tready = !stall && s_axis_1_tvalid && s_axis_2_b0_tvalid && s_axis_2_b2_tvalid && s_axis_2_b3_tvalid;
    assign s_axis_2_b2_tready = !stall && s_axis_1_tvalid && s_axis_2_b0_tvalid && s_axis_2_b1_tvalid && s_axis_2_b3_tvalid;
    assign s_axis_2_b3_tready = !stall && s_axis_1_tvalid && s_axis_2_b0_tvalid && s_axis_2_b1_tvalid && s_axis_2_b2_tvalid;

    reg                    s1_valid;
    reg signed [31:0]      s1_mvau_pop;
    (* use_dsp = "no" *) reg signed [31:0]      s1_adp_contrib_b0;
    (* use_dsp = "no" *) reg signed [31:0]      s1_adp_contrib_b1;
    (* use_dsp = "no" *) reg signed [31:0]      s1_adp_contrib_b2;
    (* use_dsp = "no" *) reg signed [31:0]      s1_adp_contrib_b3;
    reg signed [31:0]      s1_threshold;
    reg                    s1_adp_sign;

    reg                    s2_valid;
    reg signed [31:0]      s2_total_q8;
    reg signed [31:0]      s2_threshold;
    reg                    s2_pol;

    wire signed [31:0] contrib_sum_s1 = s1_adp_contrib_b0 + s1_adp_contrib_b1 + s1_adp_contrib_b2 + s1_adp_contrib_b3;

    always @(posedge aclk) begin
        if (!aresetn) begin
            ch_cnt <= 0;
            m_axis_tvalid <= 0; m_axis_tdata <= 0;
            s1_valid <= 0; s2_valid <= 0;
        end else if (!stall) begin
            // Stage 3 (compare/output)
            if (s2_valid) begin
                m_axis_tvalid <= 1'b1;
                m_axis_tdata  <= ((s2_total_q8 >= s2_threshold) ? 1'b1 : 1'b0) ^ s2_pol;
            end else begin
                m_axis_tvalid <= 1'b0;
            end

            // Stage 2 (widen + add summed branch contributions)
            if (s1_valid) begin
                s2_valid <= 1'b1;
                if (adapter_enable) begin
                    if (s1_adp_sign)
                        s2_total_q8 <= (($signed(K_TOTAL) - s1_mvau_pop) <<< 8) + contrib_sum_s1;
                    else
                        s2_total_q8 <= (s1_mvau_pop <<< 8) + contrib_sum_s1;
                end else begin
                    if (s1_adp_sign)
                        s2_total_q8 <= ($signed(K_TOTAL) - s1_mvau_pop) <<< 8;
                    else
                        s2_total_q8 <= s1_mvau_pop <<< 8;
                end
                s2_pol       <= s1_adp_sign;
                s2_threshold <= s1_threshold;
            end else begin
                s2_valid <= 1'b0;
            end

            // Stage 1 (capture + per-branch LUT lookup)
            if (in_fire) begin
                s1_valid       <= 1'b1;
                s1_mvau_pop    <= $signed(s_axis_1_tdata);
                s1_adp_contrib_b0 <= ($signed({24'd0, s_axis_2_b0_tdata}) - CONTRIB_OFFSET) * ALPHA_Q8_B0;
                s1_adp_contrib_b1 <= ($signed({24'd0, s_axis_2_b1_tdata}) - CONTRIB_OFFSET) * ALPHA_Q8_B1;
                s1_adp_contrib_b2 <= ($signed({24'd0, s_axis_2_b2_tdata}) - CONTRIB_OFFSET) * ALPHA_Q8_B2;
                s1_adp_contrib_b3 <= ($signed({24'd0, s_axis_2_b3_tdata}) - CONTRIB_OFFSET) * ALPHA_Q8_B3;
                s1_threshold   <= thresh_rom[ch_cnt];
                s1_adp_sign    <= adp_sign_rom[ch_cnt];

                if (ch_cnt == OUT_CH - 1) ch_cnt <= 0;
                else                       ch_cnt <= ch_cnt + 1;
            end else begin
                s1_valid <= 1'b0;
            end
        end
    end

endmodule
