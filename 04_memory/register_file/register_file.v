/*******************************************************************************
 * Module: register_file.v                                                     *
 * Description: Parameterized 2-read / 1-write register file with synchronous  *
 *              active-low reset and optional hardwired zero register.         *
 * File Created: Wednesday, 22nd April 2026 11:38:00 am                        *
 * Author: Long Hai                                                            *
 * -----                                                                       *
 * Last Modified: Tuesday, 14th July 2026                                      *
 * Modified By:                                                           *
 ******************************************************************************/

`timescale 1ns/1ps

module register_file #(
    parameter DATA_WIDTH     = 32,  // Data width in bits
    parameter ADDR_WIDTH     = 5,   // Address width; register count = 2^ADDR_WIDTH
    parameter ZERO_REG_ENABLE = 1   // When 1, register x0 always reads as zero
) (
    input  wire                      clk,     // Clock
    input  wire                      rst_n,   // Active-low synchronous reset
    input  wire                      we,      // Write enable
    input  wire [ADDR_WIDTH-1:0]     waddr,   // Write register address
    input  wire [DATA_WIDTH-1:0]     wdata,   // Write data
    input  wire [ADDR_WIDTH-1:0]     raddr1,  // Read port 1 address
    input  wire [ADDR_WIDTH-1:0]     raddr2,  // Read port 2 address
    output wire [DATA_WIDTH-1:0]     rdata1,  // Read port 1 data
    output wire [DATA_WIDTH-1:0]     rdata2   // Read port 2 data
);

    // -------------------------------------------------------------------------
    // Parameters / Localparams
    // -------------------------------------------------------------------------
    localparam NUM_REGS = (1 << ADDR_WIDTH);

    // -------------------------------------------------------------------------
    // Register storage
    // -------------------------------------------------------------------------
    reg [DATA_WIDTH-1:0] regs [0:NUM_REGS-1];

    integer i;

    // -------------------------------------------------------------------------
    // Write port and synchronous reset
    // -------------------------------------------------------------------------
    always @(posedge clk) begin
        if (!rst_n) begin
            for (i = 0; i < NUM_REGS; i = i + 1) begin
                regs[i] <= {DATA_WIDTH{1'b0}};
            end
        end else if (we) begin
            if (!(ZERO_REG_ENABLE && (waddr == {ADDR_WIDTH{1'b0}}))) begin
                regs[waddr] <= wdata;
            end
        end
    end

    // -------------------------------------------------------------------------
    // Asynchronous read ports
    // -------------------------------------------------------------------------
    assign rdata1 = (ZERO_REG_ENABLE && (raddr1 == {ADDR_WIDTH{1'b0}})) ?
                    {DATA_WIDTH{1'b0}} : regs[raddr1];

    assign rdata2 = (ZERO_REG_ENABLE && (raddr2 == {ADDR_WIDTH{1'b0}})) ?
                    {DATA_WIDTH{1'b0}} : regs[raddr2];

endmodule
