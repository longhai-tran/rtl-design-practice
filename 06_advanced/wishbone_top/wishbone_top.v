/*******************************************************************************
 * Module  : wishbone_top.v
 * Brief   : Wishbone B4 subsystem: one master, one interconnect, two slaves.
 *
 * Description:
 *   Integration wrapper that ties together:
 *     - wishbone_master    : accepts one-cycle commands and drives the Wishbone bus
 *     - wishbone_interconnect : decodes addresses and muxes responses
 *     - wishbone_slave x2  : register-bank peripherals at two address regions
 *
 *   Internal Wishbone bus signals (wb_*) are exposed as top-level outputs for
 *   waveform inspection and on-chip debug.  They carry no functional meaning at
 *   the system boundary; connect only to observation logic (ILA, SignalTap, etc.).
 *
 *   Address map:
 *     0x0000–0x0FFF  ->  Slave 0  (ID = 0x57425330, "WBS0")
 *     0x1000–0x1FFF  ->  Slave 1  (ID = 0x57425331, "WBS1")
 *     0x2000–0xFFFF  ->  Unmapped (immediate ERR from interconnect)
 *
 * Parameters:
 *   ADDR_WIDTH — address bus width propagated to all sub-modules (default 16)
 *   DATA_WIDTH — data bus width propagated to all sub-modules   (default 32)
 *
 * Author: Long Hai
 *******************************************************************************/

`timescale 1ns/1ps

module wishbone_top #(
    parameter integer ADDR_WIDTH = 16,
    parameter integer DATA_WIDTH = 32
) (
    input  wire                      clk,
    input  wire                      rst_n,        // Active-low synchronous reset

    // -------------------------------------------------------------------------
    // Command interface (same as wishbone_master command port)
    // -------------------------------------------------------------------------
    input  wire                      cmd_valid,    // Host presents a new command
    input  wire                      cmd_write,    // 1=write, 0=read
    input  wire [ADDR_WIDTH-1:0]     cmd_addr,     // Byte address
    input  wire [DATA_WIDTH-1:0]     cmd_wdata,    // Write payload
    input  wire [(DATA_WIDTH/8)-1:0] cmd_sel,      // Active byte lanes
    output wire                      cmd_ready,    // Master ready to accept command
    output wire [DATA_WIDTH-1:0]     read_data,    // Read result (valid on done cycle)
    output wire                      busy,         // Transaction outstanding
    output wire                      done,         // 1-clock completion pulse
    output wire                      error,        // ERR or timeout on done cycle

    // -------------------------------------------------------------------------
    // Internal Wishbone bus — exposed for debug / waveform observation only
    // -------------------------------------------------------------------------
    output wire [ADDR_WIDTH-1:0]     wb_addr,      // Master address
    output wire [DATA_WIDTH-1:0]     wb_wdata,     // Master write data
    output wire [DATA_WIDTH-1:0]     wb_rdata,     // Response read data (muxed)
    output wire [(DATA_WIDTH/8)-1:0] wb_sel,       // Byte enables
    output wire                      wb_we,        // Write enable
    output wire                      wb_cyc,       // CYC
    output wire                      wb_stb,       // STB
    output wire                      wb_ack,       // ACK (from interconnect mux)
    output wire                      wb_err,       // ERR (from interconnect mux)

    // -------------------------------------------------------------------------
    // Slave register outputs — for downstream logic or observation
    // -------------------------------------------------------------------------
    output wire [DATA_WIDTH-1:0]     slave0_control,
    output wire [DATA_WIDTH-1:0]     slave0_data,
    output wire [DATA_WIDTH-1:0]     slave0_scratch,
    output wire [DATA_WIDTH-1:0]     slave1_control,
    output wire [DATA_WIDTH-1:0]     slave1_data,
    output wire [DATA_WIDTH-1:0]     slave1_scratch
);

    // -------------------------------------------------------------------------
    // Internal wires: point-to-point Wishbone links between interconnect and
    // each slave.  Prefixed s0_* for slave 0 and s1_* for slave 1.
    // -------------------------------------------------------------------------
    wire [ADDR_WIDTH-1:0]     s0_addr,  s1_addr;
    wire [DATA_WIDTH-1:0]     s0_wdata, s1_wdata;
    wire [DATA_WIDTH-1:0]     s0_rdata, s1_rdata;
    wire [(DATA_WIDTH/8)-1:0] s0_sel,   s1_sel;
    wire s0_we,  s0_cyc,  s0_stb,  s0_ack,  s0_err;
    wire s1_we,  s1_cyc,  s1_stb,  s1_ack,  s1_err;

    // -------------------------------------------------------------------------
    // Master: translates one-cycle commands into Wishbone Classic bus cycles
    // -------------------------------------------------------------------------
    wishbone_master #(
        .ADDR_WIDTH(ADDR_WIDTH),
        .DATA_WIDTH(DATA_WIDTH)
    ) u_master (
        .clk        (clk),
        .rst_n      (rst_n),
        // Command interface
        .cmd_valid  (cmd_valid),
        .cmd_write  (cmd_write),
        .cmd_addr   (cmd_addr),
        .cmd_wdata  (cmd_wdata),
        .cmd_sel    (cmd_sel),
        .cmd_ready  (cmd_ready),
        .read_data  (read_data),
        .busy       (busy),
        .done       (done),
        .error      (error),
        // Wishbone master port (drives the internal bus)
        .wb_adr_o   (wb_addr),
        .wb_dat_o   (wb_wdata),
        .wb_sel_o   (wb_sel),
        .wb_we_o    (wb_we),
        .wb_cyc_o   (wb_cyc),
        .wb_stb_o   (wb_stb),
        .wb_dat_i   (wb_rdata),
        .wb_ack_i   (wb_ack),
        .wb_err_i   (wb_err)
    );

    // -------------------------------------------------------------------------
    // Interconnect: address decoder + response multiplexer (combinational)
    // -------------------------------------------------------------------------
    wishbone_interconnect #(
        .ADDR_WIDTH(ADDR_WIDTH),
        .DATA_WIDTH(DATA_WIDTH)
    ) u_interconnect (
        // Master-facing port
        .m_adr_i    (wb_addr),
        .m_dat_i    (wb_wdata),
        .m_sel_i    (wb_sel),
        .m_we_i     (wb_we),
        .m_cyc_i    (wb_cyc),
        .m_stb_i    (wb_stb),
        .m_dat_o    (wb_rdata),
        .m_ack_o    (wb_ack),
        .m_err_o    (wb_err),
        // Slave 0 port
        .s0_adr_o   (s0_addr),
        .s0_dat_o   (s0_wdata),
        .s0_sel_o   (s0_sel),
        .s0_we_o    (s0_we),
        .s0_cyc_o   (s0_cyc),
        .s0_stb_o   (s0_stb),
        .s0_dat_i   (s0_rdata),
        .s0_ack_i   (s0_ack),
        .s0_err_i   (s0_err),
        // Slave 1 port
        .s1_adr_o   (s1_addr),
        .s1_dat_o   (s1_wdata),
        .s1_sel_o   (s1_sel),
        .s1_we_o    (s1_we),
        .s1_cyc_o   (s1_cyc),
        .s1_stb_o   (s1_stb),
        .s1_dat_i   (s1_rdata),
        .s1_ack_i   (s1_ack),
        .s1_err_i   (s1_err)
    );

    // -------------------------------------------------------------------------
    // Slave 0: register bank at address region 0x0xxx
    //   ID_VALUE = 0x57425330 = ASCII "WBS0"
    // -------------------------------------------------------------------------
    wishbone_slave #(
        .ADDR_WIDTH(ADDR_WIDTH),
        .DATA_WIDTH(DATA_WIDTH),
        .ID_VALUE  (32'h5742_5330)
    ) u_slave0 (
        .clk        (clk),
        .rst_n      (rst_n),
        .wb_adr_i   (s0_addr),
        .wb_dat_i   (s0_wdata),
        .wb_sel_i   (s0_sel),
        .wb_we_i    (s0_we),
        .wb_cyc_i   (s0_cyc),
        .wb_stb_i   (s0_stb),
        .wb_dat_o   (s0_rdata),
        .wb_ack_o   (s0_ack),
        .wb_err_o   (s0_err),
        .control_o  (slave0_control),
        .data_o     (slave0_data),
        .scratch_o  (slave0_scratch)
    );

    // -------------------------------------------------------------------------
    // Slave 1: register bank at address region 0x1xxx
    //   ID_VALUE = 0x57425331 = ASCII "WBS1"
    // -------------------------------------------------------------------------
    wishbone_slave #(
        .ADDR_WIDTH(ADDR_WIDTH),
        .DATA_WIDTH(DATA_WIDTH),
        .ID_VALUE  (32'h5742_5331)
    ) u_slave1 (
        .clk        (clk),
        .rst_n      (rst_n),
        .wb_adr_i   (s1_addr),
        .wb_dat_i   (s1_wdata),
        .wb_sel_i   (s1_sel),
        .wb_we_i    (s1_we),
        .wb_cyc_i   (s1_cyc),
        .wb_stb_i   (s1_stb),
        .wb_dat_o   (s1_rdata),
        .wb_ack_o   (s1_ack),
        .wb_err_o   (s1_err),
        .control_o  (slave1_control),
        .data_o     (slave1_data),
        .scratch_o  (slave1_scratch)
    );

endmodule
