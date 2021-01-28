`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date:    21:56:47 01/27/2021 
// Design Name: 
// Module Name:    UltiColorMEM 
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
module UltiColorMEM(
                     input clock,
                     input [9:0]address_color,
                     inout [3:0]data_color,
                     input _ce_color,
                     input _we_color,
                     output [5:0]bank,
                     inout [3:0]data_mem_a,
                     inout [3:0]data_mem_b,
                     output _ce_mem,
                     output _we_mem,
                     output _lb,
                     output _ub
                   );

reg [6:0]data_bank;
wire lb;
wire ub;
wire ce_bank_lo;
wire ce_bank_hi;

assign bank =        data_bank[5:0];
assign _ce_mem =     _ce_color;
assign _we_mem =     _we_color;
assign lb =          (!data_bank[6]);
assign ub =          (data_bank[6]);
assign _lb =         !lb;
assign _ub =         !ub;
assign data_mem_a =  (!_ce_color & !_we_color & ub ? data_color : 4'bz);
assign data_mem_b =  (!_ce_color & !_we_color & lb ? data_color : 4'bz);
assign data_color =  (!_ce_color & _we_color ? (ub ? data_mem_a : data_mem_b) : 4'bz);
assign ce_bank_lo =  !_ce_color & clock & (address_color == 10'b1111111110);
assign ce_bank_hi =  !_ce_color & clock & (address_color == 10'b1111111111);

always @(negedge _we_color)
begin
   if(ce_bank_lo)
      data_bank[3:0] <= data_color;
   else if(ce_bank_hi)
      data_bank[6:4] <= data_color[2:0];
end

endmodule
