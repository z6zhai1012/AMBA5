// -------------------------------------------------------------------
//
//
//                   (C) COPYRIGHT 2003-2004 SYNOPSYS INC.
//                             ALL RIGHTS RESERVED
//
//  This software and the associated documentation are confidential and
//  proprietary to Synopsys, Inc.  Your use or disclosure of this software
//  is subject to the terms and conditions of a written license agreement
//  between you, or your company, and Synopsys, Inc.
//
//
// File    : DW_apb_uart_biu.v
// Author  : Joe Mc Cann & edited by Marc Wall
// Created : Thu Jun 13 13:32:20 2002
//
// Abstract: Apb bus interface module.
//           This module is intended for use with APB slave
//           macro-cells.  The module generates output signals
//           from the APB bus interface that are intended for use in
//           the register block of the macro-cell.
//
//        1: Generates the write enable (wr_en) and read
//           enable (rd_en) for register accesses to the macro-cell.
//
//        2: Decodes the address bus (paddr) to generate the active
//           byte lane signal (byte_en).
//
//        3: Strips the APB address bus (paddr) to generate the
//           register offset address output (reg_addr).
//
//        4: Registers APB read data (prdata) onto the APB data bus.
//           The read data is routed to the correct byte lane in this
//           module.
//
// -------------------------------------------------------------------
// Revision: $Id: DW_apb_uart_biu.v,v 1.1 2008/09/10 11:32:24 yangjun Exp $
// -------------------------------------------------------------------

`include "DW_apb_uart_cc_constants.v"
module DW_apb_uart_biu
(
 // APB bus bus interface
 pclk,
 presetn,
 psel,
 penable,
 pwrite, 
 paddr,
 pwdata,
 prdata,

 // regfile interface
 wr_en,
 wr_enx,
 rd_en,
 byte_en,
 reg_addr,
 ipwdata,
 iprdata
 );

   // The number of address bits required to access the UART memory map
   // (register map) is 10
   parameter ADDR_SLICE_LHS = 10;

   // -------------------------------------
   // -- APB bus signals
   // -------------------------------------
   input                            pclk;      // APB clock
   input                            presetn;   // APB reset
   input                            psel;      // APB slave select
   input       [ADDR_SLICE_LHS-1:0] paddr;     // APB address
   input                            pwrite;    // APB write/read
   input                            penable;   // APB enable
   input      [`APB_DATA_WIDTH-1:0] pwdata;    // APB write data bus
   
   output     [`APB_DATA_WIDTH-1:0] prdata;    // APB read data bus

   // -------------------------------------
   // -- Register block interface signals
   // -------------------------------------
   input  [`MAX_APB_DATA_WIDTH-1:0] iprdata;   // Internal read data bus

   output                           wr_en;     // Write enable signal
   output                           wr_enx;    // Write enable extra signal
   output                           rd_en;     // Read enable signal
   output                     [3:0] byte_en;   // Active byte lane signal
   output      [ADDR_SLICE_LHS-3:0] reg_addr;  // Register address offset
   output [`MAX_APB_DATA_WIDTH-1:0] ipwdata;   // Internal write data bus

   // -------------------------------------
   // -- Local registers & wires
   // -------------------------------------
   reg        [`APB_DATA_WIDTH-1:0] prdata;    // Registered prdata output
   reg    [`MAX_APB_DATA_WIDTH-1:0] ipwdata;   // Internal pwdata bus
   reg                        [3:0] byte_en;   // Registered byte_en output

   
   // --------------------------------------------
   // -- write/read enable
   //
   // -- Generate write/read enable signals from
   // -- psel, penable and pwrite inputs
   // --------------------------------------------
   assign wr_en  = psel &  penable &  pwrite;
   assign rd_en  = psel & !penable & !pwrite;

   // Used to perform writes on the previous cycle
   assign wr_enx = psel & !penable &  pwrite;

   
   // --------------------------------------------
   // -- Register address
   //
   // -- Strips register offset address from the
   // -- APB address bus
   // --------------------------------------------
   assign reg_addr = paddr[ADDR_SLICE_LHS-1:2];

   
   // --------------------------------------------
   // -- APB write data
   //
   // -- ipwdata is zero padded before being
   //    passed through this block
   // --------------------------------------------
   always @(pwdata) begin : IPWDATA_PROC
      ipwdata = { `MAX_APB_DATA_WIDTH{1'b0} };
      ipwdata[`APB_DATA_WIDTH-1:0] = pwdata[`APB_DATA_WIDTH-1:0];
   end
   
   // --------------------------------------------
   // -- Set active byte lane
   //
   // -- This bit vector is used to set the active
   // -- byte lanes for write/read accesses to the
   // -- registers
   // --------------------------------------------
   always @(paddr) begin : BYTE_EN_PROC
      if(`APB_DATA_WIDTH == 8) begin
         case(paddr[1:0])
           2'b00   : byte_en = 4'b0001;
           2'b01   : byte_en = 4'b0010;
           2'b10   : byte_en = 4'b0100;
           default : byte_en = 4'b1000;
         endcase
      end else begin
         if(`APB_DATA_WIDTH == 16) begin
            case(paddr[1])
              1'b0    : byte_en = 4'b0011;
              default : byte_en = 4'b1100;
            endcase
         end else begin
            byte_en = 4'b1111;
         end
      end
   end
   

   // --------------------------------------------
   // -- APB read data.
   //
   // -- Register data enters this block on a
   // -- 32-bit bus (iprdata). The upper unused
   // -- bit have been zero padded before entering
   // -- this block.  The process below strips the
   // -- active byte lane(s) from the 32-bit bus
   // -- and registers the data out to the APB
   // -- read data bus (prdata).
   // --------------------------------------------
   always @(posedge pclk or negedge presetn) begin : PRDATA_PROC
      if(presetn == 1'b0) begin
         prdata <= { `APB_DATA_WIDTH{1'b0} };
      end else begin
         if(rd_en) begin
            if(`APB_DATA_WIDTH == 8) begin
               case(byte_en)
                 4'b0001 : prdata <= iprdata[7:0];
                 4'b0010 : prdata <= iprdata[15:8];
                 4'b0100 : prdata <= iprdata[23:16];
                 default : prdata <= iprdata[31:24];
               endcase
            end else begin
               if(`APB_DATA_WIDTH == 16) begin
                  case(byte_en)
                    4'b0011 : prdata <= iprdata[15:0];
                    default : prdata <= iprdata[31:16];
                  endcase
               end else begin
                  prdata <= iprdata;
               end
            end
         end
      end
   end
   
   
endmodule // DW_apb_biu
