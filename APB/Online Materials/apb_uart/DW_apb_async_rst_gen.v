// ---------------------------------------------------------------------
//
//                   (C) COPYRIGHT 2003-2004 SYNOPSYS INC.
//                             ALL RIGHTS RESERVED
//
//  This software and the associated documentation are confidential and
//  proprietary to Synopsys, Inc.  Your use or disclosure of this software
//  is subject to the terms and conditions of a written license agreement
//  between you, or your company, and Synopsys, Inc.
//
//  The entire notice above must be reproduced on all authorized copies.
//
// File :                       DW_apb_async_rst_gen.v
// Author:                      Marc Wall
// Date :                       $Date: 2008/09/10 11:32:24 $
// Version      :               $Revision: 1.1 $
// Abstract     :               Level Synchronization module
//
//
// ---------------------------------------------------------------------
// Revision: $Id: DW_apb_async_rst_gen.v,v 1.1 2008/09/10 11:32:24 yangjun Exp $
// ---------------------------------------------------------------------
`include "DW_apb_uart_cc_constants.v"
module DW_apb_async_rst_gen
  (
   // Inputs
   clk,
   async_rst1,
   async_rst2,
   scan_mode,
                  
   // Outputs
   new_async_rst,
   new_async_rst_n
   );

   // -----------------------------------------------------------
   // -- Asynchronous reset polarity parameters
   // -----------------------------------------------------------
   parameter ASYNC_RST1_POL = 0;
   parameter ASYNC_RST2_POL = 0;

   input                         clk;                 // clock
   input                         async_rst1;          // async reset 1
   input                         async_rst2;          // async reset 2
   input                         scan_mode;           // scan mode signal
   
   output                        new_async_rst;       // new async active
                                                      // high reset
   output                        new_async_rst_n;     // new async active
                                                      // low reset

   wire                          new_async_rst_n;     // new async active
                                                      // low reset
   wire                          async_rst_n;         // async active
                                                      // low reset
   wire                          int_async_rst1;      // internal async_rst1
   wire                          int_async_rst2;      // internal async_rst2
   wire                          new_async_rst;       // new async active
                                                      // high reset

   reg                           int_new_async_rst_n; // internal
                                                      // new_async_rst_n

   // New asynchronous active low reset
   assign new_async_rst_n = scan_mode ? int_async_rst1 : int_new_async_rst_n;
   
   // When the async_rst_n signal is asserted (low) the register will
   // be reset and the active low new asynchronous reset signal will
   // get asserted (asynchronously) and will be removed synchronously
   // in relation to the specified clock on the next rising edge.
   // As this reset is driven by the output of a register it must have
   // the ability to be controlled, this is done using the scan mode 
   // signal
   always @(posedge clk or negedge async_rst_n)
     begin : int_new_async_rst_PROC
       if(async_rst_n == 1'b0)
         begin
           int_new_async_rst_n <= 1'b0;
         end
       else
         begin
           if(scan_mode)
             begin
               int_new_async_rst_n <= int_new_async_rst_n;
             end
           else
             begin
               int_new_async_rst_n <= 1'b1;
             end
         end
     end // block: int_new_async_rst_n_PROC

   // The active low asynchronous reset for the reset register
   // is asserted (low) when the internal async_rst1 signal
   // or internal async_rst2 signal is asserted (low)
   assign async_rst_n = scan_mode ? int_async_rst1 : int_async_rst1 & int_async_rst2;

   // Polarity assignment for asynchronous reset inputs
   assign int_async_rst1 = (ASYNC_RST1_POL==0) ? async_rst1 : (~async_rst1);
   assign int_async_rst2 = (ASYNC_RST2_POL==0) ? async_rst2 : (~async_rst2);

   // Active high asynchronous reset
   assign new_async_rst = (~new_async_rst_n);

endmodule // DW_apb_async_rst_gen
