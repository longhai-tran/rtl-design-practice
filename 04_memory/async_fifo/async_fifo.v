/*******************************************************************************
 * Module: async_fifo.v                                                        *
 * Description: Dual-clock asynchronous FIFO using Gray-code pointers and      *
 *              2-FF synchronizers for safe clock-domain-crossing (CDC).       *
 *              full flag is generated in the write domain;                    *
 *              empty flag is generated in the read domain.                    *
 * File Created: Wednesday, 22nd April 2026 11:34:44 am                        *
 * Author: Long Hai                                                            *
 * -----                                                                       *
 * Last Modified: Tuesday, 22nd April 2026 1:31:00 pm                         *
 * Modified By: Long Hai                                                       *
 ******************************************************************************/

`timescale 1ns/1ps

module async_fifo #(
    parameter DATA_WIDTH = 8,   // Data width in bits
    parameter ADDR_WIDTH = 4    // Address width; FIFO depth = 2^ADDR_WIDTH
) (
    input  wire                  wr_clk,  // Write clock domain
    input  wire                  rd_clk,  // Read clock domain
    input  wire                  rst_n,   // Active-low asynchronous reset (both domains)
    input  wire                  wr_en,   // Write enable (effective only when full=0)
    input  wire                  rd_en,   // Read enable (effective only when empty=0)
    input  wire [DATA_WIDTH-1:0] din,     // Write data input
    output reg  [DATA_WIDTH-1:0] dout,    // Read data output (registered)
    output reg                   full,    // FIFO full flag (write domain)
    output reg                   empty    // FIFO empty flag (read domain)
);

    // -------------------------------------------------------------------------
    // Parameters / Localparams
    // -------------------------------------------------------------------------
    localparam DEPTH = (1 << ADDR_WIDTH);  // Total FIFO depth
    localparam PTR_W = ADDR_WIDTH + 1;     // Extra MSB for full/empty distinction

    // -------------------------------------------------------------------------
    // Memory array
    // -------------------------------------------------------------------------
    reg [DATA_WIDTH-1:0] mem [0:DEPTH-1];

    // -------------------------------------------------------------------------
    // Write / Read pointers (binary + Gray)
    // -------------------------------------------------------------------------
    reg [PTR_W-1:0] wr_bin;   // Write pointer — binary (write domain)
    reg [PTR_W-1:0] wr_gray;  // Write pointer — Gray  (write domain)
    reg [PTR_W-1:0] rd_bin;   // Read  pointer — binary (read domain)
    reg [PTR_W-1:0] rd_gray;  // Read  pointer — Gray  (read domain)

    // -------------------------------------------------------------------------
    // 2-FF Synchronizers (CDC)
    // -------------------------------------------------------------------------
    reg [PTR_W-1:0] rd_gray_sync1;  // rd_gray → write domain, stage 1
    reg [PTR_W-1:0] rd_gray_sync2;  // rd_gray → write domain, stage 2
    reg [PTR_W-1:0] wr_gray_sync1;  // wr_gray → read  domain, stage 1
    reg [PTR_W-1:0] wr_gray_sync2;  // wr_gray → read  domain, stage 2

    // -------------------------------------------------------------------------
    // Qualified write / read strobes
    // -------------------------------------------------------------------------
    wire wr_fire;  // Actual write: wr_en asserted and FIFO not full
    wire rd_fire;  // Actual read:  rd_en asserted and FIFO not empty

    // -------------------------------------------------------------------------
    // Combinational next-state pointer values
    // -------------------------------------------------------------------------
    reg [PTR_W-1:0] wr_bin_next;
    reg [PTR_W-1:0] wr_gray_next;
    reg [PTR_W-1:0] rd_bin_next;
    reg [PTR_W-1:0] rd_gray_next;

    wire full_next;   // Next-cycle full flag
    wire empty_next;  // Next-cycle empty flag

    // -------------------------------------------------------------------------
    // Function: binary to Gray-code conversion
    // -------------------------------------------------------------------------
    function [PTR_W-1:0] bin2gray;
        input [PTR_W-1:0] bin;
        begin
            bin2gray = (bin >> 1) ^ bin;
        end
    endfunction

    // -------------------------------------------------------------------------
    // Qualified strobes
    // -------------------------------------------------------------------------
    assign wr_fire = wr_en & ~full;
    assign rd_fire = rd_en & ~empty;

    // -------------------------------------------------------------------------
    // Combinational: next pointer & flag logic
    // -------------------------------------------------------------------------
    always @(*) begin
        wr_bin_next  = wr_bin + {{(PTR_W-1){1'b0}}, wr_fire};
        wr_gray_next = bin2gray(wr_bin_next);

        rd_bin_next  = rd_bin + {{(PTR_W-1){1'b0}}, rd_fire};
        rd_gray_next = bin2gray(rd_bin_next);
    end

    // full:  2 MSBs differ, remaining bits identical (Cummings method)
    // empty: read Gray pointer matches synchronized write Gray pointer
    assign full_next  = (wr_gray_next == {~rd_gray_sync2[PTR_W-1:PTR_W-2], rd_gray_sync2[PTR_W-3:0]});
    assign empty_next = (rd_gray_next == wr_gray_sync2);

    // -------------------------------------------------------------------------
    // Write domain: memory write, wr_bin/wr_gray update, full flag
    // -------------------------------------------------------------------------
    always @(posedge wr_clk or negedge rst_n) begin
        if (!rst_n) begin
            wr_bin  <= {PTR_W{1'b0}};
            wr_gray <= {PTR_W{1'b0}};
            full    <= 1'b0;
        end else begin
            if (wr_fire) begin
                mem[wr_bin[ADDR_WIDTH-1:0]] <= din;
            end

            wr_bin  <= wr_bin_next;
            wr_gray <= wr_gray_next;
            full    <= full_next;
        end
    end

    // -------------------------------------------------------------------------
    // Read domain: memory read, rd_bin/rd_gray update, empty flag
    // -------------------------------------------------------------------------
    always @(posedge rd_clk or negedge rst_n) begin
        if (!rst_n) begin
            rd_bin  <= {PTR_W{1'b0}};
            rd_gray <= {PTR_W{1'b0}};
            empty   <= 1'b1;
            dout    <= {DATA_WIDTH{1'b0}};
        end else begin
            if (rd_fire) begin
                dout <= mem[rd_bin[ADDR_WIDTH-1:0]];
            end

            rd_bin  <= rd_bin_next;
            rd_gray <= rd_gray_next;
            empty   <= empty_next;
        end
    end

    // -------------------------------------------------------------------------
    // 2-FF Synchronizer: rd_gray → write domain (for full detection)
    // -------------------------------------------------------------------------
    always @(posedge wr_clk or negedge rst_n) begin
        if (!rst_n) begin
            rd_gray_sync1 <= {PTR_W{1'b0}};
            rd_gray_sync2 <= {PTR_W{1'b0}};
        end else begin
            rd_gray_sync1 <= rd_gray;
            rd_gray_sync2 <= rd_gray_sync1;
        end
    end

    // -------------------------------------------------------------------------
    // 2-FF Synchronizer: wr_gray → read domain (for empty detection)
    // -------------------------------------------------------------------------
    always @(posedge rd_clk or negedge rst_n) begin
        if (!rst_n) begin
            wr_gray_sync1 <= {PTR_W{1'b0}};
            wr_gray_sync2 <= {PTR_W{1'b0}};
        end else begin
            wr_gray_sync1 <= wr_gray;
            wr_gray_sync2 <= wr_gray_sync1;
        end
    end

endmodule
