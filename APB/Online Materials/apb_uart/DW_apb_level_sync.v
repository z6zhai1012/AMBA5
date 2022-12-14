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
// File :                       DW_apb_level_sync.v
// Author:                      Marc Wall
// Date :                       $Date: 2008/09/10 11:32:24 $
// Version      :               $Revision: 1.1 $
// Abstract     :               Level Synchronization module
//
//
// ---------------------------------------------------------------------
// Revision: $Id: DW_apb_level_sync.v,v 1.1 2008/09/10 11:32:24 yangjun Exp $
// ---------------------------------------------------------------------
`include "DW_apb_uart_cc_constants.v"
module DW_apb_level_sync
  (
   // Inputs
   clk,
   rst_n,
   async,
   
   // Outputs
   sync
   );

   // -----------------------------------------------------------
   // -- Number of Register Stages parameter
   // -----------------------------------------------------------
   parameter STAGES = 2;

   // -----------------------------------------------------------
   // -- Register Reset Level parameter
   // -----------------------------------------------------------
   parameter RESET_LEV = 0;


   input                         clk;    // synchronizing clock
   input                         rst_n;  // active low async reset
   input                         async;  // async input
   
   output                        sync;   // sync'ed output

   reg                           sync1;  // stage 1 sync reg
   reg                           sync2;  // stage 2 sync reg
   reg                           sync3;  // stage 3 sync reg
   
   always @(posedge clk or negedge rst_n)
     begin : sync_PROC
       if(rst_n == 1'b0)
         begin
           sync1 <= (RESET_LEV == 1) ? 1'b1 : 1'b0;
           sync2 <= (RESET_LEV == 1) ? 1'b1 : 1'b0;
           sync3 <= (RESET_LEV == 1) ? 1'b1 : 1'b0;
         end
       else
         begin
           sync1 <= async;
           sync2 <= sync1;
           sync3 <= sync2;
         end
     end // block: sync_PROC
   
  assign sync = ((STAGES == 0) ? async : ((STAGES == 1) ? sync1 : ((STAGES == 2) ? sync2 : sync3)));

endmodule // DW_apb_level_sync
