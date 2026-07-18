`timescale 1ns / 1ps

// =====================================================================
// Adapter_MVAU1 — PE=1 version, cfg-writable RAM (no $readmemh baking)
// =====================================================================
// Datapath same as v1 (PE-parallel hidden_acc compute, parallel popcount),
// but PE=1 so:
//   - m_axis_tdata is PE*8 = 8 bits
//   - rom_up is narrow row OUT_CH × 32-bit (vs v1 wide row OUT_STEPS × PE*32)
//   - xnor_pipe is single entry
// rom_rc / rom_down / rom_up all cfg-writable via cfg_waddr/wdata/wen.

module Adapter_MVAU1 #(
    parameter LAYER_ID = 1,
    parameter IN_CH    = 64,
    parameter OUT_CH   = 64,
    parameter PE       = 1,     // <-- PE=1
    parameter SIMD     = 32,
    parameter REDUCTION = 4,

    parameter HIDDEN_CH   = (IN_CH/REDUCTION > 0) ? (IN_CH/REDUCTION) : 16,  // 16
    parameter IN_CHUNKS   = (IN_CH/SIMD > 0) ? (IN_CH/SIMD) : 1,             // 2
    parameter OUT_STEPS   = (OUT_CH/PE > 0) ? (OUT_CH/PE) : 1,               // 64

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

    // PE=1 → output is 8-bit popcount per beat
    output reg  [PE*8-1:0]       m_axis_tdata,
    output reg                   m_axis_tvalid,
    input  wire                  m_axis_tready,

    // Runtime config write port (cfg_hub → adapter)
    input  wire [10:0]           cfg_waddr,
    input  wire [31:0]           cfg_wdata,
    input  wire                  cfg_wen
);
    // =====================================================
    // RAM (cfg-writable). For SIMULATION, optional `SIM_INIT_ROM macro loads
    // baked SVHN values via $readmemh. For SYNTHESIS, don't define the macro —
    // ROM defaults to 0 and driver writes via cfg_hub at runtime.
    // =====================================================
    (* ram_style = "distributed" *) reg [15:0]                    rom_rc   [0 : HIDDEN_CH - 1];
    (* ram_style = "distributed" *) reg [(HIDDEN_CH*SIMD)-1:0]    rom_down [0 : IN_CHUNKS - 1];
    (* ram_style = "distributed" *) reg [31:0]                    rom_up   [0 : OUT_CH - 1];  // narrow row for PE=1

`ifdef SIM_INIT_ROM
    initial begin
        $readmemh("/home/barkie1/mvau_pipeline_runtime_3ds_pe1/mvau_adapter/mvau1/data/rom_rc_load.dat",   rom_rc);
        $readmemh("/home/barkie1/mvau_pipeline_runtime_3ds_pe1/mvau_adapter/mvau1/data/rom_down_load.dat", rom_down);
        $readmemh("/home/barkie1/mvau_pipeline_runtime_3ds_pe1/mvau_adapter/mvau1/data/rom_up_load.dat",   rom_up);
    end
`endif

    // =====================================================
    // internal state
    // =====================================================
    reg [15:0] cycle_cnt;
    reg [15:0] out_step_cnt;
    reg        is_outputting;

    reg signed [15:0] hidden_acc      [0:HIDDEN_CH-1];
    reg        [HIDDEN_CH-1:0] hidden_act;
    reg        [HIDDEN_CH-1:0] hidden_act_next;

    // PE=1 → single xnor pipe entry
    reg [31:0] xnor_pipe;
    reg        valid_pipe;
    wire [31:0] current_up_weights = rom_up[out_step_cnt];

    // hidden-path pipeline
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

    function [7:0] popcount32;
        input [31:0] vec; integer n;
        begin popcount32 = 0; for (n = 0; n < 32; n = n + 1) popcount32 = popcount32 + vec[n]; end
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
            xnor_pipe <= 32'd0;
            for (i = 0; i < HIDDEN_CH; i = i + 1) begin
                hidden_acc[i] <= $signed(rom_rc[i]);
                s1_down[i]    <= {SIMD{1'b0}};
                s2_xnor[i]    <= {SIMD{1'b0}};
                s3_pop[i]     <= 8'd0;
            end
        end
        else if (!stall) begin
            // Stage shift
            s3_valid <= s2_valid;
            s2_valid <= s1_valid;
            s1_valid <= s0_valid;
            s0_valid <= 1'b0;

            if (s1_valid) for (i = 0; i < HIDDEN_CH; i = i + 1) s2_xnor[i] <= ~(s1_act ^ s1_down[i]);
            if (s2_valid) for (i = 0; i < HIDDEN_CH; i = i + 1) s3_pop[i] <= popcount_simd(s2_xnor[i]);
            if (s3_valid) for (i = 0; i < HIDDEN_CH; i = i + 1) hidden_acc[i] <= hidden_acc[i] + s3_pop[i];

            if (valid_pipe) begin
                m_axis_tvalid <= 1'b1;
                m_axis_tdata  <= popcount32(xnor_pipe);
            end else begin
                m_axis_tvalid <= 1'b0;
            end

            if (is_outputting) begin
                valid_pipe <= 1'b1;
                xnor_pipe  <= ~({{(32-HIDDEN_CH){1'b0}}, hidden_act} ^ current_up_weights);
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

    // =====================================================
    // Config write port — PS writes adapter weights at runtime
    // Memory map (word addresses, same as v1):
    //   4..4+HIDDEN_CH-1                  : rom_rc[i]                   (16 words)
    //   128..128+IN_CHUNKS*HIDDEN_CH-1    : rom_down (entry*HIDDEN_CH + word)   (32 words)
    //   640..640+OUT_CH-1                 : rom_up[i] (narrow row, 32-bit each) (64 words)
    // =====================================================
    localparam CFG_RC_BASE   = 11'd4;
    localparam CFG_DOWN_BASE = 11'd128;
    localparam CFG_UP_BASE   = 11'd640;

    localparam HIDDEN_CH_BITS = $clog2(HIDDEN_CH);
    localparam OUT_CH_BITS    = $clog2(OUT_CH);
    localparam IN_CHUNKS_BITS = (IN_CHUNKS > 1) ? $clog2(IN_CHUNKS) : 1;

    wire [10:0] rc_offset   = cfg_waddr - CFG_RC_BASE;
    wire [10:0] down_offset = cfg_waddr - CFG_DOWN_BASE;
    wire [10:0] up_offset   = cfg_waddr - CFG_UP_BASE;

    always @(posedge aclk) begin
        if (cfg_wen) begin
            if (cfg_waddr >= CFG_RC_BASE && cfg_waddr < CFG_RC_BASE + HIDDEN_CH)
                rom_rc[rc_offset[HIDDEN_CH_BITS-1:0]] <= cfg_wdata[15:0];

            // rom_down wide row: chunk index = down_offset / HIDDEN_CH, hidden index = down_offset % HIDDEN_CH
            if (cfg_waddr >= CFG_DOWN_BASE && cfg_waddr < CFG_DOWN_BASE + IN_CHUNKS * HIDDEN_CH)
                rom_down[down_offset[HIDDEN_CH_BITS +: IN_CHUNKS_BITS]]
                        [down_offset[HIDDEN_CH_BITS-1:0] * SIMD +: SIMD] <= cfg_wdata[SIMD-1:0];

            // rom_up narrow row (PE=1): just index by offset
            if (cfg_waddr >= CFG_UP_BASE && cfg_waddr < CFG_UP_BASE + OUT_CH)
                rom_up[up_offset[OUT_CH_BITS-1:0]] <= cfg_wdata;
        end
    end

endmodule
