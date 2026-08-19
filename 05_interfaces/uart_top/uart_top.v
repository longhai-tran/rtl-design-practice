/*******************************************************************************
 * Module: uart_top.v                                                          *
 * Description: Full-duplex UART 8N1 wrapper integrating uart_tx and uart_rx.  *
 *              The wrapper exposes independent transmit and receive paths.   *
 * File Created: Thursday, 23rd July 2026 1:19:19 pm                           *
 * Author: Long Hai                                                            *
 * -----                                                                       *
 * Last Modified: Friday, 24th July 2026 1:47:37 pm                            *
 * Modified By: Long Hai                                                       *
*******************************************************************************/

`timescale 1ns/1ps

module uart_top #(
    parameter integer CLK_FREQ_HZ = 50_000_000,
    parameter integer BAUD_RATE   = 115_200
) (
    input  wire       clk,
    input  wire       rst_n,

    input  wire       tx_start,
    input  wire [7:0] tx_data,
    output wire       tx,
    output wire       tx_busy,
    output wire       tx_done,

    input  wire       rx,
    output wire [7:0] rx_data,
    output wire       rx_busy,
    output wire       rx_done_valid,
    output wire       framing_error
);

    uart_tx #(
        .CLK_FREQ_HZ(CLK_FREQ_HZ),
        .BAUD_RATE(BAUD_RATE)
    ) u_tx (
        .clk(clk),
        .rst_n(rst_n),
        .tx_start(tx_start),
        .data_in(tx_data),
        .tx(tx),
        .tx_busy(tx_busy),
        .tx_done(tx_done)
    );

    uart_rx #(
        .CLK_FREQ_HZ(CLK_FREQ_HZ),
        .BAUD_RATE(BAUD_RATE)
    ) u_rx (
        .clk(clk),
        .rst_n(rst_n),
        .rx(rx),
        .data_out(rx_data),
        .rx_busy(rx_busy),
        .rx_done_valid(rx_done_valid),
        .framing_error(framing_error)
    );

endmodule
