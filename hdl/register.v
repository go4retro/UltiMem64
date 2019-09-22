`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date:    23:52:36 12/08/2013 
// Design Name: 
// Module Name:    register 
// Project Name: 
// Target Devices: 
// Tool versions: 
// Description: 
//
// Dependencies: 
//
// Revision: 
// Revision 0.01 - File Created
// Additional Comments: 
//
//////////////////////////////////////////////////////////////////////////////////
`ifndef _register
`define _register
module register(clock, reset, enable, d, q);

parameter WIDTH = 8 ;
parameter RESET = 0 ;

input clock;
input reset;
input enable;
input [WIDTH-1:0] d;
output [WIDTH-1:0] q;
reg [WIDTH-1:0] q;
initial q = RESET;

always @ (negedge clock, posedge reset)
  begin
  if(reset)
		q <= RESET;
  else if(enable)
	   q <= d;
  end
endmodule
`endif