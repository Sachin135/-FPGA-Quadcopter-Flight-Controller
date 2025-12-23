`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 11/20/2025 09:34:13 PM
// Design Name: 
// Module Name: rx_capture_core
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: 
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////


module rx_capture_core #(
    parameter int COUNTER_WIDTH = 32
)(
    input  logic                     rst_n,
    input  logic                     clk,

    input  logic                     rx_in,       // from the gpio pins

    output logic [COUNTER_WIDTH-1:0] pulse_width,
    output logic [COUNTER_WIDTH-1:0] pulse_period,
    output logic                     new_data,
    output logic                     overflow
);

    // metastability cleanup for signal
    logic rx_meta, rx_sync;
    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            rx_meta <= 1'b0;
            rx_sync <= 1'b0;
        end else begin
            rx_meta <= rx_in;
            rx_sync <= rx_meta;
        end
    end

    // edge detection
    logic rx_prev;
    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n)
            rx_prev <= 1'b0;
        else
            rx_prev <= rx_sync;
    end

    wire rising_edge  = (rx_sync && !rx_prev);
    wire falling_edge = (!rx_sync && rx_prev);

    // counter for measuring pulse/period
    logic [COUNTER_WIDTH-1:0] counter;
    logic [COUNTER_WIDTH-1:0] rise_time;

    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            counter     <= 32'd0;
            rise_time   <= 32'd0;
            pulse_width <= 32'd0;
            pulse_period<= 32'd0;
            new_data    <= 1'b0;
            overflow    <= 1'b0;
        end else begin
            new_data <= 1'b0;  

            counter <= counter + 1;

            if (counter == 32'hFFFFFFFF)
                overflow <= 1'b1;

            if (rising_edge) begin
                pulse_period <= counter - rise_time;
                rise_time    <= counter;
            end

            if (falling_edge) begin
                pulse_width <= counter - rise_time;
                new_data    <= 1'b1;
            end
        end
    end

endmodule
