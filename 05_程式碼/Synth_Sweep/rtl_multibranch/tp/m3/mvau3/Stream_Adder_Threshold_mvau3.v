`timescale 1ns / 1ps

// Stream_Adder_Threshold_mvau3 — multi-branch M=3, PE=16 (throughput),
// per-PE storage structure (1W1R per array -> distributed RAM).
// Per lane p (ch = step*PE+p): total_q8 = (mvau_pop << 8) + (sign ? -sum : +sum),
// sum = sum over branches of lane-local contrib LUT lookups; out = (>= thr).
(* use_dsp = "no" *)
module Stream_Adder_Threshold_mvau3 (
    input  wire                  aclk,
    input  wire                  aresetn,

    input  wire [511:0]         s_axis_1_tdata,
    input  wire                  s_axis_1_tvalid,
    output wire                  s_axis_1_tready,

    input  wire [127:0]          s_axis_2_b0_tdata,
    input  wire                  s_axis_2_b0_tvalid,
    output wire                  s_axis_2_b0_tready,

    input  wire [127:0]          s_axis_2_b1_tdata,
    input  wire                  s_axis_2_b1_tvalid,
    output wire                  s_axis_2_b1_tready,

    input  wire [127:0]          s_axis_2_b2_tdata,
    input  wire                  s_axis_2_b2_tvalid,
    output wire                  s_axis_2_b2_tready,

    output reg  [15:0]           m_axis_tdata,
    output reg                   m_axis_tvalid,
    input  wire                  m_axis_tready,

    input  wire [10:0]           cfg_waddr,
    input  wire [31:0]           cfg_wdata,
    input  wire                  cfg_wen,
    input  wire [1:0]            branch_sel,
    input  wire                  adapter_enable
);
    parameter PE        = 16;
    parameter OUT_CH    = 128;
    parameter OUT_STEPS = 8;

    localparam CFG_THRESH_BASE = 11'd1152;
    localparam CFG_SIGN_BASE   = 11'd1408;
    localparam signed [31:0] CONTRIB_OFFSET = 16;
    localparam signed [31:0] ALPHA_Q8_B0 = 983;  // baked from checkpoint
    localparam signed [31:0] ALPHA_Q8_B1 = 1024;  // baked from checkpoint
    localparam signed [31:0] ALPHA_Q8_B2 = 1029;  // baked from checkpoint

    reg [2:0] step_cnt;

    wire stall = m_axis_tvalid && !m_axis_tready;
    wire all_br_valid = s_axis_2_b0_tvalid && s_axis_2_b1_tvalid && s_axis_2_b2_tvalid;
    wire in_fire = s_axis_1_tvalid && all_br_valid && !stall;
    assign s_axis_1_tready = !stall && all_br_valid;
    assign s_axis_2_b0_tready = !stall && s_axis_1_tvalid && s_axis_2_b1_tvalid && s_axis_2_b2_tvalid;
    assign s_axis_2_b1_tready = !stall && s_axis_1_tvalid && s_axis_2_b0_tvalid && s_axis_2_b2_tvalid;
    assign s_axis_2_b2_tready = !stall && s_axis_1_tvalid && s_axis_2_b0_tvalid && s_axis_2_b1_tvalid;

    reg s1_valid, s2_valid;
    wire [15:0] cmp_bit;

    // ---- per-lane storage + datapath ----
    genvar gp;
    generate
        for (gp = 0; gp < PE; gp = gp + 1) begin : g_lane
            // lane-column thresh/sign: entry s = channel s*PE+gp (1W1R)
            (* ram_style = "distributed" *) reg signed [31:0] th_mem [0:OUT_STEPS-1];
            (* ram_style = "distributed" *) reg               sg_mem [0:OUT_STEPS-1];

            always @(posedge aclk) begin
                if (cfg_wen) begin
                    if (cfg_waddr >= CFG_THRESH_BASE && cfg_waddr < CFG_THRESH_BASE + OUT_CH
                        && ((cfg_waddr - CFG_THRESH_BASE) & (PE-1)) == gp)
                        th_mem[(cfg_waddr - CFG_THRESH_BASE) >> 4] <= $signed(cfg_wdata);
                    if (cfg_waddr >= CFG_SIGN_BASE && cfg_waddr < CFG_SIGN_BASE + OUT_CH
                        && ((cfg_waddr - CFG_SIGN_BASE) & (PE-1)) == gp)
                        sg_mem[(cfg_waddr - CFG_SIGN_BASE) >> 4] <= cfg_wdata[0];
                end
            end

            reg signed [31:0] s1_mvau_pop;
            reg signed [31:0] s1_contrib_b0;
            reg signed [31:0] s1_contrib_b1;
            reg signed [31:0] s1_contrib_b2;
            reg signed [31:0] s1_threshold;
            reg               s1_adp_sign;
            reg signed [31:0] s2_total_q8;
            reg signed [31:0] s2_threshold;
            wire signed [31:0] contrib_sum = s1_contrib_b0 + s1_contrib_b1 + s1_contrib_b2;

            always @(posedge aclk) begin
                if (!aresetn) begin
                    s1_mvau_pop <= 32'sd0; s1_threshold <= 32'sd0; s1_adp_sign <= 1'b0;
                    s1_contrib_b0 <= 32'sd0;
                    s1_contrib_b1 <= 32'sd0;
                    s1_contrib_b2 <= 32'sd0;
                    s2_total_q8 <= 32'sd0; s2_threshold <= 32'sd0;
                end else if (!stall) begin
                    if (s1_valid) begin
                        if (adapter_enable)
                            s2_total_q8 <= (s1_mvau_pop <<< 8)
                                           + (s1_adp_sign ? -contrib_sum : contrib_sum);
                        else
                            s2_total_q8 <= (s1_mvau_pop <<< 8);
                        s2_threshold <= s1_threshold;
                    end
                    if (in_fire) begin
                        s1_mvau_pop  <= $signed(s_axis_1_tdata[(gp*32) +: 32]);
                        s1_contrib_b0 <= ($signed({24'd0, s_axis_2_b0_tdata[(gp*8) +: 8]}) - CONTRIB_OFFSET) * ALPHA_Q8_B0;
                        s1_contrib_b1 <= ($signed({24'd0, s_axis_2_b1_tdata[(gp*8) +: 8]}) - CONTRIB_OFFSET) * ALPHA_Q8_B1;
                        s1_contrib_b2 <= ($signed({24'd0, s_axis_2_b2_tdata[(gp*8) +: 8]}) - CONTRIB_OFFSET) * ALPHA_Q8_B2;
                        s1_threshold <= th_mem[step_cnt];
                        s1_adp_sign  <= sg_mem[step_cnt];
                    end
                end
            end

            assign cmp_bit[gp] = (s2_total_q8 >= s2_threshold);
        end
    endgenerate

    // ---- central control ----
    always @(posedge aclk) begin
        if (!aresetn) begin
            m_axis_tvalid <= 1'b0;
            m_axis_tdata  <= 16'd0;
            s1_valid      <= 1'b0;
            s2_valid      <= 1'b0;
            step_cnt      <= 0;
        end else if (!stall) begin
            if (s2_valid) begin
                m_axis_tvalid <= 1'b1;
                m_axis_tdata  <= cmp_bit;
            end else begin
                m_axis_tvalid <= 1'b0;
            end
            s2_valid <= s1_valid;
            if (in_fire) begin
                s1_valid <= 1'b1;
                if (step_cnt == (OUT_STEPS - 1)) step_cnt <= 0;
                else                             step_cnt <= step_cnt + 1;
            end else begin
                s1_valid <= 1'b0;
            end
        end
    end

endmodule
