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
// File :                       DW_apb_uart_tx.v
// Author:                      Marc Wall
// Date :                       $Date: 2008/09/10 11:32:24 $
// Version      :               $Revision: 1.1 $
// Abstract     :               Top level FIFO module for the DW_apb_uart
//                              macro-cell. May include internal DW RAM
//                              (when configured), else it will connect
//                              to an external RAM via I/F signals 
//
//
// ---------------------------------------------------------------------
// Revision: $Id: DW_apb_uart_fifo.v,v 1.1 2008/09/10 11:32:24 yangjun Exp $
// ---------------------------------------------------------------------
`include "DW_apb_uart_cc_constants.v"
module DW_apb_uart_fifo
  (
   // Inputs
   pclk,
   presetn,
   tx_push,
   tx_pop,
   rx_push,
   rx_pop,
   tx_fifo_rst,
   rx_fifo_rst,
   rx_err_check_oe,
   tx_ram_out,
   tx_push_data,
   rx_ram_out,
   rx_push_data,
   
   // Outputs
   tx_full,
   tx_empty,
   //tx_almost_empty,
   rx_full,
   rx_empty,
   rx_overflow,
   //rx_almost_full,
   tx_ram_we_n,
   tx_ram_re_n,
   tx_ram_rd_ce_n,
   rx_ram_we_n,
   rx_ram_re_n,
   rx_ram_rd_ce_n,
   tx_ram_in,
   tx_ram_wr_addr,
   tx_ram_rd_addr,
   tx_pop_data,
   rx_ram_in,
   rx_ram_wr_addr,
   rx_ram_rd_addr,
   rx_pop_data
   );

   input                             pclk;             // APB clock 
   input                             presetn;          // APB async reset
   input                             tx_push;          // tx fifo pop
   input                             tx_pop;           // tx fifo pop
   input                             rx_push;          // rx fifo push
   input                             rx_pop;           // rx fifo pop
   input                             tx_fifo_rst;      // tx fifo reset
   input                             rx_fifo_rst;      // rx fifo reset
   input                             rx_err_check_oe;  // rx error check
                                                       // output enable
   input  [7:0]                      tx_ram_out;       // tx fifo read data
                                                       // from external ram
   input  [7:0]                      tx_push_data;     // data to the tx fifo
   input  [9:0]                      rx_ram_out;       // rx fifo read data
                                                       // from external ram
   input  [9:0]                      rx_push_data;     // data to the tx fifo

   output                            tx_full;          // tx fifo full status
   output                            tx_empty;         // tx fifo empty status
   //output                          tx_almost_empty;  // tx fifo almost empty status
   output                            rx_full;          // rx fifo full status
   output                            rx_empty;         // rx fifo empty status
   output                            rx_overflow;      // rx fifo overflow status
   //output                          rx_almost_full;   // rx fifo almost full status
   output                            tx_ram_we_n;      // tx fifo write 
                                                       // enable for external
                                                       // ram, active low
   output                            tx_ram_re_n;      // tx fifo read 
                                                       // enable for external
                                                       // ram, active low
   output                            tx_ram_rd_ce_n;   // tx fifo read port chip
                                                       // enable for external
                                                       // ram, active low
   output                            rx_ram_we_n;      // rx fifo write 
                                                       // enable for external
                                                       // ram, active low
   output                            rx_ram_re_n;      // rx fifo read 
                                                       // enable for external
                                                       // ram, active low
   output                            rx_ram_rd_ce_n;   // rx fifo read port chip
                                                       // enable for external
                                                       // ram, active low
   output [7:0]                      tx_ram_in;        // tx fifo write data
                                                       // to external ram
   output [`FIFO_ADDR_WIDTH-1:0]     tx_ram_wr_addr;   // tx fifo write address
                                                       // for external ram
   output [`FIFO_ADDR_WIDTH-1:0]     tx_ram_rd_addr;   // tx fifo read address
                                                       // for external ram
   output [7:0]                      tx_pop_data;      // data from the tx fifo
   output [9:0]                      rx_ram_in;        // rx fifo write data
                                                       // to external ram
   output [`FIFO_ADDR_WIDTH-1:0]     rx_ram_wr_addr;   // rx fifo write address
                                                       // for external ram
   output [`FIFO_ADDR_WIDTH-1:0]     rx_ram_rd_addr;   // rx fifo read address
                                                       // for external ram
   output [9:0]                      rx_pop_data;      // data from the rx fifo

   wire                              tx_we_n;          // tx fifo write 
                                                       // enable, active low
   wire                              tx_ram_we_n;      // tx fifo write 
                                                       // enable for external
                                                       // ram, active low
   wire                              tx_ram_re_n;      // tx fifo read 
                                                       // enable for external
                                                       // ram, active low
   wire                              rx_we_n;          // rx fifo write
                                                       // enable, active low
   wire                              rx_ram_we_n;      // rx fifo write 
                                                       // enable for external
                                                       // ram, active low
   wire                              rx_ram_re_n;      // rx fifo read 
                                                       // enable for external
                                                       // ram, active low
   wire                              tx_fifo_rst_n;    // tx fifo reset,
                                                       // active low
   wire                              tx_push_n;        // tx fifo push,
                                                       // active low
   wire                              tx_pop_n;         // tx fifo pop,
                                                       // active low
   wire                              rx_fifo_rst_n;    // rx fifo reset,
                                                       // active low
   wire                              rx_push_n;        // rx fifo push,
                                                       // active low
   wire                              rx_pop_n;         // rx fifo pop,
                                                       // active low
   wire                              rx_overflow;      // rx fifo overflow status
   wire                              tx_full;          // tx fifo full status 
   wire                              tx_empty;         // tx fifo empty status
   wire                              rx_full;          // rx fifo full status 
   wire                              rx_empty;         // rx fifo empty status

   wire   [`FIFO_ADDR_WIDTH-1:0]     tx_wr_addr;       // tx fifo write address
   wire   [`FIFO_ADDR_WIDTH-1:0]     tx_rd_addr;       // tx fifo read address
   wire   [7:0]                      tx_push_data;     // tx fifo write data
   wire   [7:0]                      tx_pop_data;      // tx fifo read data
   wire   [7:0]                      tx_data_out;      // tx fifo internal
                                                       // (dw) ram read data
   wire   [7:0]                      tx_ram_in;        // tx fifo write data
                                                       // from external ram
   wire   [7:0]                      tx_ram_out;       // tx fifo read data
                                                       // to external ram
   wire   [`FIFO_ADDR_WIDTH-1:0]     tx_ram_wr_addr;   // tx fifo write address
                                                       // for external ram
   wire   [`FIFO_ADDR_WIDTH-1:0]     tx_ram_rd_addr;   // tx fifo read address
                                                       // for external ram
   wire   [`FIFO_ADDR_WIDTH-1:0]     rx_wr_addr;       // rx fifo write address
   wire   [`FIFO_ADDR_WIDTH-1:0]     rx_rd_addr;       // rx fifo read address
   wire   [9:0]                      rx_push_data;     // rx fifo write data
   wire   [9:0]                      rx_pop_data;      // rx fifo read data
   wire   [9:0]                      rx_data_out;      // rx fifo dw ram read data
   wire   [9:0]                      rx_ram_in;        // rx fifo write data
                                                       // from external ram
   wire   [9:0]                      rx_ram_out;       // rx fifo read data
                                                       // to external ram
   wire   [`FIFO_ADDR_WIDTH-1:0]     rx_ram_wr_addr;   // rx fifo write address
                                                       // for external ram
   wire   [`FIFO_ADDR_WIDTH-1:0]     rx_ram_rd_addr;   // rx fifo read address
                                                       // for external ram
   
   reg                               tx_ram_rd_ce_n;   // tx fifo read port chip
                                                       // enable for external   
                                                       // ram, active low             
   reg                               rx_ram_rd_ce_n;   // rx fifo read port chip
                                                       // enable for external
                                                       // ram, active low


   // ------------------------------------------------------
   // Instance of transmit FIFO controller
   // ------------------------------------------------------

   DW_apb_uart_DWbb_fifoctl_s1_df
    #(`FIFO_MODE_UART, 2, `FIFO_ADDR_WIDTH )
   U_tx_fifo
     (
      .clk            (pclk),
      .rst_n          (tx_fifo_rst_n),
      .init_n         (1'b1),
      .push_req_n     (tx_push_n),
      .pop_req_n      (tx_pop_n),
      .diag_n         (1'b1),
      .ae_level       ({`FIFO_ADDR_WIDTH{1'b0}}),
      .af_thresh      ({`FIFO_ADDR_WIDTH{1'b1}}),
      .we_n           (tx_we_n),
      .wr_addr        (tx_wr_addr),
      .rd_addr        (tx_rd_addr),
      .empty          (tx_empty),
      .almost_empty   (),
      .full           (tx_full),
      .almost_full    (),
      .half_full      (),
      .error          ()
      );


   assign tx_fifo_rst_n = ~tx_fifo_rst;
   assign tx_push_n     = ~tx_push;
   assign tx_pop_n      = ~tx_pop;

   // ------------------------------------------------------
   // Instance of transmit FIFO DW RAM block, which is only
   // included if the UART is configured to use internal
   // FIFO memories
   // ------------------------------------------------------

   DW_apb_uart_DWbb_ram_r_w_s_dff
    #(8, `FIFO_MODE_UART, 0, `FIFO_ADDR_WIDTH)
   U_DW_tx_ram
     (
      .clk            (pclk),
      .rst_n          (presetn),
      .init_n         (1'b1),
      .wr_addr        (tx_wr_addr),
      .rd_addr        (tx_rd_addr),
      .data_in        (tx_push_data),
      .wr_n           (tx_we_n),
      .data_out       (tx_data_out)
      );


   // ------------------------------------------------------
   // Selection between internal and external FIFO RAM
   // If the UART is configured to use external RAM's then
   // TX pop data is the read data from the external RAM
   // (tx_ram_out), else it is the read data from the DW RAM
   // (tx_data_out). All external FIFO RAM signals are driven
   // low if the UART is configured to use internal RAM's,
   // except the active low control signals which are driven
   // high
   // ------------------------------------------------------
   assign tx_pop_data    = (`MEM_SELECT == 0) ? tx_ram_out           : tx_data_out;
   assign tx_ram_in      = (`MEM_SELECT == 0) ? tx_push_data         : 8'b0;
   assign tx_ram_wr_addr = (`MEM_SELECT == 0) ? tx_wr_addr           : {`FIFO_ADDR_WIDTH{1'b0}};
   assign tx_ram_rd_addr = (`MEM_SELECT == 0) ? tx_rd_addr           : {`FIFO_ADDR_WIDTH{1'b0}};
   assign tx_ram_we_n    = (`MEM_SELECT == 0) ? tx_we_n              : 1'b1;
   assign tx_ram_re_n    = (`MEM_SELECT == 0) ? (~tx_pop | tx_empty) : 1'b1;

   // External TX FIFO RAM read port chip enable
   always @(posedge pclk or negedge presetn)
     begin : tx_ram_rd_ce_n_PROC
       if(presetn == 1'b0) 
         begin
           tx_ram_rd_ce_n     <= 1'b1;
         end

       // The external TX FIFO RAM read port chip enable, this signal is
       // driven high if the UART is configured to use internal RAM's
       else if(`MEM_SELECT == 0)
         begin

           // The external TX FIFO RAM read port chip enable is asserted
           // if a write to the TX FIFO RAM occurs and the write address
           // is equal to the read address (indicating that there is valid
           // data at the first memory location thus a pre-fetch can be
           // performed) or if a read of the TX FIFO RAM occurs and the
           // TX FIFO is not empty (indicating that there is valid data
           // at the next read address thus a pre-fetch can be performed)
           if(((~tx_ram_we_n) && (tx_ram_wr_addr == tx_ram_rd_addr)) ||
              ((~tx_ram_re_n) && (~tx_empty)))
             begin
               tx_ram_rd_ce_n <= 1'b0;
             end
           else
             begin
               tx_ram_rd_ce_n <= 1'b1;
             end
         end
       else
         begin
           tx_ram_rd_ce_n     <= 1'b1;
         end
     end

   // ------------------------------------------------------
   // Instance of receive FIFO controller
   // ------------------------------------------------------
   DW_apb_uart_DWbb_fifoctl_s1_df
    #(`FIFO_MODE_UART, 2, `FIFO_ADDR_WIDTH)
   U_rx_fifo
     (
      .clk            (pclk),
      .rst_n          (rx_fifo_rst_n),
      .init_n         (1'b1),
      .push_req_n     (rx_push_n),
      .pop_req_n      (rx_pop_n),
      .diag_n         (1'b1),
      .ae_level       ({`FIFO_ADDR_WIDTH{1'b0}}),
      .af_thresh      ({`FIFO_ADDR_WIDTH{1'b1}}),
      .we_n           (rx_we_n),
      .wr_addr        (rx_wr_addr),
      .rd_addr        (rx_rd_addr),
      .empty          (rx_empty),
      .almost_empty   (),
      .full           (rx_full),
      .almost_full    (),
      .half_full      (),
      .error          ()
      );



   // the receive FIFO overflow signal get asserted if the RX FIFO is
   // full and a RX push occurs and there is no RX pop at the same time
   assign rx_overflow   = rx_full & (rx_push & ~rx_pop);

   assign rx_fifo_rst_n = ~rx_fifo_rst;
   assign rx_push_n     = ~rx_push;
   assign rx_pop_n      = ~rx_pop;
   

   // ------------------------------------------------------
   // Instance of receive FIFO DW RAM block, which is only
   // included if the UART is configured to use internal
   // FIFO memories
   // ------------------------------------------------------
   DW_apb_uart_DWbb_ram_r_w_s_dff
    #(10, `FIFO_MODE_UART, 0, `FIFO_ADDR_WIDTH)
   U_DW_rx_ram
     (
      .clk            (pclk),
      .rst_n          (presetn),
      .init_n         (1'b1),
      .wr_addr        (rx_wr_addr),
      .rd_addr        (rx_rd_addr),
      .data_in        (rx_push_data),
      .wr_n           (rx_we_n),
      .data_out       (rx_data_out)
      );


   // ------------------------------------------------------
   // Selection between internal and external FIFO RAM
   // If the UART is configured to use external RAM's then
   // RX pop data is the read data from the external RAM
   // (rx_ram_out), else it is the read data from the DW RAM
   // (rx_data_out). All external FIFO RAM signals are driven
   // low if the UART is configured to use internal RAM's,
   // except the active low control signals which are driven
   // high
   // ------------------------------------------------------
   assign rx_pop_data    = (`MEM_SELECT == 0) ? rx_ram_out                                : rx_data_out;
   assign rx_ram_in      = (`MEM_SELECT == 0) ? rx_push_data                              : 8'b0;
   assign rx_ram_wr_addr = (`MEM_SELECT == 0) ? rx_wr_addr                                : {`FIFO_ADDR_WIDTH{1'b0}};
   assign rx_ram_rd_addr = (`MEM_SELECT == 0) ? rx_rd_addr                                : {`FIFO_ADDR_WIDTH{1'b0}};
   assign rx_ram_we_n    = (`MEM_SELECT == 0) ? rx_we_n                                   : 1'b1;
   assign rx_ram_re_n    = (`MEM_SELECT == 0) ? (~rx_pop | rx_empty) & (~rx_err_check_oe) : 1'b1;

   // External RX FIFO RAM read port chip enable
   always @(posedge pclk or negedge presetn)
     begin : rx_ram_rd_ce_n_PROC
       if(presetn == 1'b0) 
         begin
           rx_ram_rd_ce_n  <= 1'b1;
         end

       // The external RX FIFO RAM read port chip enable, this signal is
       // driven high if the UART is configured to use internal RAM's
       else if(`MEM_SELECT == 0)
         begin
            
           // The external RX FIFO RAM read port chip enable is asserted
           // if a write to the RX FIFO RAM occurs and the write address
           // is equal to the read address (indicating that there is valid
           // data at the first memory location thus a pre-fetch can be
           // performed) or if a read of the RX FIFO RAM occurs when its
           // not for checking for receive errors or a new reads occurs
           // at the same time as the check and the RX FIFO is not empty
           // (indicating that there is valid data at the next read
           // address thus a pre-fetch can be performed)
           if(((~rx_ram_we_n) && (rx_ram_wr_addr == rx_ram_rd_addr)) ||
              (((~rx_ram_re_n) && ((~rx_err_check_oe) || rx_pop)) && (~rx_empty)))
             begin
               rx_ram_rd_ce_n <= 1'b0;
             end
           else
             begin
               rx_ram_rd_ce_n <= 1'b1;
             end
         end
        else
         begin
           rx_ram_rd_ce_n  <= 1'b1;
         end
     end

endmodule
