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
// File :                       DW_apb_uart_rx.v
// Author:                      Marc Wall
// Date :                       $Date: 2008/09/10 11:32:24 $
// Version      :               $Revision: 1.1 $
// Abstract     :               Serial receiver module for the
//                              DW_apb_uart macro-cell
//
//
// ---------------------------------------------------------------------
// Revision: $Id: DW_apb_uart_rx.v,v 1.1 2008/09/10 11:32:24 yangjun Exp $
// ---------------------------------------------------------------------

// -----------------------------------------------------------
// -- UART Divisor Width Macro
// -----------------------------------------------------------
`define   UART_DIV_WIDTH    16
`include "DW_apb_uart_cc_constants.v"
module DW_apb_uart_rx
  (
   // Inputs
   sclk,
   s_rst_n,
   bclk,
   sin,
   sir_in,
   char_info,
   sir_en,
   lb_en,
   ser_out_lb,
   divisor,
   
   // Outputs
   rx_in_prog,
   rx_finish,
   ser_in,
   final_rx_in,
   rx_data
   );

   input                             sclk;          // APB Clock
   input                             s_rst_n;       // APB active low
                                                    // async reset
   input                             bclk;          // baud clock
   input                             sin;           // serial data in
   input                             sir_in;        // serial infrared
                                                    // data in
   input  [4:0]                      char_info;     // serial character
                                                    // information
   input                             sir_en;        // serial infrared
                                                    // enable
   input                             lb_en;         // loopback enable
   input                             ser_out_lb;    // serial tx data out
                                                    // for loopback
   input  [`UART_DIV_WIDTH-1:0]      divisor;       // clock divisor

   output                            rx_in_prog;    // serial reception
                                                    // in progress
   output                            rx_finish;     // serial reception of
                                                    // current character
                                                    // finished
   output                            ser_in;        // serial in
   output                            final_rx_in;   // final rx data in
                                                    // seen by the fsm
   output [9:0]                      rx_data;       // received data

   reg                               sync1;         // meta register 1
   reg                               sync2;         // meta register 2
   reg                               di_reg1;       // data integrity reg1
   reg                               di_reg2;       // data integrity reg2
   reg                               rx_in_prog;    // serial reception
                                                    // in progress
   reg                               parity_err;    // parity error detect
   reg                               dly_cnt16;     // delayed cnt16
   reg    [3:0]                      rx_bclk_cnt;   // transmitter baud
                                                    // clock counter
   reg    [3:0]                      c_state;       // current state rx fsm
                                                    // state reg
   reg    [3:0]                      n_state;       // next state rx fsm
                                                    // state reg
   reg    [1:0]                      c_state_break; // current state break
                                                    // fsm state reg
   reg    [1:0]                      n_state_break; // next state break
                                                    // fsm state reg
   reg    [9:0]                      rx_shift_reg;  // rx shift register

   wire                              cnt16;         // 16 baud clock count
   wire                              ser_in;        // serial in
   wire                              rx_in;         // receive in
   wire                              di_rx_in;      // data integrity rx_in
   wire                              brk_di_rx_in;  // break di_rx_in
   wire                              check_parity;  // check parity enable
   wire                              rx_finish;     // serial reception of
                                                    // current character
                                                    // finished
   wire                              load_cnt;      // rx baud clock
                                                    // counter load enable
   wire                              start_check;   // start check for
                                                    // break interrupts
   wire                              shift_en;      // rx shift reg shift
                                                    // enable
   wire                              f_err;         // framing error
   wire                              int_f_err;     // internal framing
                                                    // error
   wire                              rx_fsm_rst;    // rx fsm reset
   wire   [9:0]                      rx_data;       // received data

   // state variables for RX FSM
   parameter          IDLE      = 4'b1000;
   parameter          LOW_DET   = 4'b1001;
   parameter          START     = 4'b1010;
   parameter          DATA0     = 4'b0000;
   parameter          DATA1     = 4'b0001;
   parameter          DATA2     = 4'b0010;
   parameter          DATA3     = 4'b0011;
   parameter          DATA4     = 4'b0100;
   parameter          DATA5     = 4'b0101;
   parameter          DATA6     = 4'b0110;
   parameter          DATA7     = 4'b0111;
   parameter          PARITY    = 4'b1110;
   parameter          STOP      = 4'b1111;

   // state variables for break FSM
   parameter          BRK_IDLE  = 2'b00;
   parameter          CHECK     = 2'b01;
   parameter          CHAR_OK   = 2'b10;
   parameter          BREAK     = 2'b11;

   // ------------------------------------------------------
   // receiver baud clock counter, this is used to keep
   // track of the number of baud clocks that have occurred
   // so that each received bit is sampled at the correct
   // time i.e. approx. the mid point of the bit time, this
   // is done to ensure stability on the line.
   // the counter will remain at zero when the RX FSM is in
   // the IDLE state, except when in SIR mode when the break
   // FSM is in the break state (as the counter needs to
   // keep counting to enable the sampling of the di_rx_in
   // signal at the correct time to give the break di_rx_in
   // signal) or when the load counter signal is asserted.
   // this is done to prevent the counter from counting when
   // there is no need, hence saving power which would be lost
   // due to switching
   // ------------------------------------------------------
   always @(posedge sclk or negedge s_rst_n)
     begin : rx_bclk_cnt_PROC
       if(s_rst_n == 1'b0)
         begin
           rx_bclk_cnt <= 4'b0000;
         end
       else if(c_state == IDLE && !(sir_en && c_state_break == BREAK) && !(load_cnt))
         begin
           rx_bclk_cnt <= 4'b0000;
         end
       else if(load_cnt)
         begin
           if(sir_en)
             begin

               // Ensures that the SiR 3/16th pulse is sampled
               // in the middle
               if(divisor == 16'b1)
                 begin
                   rx_bclk_cnt <= 4'b1111;
                 end
               else
                 begin
                   rx_bclk_cnt <= 4'b1110;
                 end
             end
           else
             begin
               rx_bclk_cnt <= 4'b1000;
             end
         end
       else if(bclk == 1'b1)
         begin
           rx_bclk_cnt <= rx_bclk_cnt + 1'b1;
         end
     end // block: rx_bclk_cnt_PROC

   // the count 16 signal is asserted when the receiver baud clock
   // counter reaches 15 (0-15 therefore count of 16) and the baud clock
   // signal is asserted. this is used to indicate to the FSM that the
   // current character bit has been received (sampled)
   assign cnt16 = (rx_bclk_cnt == 4'b1111 && bclk == 1'b1) ? 1'b1 : 1'b0;

   // delayed cnt16, required for break FSM in SIR mode
   always @(posedge sclk or negedge s_rst_n)
     begin : dly_cnt16_PROC
       if(s_rst_n == 1'b0)
         begin
           dly_cnt16 <= 1'b0;
         end
       else
         begin
           dly_cnt16 <= cnt16;
         end
     end // block: dly_cnt16_PROC

   // ------------------------------------------------------
   // serial input, this is the result of the selection of 
   // serial data between the standard serial input (in UART
   // mode) and serial infrared input data (in IR mode)
   // ------------------------------------------------------
   assign ser_in = sir_en ? sir_in : sin;

   // the serial input is then passed through two stage
   // synchronization registers to take care of metastability
   always @(posedge sclk or negedge s_rst_n)
     begin : sync_PROC
       if(s_rst_n == 1'b0)
         begin
           sync1 <= 1'b1;
           sync2 <= 1'b1;
         end
       else
         begin
           sync1 <= ser_in;
           sync2 <= sync1;
         end
     end // block: sync_PROC

   // receive in
   // when in loopback mode the receive in signal is assigned to the
   // serial output for loopback signal which is the output of the
   // serial TX block, that is sout (in UART mode) and the inverse of
   // sir_out_n (in IR mode)
   assign rx_in = lb_en ? ser_out_lb : sync2;
   
   // ------------------------------------------------------
   // data integrity, the best two out of three samples will
   // give the resulting serial input that will be passed to
   // the RX FSM
   // ------------------------------------------------------
   assign di_rx_in = (rx_in & di_reg1) | (rx_in & di_reg2) |
                     (di_reg1 & di_reg2);

   // final RX in
   assign final_rx_in = di_rx_in;
   
   always @(posedge sclk or negedge s_rst_n)
     begin : di_reg_PROC
       if(s_rst_n == 1'b0)
         begin
           di_reg1 <= 1'b1;
           di_reg2 <= 1'b1;
         end
       else if(bclk)
         begin
           di_reg1 <= rx_in;
           di_reg2 <= di_reg1;
         end
     end // block: di_reg_PROC
   
   // ------------------------------------------------------
   // RX FSM state assignment
   // ------------------------------------------------------
   always @(posedge sclk or negedge s_rst_n)
     begin : RX_FSM_SEQ_PROC
       if(s_rst_n == 1'b0)
         begin
           c_state <= IDLE;
         end
       else if(rx_fsm_rst)
         begin
           c_state <= IDLE;
         end
       else
         begin
           c_state <= n_state;
         end
     end

   // ------------------------------------------------------
   // RX FSM next state logic
   // ------------------------------------------------------
   always @(c_state   or di_rx_in or cnt16 or
            char_info or c_state_break
            )
     begin : RX_FSM_PROC
    
       case(c_state)
      
         LOW_DET :
           if(cnt16)
             begin
               if(di_rx_in == 1'b0)
                 n_state = START;
               else
                 n_state = IDLE;
             end
           else
             n_state = LOW_DET;
        
         START :
           if(cnt16)
             n_state = DATA0;
           else
             n_state = START;

         DATA0 :
           if(cnt16)
             n_state = DATA1;
           else
             n_state = DATA0;

         DATA1 :
           if(cnt16)
             n_state = DATA2;
           else
             n_state = DATA1;

         DATA2 :
           if(cnt16)
             n_state = DATA3;
           else
             n_state = DATA2;

         DATA3 :
           if(cnt16)
             n_state = DATA4;
           else
             n_state = DATA3;

         DATA4 :
           if(cnt16)
             begin
               if(char_info[1:0] == 2'b00)
                 if(char_info[3])
                   n_state = PARITY;
                 else
                   n_state = STOP;
               else
                 n_state = DATA5;
             end
           else
             n_state = DATA4;

         DATA5 :
           if(cnt16)
             begin
               if(char_info[1:0] == 2'b01)
                 if(char_info[3])
                   n_state = PARITY;
                 else
                   n_state = STOP;
               else
                 n_state = DATA6;
             end
           else
             n_state = DATA5;

         DATA6 :
           if(cnt16)
             begin
               if(char_info[1:0] == 2'b10)
                 if(char_info[3])
                   n_state = PARITY;
                 else
                   n_state = STOP;
               else
                 n_state = DATA7;
             end
           else
             n_state = DATA6;

         DATA7 :
           if(cnt16)
             begin
               if(char_info[3])
                 n_state = PARITY;
               else
                 n_state = STOP;
             end
           else
             n_state = DATA7;

         PARITY :
           if(cnt16)
             n_state = STOP;
           else
             n_state = PARITY;

         STOP :
           if(di_rx_in == 1'b0)
             n_state = START;
           else
             n_state = IDLE;
      
         default :
           if(di_rx_in == 1'b0 && (c_state_break != BREAK))
             n_state = LOW_DET;
           else
             n_state = IDLE;

       endcase
     end // block: RX_FSM_PROC

   // ------------------------------------------------------
   // load counter, the assertion of this signal causes the
   // RX baud clock counter to be loaded with the appropriate
   // value so that it is synchronized with the mid point of
   // bit time
   // ------------------------------------------------------
   assign load_cnt     = ((c_state==IDLE) && (n_state==LOW_DET));

   // ------------------------------------------------------
   // start check for break
   // ------------------------------------------------------
   assign start_check  = (c_state==START);

   // ------------------------------------------------------
   // shift enable, the assertion of this signal causes the
   // RX shift register to shift in the received serial data
   // on the line
   // ------------------------------------------------------
   assign shift_en     = (c_state==DATA0 && (rx_bclk_cnt == 4'b0000 && bclk)) || 
                         (c_state==DATA1 && (rx_bclk_cnt == 4'b0000 && bclk)) ||
                         (c_state==DATA2 && (rx_bclk_cnt == 4'b0000 && bclk)) ||
                         (c_state==DATA3 && (rx_bclk_cnt == 4'b0000 && bclk)) ||
                         (c_state==DATA4 && (rx_bclk_cnt == 4'b0000 && bclk)) ||
                         (c_state==DATA5 && (rx_bclk_cnt == 4'b0000 && bclk)) ||
                         (c_state==DATA6 && (rx_bclk_cnt == 4'b0000 && bclk)) ||
                         (c_state==DATA7 && (rx_bclk_cnt == 4'b0000 && bclk));

   // ------------------------------------------------------
   // check parity, the assertion of this signal causes the
   // the parity of the received data to be checked against
   // the received parity bit
   // ------------------------------------------------------
   assign check_parity = (c_state==PARITY && rx_bclk_cnt == 4'b0000);

   // ------------------------------------------------------
   // RX finished, is asserted when the the current
   // character has been received
   // ------------------------------------------------------
   assign rx_finish    = (c_state==STOP);

   // ------------------------------------------------------
   // framing error, is asserted when the receiver does not
   // detect a valid stop bit
   // ------------------------------------------------------
   assign f_err        = (c_state==STOP && di_rx_in == 1'b0);

   // internal framing error
   assign int_f_err    = rx_finish ? f_err: rx_shift_reg[9];

   // ------------------------------------------------------
   // break di_rx_in
   // if in serial IR mode break di_rx_in is assigned the
   // actual data value only at the sample point (assertion
   // of cnt16), otherwise it is set to zero. in normal (UART)
   // mode operation break di_rx_in is assigned to di_rx_in
   // ------------------------------------------------------
   assign brk_di_rx_in = sir_en ? ((cnt16 | dly_cnt16) ? di_rx_in : 1'b0) : di_rx_in;

   // ------------------------------------------------------
   // break interrupt detection FSM state assignment
   // ------------------------------------------------------
   always @(posedge sclk or negedge s_rst_n)
     begin : BREAK_FSM_SEQ_PROC
       if(s_rst_n == 1'b0)
         begin
           c_state_break <= BRK_IDLE;
         end
       else
         begin
           c_state_break <= n_state_break;
         end
     end // block: BREAK_FSM_SEQ_PROC
   
   // ------------------------------------------------------
   // break interrupt detection FSM next state logic
   // ------------------------------------------------------
   always @(c_state_break or start_check or
            brk_di_rx_in  or rx_finish
            )
     begin : BREAK_FSM_PROC
    
       case(c_state_break)
      
         BRK_IDLE :
           if(start_check)
             n_state_break = CHECK;
           else
             n_state_break = BRK_IDLE;

         CHECK :
           if(rx_finish)
             begin
               if(brk_di_rx_in == 1'b0)
                 n_state_break = BREAK;
               else
                 n_state_break = BRK_IDLE;
             end
           else
             begin
               if(brk_di_rx_in == 1'b0)
                 n_state_break = CHECK;
               else
                 n_state_break = CHAR_OK;
             end

         CHAR_OK:
           if(rx_finish)
             n_state_break = BRK_IDLE;
           else
             n_state_break = CHAR_OK;

         default:
           if(brk_di_rx_in == 1'b0)
             n_state_break = BREAK;
           else
             n_state_break = BRK_IDLE;

       endcase
     end // block: BREAK_FSM_PROC

   // ------------------------------------------------------
   // RX FSM reset, 
   // ------------------------------------------------------
   assign rx_fsm_rst = ((n_state_break==BREAK) || (c_state_break==BREAK));

   // ------------------------------------------------------
   // indicates if a serial reception is in progress
   // gets asserted when the start check signal is asserted,
   // and gets de-asserted when the character has been
   // completely received (rx_finish asserted)
   // ------------------------------------------------------
   always @(posedge sclk or negedge s_rst_n)
     begin : rx_in_prog_PROC
       if(s_rst_n == 1'b0)
         begin
           rx_in_prog   <= 1'b0;
         end
       else
         if(start_check)
           begin
             rx_in_prog <= 1'b1;
           end
         else if(rx_finish)
           begin
             rx_in_prog <= 1'b0;
           end
     end // block: rx_in_prog_PROC
   
   // ------------------------------------------------------
   // parity error detection
   // if parity is enabled (char_info[3] set to one), then
   // the parity error signal is asserted if the parity of
   // the received data does not match the received parity
   // bit
   // ------------------------------------------------------
   always @(char_info     or check_parity or
            rx_shift_reg  or di_rx_in
            )
     begin : parity_err_PROC
       if(char_info[3])
         begin
           // the parity is checked when the parity bit of
           // the character has been received as indicated
           // by the assertion of the check parity signal,
           // otherwise the parity error signal remains
           // the unchanged (i.e. value in bit[8] of the RX
           // shift reg
           if(check_parity)
             begin
               parity_err = di_rx_in ^ (^{rx_shift_reg[7:0], ~char_info[4]});
             end
           else
             begin
                parity_err = rx_shift_reg[8];
             end
         end
       else
         begin
           parity_err     = 1'b0;
         end
     end // block: parity_err_PROC

   // ------------------------------------------------------
   // RX shift register
   // The data is shifted in on each consecutive rising edge
   // of the serial clock when the shift enable signal is
   // asserted
   // ------------------------------------------------------
   always @(posedge sclk or negedge s_rst_n)
     begin : rx_shift_reg_PROC
       if(s_rst_n == 1'b0)
         begin
           rx_shift_reg                    <= {10{1'b0}};
         end
       else 
         begin
           if(shift_en)
             begin
               case(char_info[1:0])
                 2'b00   : rx_shift_reg[7:0] <= {3'b000,   di_rx_in, rx_shift_reg[4:1]};
                 2'b01   : rx_shift_reg[7:0] <= {2'b00,    di_rx_in, rx_shift_reg[5:1]};
                 2'b10   : rx_shift_reg[7:0] <= {1'b0,     di_rx_in, rx_shift_reg[6:1]};
                 default : rx_shift_reg[7:0] <= {di_rx_in, rx_shift_reg[7:1]};
               endcase
             end
           rx_shift_reg[9:8]               <= {int_f_err, parity_err};
         end
     end // block: rx_shift_reg_PROC

   // ------------------------------------------------------
   // received data, this is the data from the received
   // character and also includes framing error and parity
   // error information
   // ------------------------------------------------------
   assign rx_data = {int_f_err, parity_err, rx_shift_reg[7:0]};

endmodule // DW_apb_uart_rx
