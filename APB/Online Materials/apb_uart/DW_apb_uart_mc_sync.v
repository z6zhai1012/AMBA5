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
// File :                       DW_apb_uart_mc_sync.v
// Author:                      Marc Wall
// Date :                       $Date: 2008/09/10 11:32:24 $
// Version      :               $Revision: 1.1 $
// Abstract     :               Modem control synchronization module for
//                              the DW_apb_uart macro-cell
//
//
// ---------------------------------------------------------------------
// Revision: $Id: DW_apb_uart_mc_sync.v,v 1.1 2008/09/10 11:32:24 yangjun Exp $
// ---------------------------------------------------------------------
`include "DW_apb_uart_cc_constants.v"
module DW_apb_uart_mc_sync
  (
   // Inputs
   pclk,
   presetn,
   cts_n,
   dsr_n,
   dcd_n,
   ri_n,
   
   // Outputs
   sync_cts_n,
   sync_dsr_n,
   sync_dcd_n,
   sync_ri_n
   );

   input                             pclk;                // APB clock 
   input                             presetn;             // APB async reset
   input                             cts_n;               // clear to send,
                                                          // active low
   input                             dsr_n;               // data set ready,
                                                          // active low
   input                             dcd_n;               // data carrier detect,
                                                          // active low
   input                             ri_n;                // ring indicator,
                                                          // active low

   output                            sync_cts_n;          // synd'ed clear to send,         
                                                          // active low
   output                            sync_dsr_n;          // synd'ed data set ready,        
                                                          // active low
   output                            sync_dcd_n;          // synd'ed data carrier detect,
                                                          // active low
   output                            sync_ri_n;           // synd'ed ring indicator,        
                                                          // active low

   wire                              cts_n;               // clear to send,
                                                          // active low
   wire                              sync_cts_n;          // synd'ed clear to
                                                          // send, active low
   wire                              dsr_n;               // data set ready,
                                                          // active low
   wire                              sync_dsr_n;          // synd'ed data set
                                                          // ready, active low
   wire                              dcd_n;               // data carrier detect,
                                                          // active low
   wire                              sync_dcd_n;          // synd'ed data carrier
                                                          // detect, active low
   wire                              ri_n;                // ring indicator,
                                                          // active low
   wire                              sync_ri_n;           // synd'ed ring indicator,
                                                          // active low

   // Level synchronizer for cts_n
   DW_apb_level_sync
    #(2, 1) U_DW_apb_level_sync8
     (
      // Inputs
      .clk           (pclk),
      .rst_n         (presetn),
      .async         (cts_n),
   
      // Outputs
      .sync          (sync_cts_n)
      );

   // Level synchronizer for dsr_n
   DW_apb_level_sync
    #(2, 1) U_DW_apb_level_sync9
     (
      // Inputs
      .clk           (pclk),
      .rst_n         (presetn),
      .async         (dsr_n),
   
      // Outputs
      .sync          (sync_dsr_n)
      );

   // Level synchronizer for dcd_n
   DW_apb_level_sync
    #(2, 1) U_DW_apb_level_sync10
     (
      // Inputs
      .clk           (pclk),
      .rst_n         (presetn),
      .async         (dcd_n),
   
      // Outputs
      .sync          (sync_dcd_n)
      );

   // Level synchronizer for ri_n
   DW_apb_level_sync
    #(2, 1) U_DW_apb_level_sync11
     (
      // Inputs
      .clk           (pclk),
      .rst_n         (presetn),
      .async         (ri_n),
   
      // Outputs
      .sync          (sync_ri_n)
      );

endmodule // DW_apb_uart_mc_sync
