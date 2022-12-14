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
// File :                       DW_apb_uart_bclk_gen.v
// Author:                      Marc Wall
// Date :                       $Date: 2008/09/10 11:32:24 $
// Version      :               $Revision: 1.1 $
// Abstract     :               UART baud clock generator
//
// ---------------------------------------------------------------------
// Revision: $Id: DW_apb_uart_bclk_gen.v,v 1.1 2008/09/10 11:32:24 yangjun Exp $
// ---------------------------------------------------------------------

// -----------------------------------------------------------
// -- UART Divisor Width Macro
// -----------------------------------------------------------
`define   UART_DIV_WIDTH    16
`include "DW_apb_uart_cc_constants.v"
module DW_apb_uart_bclk_gen
  (
   // Inputs
   sclk,
   s_rst_n,
   divisor,
   divisor_wd,
   scan_mode,
   uart_lp_req,

   // Outputs
   allow_lp_req,
   bclk,
   baudout_n
   );

   input                         sclk;          // clock
   input                         s_rst_n;       // active low async reset
   input  [`UART_DIV_WIDTH-1:0]  divisor;       // clock divisor
   input                         divisor_wd;    // divisor change indicator
   input                         scan_mode;     // when 1 => we are in scan_mode   
   input                         uart_lp_req;   // uart low power request

   output                        allow_lp_req;  // allow low power request
   output                        bclk;          // baud clock
   output                        baudout_n;     // external baud clock reference

   reg                           next_bclk;     // Next bclk
   reg                           next_baud_n;   // Next baud_n
   reg                           allow_lp_req;  // allow low power request
   reg                           bclk;          // baud clock
   reg                           baudout_n;     // external baud clock
                                                // reference
   reg                           baud_n;        // external baud clock
                                                // protocol for divisor >= 3
   reg                           dly_divisor_wd;// delayed divisor_wd
   reg    [`UART_DIV_WIDTH-1:0]  cnt;           // clock counter reg

   wire                          clear;         // counter and generated
                                                // clock clear indicator
   wire                          int_divisor_wd;// internal divisor_wd
   wire                          divisor_wd_ed; // divisor change indicator
                                                // edge detect

   // Counts the number of sclk cycles that have passed,
   // up to the divisor value minus one. When this value
   // is reached OR a clear occurs the counter wraps to
   // zero.
   // Used in the generation of the baud clock signals
   //
   // clear is the highest precedence as the divisor could be changed 
   // to be lower than the cnt value and we would have lockout.
   always @ (posedge sclk or negedge s_rst_n)
     begin : cnt_PROC
       if(s_rst_n == 1'b0)
         begin
           cnt     <= {`UART_DIV_WIDTH{1'b0}};
         end
       else
         begin
           if(clear) begin
             cnt <= {`UART_DIV_WIDTH{1'b0}};
           end else begin
             if(divisor != {`UART_DIV_WIDTH{1'b0}})
             begin
               if(cnt == (divisor - 1'b1))
                 begin
                   cnt <= {`UART_DIV_WIDTH{1'b0}};
                 end
               else
                 begin
                   cnt <= cnt + 1'b1;
                 end
             end
           end
          end
     end // block: cnt_PROC

   // The clear signal gets asserted when the divisor is zero or
   // whenever the divisor value is going to be changed as indicated
   // by the assertion of divisor_wd signal
   assign clear = ((divisor == {`UART_DIV_WIDTH{1'b0}}) || int_divisor_wd) ? 1 : 0;

   // Internal divisor_wd, is asserted when the divisor_wd edge detect
   // signal is asserted when the DW_apb_uart is configured to have two
   // clocks, else it is asserted when the divisor_wd signal is asserted
   assign int_divisor_wd = (`CLOCK_MODE == 2) ? divisor_wd_ed : divisor_wd;

   // divisor_wd rising edge detect
   assign divisor_wd_ed = divisor_wd & (~dly_divisor_wd);

   // divisor_wd edge detect register
   always @(posedge sclk or negedge s_rst_n)
     begin : dly_divisor_wd_PROC
       if(s_rst_n == 1'b0)
         begin
           dly_divisor_wd <= 1'b0;
         end 
       else 
         begin
           dly_divisor_wd <= divisor_wd;
         end
     end // block: dly_divisor_wd_PROC

   // Baud clock generator
   // When clear is asserted the baud clock signal is set to
   // its inactive state, the assertion of the baud clock signal
   // is determined by the current value of the clock counter.
   // some examples of baud clock assertion for differing
   // divisors are as follows:
   //
   //          _   _   _   _   _   _   _
   //  sclk  _| |_| |_| |_| |_| |_| |_| |_
   //        _____
   //  clear      |_______________________
   //
   //  Divisor of 2
   //        _________ ___ ___ ___ ___ ___
   //  cnt   ___0_____X_1_X_0_X_1_X_0_X_1_X
   //                  ___     ___     ___
   //  bclk  _________|   |___|   |___|   |
   //
   //  Divisor of 3
   //        _________ ___ ___ ___ ___ ___
   //  cnt   ___0_____X_1_X_2_X_0_X_1_X_2_X
   //                  ___         ___
   //  bclk  _________|   |_______|   |___
   //
   //  Divisor of 5
   //        _________ ___ ___ ___ ___ ___
   //  cnt   ___0_____X_1_X_2_X_3_X_4_X_0_X
   //                  ___
   //  bclk  _________|   |_______________|
   //
   always @ (posedge sclk or negedge s_rst_n)
     begin : bclk_PROC
     if (s_rst_n == 1'b0)
       bclk <= 1'b0;
     else
       bclk <= next_bclk;
   end

   // Next bclk
   always @(uart_lp_req or clear or divisor or bclk or cnt)
     begin : next_bclk_PROC
       if(clear)
         next_bclk = 1'b0;
       else if(divisor == 16'b10)
         if (uart_lp_req == 1) next_bclk = bclk;
         else                  next_bclk = ~bclk;
       else if(cnt == {`UART_DIV_WIDTH{1'b0}})
         next_bclk = 1'b1;
       else
         next_bclk = 1'b0;
     end

   // External baud clock reference generator
   // This signal is passed out at the top level and is part
   // of Nationals protocol, it is used as a baud clock
   // reference for receiving devices.
   // When the selected divisor value is one the baudout_n
   // signal is assigned to the sclk, if the divisor is two
   // the baudout_n signal is assigned to the baud clock (bclk),
   // otherwise it is assigned to the baud_n generated signal
   // which adheres to Nationals standard in regard to duty
   // cycle, that is for divisors of three and above the signal
   // will be active (low) for two sclk cycles and inactive
   // (high) for (divisor - two) sclk cycles. some examples of
   // baud clock assertion for differing divisors are as follows:
   //
   //               _   _   _   _   _   _   _
   //  sclk       _| |_| |_| |_| |_| |_| |_| |_
   //             _____
   //  clear           |_______________________
   //
   //  Divisor of 2
   //             _________ ___ ___ ___ ___ ___
   //  cnt        ___0_____X_1_X_0_X_1_X_0_X_1_X
   //             _____________     ___     ___
   //  baudout_n               |___|   |___|   |
   //
   //  Divisor of 3
   //             _________ ___ ___ ___ ___ ___
   //  cnt        ___0_____X_1_X_2_X_0_X_1_X_2_X
   //             _____________         ___
   //  baudout_n               |_______|   |___
   //
   //  Divisor of 5
   //             _________ ___ ___ ___ ___ ___
   //  cnt        ___0_____X_1_X_2_X_3_X_4_X_0_X
   //             _____________________
   //  baudout_n                       |_______|
   //
   // If the divisor is 1 then always allow the request to clear.
   // Otherwise wait until baudout_n is gone to a 1
 
   always @ (divisor or sclk or bclk or baud_n or scan_mode or next_baud_n or next_bclk or uart_lp_req)
     begin : baudout_n_PROC

       if(divisor == 16'b1)
         begin
           baudout_n = scan_mode ? bclk : (uart_lp_req == 1 ? 1'b1 : sclk);
           allow_lp_req = 1'b1;
         end
       else if(divisor == 16'b10)
         begin
           baudout_n = bclk;
           allow_lp_req = next_bclk;
         end
       else
         begin
           baudout_n = baud_n;
           allow_lp_req = next_baud_n;
         end
     end // block: baudout_n_PROC
                   
   // When clear is asserted the baud_n signal is set to its
   // inactive state, the assertion of the baud_n signal is
   // determined by the current value of the clock counter.
   always @ (posedge sclk or negedge s_rst_n)
     begin : baud_n_PROC
       if(s_rst_n == 1'b0) begin
         baud_n     <= 1'b1;
       end else begin
         baud_n <= next_baud_n;
       end
     end

   // Next baud_n
   always @(uart_lp_req or clear or cnt or divisor or baud_n)
     begin : next_baud_n_PROC
       if (clear)
         next_baud_n = 1'b1;
        else
          if (cnt == {`UART_DIV_WIDTH{1'b0}})
            next_baud_n = 1'b1;
          else 
            if ((cnt == (divisor - 2'b10)) && (uart_lp_req == 0))
              next_baud_n = 1'b0;
            else 
              next_baud_n = baud_n;
     end

endmodule
