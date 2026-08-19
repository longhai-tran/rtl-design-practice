/*******************************************************************************
 * Module  : wishbone_slave.v
 * Brief   : Wishbone B4 Classic register-bank slave with byte enables.
 *
 * Description:
 *   Implements a four-register peripheral addressed over Wishbone B4 Classic.
 *   Each register is independently writable per byte lane via SEL.
 *   The module is synchronous (registered ACK/ERR) and produces exactly one
 *   ACK or ERR pulse per transfer, regardless of how long the master holds
 *   CYC/STB.
 *
 * Register map (offset from slave base, word-aligned byte addresses):
 *   Offset 0x0  CONTROL   R/W   reset=0         General control register
 *   Offset 0x4  DATA      R/W   reset=0         General data register
 *   Offset 0x8  SCRATCH   R/W   reset=0         Software scratch register
 *   Offset 0xC  ID        R/O   reset=ID_VALUE  Read-only instance identifier
 *
 * Error conditions (ERR response, no state change):
 *   - Unaligned access  : wb_adr_i[1:0] != 2'b00
 *   - Write to ID reg   : write to offset 0xC
 *
 * Parameters:
 *   ADDR_WIDTH — address bus width (default 16)
 *   DATA_WIDTH — data bus width   (default 32)
 *   ID_VALUE   — read-only identifier returned at offset 0xC
 *
 * Author: Long Hai
 *******************************************************************************/

`timescale 1ns/1ps

module wishbone_slave #(
    parameter integer ADDR_WIDTH = 16,
    parameter integer DATA_WIDTH = 32,
    parameter [DATA_WIDTH-1:0] ID_VALUE = 32'h0000_0000
) (
    input  wire                      clk,
    input  wire                      rst_n,       // Active-low synchronous reset

    // -------------------------------------------------------------------------
    // Wishbone B4 Classic slave port
    // -------------------------------------------------------------------------
    input  wire [ADDR_WIDTH-1:0]     wb_adr_i,   // Byte address from master
    input  wire [DATA_WIDTH-1:0]     wb_dat_i,   // Write data from master
    input  wire [(DATA_WIDTH/8)-1:0] wb_sel_i,   // Byte enables (1=lane active)
    input  wire                      wb_we_i,    // 1=write, 0=read
    input  wire                      wb_cyc_i,   // Bus cycle active
    input  wire                      wb_stb_i,   // Transfer request valid
    output reg  [DATA_WIDTH-1:0]     wb_dat_o,   // Read data to master
    output reg                       wb_ack_o,   // Normal termination
    output reg                       wb_err_o,   // Error termination

    // -------------------------------------------------------------------------
    // Register outputs (for wiring to downstream logic or debug observation)
    // -------------------------------------------------------------------------
    output wire [DATA_WIDTH-1:0]     control_o,  // Live value of CONTROL register
    output wire [DATA_WIDTH-1:0]     data_o,     // Live value of DATA register
    output wire [DATA_WIDTH-1:0]     scratch_o   // Live value of SCRATCH register
);

    localparam integer SEL_WIDTH = DATA_WIDTH / 8;

    // Internal register file: index 0=CONTROL, 1=DATA, 2=SCRATCH
    reg [DATA_WIDTH-1:0] registers [0:2];

    // request_seen: tracks whether the current CYC/STB assertion has already
    // been processed.  Because ACK/ERR are registered outputs, the master
    // observes the response one clock after this module processes the request.
    // During that extra clock, CYC/STB are still high, so without this flag
    // the slave would execute the same write or read a second time.
    reg request_seen;

    // Expose register contents as combinational outputs
    assign control_o = registers[0];
    assign data_o    = registers[1];
    assign scratch_o = registers[2];

    // Upper address bits [ADDR_WIDTH-1:4] are intentionally unused: region
    // selection is performed by the interconnect before routing to this slave.
    // The wire below makes this explicit and silences Verilator UNUSEDSIGNAL.
    wire _unused_upper_adr = &{1'b0, wb_adr_i[ADDR_WIDTH-1:4]};

    // -------------------------------------------------------------------------
    // merge_bytes: perform a byte-enable-masked write.
    //   For each byte lane n: if sel[n]=1, copy new_value[8n+:8] into result;
    //   otherwise keep current_value[8n+:8] unchanged.
    //   This is synthesized as DATA_WIDTH/8 independent 2-to-1 muxes.
    // -------------------------------------------------------------------------
    function [DATA_WIDTH-1:0] merge_bytes;
        input [DATA_WIDTH-1:0] current_value;
        input [DATA_WIDTH-1:0] new_value;
        input [SEL_WIDTH-1:0]  select;
        integer byte_index;
        begin
            merge_bytes = current_value;
            for (byte_index = 0; byte_index < SEL_WIDTH; byte_index = byte_index + 1)
                if (select[byte_index])
                    merge_bytes[(byte_index*8) +: 8] = new_value[(byte_index*8) +: 8];
        end
    endfunction

    always @(posedge clk) begin
        if (!rst_n) begin
            // -----------------------------------------------------------------
            // Synchronous reset: clear register bank and all bus outputs
            // -----------------------------------------------------------------
            registers[0]  <= {DATA_WIDTH{1'b0}};
            registers[1]  <= {DATA_WIDTH{1'b0}};
            registers[2]  <= {DATA_WIDTH{1'b0}};
            wb_dat_o      <= {DATA_WIDTH{1'b0}};
            wb_ack_o      <= 1'b0;
            wb_err_o      <= 1'b0;
            request_seen  <= 1'b0;
        end else begin
            // Default: deassert response signals every clock.
            // ACK or ERR will be driven to 1 in the processing branch below,
            // producing exactly one clock-wide pulse per transfer.
            wb_ack_o <= 1'b0;
            wb_err_o <= 1'b0;

            if (!(wb_cyc_i && wb_stb_i)) begin
                // -------------------------------------------------------------
                // Bus idle or STB deasserted: clear the one-shot flag so the
                // next assertion of CYC/STB triggers a fresh transaction.
                // -------------------------------------------------------------
                request_seen <= 1'b0;

            end else if (!request_seen) begin
                // -------------------------------------------------------------
                // First clock of a new transfer: process the request once.
                // Setting request_seen prevents re-execution on subsequent clocks
                // while the master is still holding CYC/STB to observe the response.
                // -------------------------------------------------------------
                request_seen <= 1'b1;

                if (wb_adr_i[1:0] != 2'b00) begin
                    // Unaligned access: this design supports word-granularity only
                    wb_err_o <= 1'b1;
                end else begin
                    case (wb_adr_i[3:2])
                        // Offset 0x0 / 0x4 / 0x8 — read/write general registers
                        2'd0, 2'd1, 2'd2: begin
                            if (wb_we_i)
                                // Byte-enable-masked write: only update selected lanes
                                registers[wb_adr_i[3:2]] <= merge_bytes(
                                    registers[wb_adr_i[3:2]], wb_dat_i, wb_sel_i);
                            else
                                wb_dat_o <= registers[wb_adr_i[3:2]];
                            wb_ack_o <= 1'b1;
                        end

                        // Offset 0xC — read-only ID register
                        2'd3: begin
                            if (wb_we_i)
                                // Write to read-only register: return error, no state change
                                wb_err_o <= 1'b1;
                            else begin
                                wb_dat_o <= ID_VALUE;
                                wb_ack_o <= 1'b1;
                            end
                        end

                        // All 2-bit combinations (0–3) are covered above;
                        // this branch is unreachable for well-formed addresses.
                        default: wb_err_o <= 1'b1;
                    endcase
                end
            end
            // If request_seen=1 and CYC/STB still high: wait silently for master
            // to observe the ACK/ERR that was driven in the previous clock.
        end
    end

endmodule
