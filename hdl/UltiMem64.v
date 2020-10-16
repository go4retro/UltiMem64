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
                 input _reset,
                 input clock,
                 input [7:0]maddress,
                 inout [7:0]data,
                 input _ras,
                 input _cas,
                 input _we,
                 output [6:0]address_color,
                 output reg [20:0]baddress,
                 inout [15:0]bdata,
                 output _ce_ram,
                 output _ce_tag,
                 output _we_mem,
                 output _ub,
                 output _lb
                 //output [7:1]test
                );

reg [7:0]address;
reg [8:0]address_mmu;
wire [15:0]faddress;
wire [7:0]data_task_win;
wire [7:0]data_task;
wire [6:0]data_color;
reg [7:0]data_out;
wire ce_mmu_base;
wire ce_mmu_regs;
wire ce_mmu_ctrl;
wire ce_mmu_task_conf;
wire ce_mmu_task;
wire ce_mmu_map_lo;
wire ce_mmu_map_hi;
wire ce_mmu_map;
wire we;
wire oe;
wire flag_mmu_enabled;
wire flag_mmu_visible;
wire bus_active;
reg [3:0]ctr;
wire [7:0]page_mmu;

//assign test[1] =           (faddress[15:8] == 8'hc0 & oe & bus_active);
//assign test[2] =           flag_mmu_visible;
//assign test[3] =           0;
//assign test[4] =           0;
//assign test[5] =           0;
//assign test[6] =           0;
//assign test[7] =           0;
//assign test[8] =           0;

assign address_color =     data_color;
assign faddress =          {maddress, address};
assign flag_mmu_visible =  (page_mmu != 0);
//assign ce_mmu_base =       (faddress[15:8] == 8'hc0);
assign ce_mmu_base =       ((faddress[15:8] == page_mmu) & flag_mmu_visible);
assign ce_mmu_regs =       (ce_mmu_base & faddress[7:4] == 4'h0);
assign ce_mmu_ctrl =       ce_mmu_regs & (faddress[3:0] == 0);
assign ce_mmu_task_conf =  ce_mmu_regs & (faddress[3:0] == 1);
assign ce_mmu_task =       ce_mmu_regs & (faddress[3:0] == 2);
assign ce_mmu_color =      ce_mmu_regs & (faddress[3:0] == 3);
assign ce_mmu_map_lo =     (ce_mmu_base & faddress[7:4] == 4'h1);
assign ce_mmu_map_hi =     (ce_mmu_base & faddress[7:4] == 4'h2);
assign ce_mmu_map =        ce_mmu_map_lo | ce_mmu_map_hi;
assign bus_active =        !_ras & !_cas;

assign _ce_ram =           !(bus_active & !ce_mmu_regs & !ce_mmu_map & (ctr >= 2));
assign ce_tag =            (bus_active & ((ctr < 2) | (ctr >= 2) & ce_mmu_map));
assign _we_mem =           !(!_we & (ctr >=2));       // no writing until after tag ram has been accessed.
assign bdata[7:0] =        (!_we_mem ? data : 8'bz);  // RAM selected and we're writing, else bz
assign bdata[15:8] =       (!_we_mem ? (ce_mmu_map_lo ? 0 : data) : 8'bz);  // RAM selected and we're writing, else bz

assign we =                !_we;
assign oe =                _we;
assign data =              data_out;
assign _ce_tag =           !ce_tag;
assign _ub =               !(ce_tag & (ce_mmu_map_hi | (ce_mmu_map_lo & !_we_mem) | (bus_active & (ctr < 2))));
assign _lb =               !(ce_tag & (ce_mmu_map_lo | (bus_active & (ctr < 2))));

register #(.WIDTH(1))		mmu_enabled_reg(bus_active, !_reset, we & ce_mmu_ctrl, data[0], flag_mmu_enabled);
register #(.WIDTH(8))		mmu_win_reg(bus_active, !_reset, we & ce_mmu_task_conf, data, data_task_win);
register #(.WIDTH(8))		mmu_task_reg(bus_active, !_reset, we & ce_mmu_task, data, data_task);
register #(.WIDTH(7))		mmu_ctask_reg(bus_active, !_reset, we & ce_mmu_color, data[6:0], data_color);

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
      data_out = bdata[7:0];
   else if (!_ce_tag & oe & !_ub)
      data_out = bdata[15:8];
   else
      data_out = 8'bz;
end

always @(*)
begin
   if(!_ce_ram & !flag_mmu_enabled)             // accessing main RAM with MMU off
      baddress = {5'b0, faddress};
   else  if(!_ce_ram & flag_mmu_enabled)        // accessing main RAM with MMU enabled
      baddress = {address_mmu, faddress[11:0]};
   else if(!_ce_tag & ce_mmu_map)               // accessing the actual TAG RAM itself.
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

sm_unlock					   sm1(
                               !(faddress[15:8] == 8'hc0 & oe & bus_active), 
                               faddress[7:0], 
                               page_mmu
                              );


endmodule

module sm_unlock(
                  input clock, 
                  input [7:0]data,
                  output reg [7:0]out1
                );

reg [2:0]state;

always @(negedge clock)
begin
   case(state)
      0:
         if(data == 8'h55)
            state <= 1;
      1:
         if(data == 8'haa)
            state <= 2;
         else
            state <= 0;
      2:
         if(data == 8'hff)
            state <= 3;
         else
            state <= 0;
      3:
         if(data == 8'h00)
            state <= 4;
         else
            state <= 0;
      4:
         begin
            out1 <= data;
            state <= 0;
         end
      default:
            state <= 0;
   endcase
end
endmodule
