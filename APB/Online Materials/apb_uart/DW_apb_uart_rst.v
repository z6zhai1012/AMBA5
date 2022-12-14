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
// File :                       DW_apb_uart_rst.v
// Author:                      Marc Wall
// Date :                       $Date: 2008/09/10 11:32:24 $
// Version      :               $Revision: 1.1 $
// Abstract     :               Reset module for the DW_apb_uart
//                              macro-cell.
//
//
// ---------------------------------------------------------------------
// Revision: $Id: DW_apb_uart_rst.v,v 1.1 2008/09/10 11:32:24 yangjun Exp $
// ---------------------------------------------------------------------
`include "DW_apb_uart_cc_constants.v"
module DW_apb_uart_rst
  (
   // Inputs
   pclk,
   presetn,
   sw_rst_dec,
   scan_mode,
   // Outputs
   new_presetn,
   new_s_rst_n
   );

   input                             pclk;               // APB clock 
   input                             presetn;            // APB async reset
                                                         // low async reset
   input                             sw_rst_dec;         // SW reset decode
   input                             scan_mode;          // scan mode signal
   
   output                            new_presetn;        // generated presetn,
                                                         // may include SW reset
   output                            new_s_rst_n;        // generated s_rst_n,
                                                         // may include SW reset

   reg                               sw_rst_n;           // software reset
   reg                               sclk_sync1;         // sclk domain sync
                                                         // register stage 1
   reg                               sclk_sync2;         // sclk domain sync
                                                         // register stage 2
   reg                               pclk_sync1;         // pclk domain sync
                                                         // register stage 1
   reg                               pclk_sync2;         // pclk domain sync
                                                         // register stage 2
   reg                               dly_pclk_sync2;     // delayed pclk_sync2

   wire                              sclk;               // serial I/F clock
   wire                              s_rst_n;            // serial I/F active
                                                         // low async reset
   wire                              new_presetn;        // generated presetn,
                                                         // may include SW reset
   wire                              new_s_rst_n;        // generated s_rst_n,
                                                         // may include SW reset
   wire                              int_new_s_rst_n;    // internal new_s_rst_n
   wire                              sclk_sync_rst_n;    // sclk domain SW reset
   wire                              re_sync_sw_rst_fed; // re-synchronized
                                                         // SW reset falling
                                                         // edge detect

   // ------------------------------------------------------
   // UR (UART reset) related functionality
   // ------------------------------------------------------
   
   // This signal is used as the pclk domain reset for all other modules
   // in the UART thus it must always be assigned a practical value. That
   // is, if the UART has been configured to have the SRR then it is asserted
   // when either presetn is asserted (low) or sw_rst_n is asserted (low),
   // else it is asserted when presetn (only) is asserted.
   // Under certain configurations this reset maybe driven by the output
   // of a register and hence must have the ability to be controlled, this
   // is done using the scan mode signal
   assign new_presetn = scan_mode ? presetn : ((`SHADOW == 1) ? sw_rst_n & presetn : presetn);

   // Under certain configurations this reset maybe driven by the output
   // of a register and hence must have the ability to be controlled, this
   // is done using the scan mode signal
   assign new_s_rst_n = scan_mode ? ((`CLOCK_MODE == 2) ? s_rst_n : new_presetn) : int_new_s_rst_n;

   // This signal is used as the sclk domain reset for all other modules
   // in the UART thus it must always be assigned a practical value. That
   // is, if the UART has been configured to have two clocks, then if it
   // has been configured to have the SRR then it is asserted when either
   // s_rst_n is asserted (low) or sclk_sync_rst_n is asserted (low), else
   // it is asserted when s_rst_n (only) is asserted. If the UART is
   // configured to have one clock (plck only) then it will assert when
   // new_presetn is asserted, i.e. in this case new_s_rst_n and 
   // new_presetn are identical
   assign int_new_s_rst_n = (`CLOCK_MODE == 2) ? ((`SHADOW == 1) ? sclk_sync_rst_n & s_rst_n : s_rst_n) :
          new_presetn;

   // The active low software reset signal is asserted if the internal
   // software reset register enable is asserted and the value written
   // to the UART reset bit (bit[0]) is one. When a SW reset is performed
   // it must be removed synchronously
   always @(posedge pclk or negedge presetn)
     begin : sw_rst_n_PROC
       if(presetn == 1'b0)
         begin
           sw_rst_n <= 1'b1;
         end 
       else 
         begin
           if(sw_rst_dec)
             begin
               sw_rst_n <= 1'b0;
             end
           else if(`CLOCK_MODE == 2)
             begin
               if(re_sync_sw_rst_fed)
                 begin
                   sw_rst_n <= 1'b1;
                 end
             end
           else
             begin
               sw_rst_n <= 1'b1;
             end
         end
     end // block: sw_rst_n_PROC

   // Falling edge detect of re-synchronized SW reset
   assign re_sync_sw_rst_fed = dly_pclk_sync2 & (~pclk_sync2);

   // Edge detect register
   always @(posedge pclk or negedge presetn)
     begin : dly_pclk_sync2_PROC
       if(presetn == 1'b0) 
         begin
           dly_pclk_sync2 <= 1'b1;
         end
       else
         begin
           dly_pclk_sync2 <= pclk_sync2;
         end
     end // block: dly_pclk_sync2_PROC

   // pclk metastability registers for the sclk domain SW reset
   always @(posedge pclk or negedge presetn)
     begin : pclk_sync_PROC
       if(presetn == 1'b0) 
         begin
           pclk_sync1 <= 1'b1;
           pclk_sync2 <= 1'b1;
         end 
       else 
         begin
           pclk_sync1 <= sclk_sync_rst_n;
           pclk_sync2 <= pclk_sync1;
         end
     end // block: pclk_sync_PROC
   
   // sclk metastability registers for the SW reset
   always @(posedge sclk or negedge s_rst_n)
     begin : sclk_sync_PROC
       if(s_rst_n == 1'b0) 
         begin
           sclk_sync1 <= 1'b1;
           sclk_sync2 <= 1'b1;
         end 
       else 
         begin
           sclk_sync1 <= sw_rst_n;
           sclk_sync2 <= sclk_sync1;
         end
     end // block: sclk_sync_PROC

   // sclk domain synchronized SW reset
   assign sclk_sync_rst_n = sclk_sync2;

endmodule // DW_apb_uart_rst
