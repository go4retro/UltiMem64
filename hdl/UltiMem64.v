`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date:    00:18:51 07/06/2019 
// Design Name: 
// Module Name:    IntMem64 
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
module UltiMem64(
                input [7:0]maddress,
                inout [7:0]data,
                input _ras,
                input _cas,
                input _we,
                output [18:0]baddress,
                inout [7:0]bdata,
                output _ce_ram,
                output _we_ram,
                output [4:1]test
               );

reg [7:0]address;

assign _ce_ram =           (_cas | _ras);
assign _we_ram =           _we;
assign baddress[18:0] =    {3'b0, maddress, address};
assign bdata =             (!_ce_ram & !_we_ram ? data : 8'bz);  // RAM selected and we're writing, else bz
assign data =              (!_ce_ram & _we_ram ? bdata : 8'bz);  // RAM selected and we're reading, else bz

// bit 0 is bit 6.
// bit 1 is bit 1.
// bit 2 is bit 2.
// bit 3 is bit 3.
// bit 4 is bit 4.
// bit 5 is bit 5.
// bit 6 is bit 0.
// bit 7 is bit 7.
// bit 8 is bit 14.
// bit 9 is bit 9.
// bit 10 is bit 10.
// bit 11 is bit 11.
// bit 12 is bit 12.
// bit 13 is bit 13.
// bit 14 is bit 8.
// bit 15 is bit 15.


assign test[1] =           (!_ras & _cas);
assign test[2] =           0;
assign test[3] =           0;
assign test[4] =           0;

always @(negedge _ras)
begin
   address[7:0] <= maddress[7:0];
end

endmodule
