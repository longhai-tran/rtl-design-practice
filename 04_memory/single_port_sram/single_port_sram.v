/*******************************************************************************
 * Module: single_port_sram.v                                                  *
 * Description: Parameterized single-port synchronous SRAM with chip enable,   *
 *              write enable, registered read data, and read-first behavior.   *
 * File Created: Wednesday, 22nd April 2026 11:38:00 am                        *
 * Author: Long Hai                                                            *
 * -----                                                                       *
 * Last Modified: Thursday, 16th July 2026                                     *
 * Modified By: Long Hai                                                       *
 ******************************************************************************/

`timescale 1ns/1ps

module single_port_sram #(
    parameter DATA_WIDTH = 8,   // Data width in bits
    parameter ADDR_WIDTH = 4    // Address width; SRAM depth = 2^ADDR_WIDTH
) (
    input  wire                  clk,    // Clock
    input  wire                  rst_n,  // Active-low synchronous reset for rdata
    input  wire                  cs,     // Chip select / memory enable
    input  wire                  we,     // Write enable: 1=write, 0=read
    input  wire [ADDR_WIDTH-1:0] addr,   // Shared read/write address
    input  wire [DATA_WIDTH-1:0] wdata,  // Write data
    output reg  [DATA_WIDTH-1:0] rdata   // Registered read data
);

    // -------------------------------------------------------------------------
    // Parameters / Localparams
    // -------------------------------------------------------------------------
    localparam DEPTH = (1 << ADDR_WIDTH);

    // -------------------------------------------------------------------------
    // Memory array
    // -------------------------------------------------------------------------
    reg [DATA_WIDTH-1:0] mem [0:DEPTH-1];

    // -------------------------------------------------------------------------
    // Single synchronous port
    // -------------------------------------------------------------------------
    always @(posedge clk) begin
        if (!rst_n) begin
            rdata <= {DATA_WIDTH{1'b0}};
        end else if (cs) begin
            rdata <= mem[addr];

            if (we) begin
                mem[addr] <= wdata;
            end
        end
    end

endmodule
