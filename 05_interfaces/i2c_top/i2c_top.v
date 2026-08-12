/*******************************************************************************
 * Module: i2c_top.v                                                           *
 * Description: Integrated I2C controller/target with resolved open-drain bus. *
 * File Created: Friday, 31st July 2026 10:28:07 am                            *
 * Author: Long Hai                                                            *
 * -----                                                                       *
 * Last Modified: Tuesday, 4th August 2026 11:36:34 am                         *
 * Modified By: Long Hai                                                       *
 *******************************************************************************/

/*
 * I2C Top-Level Integration — Design Notes
 * =========================================
 * This module wires an i2c_master and an i2c_slave together on a shared
 * simulated I2C bus.  The bus model accurately represents the open-drain,
 * wired-AND physical characteristic of real I2C hardware:
 *
 *   Physical reality:
 *     - Each device can only pull a line LOW (open-drain transistor).
 *     - A shared pull-up resistor returns the line to HIGH when no one drives it.
 *     - If ANY device pulls the line LOW the line is LOW ("wired-AND").
 *
 *   Simulation model:
 *     - Each submodule exports a "_drive_low" signal instead of a tri-state.
 *     - This module ORs those signals and drives the resolved bus value:
 *         scl = (master_scl_drive_low)              ? 1'b0 : 1'b1
 *         sda = (master_sda_drive_low || slave_sda_drive_low) ? 1'b0 : 1'b1
 *
 * slave_tx_data latching:
 *   The slave's read-back data is latched in this module (not in the slave)
 *   because the slave samples tx_data at the START event.  Capturing it here
 *   one cycle before the master asserts start gives the slave a stable value
 *   when that START condition is generated.
 *
 * Bus arbitration:
 *   Only one master is instantiated, so no arbitration logic is required.
 *   Multi-master support would require monitoring SCL/SDA for lost-arbitration.
 */

`timescale 1ns/1ps

module i2c_top #(
    // CLK_DIV: system-clock cycles per SCL half-period (passed to master).
    parameter integer CLK_DIV    = 4,
    // SLAVE_ADDR: 7-bit I2C address the slave responds to.
    parameter [6:0]   SLAVE_ADDR = 7'h42
) (
    // ── System interface ─────────────────────────────────────────────────────
    input  wire       clk,             // System clock
    input  wire       rst_n,           // Synchronous active-low reset

    // ── Master control inputs ────────────────────────────────────────────────
    input  wire       start,           // Pulse HIGH to begin a transfer
    input  wire       rw,              // 0 = write, 1 = read
    input  wire [6:0] target_addr,     // 7-bit address to send on bus
    input  wire [7:0] master_tx_data,  // Byte the master writes (write transfers)
    input  wire [7:0] slave_tx_data,   // Byte the slave returns (read transfers)

    // ── Data outputs ─────────────────────────────────────────────────────────
    output wire [7:0] master_rx_data,  // Byte master received (read transfers)
    output wire [7:0] slave_rx_data,   // Byte slave received  (write transfers)
    output wire       slave_rx_valid,  // One-cycle pulse: slave_rx_data is valid

    // ── Status outputs ───────────────────────────────────────────────────────
    output wire       master_busy,     // High while master transfer is in progress
    output wire       master_done,     // One-cycle pulse: master transfer complete
    output wire       slave_busy,      // High while slave is engaged with a transfer
    output wire       slave_done,      // One-cycle pulse: slave transfer complete
    output wire       ack_error,       // HIGH if master received NACK from slave

    // ── Observable bus lines (for testbench probing / waveform inspection) ──
    output wire       scl,             // Resolved I2C clock  line
    output wire       sda              // Resolved I2C data line
);

    // -------------------------------------------------------------------------
    // Internal drive-low signals (open-drain outputs from each submodule)
    // -------------------------------------------------------------------------
    wire master_scl_drive_low; // Master requests SCL pulled LOW
    wire master_sda_drive_low; // Master requests SDA pulled LOW
    wire slave_sda_drive_low;  // Slave  requests SDA pulled LOW

    // -------------------------------------------------------------------------
    // slave_tx_data latch
    // -------------------------------------------------------------------------
    // Capture the TX byte one cycle before the master starts driving the bus.
    // This ensures the slave sees a stable value when it latches tx_data on
    // the START event.  The latch is guarded by !master_busy so updates are
    // ignored while a transfer is already in progress.
    reg [7:0] slave_tx_latched;

    always @(posedge clk) begin
        if (!rst_n)
            slave_tx_latched <= 8'h00;
        else if (start && !master_busy)
            slave_tx_latched <= slave_tx_data;
    end

    // -------------------------------------------------------------------------
    // Open-drain / wired-AND bus resolution
    // -------------------------------------------------------------------------
    // SCL is only driven by the master (slaves may clock-stretch in real HW,
    // but this design does not implement clock-stretching).
    assign scl = master_scl_drive_low ? 1'b0 : 1'b1;

    // SDA is driven by master OR slave depending on the protocol phase:
    //   - Master drives during START, address, write data, NACK, STOP
    //   - Slave  drives during ACK and read data
    // Logical OR of both drive signals models the wired-AND pull-down.
    assign sda = (master_sda_drive_low || slave_sda_drive_low) ? 1'b0 : 1'b1;

    // -------------------------------------------------------------------------
    // i2c_master instantiation
    // -------------------------------------------------------------------------
    i2c_master #(
        .CLK_DIV(CLK_DIV)
    ) u_master (
        .clk          (clk),
        .rst_n        (rst_n),
        .start        (start),
        .rw           (rw),
        .target_addr  (target_addr),
        .tx_data      (master_tx_data),
        .sda          (sda),             // Reads the resolved bus to detect ACK/data
        .scl_drive_low(master_scl_drive_low),
        .sda_drive_low(master_sda_drive_low),
        .rx_data      (master_rx_data),
        .busy         (master_busy),
        .done         (master_done),
        .ack_error    (ack_error)
    );

    // -------------------------------------------------------------------------
    // i2c_slave instantiation
    // -------------------------------------------------------------------------
    i2c_slave #(
        .SLAVE_ADDR(SLAVE_ADDR)
    ) u_slave (
        .clk          (clk),
        .rst_n        (rst_n),
        .scl          (scl),             // Slave follows master-generated SCL
        .sda          (sda),             // Resolved SDA — slave reads and drives this
        .tx_data      (slave_tx_latched),
        .sda_drive_low(slave_sda_drive_low),
        .rx_data      (slave_rx_data),
        .rx_valid     (slave_rx_valid),
        .busy         (slave_busy),
        .done         (slave_done)
    );

endmodule
