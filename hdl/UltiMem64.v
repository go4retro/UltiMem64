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
                 input clock,
                 input [7:0]maddress,
                 inout [7:0]data,
                 input _ras,
                 input _cas,
                 input _we,
                 output reg [20:0]baddress,
                 inout [7:0]bdata,
                 output _ce_ram,
                 output _ce_tag,
                 output _we_ram,
                 output _ub,
                 output _lb,
                 output [8:1]test
                );

reg [7:0]address;
reg [7:0]address_mmu;
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
wire flag_mmu_visible;
wire bus_active;
reg [3:0]ctr;

wire jim = (faddress[15:0] == 4096);

assign test[1] =           flag_mmu_enabled; //bus_active;
assign test[2] =           flag_mmu_visible; //!_ce_tag;
assign test[3] =           !_ce_ram & jim;
assign test[4] =           0; //!_we_ram;
assign test[5] =           address_mmu[0] & jim;
assign test[6] =           address_mmu[1] & jim;
assign test[7] =           address_mmu[2] & jim;
assign test[8] =           address_mmu[3] & jim;

assign faddress =          {maddress, address};
assign ce_mmu_regs =       (faddress[15:4] == 12'hc00 & flag_mmu_visible);
assign ce_mmu_ctrl =       ce_mmu_regs & (faddress[3:0] == 0);
assign ce_mmu_task_conf =  ce_mmu_regs & (faddress[3:0] == 1);
assign ce_mmu_task =       ce_mmu_regs & (faddress[3:0] == 2);
assign ce_mmu_map =        (faddress[15:4] == 12'hc01 & flag_mmu_visible);
assign we =                !_we;
assign oe =                _we;
assign bus_active =        !_ras & !_cas;

assign _ce_ram =           !(bus_active & !ce_mmu_regs & !ce_mmu_map & (ctr >= 2));
assign _ce_tag =           !(bus_active & ((ctr < 2) | (ctr >= 2) & ce_mmu_map));
assign _we_ram =           !(!_we & (ctr >=2));    // no writing until after tag ram has been accessed.
assign bdata =             ((!_ce_ram | !_ce_tag) & !_we_ram ? data : 8'bz);  // RAM selected and we're writing, else bz
assign data =              data_out;  // RAM selected and we're reading, else bz
assign _ub =               1;
assign _lb =               _ce_tag;

register #(.WIDTH(1))		mmu_enabled_reg(bus_active, 0, we & ce_mmu_ctrl, data[0], flag_mmu_enabled);
register #(.WIDTH(1),.RESET(1))		mmu_visible_reg(bus_active, 0, we & ce_mmu_ctrl, data[7], flag_mmu_visible);
register #(.WIDTH(8))		mmu_win_reg(bus_active, 0, we & ce_mmu_task_conf, data, data_task_win);
register #(.WIDTH(8))		mmu_task_reg(bus_active, 0, we & ce_mmu_task, data, data_task);

always @(*)
begin
   if(ce_mmu_ctrl & oe)
      data_out = {4'h7,3'b0,flag_mmu_enabled};
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

always @(*)
begin
   if(!_ce_ram & flag_mmu_enabled)
      baddress = {1'b0, address_mmu, faddress[11:0]};
   else if(!_ce_ram & !flag_mmu_enabled)
      baddress = {5'b0, faddress};
   else if(!_ce_tag & ce_mmu_map)
      baddress = {9'b0, data_task_win, faddress[3:0]};
   else
      baddress = {9'b0, data_task, faddress[15:12]};
end

always @(posedge clock)
begin
   if(!bus_active)
      ctr <= 0;
   else
      ctr <= ctr + 1;
end

always @(posedge _ce_tag)
begin
   address_mmu <= bdata;
end

always @(negedge _ras)
begin
   address[7:0] <= maddress[7:0];
end

endmodule
