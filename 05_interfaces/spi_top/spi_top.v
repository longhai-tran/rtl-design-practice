/*******************************************************************************
 * Module: spi_top.v                                                           *
 * Description: Integrated SPI master/slave loopback pair with observable bus  *
 *              signals and independent payload/status interfaces.             *
 * File Created: Tuesday, 28th July 2026 11:44:28 am                           *
 * Author: Long Hai                                                            *
 * -----                                                                       *
 * Last Modified: Tuesday, 28th July 2026 1:49:05 pm                           *
 * Modified By: Long Hai                                                       *
*******************************************************************************/

`timescale 1ns/1ps

module spi_top #(
    parameter integer DATA_WIDTH = 8,
    parameter integer CLK_DIV    = 3,
    parameter integer CPOL       = 0,
    parameter integer CPHA       = 0
) (
    input  wire                  clk,
    input  wire                  rst_n,
    input  wire                  start,
    input  wire [DATA_WIDTH-1:0] master_tx_data,
    input  wire [DATA_WIDTH-1:0] slave_tx_data,
    output wire [DATA_WIDTH-1:0] master_rx_data,
    output wire [DATA_WIDTH-1:0] slave_rx_data,
    output wire                  master_busy,
    output wire                  master_done,
    output wire                  slave_busy,
    output wire                  slave_done,
    output wire                  sclk,
    output wire                  mosi,
    output wire                  miso,
    output wire                  cs_n
);

    // The system-clocked slave requires at least two clocks per SCLK half-cycle.
    localparam integer SAFE_CLK_DIV = (CLK_DIV < 2) ? 2 : CLK_DIV;

    spi_master #(
        .DATA_WIDTH(DATA_WIDTH),
        .CLK_DIV(SAFE_CLK_DIV),
        .CPOL(CPOL),
        .CPHA(CPHA)
    ) u_master (
        .clk(clk),
        .rst_n(rst_n),
        .start(start),
        .tx_data(master_tx_data),
        .miso(miso),
        .sclk(sclk),
        .mosi(mosi),
        .cs_n(cs_n),
        .busy(master_busy),
        .done(master_done),
        .rx_data(master_rx_data)
    );

    spi_slave #(
        .DATA_WIDTH(DATA_WIDTH),
        .CPOL(CPOL),
        .CPHA(CPHA)
    ) u_slave (
        .clk(clk),
        .rst_n(rst_n),
        .sclk(sclk),
        .cs_n(cs_n),
        .mosi(mosi),
        .tx_data(slave_tx_data),
        .miso(miso),
        .busy(slave_busy),
        .done(slave_done),
        .rx_data(slave_rx_data)
    );

endmodule
