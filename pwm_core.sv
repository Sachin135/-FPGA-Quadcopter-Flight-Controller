`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 11/18/2025 03:50:51 PM
// Design Name: 
// Module Name: pwm_core
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


module pwm_core #(
    parameter int COUNTER_WIDTH = 32
) (
    input  logic                     clk,
    input  logic                     rst_n,      

// defining duty cycle for all 4 channels
    input  logic [COUNTER_WIDTH-1:0] period,    
    input  logic [COUNTER_WIDTH-1:0] duty0,      
    input  logic [COUNTER_WIDTH-1:0] duty1,      
    input  logic [COUNTER_WIDTH-1:0] duty2,      
    input  logic [COUNTER_WIDTH-1:0] duty3,     

    output logic [3:0]               pwm_out
);
logic [COUNTER_WIDTH-1:0] counter;

// simple pwm logic
always_ff @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        counter <= '0;
    end else if (counter >= period - 1) begin
        counter <= '0;
    end else begin
        counter <= counter + 1;
    end
end

always_comb begin
    pwm_out[0] = (counter < duty0);
    pwm_out[1] = (counter < duty1);
    pwm_out[2] = (counter < duty2);
    pwm_out[3] = (counter < duty3);
end
endmodule
