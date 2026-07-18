`timescale 1ns / 1ps

// =====================================================================
// adapter_cfg_hub — AXI-Lite slave → 8 unit config write ports
// =====================================================================
// Address space: 64 KB (16-bit byte address)
//   [15:13] selects unit:
//     000 = MVAU_hls_0 (0x0000-0x1FFF) — first conv layer thresholds
//     001 = MVAU1 (0x2000-0x3FFF)
//     010 = MVAU2 (0x4000-0x5FFF)
//     011 = MVAU3 (0x6000-0x7FFF)
//     100 = MVAU4 (0x8000-0x9FFF)
//     101 = MVAU5 (0xA000-0xBFFF)
//     110 = FC1/MVAU_hls_6 (0xC000-0xDFFF) — FC layer 1 thresholds
//     111 = FC2/MVAU_hls_7 (0xE000-0xFFFF) — FC layer 2 thresholds
//
//   [12:2] = 11-bit word address within each unit
//
// MVAU1-5 memory map (unchanged):
//   Word 0:              adapter_enable
//   Word 1152..1407:     thresh_mem[0..255]
//   Word 1408..1663:     sign_mem[0..255]
//
// MVAU_hls_0 memory map (unit 0, low half, byte addr 0x0000-0x0FFF):
//   Word 0..63:          thresh[ch], ch = step*16 + pe_idx
//
// Classifier memory map (unit 0, high half, byte addr 0x1000-0x1FFF):
//   Word 0..1023:        classifier weight[i], 8-bit
//
// FC1/FC2 memory map (new):
//   Word 0..511:         thresh[ch]
// =====================================================================

module adapter_cfg_hub #(
    parameter C_S_AXI_DATA_WIDTH = 32,
    parameter C_S_AXI_ADDR_WIDTH = 16
)(
    // AXI-Lite Slave Interface
    input  wire                                S_AXI_ACLK,
    input  wire                                S_AXI_ARESETN,

    input  wire [C_S_AXI_ADDR_WIDTH-1:0]       S_AXI_AWADDR,
    input  wire [2:0]                          S_AXI_AWPROT,
    input  wire                                S_AXI_AWVALID,
    output reg                                 S_AXI_AWREADY,

    input  wire [C_S_AXI_DATA_WIDTH-1:0]       S_AXI_WDATA,
    input  wire [(C_S_AXI_DATA_WIDTH/8)-1:0]   S_AXI_WSTRB,
    input  wire                                S_AXI_WVALID,
    output reg                                 S_AXI_WREADY,

    output reg  [1:0]                          S_AXI_BRESP,
    output reg                                 S_AXI_BVALID,
    input  wire                                S_AXI_BREADY,

    input  wire [C_S_AXI_ADDR_WIDTH-1:0]       S_AXI_ARADDR,
    input  wire [2:0]                          S_AXI_ARPROT,
    input  wire                                S_AXI_ARVALID,
    output reg                                 S_AXI_ARREADY,

    output reg  [C_S_AXI_DATA_WIDTH-1:0]       S_AXI_RDATA,
    output reg  [1:0]                          S_AXI_RRESP,
    output reg                                 S_AXI_RVALID,
    input  wire                                S_AXI_RREADY,

    // Config output ports to 5 MVAUs (existing)
    output reg  [10:0]  mvau1_cfg_waddr,
    output reg  [31:0]  mvau1_cfg_wdata,
    output reg          mvau1_cfg_wen,

    output reg  [10:0]  mvau2_cfg_waddr,
    output reg  [31:0]  mvau2_cfg_wdata,
    output reg          mvau2_cfg_wen,

    output reg  [10:0]  mvau3_cfg_waddr,
    output reg  [31:0]  mvau3_cfg_wdata,
    output reg          mvau3_cfg_wen,

    output reg  [10:0]  mvau4_cfg_waddr,
    output reg  [31:0]  mvau4_cfg_wdata,
    output reg          mvau4_cfg_wen,

    output reg  [10:0]  mvau5_cfg_waddr,
    output reg  [31:0]  mvau5_cfg_wdata,
    output reg          mvau5_cfg_wen,

    // Config output port for MVAU_hls_0 (first conv layer)
    output reg  [5:0]   mvau0_cfg_waddr,
    output reg  [31:0]  mvau0_cfg_wdata,
    output reg          mvau0_cfg_wen,

    // Config output port for FC1 (MVAU_hls_6) — wdata widened to 32-bit for BD wiring; low 8 bits used
    output reg  [8:0]   fc1_cfg_waddr,
    output reg  [31:0]  fc1_cfg_wdata,
    output reg          fc1_cfg_wen,

    // Config output port for FC2 (MVAU_hls_7) — wdata widened to 32-bit for BD wiring; low 10 bits used
    output reg  [8:0]   fc2_cfg_waddr,
    output reg  [31:0]  fc2_cfg_wdata,
    output reg          fc2_cfg_wen,

    // Config output port for classifier (MVAU_hls_8 memstream weights)
    output reg  [9:0]   cls_cfg_waddr,
    output reg  [7:0]   cls_cfg_wdata,
    output reg          cls_cfg_wen
);

    // =========================================================
    // AXI-Lite write state machine
    // =========================================================
    reg [C_S_AXI_ADDR_WIDTH-1:0] aw_addr_latched;
    reg aw_done, w_done;

    always @(posedge S_AXI_ACLK) begin
        if (!S_AXI_ARESETN) begin
            S_AXI_AWREADY <= 1'b0;
            S_AXI_WREADY  <= 1'b0;
            S_AXI_BVALID  <= 1'b0;
            S_AXI_BRESP   <= 2'b00;
            aw_done       <= 1'b0;
            w_done        <= 1'b0;
            aw_addr_latched <= {C_S_AXI_ADDR_WIDTH{1'b0}};

            mvau1_cfg_wen <= 1'b0;
            mvau2_cfg_wen <= 1'b0;
            mvau3_cfg_wen <= 1'b0;
            mvau4_cfg_wen <= 1'b0;
            mvau5_cfg_wen <= 1'b0;
            mvau0_cfg_wen <= 1'b0;
            fc1_cfg_wen   <= 1'b0;
            fc2_cfg_wen   <= 1'b0;
            cls_cfg_wen   <= 1'b0;
        end else begin
            // Default: deassert write enables after one cycle
            mvau1_cfg_wen <= 1'b0;
            mvau2_cfg_wen <= 1'b0;
            mvau3_cfg_wen <= 1'b0;
            mvau4_cfg_wen <= 1'b0;
            mvau5_cfg_wen <= 1'b0;
            mvau0_cfg_wen <= 1'b0;
            fc1_cfg_wen   <= 1'b0;
            fc2_cfg_wen   <= 1'b0;
            cls_cfg_wen   <= 1'b0;

            // AW channel
            if (S_AXI_AWVALID && !aw_done && !S_AXI_BVALID) begin
                S_AXI_AWREADY   <= 1'b1;
                aw_addr_latched <= S_AXI_AWADDR;
                aw_done         <= 1'b1;
            end else begin
                S_AXI_AWREADY <= 1'b0;
            end

            // W channel
            if (S_AXI_WVALID && !w_done && !S_AXI_BVALID) begin
                S_AXI_WREADY <= 1'b1;
                w_done       <= 1'b1;
            end else begin
                S_AXI_WREADY <= 1'b0;
            end

            // Both AW and W done → issue write + B response
            if (aw_done && w_done && !S_AXI_BVALID) begin
                S_AXI_BVALID <= 1'b1;
                S_AXI_BRESP  <= 2'b00;  // OKAY

                // Decode unit select and dispatch
                case (aw_addr_latched[15:13])
                    3'd0: begin  // Unit 0: split by bit[12]
                        if (!aw_addr_latched[12]) begin
                            // Low half: MVAU_hls_0 thresholds (word 0-63)
                            mvau0_cfg_waddr <= aw_addr_latched[7:2];
                            mvau0_cfg_wdata <= S_AXI_WDATA;
                            mvau0_cfg_wen   <= 1'b1;
                        end else begin
                            // High half: Classifier weights (word 0-1023)
                            cls_cfg_waddr   <= aw_addr_latched[11:2];
                            cls_cfg_wdata   <= S_AXI_WDATA[7:0];
                            cls_cfg_wen     <= 1'b1;
                        end
                    end
                    3'd1: begin
                        mvau1_cfg_waddr <= aw_addr_latched[12:2];
                        mvau1_cfg_wdata <= S_AXI_WDATA;
                        mvau1_cfg_wen   <= 1'b1;
                    end
                    3'd2: begin
                        mvau2_cfg_waddr <= aw_addr_latched[12:2];
                        mvau2_cfg_wdata <= S_AXI_WDATA;
                        mvau2_cfg_wen   <= 1'b1;
                    end
                    3'd3: begin
                        mvau3_cfg_waddr <= aw_addr_latched[12:2];
                        mvau3_cfg_wdata <= S_AXI_WDATA;
                        mvau3_cfg_wen   <= 1'b1;
                    end
                    3'd4: begin
                        mvau4_cfg_waddr <= aw_addr_latched[12:2];
                        mvau4_cfg_wdata <= S_AXI_WDATA;
                        mvau4_cfg_wen   <= 1'b1;
                    end
                    3'd5: begin
                        mvau5_cfg_waddr <= aw_addr_latched[12:2];
                        mvau5_cfg_wdata <= S_AXI_WDATA;
                        mvau5_cfg_wen   <= 1'b1;
                    end
                    3'd6: begin  // FC1: word addr [8:0] → 512 thresholds (low 8 bits used)
                        fc1_cfg_waddr   <= aw_addr_latched[10:2];
                        fc1_cfg_wdata   <= S_AXI_WDATA;
                        fc1_cfg_wen     <= 1'b1;
                    end
                    3'd7: begin  // FC2: word addr [8:0] → 512 thresholds (low 10 bits used)
                        fc2_cfg_waddr   <= aw_addr_latched[10:2];
                        fc2_cfg_wdata   <= S_AXI_WDATA;
                        fc2_cfg_wen     <= 1'b1;
                    end
                endcase

                aw_done <= 1'b0;
                w_done  <= 1'b0;
            end

            // B handshake
            if (S_AXI_BVALID && S_AXI_BREADY) begin
                S_AXI_BVALID <= 1'b0;
            end
        end
    end

    // =========================================================
    // AXI-Lite read (stub — return 0, write-only interface)
    // =========================================================
    always @(posedge S_AXI_ACLK) begin
        if (!S_AXI_ARESETN) begin
            S_AXI_ARREADY <= 1'b0;
            S_AXI_RVALID  <= 1'b0;
            S_AXI_RDATA   <= 32'd0;
            S_AXI_RRESP   <= 2'b00;
        end else begin
            if (S_AXI_ARVALID && !S_AXI_RVALID) begin
                S_AXI_ARREADY <= 1'b1;
                S_AXI_RVALID  <= 1'b1;
                S_AXI_RDATA   <= 32'd0;
                S_AXI_RRESP   <= 2'b00;
            end else begin
                S_AXI_ARREADY <= 1'b0;
            end

            if (S_AXI_RVALID && S_AXI_RREADY) begin
                S_AXI_RVALID <= 1'b0;
            end
        end
    end

endmodule
