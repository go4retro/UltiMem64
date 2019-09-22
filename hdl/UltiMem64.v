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
                output [20:0]baddress,
                inout [7:0]bdata,
                output _ce_ram,
                output _ce_tag,
                output _we_ram,
                output _ub,
                output _lb,
                output [8:1]test
               );

reg [7:0]address;
wire [15:0]faddress;
wire [7:0]data_task_win;
wire [7:0]data_task;
reg [7:0]data_out;
wire ce_mmu_regs;
wire ce_mmu_ctrl;
wire ce_mmu_task_conf;
wire ce_mmu_task;
wire ce_mmu_map;
wire we;
wire oe;
wire flag_mmu_enabled;
wire clock;

assign test[1] =           (!_ras & !_cas);
assign test[2] =           !_we & (faddress == 49152);
assign test[3] =           flag_mmu_enabled;
assign test[4] =           0;
assign test[5] =           0;
assign test[6] =           0;
assign test[7] =           0;
assign test[8] =           0;

assign faddress =          {maddress, address};
assign ce_mmu_regs =       (faddress[15:4] == 12'hc00);
assign ce_mmu_ctrl =       ce_mmu_regs & (faddress[3:0] == 0);
assign ce_mmu_task_conf =  ce_mmu_regs & (faddress[3:0] == 1);
assign ce_mmu_task =       ce_mmu_regs & (faddress[3:0] == 2);
assign ce_mmu_map =        (faddress[15:4] == 12'hc01);
assign we =                !_we;
assign oe =                _we;
assign clock =             !_ras & !_cas;

assign _ce_ram =           !(clock & !ce_mmu_map);
assign _ce_tag =           !(clock & ce_mmu_map);
assign _we_ram =           _we;
assign baddress[20:0] =    (!_ce_ram ? {5'b0, faddress} : {9'b0, data_task_win, faddress[3:0]});
assign bdata =             ((!_ce_ram | !_ce_tag) & !_we_ram ? data : 8'bz);  // RAM selected and we're writing, else bz
assign data =              data_out;  // RAM selected and we're reading, else bz
assign _ub =               1;
assign _lb =               _ce_tag;

register #(.WIDTH(1))				mmu_enabled_reg(clock, 0, we & ce_mmu_ctrl, data[0], flag_mmu_enabled);
register #(.WIDTH(8))				mmu_win_reg(clock, 0, we & ce_mmu_task_conf, data, data_task_win);
register #(.WIDTH(8))				mmu_task_reg(clock, 0, we & ce_mmu_task, data, data_task);

always @(*)
begin
   if(ce_mmu_ctrl & oe)
      data_out = {7'b0,flag_mmu_enabled};
   else if (ce_mmu_task_conf & oe)
      data_out = data_task_win;
   else if (ce_mmu_task & oe)
      data_out = data_task;
   else if(!_ce_ram & oe)
      data_out = bdata;
   else if (!_ce_tag & oe & !_lb)
      data_out = bdata;
   else
      data_out = 8'bz;
end

always @(negedge _ras)
begin
   address[7:0] <= maddress[7:0];
end

endmodule
