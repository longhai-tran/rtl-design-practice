/*******************************************************************************
 * Module  : wishbone_interconnect.v
 * Brief   : One-master / two-slave Wishbone B4 address decoder and response mux.
 *
 * Description:
 *   Routes a single master's request to one of two slaves based on the upper
 *   nibble of the address, and multiplexes the selected slave's response back
 *   to the master.  All logic is purely combinational (no registers).
 *
 *   Address decode (uses ADR[ADDR_WIDTH-1 -: 4], i.e. the top nibble):
 *     4'h0  ->  Slave 0   (address range 0x0000–0x0FFF with 16-bit ADDR_WIDTH)
 *     4'h1  ->  Slave 1   (address range 0x1000–0x1FFF)
 *     other ->  Unmapped: combinational ERR is asserted immediately;
 *               master will sample ERR on the next clock edge without timeout.
 *
 *   Fan-out: ADR, DAT_M→S, SEL, and WE are broadcast to both slaves.
 *   CYC and STB are individually gated so only the selected slave sees a
 *   valid request.  Unselected slaves remain idle.
 *
 * Parameters:
 *   ADDR_WIDTH — address bus width (default 16)
 *   DATA_WIDTH — data bus width   (default 32)
 *
 * Author: Long Hai
 *******************************************************************************/

`timescale 1ns/1ps

module wishbone_interconnect #(
    parameter integer ADDR_WIDTH = 16,
    parameter integer DATA_WIDTH = 32
) (
    // -------------------------------------------------------------------------
    // Master-facing port (signals named from the master's perspective)
    // -------------------------------------------------------------------------
    input  wire [ADDR_WIDTH-1:0]     m_adr_i,   // Address from master
    input  wire [DATA_WIDTH-1:0]     m_dat_i,   // Write data from master
    input  wire [(DATA_WIDTH/8)-1:0] m_sel_i,   // Byte enables from master
    input  wire                      m_we_i,    // Write enable from master
    input  wire                      m_cyc_i,   // Bus cycle active (from master)
    input  wire                      m_stb_i,   // Transfer request (from master)
    output reg  [DATA_WIDTH-1:0]     m_dat_o,   // Read data returned to master
    output reg                       m_ack_o,   // ACK forwarded to master
    output reg                       m_err_o,   // ERR forwarded to master (or generated here)

    // -------------------------------------------------------------------------
    // Slave 0 port
    // -------------------------------------------------------------------------
    output wire [ADDR_WIDTH-1:0]     s0_adr_o,  // Address to slave 0
    output wire [DATA_WIDTH-1:0]     s0_dat_o,  // Write data to slave 0
    output wire [(DATA_WIDTH/8)-1:0] s0_sel_o,  // Byte enables to slave 0
    output wire                      s0_we_o,   // Write enable to slave 0
    output wire                      s0_cyc_o,  // CYC gated for slave 0
    output wire                      s0_stb_o,  // STB gated for slave 0
    input  wire [DATA_WIDTH-1:0]     s0_dat_i,  // Read data from slave 0
    input  wire                      s0_ack_i,  // ACK from slave 0
    input  wire                      s0_err_i,  // ERR from slave 0

    // -------------------------------------------------------------------------
    // Slave 1 port
    // -------------------------------------------------------------------------
    output wire [ADDR_WIDTH-1:0]     s1_adr_o,  // Address to slave 1
    output wire [DATA_WIDTH-1:0]     s1_dat_o,  // Write data to slave 1
    output wire [(DATA_WIDTH/8)-1:0] s1_sel_o,  // Byte enables to slave 1
    output wire                      s1_we_o,   // Write enable to slave 1
    output wire                      s1_cyc_o,  // CYC gated for slave 1
    output wire                      s1_stb_o,  // STB gated for slave 1
    input  wire [DATA_WIDTH-1:0]     s1_dat_i,  // Read data from slave 1
    input  wire                      s1_ack_i,  // ACK from slave 1
    input  wire                      s1_err_i   // ERR from slave 1
);

    // -------------------------------------------------------------------------
    // Address decode: compare top 4 bits of the address against slave regions.
    // select_s0 and select_s1 are mutually exclusive by construction.
    // -------------------------------------------------------------------------
    wire select_s0 = (m_adr_i[ADDR_WIDTH-1 -: 4] == 4'h0);
    wire select_s1 = (m_adr_i[ADDR_WIDTH-1 -: 4] == 4'h1);

    // A request is active when both CYC and STB are asserted
    wire request   = m_cyc_i && m_stb_i;

    // -------------------------------------------------------------------------
    // Request fan-out: broadcast address, data, sel, and we to all slaves.
    // Each slave relies on its own CYC/STB being gated to determine whether
    // it should respond.
    // -------------------------------------------------------------------------
    assign s0_adr_o = m_adr_i;
    assign s0_dat_o = m_dat_i;
    assign s0_sel_o = m_sel_i;
    assign s0_we_o  = m_we_i;

    assign s1_adr_o = m_adr_i;
    assign s1_dat_o = m_dat_i;
    assign s1_sel_o = m_sel_i;
    assign s1_we_o  = m_we_i;

    // Gate CYC and STB so only the selected slave sees a valid request
    assign s0_cyc_o = m_cyc_i && select_s0;
    assign s1_cyc_o = m_cyc_i && select_s1;
    assign s0_stb_o = m_stb_i && select_s0;
    assign s1_stb_o = m_stb_i && select_s1;

    // -------------------------------------------------------------------------
    // Response mux: combinational selection of the active slave's response.
    //   - Default outputs are 0 when no request is active (no latch inference
    //     because all paths are covered).
    //   - Unmapped addresses generate an immediate combinational ERR so the
    //     master receives a deterministic error on the next clock without
    //     waiting for the full TIMEOUT_CYCLES.
    // -------------------------------------------------------------------------
    always @(*) begin
        // Safe defaults: no response while bus is idle
        m_dat_o = {DATA_WIDTH{1'b0}};
        m_ack_o = 1'b0;
        m_err_o = 1'b0;

        if (request) begin
            if (select_s0) begin
                // Route slave 0 response to master
                m_dat_o = s0_dat_i;
                m_ack_o = s0_ack_i;
                m_err_o = s0_err_i;
            end else if (select_s1) begin
                // Route slave 1 response to master
                m_dat_o = s1_dat_i;
                m_ack_o = s1_ack_i;
                m_err_o = s1_err_i;
            end else begin
                // Unmapped address: assert ERR combinationally.
                // Master samples this on the next rising edge and terminates
                // immediately — no timeout delay for unmapped regions.
                m_err_o = 1'b1;
            end
        end
    end

endmodule
