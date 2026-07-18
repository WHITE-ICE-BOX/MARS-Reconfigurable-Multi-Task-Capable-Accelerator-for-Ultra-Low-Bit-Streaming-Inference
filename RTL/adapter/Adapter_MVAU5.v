`timescale 1ns / 1ps

// =====================================================================
// Adapter_MVAU5 — PE=1 version, cfg-writable RAM
// IN_CH=256, OUT_CH=256, HIDDEN=64, IN_CHUNKS=8, UP_WIDTH=64
// SPECIAL: rom_up entries are 64-bit, xnor_pipe is 64-bit, popcount64
// =====================================================================

module Adapter_MVAU5 #(
    parameter LAYER_ID = 5,
    parameter IN_CH    = 256,
    parameter OUT_CH   = 256,
    parameter PE       = 1,
    parameter SIMD     = 32,
    parameter REDUCTION = 4,
    parameter UP_WIDTH  = 64,

    parameter HIDDEN_CH   = (IN_CH/REDUCTION > 0) ? (IN_CH/REDUCTION) : 16,  // 64
    parameter IN_CHUNKS   = (IN_CH/SIMD > 0) ? (IN_CH/SIMD) : 1,             // 8
    parameter OUT_STEPS   = (OUT_CH/PE > 0) ? (OUT_CH/PE) : 1,               // 256

    parameter PIXEL_CYCLES = IN_CHUNKS,
    parameter WIN_CYCLES   = 9 * PIXEL_CYCLES,
    parameter CENTER_START = 4 * PIXEL_CYCLES,
    parameter CENTER_END   = 5 * PIXEL_CYCLES - 1
)(
    input  wire                  aclk,
    input  wire                  aresetn,
    input  wire [SIMD-1:0]       s_axis_tdata,
    input  wire                  s_axis_tvalid,
    output wire                  s_axis_tready,

    output reg  [PE*8-1:0]       m_axis_tdata,
    output reg                   m_axis_tvalid,
    input  wire                  m_axis_tready,

    input  wire [10:0]           cfg_waddr,
    input  wire [31:0]           cfg_wdata,
    input  wire                  cfg_wen
);
    (* ram_style = "distributed" *) reg [15:0]                    rom_rc   [0 : HIDDEN_CH - 1];
    (* ram_style = "distributed" *) reg [(HIDDEN_CH*SIMD)-1:0]    rom_down [0 : IN_CHUNKS - 1];
    (* ram_style = "distributed" *) reg [UP_WIDTH-1:0]            rom_up   [0 : OUT_CH - 1];

`ifdef SIM_INIT_ROM
    initial begin
        $readmemh("/home/barkie1/mvau_pipeline_runtime_3ds_pe1/mvau_adapter/mvau5/data/rom_rc_load.dat",   rom_rc);
        $readmemh("/home/barkie1/mvau_pipeline_runtime_3ds_pe1/mvau_adapter/mvau5/data/rom_down_load.dat", rom_down);
        $readmemh("/home/barkie1/mvau_pipeline_runtime_3ds_pe1/mvau_adapter/mvau5/data/rom_up_load.dat",   rom_up);
    end
`endif

    reg [15:0] cycle_cnt;
    reg [15:0] out_step_cnt;
    reg        is_outputting;

    reg signed [15:0] hidden_acc      [0:HIDDEN_CH-1];
    reg        [HIDDEN_CH-1:0] hidden_act;
    reg        [HIDDEN_CH-1:0] hidden_act_next;

    reg [UP_WIDTH-1:0] xnor_pipe;
    reg        valid_pipe;
    wire [UP_WIDTH-1:0] current_up_weights = rom_up[out_step_cnt];

    reg [SIMD-1:0] s0_tdata;
    reg [15:0]     s0_idx;
    reg            s0_valid;
    reg [SIMD-1:0] s1_act;
    reg [SIMD-1:0] s1_down [0:HIDDEN_CH-1];
    reg            s1_valid;
    reg [SIMD-1:0] s2_xnor [0:HIDDEN_CH-1];
    reg            s2_valid;
    reg [7:0]      s3_pop  [0:HIDDEN_CH-1];
    reg            s3_valid;
    integer i, k;

    wire stall = m_axis_tvalid && !m_axis_tready;
    assign s_axis_tready = aresetn && !is_outputting && !valid_pipe && (!m_axis_tvalid || m_axis_tready);

    function [7:0] popcount_simd;
        input [SIMD-1:0] vec; integer n;
        begin popcount_simd = 0; for (n = 0; n < SIMD; n = n + 1) popcount_simd = popcount_simd + vec[n]; end
    endfunction

    function [7:0] popcount64;
        input [UP_WIDTH-1:0] vec; integer n;
        begin popcount64 = 0; for (n = 0; n < UP_WIDTH; n = n + 1) popcount64 = popcount64 + vec[n]; end
    endfunction

    always @(*) begin
        for (k = 0; k < HIDDEN_CH; k = k + 1) begin
            hidden_act_next[k] = (hidden_acc[k] >= 0) ? 1'b1 : 1'b0;
        end
    end

    always @(posedge aclk) begin
        if (!aresetn) begin
            cycle_cnt     <= 0;
            out_step_cnt  <= 0;
            is_outputting <= 1'b0;

            m_axis_tvalid <= 1'b0;
            m_axis_tdata  <= 8'd0;
            hidden_act    <= {HIDDEN_CH{1'b0}};
            valid_pipe    <= 1'b0;

            s0_tdata <= {SIMD{1'b0}};
            s0_idx   <= 16'd0;
            s0_valid <= 1'b0;
            s1_act   <= {SIMD{1'b0}};
            s1_valid <= 1'b0;

            s2_valid <= 1'b0;
            s3_valid <= 1'b0;
            xnor_pipe <= {UP_WIDTH{1'b0}};
            for (i = 0; i < HIDDEN_CH; i = i + 1) begin
                hidden_acc[i] <= $signed(rom_rc[i]);
                s1_down[i]    <= {SIMD{1'b0}};
                s2_xnor[i]    <= {SIMD{1'b0}};
                s3_pop[i]     <= 8'd0;
            end
        end
        else if (!stall) begin
            s3_valid <= s2_valid;
            s2_valid <= s1_valid;
            s1_valid <= s0_valid;
            s0_valid <= 1'b0;

            if (s1_valid) for (i = 0; i < HIDDEN_CH; i = i + 1) s2_xnor[i] <= ~(s1_act ^ s1_down[i]);
            if (s2_valid) for (i = 0; i < HIDDEN_CH; i = i + 1) s3_pop[i] <= popcount_simd(s2_xnor[i]);
            if (s3_valid) for (i = 0; i < HIDDEN_CH; i = i + 1) hidden_acc[i] <= hidden_acc[i] + s3_pop[i];

            if (valid_pipe) begin
                m_axis_tvalid <= 1'b1;
                m_axis_tdata  <= popcount64(xnor_pipe);
            end else begin
                m_axis_tvalid <= 1'b0;
            end

            if (is_outputting) begin
                valid_pipe <= 1'b1;
                // HIDDEN_CH = UP_WIDTH = 64 → no padding needed
                xnor_pipe  <= ~(hidden_act ^ current_up_weights);
                if (out_step_cnt == OUT_STEPS - 1) begin
                    is_outputting <= 1'b0; out_step_cnt  <= 0;
                end else begin
                    out_step_cnt <= out_step_cnt + 1;
                end
            end else begin
                valid_pipe <= 1'b0;
            end

            if (s_axis_tvalid && s_axis_tready) begin
                if (cycle_cnt >= CENTER_START && cycle_cnt <= CENTER_END) begin
                    s0_tdata <= s_axis_tdata;
                    s0_idx   <= cycle_cnt - CENTER_START;
                    s0_valid <= 1'b1;
                end
                if (cycle_cnt == WIN_CYCLES - 1) begin
                    cycle_cnt <= 0;
                    hidden_act <= hidden_act_next;
                    for (i = 0; i < HIDDEN_CH; i = i + 1) hidden_acc[i] <= $signed(rom_rc[i]);
                    is_outputting <= 1'b1;
                    out_step_cnt  <= 0;
                end else begin
                    cycle_cnt <= cycle_cnt + 1;
                end
            end

            if (s0_valid) begin
                s1_act <= s0_tdata;
                for (i = 0; i < HIDDEN_CH; i = i + 1) begin
                    s1_down[i] <= rom_down[s0_idx][i*SIMD +: SIMD];
                end
            end
        end
    end

    localparam CFG_RC_BASE   = 11'd4;
    localparam CFG_DOWN_BASE = 11'd128;
    localparam CFG_UP_BASE   = 11'd640;

    localparam HIDDEN_CH_BITS = $clog2(HIDDEN_CH);
    localparam OUT_CH_BITS    = $clog2(OUT_CH);
    localparam IN_CHUNKS_BITS = (IN_CHUNKS > 1) ? $clog2(IN_CHUNKS) : 1;

    wire [10:0] rc_offset   = cfg_waddr - CFG_RC_BASE;
    wire [10:0] down_offset = cfg_waddr - CFG_DOWN_BASE;
    wire [10:0] up_offset   = cfg_waddr - CFG_UP_BASE;

    // For MVAU5 UP_WIDTH=64: cfg_hub writes two 32-bit halves per OC?
    // Keep simple: assume single 32-bit lower half write only via cfg.
    // For sim, $readmemh fills both halves. For board runtime, separate scheme TBD.
    always @(posedge aclk) begin
        if (cfg_wen) begin
            if (cfg_waddr >= CFG_RC_BASE && cfg_waddr < CFG_RC_BASE + HIDDEN_CH)
                rom_rc[rc_offset[HIDDEN_CH_BITS-1:0]] <= cfg_wdata[15:0];
            if (cfg_waddr >= CFG_DOWN_BASE && cfg_waddr < CFG_DOWN_BASE + IN_CHUNKS * HIDDEN_CH)
                rom_down[down_offset[HIDDEN_CH_BITS +: IN_CHUNKS_BITS]]
                        [down_offset[HIDDEN_CH_BITS-1:0] * SIMD +: SIMD] <= cfg_wdata[SIMD-1:0];
            // Two-word scheme: low at base+2*oc, high at base+2*oc+1
            if (cfg_waddr >= CFG_UP_BASE && cfg_waddr < CFG_UP_BASE + 2 * OUT_CH) begin
                if (up_offset[0] == 1'b0)
                    rom_up[up_offset[OUT_CH_BITS:1]][31:0]  <= cfg_wdata;
                else
                    rom_up[up_offset[OUT_CH_BITS:1]][63:32] <= cfg_wdata;
            end
        end
    end

endmodule
