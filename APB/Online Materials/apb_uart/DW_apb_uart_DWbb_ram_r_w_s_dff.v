//-----------------------------------------------------------------------------
//
//       This confidential and proprietary software may be used only
//     as authorized by a licensing agreement from Synopsys Inc.
//     In the event of publication, the following notice is applicable:
//
//                    (C) COPYRIGHT 2004 SYNOPSYS INC.
//                           ALL RIGHTS RESERVED
//
//       The entire notice above must be reproduced on all authorized
//     copies.
//
// AUTHOR:    Rick Kelly    April 26, 2004
//
// VERSION:   DW_apb_uart_DWbb_ram_r_w_s Verilog Synthesis Model
//
// DesignWare_version: 7b877cb5
//
//-----------------------------------------------------------------------------
`include "DW_apb_uart_cc_constants.v"

  module DW_apb_uart_DWbb_ram_r_w_s_dff (
	clk,
	rst_n,
	init_n,
	wr_n,
	data_in,
	wr_addr,
        rd_addr,
	data_out
	);

   parameter data_width = 4;
   parameter depth = 8;
   parameter mem_mode = 0;
   parameter addr_width = 3;

   input 			clk;
   input 			rst_n;
   input 			init_n;
   input 			wr_n;
   input [data_width-1:0]	data_in;
   input [addr_width-1:0]	wr_addr;
   input [addr_width-1:0]	rd_addr;

   output [data_width-1:0]	data_out;

   reg [depth*data_width-1:0]   O1OO1IOO;
   reg [depth*data_width-1:0]   Illll1l1;
  wire [depth*data_width-1:0]	llOO1IIO;

   reg [addr_width-1:0]		lIOOI0l0;
   reg				O0101IOI;
   reg [data_width-1:0]		OII10lOI;
   reg [addr_width-1:0]		O1O1I0II;
   reg [data_width-1:0]		l0I0I1I0;

  wire [addr_width-1:0]		Il1IIIO0;
  wire				lI1Il10l;
  wire [data_width-1:0]		I100IIII;
  wire [addr_width-1:0]		II1IlO0I;
  wire [data_width-1:0]		OO0OI11l;
  reg [15:0] OlOlII11, l10I1O10;
  reg [24:0] llIIOOl0;
   
   
  function [data_width-1:0] l01IOl0l ;
    input [data_width*depth-1:0]	A;
    input [addr_width-1:0]  	SEL;
    reg   [31:0]		OlOlII11, l10I1O10, llIIOOl0;
    begin
      l01IOl0l  = {data_width {1'b0}};
      llIIOOl0 = 0;
      for (OlOlII11=0 ; OlOlII11<depth ; OlOlII11=OlOlII11+1) begin
	if (OlOlII11 == SEL) begin
	  for (l10I1O10=0 ; l10I1O10<data_width ; l10I1O10=l10I1O10+1) begin
	    l01IOl0l  [l10I1O10] = A [l10I1O10 + llIIOOl0];
	  end // for (l10I1O10
	end // if
	llIIOOl0 = llIIOOl0 + data_width;
      end // for (OlOlII11
    end
  endfunction

  assign OO0OI11l = l01IOl0l ( Illll1l1, II1IlO0I );



   always @ (Illll1l1 or lI1Il10l or Il1IIIO0 or I100IIII) begin : Il1I0I01
     O1OO1IOO = Illll1l1;

     if ( lI1Il10l == 1'b0 ) begin
       llIIOOl0 = 0;
       for (OlOlII11=0 ; OlOlII11<depth ; OlOlII11=OlOlII11+1) begin
	 if (Il1IIIO0 == OlOlII11) begin
	   for (l10I1O10=0 ; l10I1O10 < data_width ; l10I1O10=l10I1O10+1) begin
	     O1OO1IOO[ llIIOOl0+l10I1O10] = I100IIII[l10I1O10];
	   end
	 end
	 llIIOOl0 = llIIOOl0 + data_width;
       end
     end
   end


  
  always @ (posedge clk or negedge rst_n) begin : IlII000I
    if (rst_n == 1'b0) begin
      Illll1l1 <= {data_width*depth{1'b0}};
      O0101IOI <= 1'b0;
      lIOOI0l0 <= {addr_width{1'b0}};
      OII10lOI <= {data_width{1'b0}};
      O1O1I0II <= {addr_width{1'b0}};
      l0I0I1I0 <= {data_width{1'b0}};
    end else if (init_n == 1'b0) begin
      Illll1l1 <= {data_width*depth{1'b0}};
      O0101IOI <= 1'b0;
      lIOOI0l0 <= {addr_width{1'b0}};
      OII10lOI <= {data_width{1'b0}};
      O1O1I0II <= {addr_width{1'b0}};
      l0I0I1I0 <= {data_width{1'b0}};
    end else begin
      Illll1l1 <= O1OO1IOO;
      O0101IOI <= wr_n;
      lIOOI0l0 <= wr_addr;
      OII10lOI <= data_in;
      O1O1I0II <= rd_addr;
      l0I0I1I0 <= OO0OI11l;
    end
  end


  assign lI1Il10l = (mem_mode & 2)? O0101IOI : wr_n;
  assign I100IIII = (mem_mode & 2)? OII10lOI : data_in;
  assign Il1IIIO0 = (mem_mode & 2)? lIOOI0l0 : wr_addr;
  assign II1IlO0I  = (mem_mode & 2)? O1O1I0II : rd_addr;
  assign data_out = (mem_mode & 1)? l0I0I1I0 : OO0OI11l;
   
endmodule
