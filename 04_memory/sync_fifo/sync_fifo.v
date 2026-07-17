/*******************************************************************************
 * Module: sync_fifo.v                                                         *
 * Description: Parameterized single-clock FIFO with registered read data,     *
 *              full/empty flags, occupancy level, and simultaneous            *
 *              read/write support.                                           *
 * File Created: Wednesday, 22nd April 2026 11:38:00 am                        *
 * Author: Long Hai                                                            *
 * -----                                                                       *
 * Last Modified: Friday, 17th July 2026                                       *
 * Modified By: Long Hai                                                       *
 ******************************************************************************/

`timescale 1ns/1ps

module sync_fifo #(
    parameter DATA_WIDTH = 8,  // Data width in bits
    parameter ADDR_WIDTH = 4   // Address width; FIFO depth = 2^ADDR_WIDTH
) (
    input  wire                  clk,    // Clock
    input  wire                  rst_n,  // Active-low synchronous reset
    input  wire                  wr_en,  // Write enable
    input  wire                  rd_en,  // Read enable
    input  wire [DATA_WIDTH-1:0] din,    // Write data
    output reg  [DATA_WIDTH-1:0] dout,   // Registered read data
    output reg                   full,   // FIFO full flag
    output reg                   empty,  // FIFO empty flag
    output reg  [ADDR_WIDTH:0]   level   // Occupancy count: 0..DEPTH
);

    // -------------------------------------------------------------------------
    // Parameters / Localparams
    // -------------------------------------------------------------------------
    localparam DEPTH = (1 << ADDR_WIDTH);

    // -------------------------------------------------------------------------
    // Memory and pointers
    // -------------------------------------------------------------------------
    reg [DATA_WIDTH-1:0] mem [0:DEPTH-1];
    reg [ADDR_WIDTH-1:0] wr_ptr;
    reg [ADDR_WIDTH-1:0] rd_ptr;

    // -------------------------------------------------------------------------
    // Qualified operations
    // -------------------------------------------------------------------------
    wire rd_fire;
    wire wr_fire;

    assign rd_fire = rd_en && !empty;
    assign wr_fire = wr_en && (!full || rd_fire);

    // -------------------------------------------------------------------------
    // Single-clock FIFO control
    // -------------------------------------------------------------------------
    always @(posedge clk) begin
        if (!rst_n) begin
            wr_ptr <= {ADDR_WIDTH{1'b0}};
            rd_ptr <= {ADDR_WIDTH{1'b0}};
            level  <= {(ADDR_WIDTH+1){1'b0}};
            full   <= 1'b0;
            empty  <= 1'b1;
            dout   <= {DATA_WIDTH{1'b0}};
        end else begin
            if (rd_fire) begin
                dout   <= mem[rd_ptr];
                rd_ptr <= rd_ptr + 1'b1;
            end

            if (wr_fire) begin
                mem[wr_ptr] <= din;
                wr_ptr      <= wr_ptr + 1'b1;
            end

            case ({wr_fire, rd_fire})
                2'b10:    level <= level + 1'b1;  // write only: +1
                2'b01:    level <= level - 1'b1;  // read only:  -1
                2'b11:    level <= level;          // simultaneous R/W: net 0
                default:  level <= level;          // no operation
            endcase

            case ({wr_fire, rd_fire})
                2'b10: begin              // write only
                    full  <= (level == (DEPTH - 1));
                    empty <= 1'b0;
                end
                2'b01: begin              // read only
                    full  <= 1'b0;
                    empty <= (level == 1);
                end
                2'b11: begin              // simultaneous R/W: level unchanged
                    full  <= (level == DEPTH);
                    empty <= (level == 0);
                end
                default: begin            // no operation
                    full  <= (level == DEPTH);
                    empty <= (level == 0);
                end
            endcase
        end
    end

endmodule
