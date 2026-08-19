/*******************************************************************************
 * Module  : wishbone_master.v
 * Brief   : Single-outstanding Wishbone B4 Classic master.
 *
 * Description:
 *   Translates a one-cycle command interface (cmd_valid / cmd_ready) into a
 *   Wishbone B4 Classic single-transfer bus cycle.  Only one transaction is
 *   outstanding at a time; a second command is silently ignored while busy=1.
 *
 *   Termination priority (highest to lowest):
 *     1. wb_ack_i  — normal completion
 *     2. wb_err_i  — slave-reported error
 *     3. timeout   — no response within TIMEOUT_CYCLES clocks
 *
 * Parameters:
 *   ADDR_WIDTH     — address bus width in bits  (default 16)
 *   DATA_WIDTH     — data bus width in bits      (default 32)
 *   TIMEOUT_CYCLES — max clocks to wait for ACK/ERR before forcing error done
 *                    (default 16; must be >= 1)
 *
 * Timing:
 *   cmd_valid && cmd_ready : command accepted, fields latched into Wishbone bus
 *   busy=1                 : CYC/STB held, address/data/sel/we stable
 *   done (1-clock pulse)   : transaction complete; read_data and error are valid
 *
 * Author: Long Hai
 *******************************************************************************/

`timescale 1ns/1ps

module wishbone_master #(
    parameter integer ADDR_WIDTH     = 16,
    parameter integer DATA_WIDTH     = 32,
    parameter integer TIMEOUT_CYCLES = 16
) (
    input  wire                      clk,
    input  wire                      rst_n,       // Active-low synchronous reset

    // -------------------------------------------------------------------------
    // Command interface (host side)
    // -------------------------------------------------------------------------
    input  wire                      cmd_valid,   // Host presents a new command
    input  wire                      cmd_write,   // 1=write, 0=read
    input  wire [ADDR_WIDTH-1:0]     cmd_addr,    // Byte address
    input  wire [DATA_WIDTH-1:0]     cmd_wdata,   // Write payload (ignored on reads)
    input  wire [(DATA_WIDTH/8)-1:0] cmd_sel,     // Active byte lanes (1=update)
    output wire                      cmd_ready,   // 1 when master can accept a command
    output reg  [DATA_WIDTH-1:0]     read_data,   // Read result, valid on done cycle
    output reg                       busy,        // 1 while a transaction is outstanding
    output reg                       done,        // 1-clock pulse: transaction finished
    output reg                       error,       // 1 on done cycle if ERR or timeout

    // -------------------------------------------------------------------------
    // Wishbone B4 Classic master port
    // -------------------------------------------------------------------------
    output reg  [ADDR_WIDTH-1:0]     wb_adr_o,   // Address
    output reg  [DATA_WIDTH-1:0]     wb_dat_o,   // Write data (master → slave)
    output reg  [(DATA_WIDTH/8)-1:0] wb_sel_o,   // Byte enables
    output reg                       wb_we_o,    // Write enable: 1=write, 0=read
    output reg                       wb_cyc_o,   // Bus cycle active
    output reg                       wb_stb_o,   // Transfer request valid
    input  wire [DATA_WIDTH-1:0]     wb_dat_i,   // Read data (slave → master)
    input  wire                      wb_ack_i,   // Normal termination from slave
    input  wire                      wb_err_i    // Error termination from slave
);

    // -------------------------------------------------------------------------
    // Timeout counter width: ceil(log2(TIMEOUT_CYCLES)), minimum 1 bit
    // -------------------------------------------------------------------------
    localparam integer TIMEOUT_WIDTH = (TIMEOUT_CYCLES < 2) ? 1 : $clog2(TIMEOUT_CYCLES);
    // Comparison threshold sized to TIMEOUT_WIDTH bits (lint: truncation is safe by $clog2 construction).
    /* verilator lint_off WIDTHTRUNC */
    localparam [TIMEOUT_WIDTH-1:0] TIMEOUT_MAX = TIMEOUT_CYCLES - 1;
    /* verilator lint_on WIDTHTRUNC */
    reg [TIMEOUT_WIDTH-1:0] timeout_count;

    // cmd_ready is purely combinational: master accepts a new command only when idle
    assign cmd_ready = !busy;

    always @(posedge clk) begin
        if (!rst_n) begin
            // ---------------------------------------------------------------
            // Synchronous reset: release bus, clear all status outputs
            // ---------------------------------------------------------------
            read_data     <= {DATA_WIDTH{1'b0}};
            busy          <= 1'b0;
            done          <= 1'b0;
            error         <= 1'b0;
            wb_adr_o      <= {ADDR_WIDTH{1'b0}};
            wb_dat_o      <= {DATA_WIDTH{1'b0}};
            wb_sel_o      <= {(DATA_WIDTH/8){1'b0}};
            wb_we_o       <= 1'b0;
            wb_cyc_o      <= 1'b0;
            wb_stb_o      <= 1'b0;
            timeout_count <= {TIMEOUT_WIDTH{1'b0}};
        end else begin
            // Default: clear done every clock; set only in termination branches
            done <= 1'b0;

            if (!busy) begin
                // -----------------------------------------------------------
                // IDLE state: bus deasserted, ready to accept next command
                // -----------------------------------------------------------
                wb_cyc_o      <= 1'b0;
                wb_stb_o      <= 1'b0;
                error         <= 1'b0;
                timeout_count <= {TIMEOUT_WIDTH{1'b0}};

                if (cmd_valid) begin
                    // Latch all command fields into Wishbone outputs in one cycle.
                    // Wishbone rule: master must hold ADR, DAT, SEL, WE, CYC, STB
                    // stable from the start of a transfer until ACK/ERR is received.
                    wb_adr_o <= cmd_addr;
                    wb_dat_o <= cmd_wdata;
                    wb_sel_o <= cmd_sel;
                    wb_we_o  <= cmd_write;
                    wb_cyc_o <= 1'b1;
                    wb_stb_o <= 1'b1;
                    busy     <= 1'b1;
                end

            end else if (wb_ack_i || wb_err_i) begin
                // -----------------------------------------------------------
                // TERMINATION: slave replied with ACK or ERR
                // -----------------------------------------------------------
                // Capture read data only on a successful read (not on error).
                // Guard !wb_err_i prevents latching stale/undefined data when
                // ACK and ERR are simultaneously asserted by a buggy slave.
                if (wb_ack_i && !wb_err_i && !wb_we_o)
                    read_data <= wb_dat_i;

                error    <= wb_err_i;
                busy     <= 1'b0;
                done     <= 1'b1;
                wb_cyc_o <= 1'b0;
                wb_stb_o <= 1'b0;

            end else if (timeout_count == TIMEOUT_MAX) begin
                // -----------------------------------------------------------
                // TIMEOUT: slave did not respond within TIMEOUT_CYCLES clocks.
                // Force termination to prevent bus hang.
                // -----------------------------------------------------------
                error    <= 1'b1;
                busy     <= 1'b0;
                done     <= 1'b1;
                wb_cyc_o <= 1'b0;
                wb_stb_o <= 1'b0;

            end else begin
                // -----------------------------------------------------------
                // WAIT STATE: transfer in progress, no response yet
                // -----------------------------------------------------------
                timeout_count <= timeout_count + 1'b1;
            end
        end
    end

endmodule
