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
// File :                       DW_apb_uart_to_det.v
// Author:                      Marc Wall
// Date :                       $Date: 2008/09/10 11:32:24 $
// Version      :               $Revision: 1.1 $
// Abstract     :               Timeout Detection module for the
//                              DW_apb_uart macro-cell
//
// ---------------------------------------------------------------------
// Revision: $Id: DW_apb_uart_to_det.v,v 1.1 2008/09/10 11:32:24 yangjun Exp $
// ---------------------------------------------------------------------
`include "DW_apb_uart_cc_constants.v"
module DW_apb_uart_to_det
  (
   // Inputs
   sclk,
   s_rst_n,
   bclk,
   clear_lp_req_pclk,
   ser_in,
   final_rx_in,
   allow_lp_req,
   rx_in_prog,
   cts_n,
   dsr_n,
   dcd_n,
   ri_n,
   scan_mode,
   char_info,
   to_det_cnt_ens,
   
   // Outputs
   clear_lp_req_sclk,
   uart_lp_req,
   char_to
   );

   input                              sclk;                // serial I/F clock
   input                              s_rst_n;             // serial I/F active
                                                           // low async reset
   input                              bclk;                // baud clock
   input                              clear_lp_req_pclk;   // clear for UART low
                                                           // power request from
                                                           // the pclk domain
   input                              ser_in;              // serial in
   input                              final_rx_in;         // final rx in seen by
                                                           // receiver
   input                              allow_lp_req;        // Allow low power request
   input                              rx_in_prog;          // rx in progress
   input                              cts_n;               // clear to send,
                                                           // active low
   input                              dsr_n;               // data set ready,
                                                           // active low
   input                              dcd_n;               // data carrier detect,
                                                           // active low
   input                              ri_n;                // ring indicator,
                                                           // active low
   input                              scan_mode;           // scan mode signal
   input  [3:0]                       char_info;           // serial character
                                                           // information
   
   input  [`TO_DET_CNT_ENS_WIDTH-1:0] to_det_cnt_ens;      // timeout detect
                                                           // count enables
   output                             clear_lp_req_sclk;   // clear for UART low
                                                           // power request from
                                                           // the sclk domain
   output                             uart_lp_req;         // uart low power
                                                           // request
   output                             char_to;             // character timeout
                                                           // toggle signal

   wire                               rx_change;           // change in final_rx_in,
                                                           // i.e. edge detect
   wire                               char_to_ed;          // character timeout
                                                           // edge detect
   wire                               char_to;             // character timeout
                                                           // toggle signal
   wire                               uart_lp_req;         // uart low power
                                                           // request
   wire                               lp_req_rst_n;        // active low async reset
                                                           // for UART low power
                                                           // request 
   wire                               clear_lp_req_sclk;   // clear for UART low
                                                           // power request from
                                                           // the sclk domain
   wire                               common_reset;        // common reset
   wire                               shdw_uart_lp_req;    // shadow uart_lp_req
   wire                               cts_ed;              // clear to send,
                                                           // edge detect
   wire                               dsr_ed;              // data set ready,
                                                           // edge detect
   wire                               dcd_ed;              // data carrier detect,
                                                           // edge detect
   wire                               ri_ed;               // ring indicator,
                                                           // edge detect
   wire                               cge_cnt_en;          // clock gate enable
                                                           // count enable
   wire                               cto_cnt_en;          // character timeout
                                                           // count enable
   wire                               lb_en;               // loopback enable
   wire                               far;                 // fifo access reg
   wire                               break;               // break control
   wire                               thr_empty;           // transmit holding reg empty
   wire                               tx_in_prog;          // transmission
                                                           // in progress
   wire                               rbr_empty;           // RBR empty
   wire                               fifo_en;             // fifo enable
   wire                               rx_pop;              // rx fifo pop
   wire                               mc_change;           // modem control
                                                           // change indicator
   wire   [7:0]                       int_to_det_cnt_ens;  // int timeout detect
                                                           // count enables
   reg    [7:0]                       internal_to_det_cnt_ens;// internal
                                                           // to_det_cnt_ens
   
   reg                                dly_final_rx_in;     // delayed final_rx_in
   reg                                int_char_to;         // internal character
                                                           // timeout toggle signal
   reg                                dly_char_to;         // delayed char_to
   reg                                int_uart_lp_req;     // internal uart low
                                                           // power request
   reg                                int_shdw_uart_lp_req;// internal
                                                           // shdw_uart_lp_req
   reg                                dly_cts_n;           // delayed cts_n
   reg                                dly_dsr_n;           // delayed dsr_n
   reg                                dly_dcd_n;           // delayed dcd_n
   reg                                dly_ri_n;            // delayed ri_n
   reg                                shdw_clear_lrs;      // shadow clear
                                                           // lp request sclk
   reg    [9:0]                       timeout_val;         // character timeout
                                                           // value
   reg    [7:0]                       cge_to_val;          // clock gate enable
                                                           // timeout value
   reg    [9:0]                       cto_cnt;             // character timeout
                                                           // counter
   reg    [7:0]                       cge_cnt;             // clock gate enable
                                                           // counter

   // Character timeout counter
   always @(posedge sclk or negedge s_rst_n)
     begin : cto_cnt_PROC
       if(s_rst_n == 1'b0)
         begin
           cto_cnt <= 10'b0;
         end
       else if(cto_cnt_en == 1'b0 || rx_change || char_to_ed)
         begin
           cto_cnt <= 10'b0;
         end
       else if(bclk == 1'b1)
         begin
           cto_cnt <= cto_cnt + 1;
         end
     end // block: cto_cnt_PROC

   // If FIFO's are enabled then the character timeout counter enable
   // signal is asserted when the RX FIFO is not empty and the RX FIFO
   // is not being read
   assign cto_cnt_en = (`FIFO_MODE_UART != 0) ? (fifo_en ? ((~rbr_empty) & (~rx_pop)) : 1'b0) : 1'b0;

   // Assignment of counter enable bits
   assign lb_en      = int_to_det_cnt_ens[7];
   assign far        = int_to_det_cnt_ens[6];
   assign break      = int_to_det_cnt_ens[5];
   assign thr_empty  = int_to_det_cnt_ens[4];
   assign tx_in_prog = int_to_det_cnt_ens[3];
   assign rbr_empty  = int_to_det_cnt_ens[2];
   assign fifo_en    = int_to_det_cnt_ens[1];
   assign rx_pop     = int_to_det_cnt_ens[0];

   // The width of to_det_cnt_ens can vary in width from 3 bits to 8 bits
   // By assigning to an 8-bit internal version we can reference from this bus rather than the input
   // This internal bus is further broken down to eliminate any logic if CLK_GATE_EN is true
   always @(to_det_cnt_ens)
     begin : internal_to_det_cnt_ens_PROC
      internal_to_det_cnt_ens = 0;
      internal_to_det_cnt_ens[`TO_DET_CNT_ENS_WIDTH-1:0] = to_det_cnt_ens[`TO_DET_CNT_ENS_WIDTH-1:0];
     end // block: internal_to_det_cnt_ens_PROC
   
   // Internal timeout detect counter enables
   assign int_to_det_cnt_ens[7:3] = (`CLK_GATE_EN == 1) ? internal_to_det_cnt_ens[7:3] : 5'b0;
   assign int_to_det_cnt_ens[2:0] = internal_to_det_cnt_ens[2:0];

   // If a change is seen on the data line entering the receiver
   // the RX change signal will be asserted for one clock cycle
   assign rx_change = final_rx_in ^ dly_final_rx_in;

   // Delayed final_rx_in
   always @(posedge sclk or negedge s_rst_n)
     begin : dly_final_rx_in_PROC
       if(s_rst_n == 1'b0)
         begin
           dly_final_rx_in <= 1'b0;
         end
       else
         begin
           dly_final_rx_in <= final_rx_in;
         end
     end // block: dly_final_rx_in_PROC

   // If the counter reaches the timeout value then the character timeout
   // signal will be toggled to indicate that a timeout has occurred
   always @(posedge sclk or negedge s_rst_n)
     begin : int_char_to_PROC
       if(s_rst_n == 1'b0)
         begin
           int_char_to <= 1'b0;
         end
       else if(cto_cnt == timeout_val && (~char_to_ed))
         begin
           int_char_to <= (~char_to);
         end
     end // block: int_char_to_PROC

   // As this module may exist even when FIFO's are not implemented, the
   // character timeout logic will be removed by DC if this is the case
   assign char_to = (`FIFO_MODE_UART != 0) ? int_char_to : 1'b0;

   // Delayed character timeout
   always @(posedge sclk or negedge s_rst_n)
     begin : dly_char_to_PROC
       if(s_rst_n == 1'b0)
         begin
           dly_char_to <= 1'b0;
         end
       else
         begin
           dly_char_to <= char_to;
         end
     end // block: dly_char_to_PROC

   // Character timeout edge detect, required to clear counter back to
   // zero to prevent the char_to signal toggling multiple times for a
   // single timeout when the baud clock is slow
   assign char_to_ed = char_to ^ dly_char_to;

   // The character timeout value is equal to 4 character times and since
   // a character time (or duration) can vary depending on the character
   // information that has been set, the character timeout value is
   // calculated as follows:
   // 
   // num. of bits in char * 4 * 16 (num. of bclks in a bit time)
   // 
   always @(char_info)
     begin : timeout_val_PROC
        case(char_info)
      
          4'b0001 : timeout_val = 512;
          4'b0010 : timeout_val = 576;
          4'b0011 : timeout_val = 640;
          4'b0100 : timeout_val = 480;
          4'b0101 : timeout_val = 576;
          4'b0110 : timeout_val = 640;
          4'b0111 : timeout_val = 704;
          4'b1000 : timeout_val = 512;
          4'b1001 : timeout_val = 576;
          4'b1010 : timeout_val = 640;
          4'b1011 : timeout_val = 704;
          4'b1100 : timeout_val = 544;
          4'b1101 : timeout_val = 640;
          4'b1110 : timeout_val = 704;
          4'b1111 : timeout_val = 768;

          default : timeout_val = 448;

        endcase
     end // block: timeout_val_PROC

   // Clock gate enable counter
   always @(posedge sclk or negedge common_reset)
     begin : cge_cnt_PROC
       if(common_reset == 1'b0)
         begin
           cge_cnt <= 8'b0;
         end
       else if(cge_cnt_en == 1'b0 || rx_change || rx_in_prog || mc_change)
         begin
           cge_cnt <= 8'b0;
         end
       else if(bclk == 1'b1 && shdw_uart_lp_req != 1'b1)
         begin
           cge_cnt <= cge_cnt + 1;
         end
     end // block: cge_cnt_PROC

   // If the UART has been configured to have a clock gate enable output(s)
   // on the interface to indicate that the device is inactive, so clocks
   // may be gated then the clock gate enable counter enable signal gets
   // asserted when the THR or TX FIFO (in FIFO mode) is empty and the
   // RBR or RX FIFO (in FIFO mode) is empty and there is no serial
   // transmission in progress and loopback operation is not enabled and
   // FIFO access mode is not in operation and a break is not being TX'ed.
   assign cge_cnt_en = (`CLK_GATE_EN == 1) ? ((~lb_en) & (~far) & (~break) &
                        thr_empty & rbr_empty & (~tx_in_prog)) : 1'b0;

   // If the clock gate enable counter reaches the clock gate enable
   // timeout value then the internal UART low power request signal is
   // asserted, else the signal will be de-asserted
   always @(posedge sclk or negedge common_reset)
     begin : int_uart_lp_req_PROC
       if(common_reset == 1'b0)
         begin
           int_uart_lp_req <= 1'b0;
         end

       // The greater than or equal to is used due to the fact that
       // when the baud clock signal is always asserted (a baud
       // divisor of 1 is selected) the counter will increment to
       // the value after the clock gate enable timeout value before
       // the assertion of the uart_lp_req is seen
       else if (cge_cnt >= cge_to_val)
         begin
           if (allow_lp_req) begin
             int_uart_lp_req <= 1'b1;
           end
         end
       else
         begin
           int_uart_lp_req <= 1'b0;
         end
     end // block: int_uart_lp_req_PROC
   assign common_reset = scan_mode ? s_rst_n : (s_rst_n & lp_req_rst_n);

   // Internal shadow UART low power request
   always @(posedge sclk or negedge s_rst_n)
     begin : int_shdw_uart_lp_req_PROC
       if(s_rst_n == 1'b0)
         begin
           int_shdw_uart_lp_req <= 1'b0;
         end

       // The greater than or equal to is used due to the fact that
       // when the baud clock signal is always asserted (a baud
       // divisor of 1 is selected) the counter will increment to
       // the value after the clock gate enable timeout value before
       // the assertion of the uart_lp_req is seen
       else if(cge_cnt >= cge_to_val)
         begin
           int_shdw_uart_lp_req <= 1'b1;
         end
       else
         begin
           int_shdw_uart_lp_req <= 1'b0;
         end
     end

   // Asynchronous reset generator for UART low power request
   DW_apb_async_rst_gen
    #(0, 1) U_DW_apb_async_rst_gen
     (
      // Inputs
      .clk             (sclk),
      .async_rst1      (s_rst_n),
      .async_rst2      (clear_lp_req_sclk),
      .scan_mode       (scan_mode),

      // Outputs
      .new_async_rst   (),
      .new_async_rst_n (lp_req_rst_n)
      );

   // sclk domain clear for the UART low power request
   // If the UART low power request is asserted and either the serial UART
   // line, sin, goes low or the serial IR input, sir_in, goes low or the
   // delayed version (after synchronization and data integrity),
   // final_rx_in, is asserted (used to solve a corner case issue that
   // occurs when in SIR mode and divisor is one) or a change on the modem
   // control signals occurs (cts_ed, dsr_ed, dcd_ed or ri_ed) then the
   // clear low power request sclk signal will get asserted. It will also
   // get asserted if the clear low power request pclk signal is asserted
   assign clear_lp_req_sclk = shdw_uart_lp_req & ((~ser_in) | (~final_rx_in) |
                              mc_change | clear_lp_req_pclk);

   // Scan shadow register for the sclk domain clear for the UART low
   // power request
   always @(posedge sclk or negedge s_rst_n)
     begin : shdw_clear_lrs_PROC
       if(s_rst_n == 1'b0)
         begin
           shdw_clear_lrs <= 1'b0;
         end
       else if(scan_mode)
         begin
           shdw_clear_lrs <= clear_lp_req_sclk;
         end
       else
         begin
           shdw_clear_lrs <= 1'b0;
         end
     end // block: shdw_clear_lrs
   

   // Change on the modem control signals
   assign mc_change = (cts_ed | dsr_ed | dcd_ed | ri_ed);

   // Clear To Send (CTS) edge detect
   assign cts_ed = cts_n ^ dly_cts_n;

   // Delayed Clear To Send
   always @(posedge sclk or negedge s_rst_n)
     begin : dly_cts_n_PROC
       if(s_rst_n == 1'b0)
         begin
           dly_cts_n <= 1'b1;
         end
       else

         // The scan shadow register for the sclk
         // domain clear for the UART low power
         // request is only OR'ed with the clear
         // to send signal so that the shadow
         // register output is used and hence not
         // optimized away. The functional operation
         // of the Delayed Clear To Send signal is
         // not effected in non-scan operation.
         begin
           dly_cts_n <= cts_n || shdw_clear_lrs;
         end
     end // block: dly_cts_n

   // Data Set Ready (DSR) edge detect
   assign dsr_ed = dsr_n ^ dly_dsr_n;

   // Delayed Data Set Ready
   always @(posedge sclk or negedge s_rst_n)
     begin : dly_dsr_n_PROC
       if(s_rst_n == 1'b0)
         begin
           dly_dsr_n <= 1'b1;
         end
       else
         begin
           dly_dsr_n <= dsr_n;
         end
     end // block: dly_dsr_n

   // Data Carrier Detect (DCD) edge detect
   assign dcd_ed = dcd_n ^ dly_dcd_n;

   // Delayed Data Carrier Detect
   always @(posedge sclk or negedge s_rst_n)
     begin : dly_dcd_n_PROC
       if(s_rst_n == 1'b0)
         begin
           dly_dcd_n <= 1'b1;
         end
       else
         begin
           dly_dcd_n <= dcd_n;
         end
     end // block: dly_dcd_n

   // Ring Indicator (RI) edge detect
   assign ri_ed = ri_n ^ dly_ri_n;

   // Delayed Ring Indicator
   always @(posedge sclk or negedge s_rst_n)
     begin : dly_ri_n_PROC
       if(s_rst_n == 1'b0)
         begin
           dly_ri_n <= 1'b1;
         end
       else
         begin
           dly_ri_n <= ri_n;
         end
     end // block: dly_ri_n

   // The clock gate enable timeout value is equal to 1 character times
   // and since a character time (or duration) can vary depending on the
   // character information that has been set, the clock gate enable
   // timeout value is calculated as follows:
   // 
   // num. of bits in char * 16 (num. of bclks in a bit time)
   // 
   always @(char_info)
     begin : cge_to_val_PROC
        case(char_info)
      
          4'b0001 : cge_to_val = 128;
          4'b0010 : cge_to_val = 144;
          4'b0011 : cge_to_val = 160;
          4'b0100 : cge_to_val = 120;
          4'b0101 : cge_to_val = 144;
          4'b0110 : cge_to_val = 160;
          4'b0111 : cge_to_val = 176;
          4'b1000 : cge_to_val = 128;
          4'b1001 : cge_to_val = 144;
          4'b1010 : cge_to_val = 160;
          4'b1011 : cge_to_val = 176;
          4'b1100 : cge_to_val = 136;
          4'b1101 : cge_to_val = 160;
          4'b1110 : cge_to_val = 176;
          4'b1111 : cge_to_val = 192;

          default : cge_to_val = 112;

        endcase
     end // block: cge_to_val_PROC

   // As this module may exist even when clock gate enable(s) are not
   // implemented, the clock gate enable logic will be removed by DC
   // if this is the case
   assign uart_lp_req      = (`CLK_GATE_EN == 1) ? int_uart_lp_req : 1'b0;
   assign shdw_uart_lp_req = (`CLK_GATE_EN == 1) ? int_shdw_uart_lp_req : 1'b0;
   
endmodule // DW_apb_uart_to_det
