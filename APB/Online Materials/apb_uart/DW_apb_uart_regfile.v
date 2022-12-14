// -------------------------------------------------------------------
//
//                   (C) COPYRIGHT 2003-2004 SYNOPSYS INC.
//                             ALL RIGHTS RESERVED
//
//  This software and the associated documentation are confidential and
//  proprietary to Synopsys, Inc.  Your use or disclosure of this software
//  is subject to the terms and conditions of a written license agreement
//  between you, or your company, and Synopsys, Inc.
//
// File    : DW_apb_uart_regfile.v
// Author  : Marc Wall
// Created : Fri June 06 11:36:58 BST 2003
// Date    : $Date: 2008/09/10 11:32:24 $
// Version : $Revision: 1.1 $
// Abstract: Register Block module for the DW_apb_uart macrocell
//           containing all of the software accessible registers.
//
//        1: Decodes the reg_addr input to generate select signals
//           for each SW register in the macro-cell.
//
//        2: Update SW register values from the ipwdata input when
//           the register is selected and the wr_en input is active.
//
//        3: Outputs the selected registers data onto the iprdata
//           output bus.  The iprdata output is zero padded when the
//           select register is less than 32-bits wide.
//
// -------------------------------------------------------------------
// Revision: $Id: DW_apb_uart_regfile.v,v 1.1 2008/09/10 11:32:24 yangjun Exp $
// -------------------------------------------------------------------


// -----------------------------------------------------------
// -- Register bit Width macros
// -----------------------------------------------------------
`define   LEGACY_RW             8
`define   RXFIFO_RW             10
`define   MCR_RW                7
`define   FAR_RW                1
`define   TFR_RW                8
`define   RFW_RW                10
`define   USR_RW                5
`define   TFL_RW                `FIFO_ADDR_WIDTH+1
`define   MAX_TFL_RW            12
`define   RFL_RW                `FIFO_ADDR_WIDTH+1
`define   MAX_RFL_RW            12
`define   SRR_RW                3
`define   SRTS_RW               1
`define   SBCR_RW               1
`define   SDMAM_RW              1
`define   SFE_RW                1
`define   SRT_RW                2
`define   STET_RW               2
`define   HTX_RW                1
`define   DMASA_RW              1

// -----------------------------------------------------------
// -- Register address offset macros
// -----------------------------------------------------------
`define   RBR_OFFSET            8'h0
`define   THR_OFFSET            8'h0
`define   DLL_OFFSET            8'h0
`define   IER_OFFSET            8'h1
`define   DLH_OFFSET            8'h1
`define   IIR_OFFSET            8'h2
`define   FCR_OFFSET            8'h2
`define   LCR_OFFSET            8'h3
`define   MCR_OFFSET            8'h4
`define   LSR_OFFSET            8'h5
`define   MSR_OFFSET            8'h6
`define   SCR_OFFSET            8'h7
`define   SRBR_LOW_OFFSET       8'hc
`define   SRBR_HIGH_OFFSET      8'h1b
`define   STHR_LOW_OFFSET       8'hc
`define   STHR_HIGH_OFFSET      8'h1b
`define   FAR_OFFSET            8'h1c
`define   TFR_OFFSET            8'h1d
`define   RFW_OFFSET            8'h1e
`define   USR_OFFSET            8'h1f
`define   TFL_OFFSET            8'h20
`define   RFL_OFFSET            8'h21
`define   SRR_OFFSET            8'h22
`define   SRTS_OFFSET           8'h23
`define   SBCR_OFFSET           8'h24
`define   SDMAM_OFFSET          8'h25
`define   SFE_OFFSET            8'h26
`define   SRT_OFFSET            8'h27
`define   STET_OFFSET           8'h28
`define   HTX_OFFSET            8'h29
`define   DMASA_OFFSET          8'h2a
`define   UART_CPR_OFFSET       8'h3d
`define   UART_CV_OFFSET        8'h3e
`define   UART_CTR_OFFSET       8'h3f
`include "DW_apb_uart_cc_constants.v"
module DW_apb_uart_regfile
  (
   // APB bus interface
   // Inputs
   pclk,
   presetn,

   // Application interface
   // Inputs
   scan_mode,

   // DW_apb_uart_biu interface
   // Inputs
   wr_en,
   wr_enx,
   rd_en,
   byte_en,
   reg_addr,
   ipwdata,
   // Outputs
   iprdata,

   // FIFO interface
   // Inputs
   tx_full,
   tx_empty,
   rx_full,
   rx_empty,
   rx_overflow,
   tx_pop_data,
   rx_pop_data,
   // Outputs
   tx_push,
   tx_pop,
   rx_push,
   rx_pop,
   tx_fifo_rst,
   rx_fifo_rst,
   rx_err_check_oe,
   tx_push_data,
   rx_push_data,

   // Serial transmitter interface
   // Inputs
   tx_finish,
   // Outputs
   tx_start,
   tx_data,

   // Serial receiver interface
   // Inputs
   rx_finish,
   rx_in_prog,
   rx_data,

   // Common serial interface
   // Outputs
   sir_en,
   lb_en,
   break,

   // Timeout detection interface
   // Inputs
   char_to,
   // Outputs
   cnt_ens_ed,
   to_det_cnt_ens,

   // Baud clock generator
   // Outputs
   divsr,
   divsr_wd,

   // Character information, used my multiple modules
   // Outputs
   char_info,

   // Modem interface
   // Inputs
   cts_n,
   dsr_n,
   dcd_n,
   ri_n,
   // Outputs
   dtr_n,
   rts_n,
   out1_n,
   out2_n,

   // DMA interface
   // Inputs
   dma_tx_ack,
   dma_rx_ack,
   // Outputs
   dma_tx_req,
   dma_tx_req_n,
   dma_tx_single,
   dma_tx_single_n,
   dma_rx_req,
   dma_rx_req_n,
   dma_rx_single,
   dma_rx_single_n,

   // Reset control
   // Outputs
   sw_rst_dec,

   // Debug interface
   // Outputs
   debug,

   // Sync interface
   // Outputs
   char_info_wd,

   // clock gate enable control
   // Inputs
   uart_lp_req_pclk,
   // Outputs
   clear_lp_req_pclk,

   // Interrupt interface
   // Outputs
   intr
   );

   input                             pclk;               // APB clock 
   input                             presetn;            // APB async reset

   input                             scan_mode;          // scan mode signal
   
   input                             wr_en;              // write enable
   input                             wr_enx;             // write enable extra
   input                             rd_en;              // read enable
   input  [3:0]                      byte_en;            // active byte lane
   input  [`UART_ADDR_SLICE_LHS-3:0] reg_addr;           // register address offset
   input  [`MAX_APB_DATA_WIDTH-1:0]  ipwdata;            // internal APB write data
   output [`MAX_APB_DATA_WIDTH-1:0]  iprdata;            // internal APB read data

   input                             tx_full;            // tx fifo full status
   input                             tx_empty;           // tx fifo empty status
   input                             rx_full;            // rx fifo full status
   input                             rx_empty;           // rx fifo empty status
   input                             rx_overflow;        // rx fifo overflow status
   input  [7:0]                      tx_pop_data;        // data from the tx fifo   
   input  [9:0]                      rx_pop_data;        // data from the rx fifo
   output                            tx_push;            // tx fifo pop
   output                            tx_pop;             // tx fifo pop
   output                            rx_push;            // rx fifo push
   output                            rx_pop;             // rx fifo pop
   output                            tx_fifo_rst;        // tx fifo reset
   output                            rx_fifo_rst;        // rx fifo reset
   output                            rx_err_check_oe;    // rx error check
                                                         // output enable
   output [7:0]                      tx_push_data;       // data to the tx fifo
   output [9:0]                      rx_push_data;       // data to the tx fifo

   input                             tx_finish;          // serial transmission
                                                         // of current character
                                                         // finished
   output                            tx_start;           // start serial
                                                         // transmission
   output [7:0]                      tx_data;            // data to be
                                                         // transmitted

   input                             rx_finish;          // serial reception
                                                         // of current character
                                                         // finished
   input                             rx_in_prog;         // serial reception
                                                         // in progress
   input  [9:0]                      rx_data;            // received data

   output                            sir_en;             // serial infrared enable
   output                            lb_en;              // loopback enable
   output                            break;              // break control

   input                             char_to;            // character timeout
                                                         // toggle signal
   output                            cnt_ens_ed;         // counter enables
                                                         // edge detect
   output [`TO_DET_CNT_ENS_WIDTH-1:0] to_det_cnt_ens;    // timeout detect
                                                         // count enables

   output [15:0]                     divsr;              // baud clock divisor
   output                            divsr_wd;           // baud clock divisor
                                                         // write detect

   output [4:0]                      char_info;          // serial character
                                                         // information
   output                            char_info_wd;       // char_info
                                                         // write detect

   input                             cts_n;              // clear to send
                                                         // active low
   input                             dsr_n;              // data set ready
                                                         // active low
   input                             dcd_n;              // data carrier detect
                                                         // active low
   input                             ri_n;               // ring indicator,
                                                         // active low
   output                            dtr_n;              // data terminal ready,
                                                         // active low
   output                            rts_n;              // request to send,
                                                         // active low
   output                            out1_n;             // programmable output1,
                                                         // active low
   output                            out2_n;             // programmable output2,
                                                         // active low

   input                             dma_tx_ack;         // DMA TX burst end
   input                             dma_rx_ack;         // DMA RX burst end
   output                            dma_tx_req;         // TX buffer ready
   output                            dma_tx_req_n;       // TX buffer ready,
                                                         // active low
   output                            dma_tx_single;      // DMA TX FIFO single
   output                            dma_tx_single_n;    // DMA TX FIFO single,
                                                         // active low
   output                            dma_rx_req;         // RX buffer ready
   output                            dma_rx_req_n;       // RX buffer ready,
                                                         // active low
   output                            dma_rx_single;      // DMA RX FIFO single
   output                            dma_rx_single_n;    // DMA RX FIFO single,
                                                         // active low
   
   output                            sw_rst_dec;         // SW reset decode
   output [31:0]                     debug;              // on-chip debug
   
   input                             uart_lp_req_pclk;   // pclk domain uart low
                                                         // power request
   output                            clear_lp_req_pclk;  // clear for UART low
                                                         // power request from
                                                         // the pclk domain
   output                            intr;               // UART interrupt

   // ------------------------------------------------------
   // -- Register enable (select) wires
   // ------------------------------------------------------
   wire                              rbr_en;             // receive buffer reg, enable
   wire                              thr_en;             // transmit holding reg, enable
   wire                              dll_en;             // divisor latch low, enable
   wire                              dlh_en;             // divisor latch high, enable
   wire                              ier_en;             // interrupt enable reg, enable
   wire                              iir_en;             // interrupt identification reg, enable
   wire                              fcr_en;             // fifo control reg, enable
   wire                              lcr_en;             // line control reg, enable
   wire                              mcr_en;             // modem control reg, enable
   wire                              lsr_en;             // line status reg, enable
   wire                              msr_en;             // modem status reg, enable
   wire                              scr_en;             // scratchpad reg, enable
   wire                              srbr_en;            // shadow receive buffer reg, enable
   wire                              sthr_en;            // shadow transmit holding reg, enable
   wire                              far_en;             // fifo access reg, enable
   wire                              tfr_en;             // transmit fifo read, enable
   wire                              rfw_en;             // receive fifo write, enable
   wire                              usr_en;             // uart status reg, enable
   wire                              tfl_en;             // transmit fifo level, enable
   wire                              rfl_en;             // receive fifo level, enable
   wire                              srr_en;             // software reset reg, enable
   wire                              srts_en;            // shadow request to send, enable
   wire                              sbcr_en;            // shadow break control reg, enable
   wire                              sdmam_en;           // shadow dma mode, enable
   wire                              sfe_en;             // shadow fifo enable, enable
   wire                              srt_en;             // shadow rcvr trigger, enable
   wire                              stet_en;            // shadow tx empty trigger, enable
   wire                              htx_en;             // halt tx, enable
   wire                              dmasa_en;           // dma software acknowledge, enable
   wire                              uart_cpr_en;        // component parameter reg, enable
   wire                              uart_cv_en;         // component version, enable
   wire                              uart_ctr_en;        // component type reg, enable
 
   // ------------------------------------------------------
   // -- Register write enable wires
   // ------------------------------------------------------
   wire                              dll_we;             // divisor latch low, write enable
   wire                              dlh_we;             // divisor latch high, write enable
   wire                              ier_we;             // interrupt enable reg, write enable
   wire                              lcr_we;             // line control reg, write enable
   wire                              mcr_we;             // modem control reg, write enable
   wire                              scr_we;             // scratchpad reg write enable
   wire                              far_we;             // fifo access reg, write enable
   wire                              srts_we;            // shadow request to send, write enable
   wire                              sbcr_we;            // shadow break control reg, write enable
   wire                              sdmam_we;           // shadow dma mode, write enable
   wire                              sfe_we;             // shadow fifo enable, write enable
   wire                              srt_we;             // shadow rcvr trigger, write enable
   wire                              stet_we;            // shadow tx empty trigger, write enable
   wire                              htx_we;             // halt tx, write enable

   // ------------------------------------------------------
   // -- Registers
   // ------------------------------------------------------
   reg    [`RXFIFO_RW-1:0]           rbr_ir;             // receive buffer reg
   wire   [`LEGACY_RW-1:0]           rbr;                // actual receive
                                                         // buffer reg
   reg    [`LEGACY_RW-1:0]           thr_ir;             // transmit holding reg
   reg    [`LEGACY_RW-1:0]           dll;                // divisor latch low
   reg    [`LEGACY_RW-1:0]           dlh;                // divisor latch high
   reg    [`LEGACY_RW-1:0]           ier_ir;             // interrupt enable reg
   wire   [`LEGACY_RW-1:0]           ier;                // actual interrupt
                                                         // enable reg
   reg    [`LEGACY_RW-1:0]           iir;                // interrupt identification reg
   reg    [`LEGACY_RW-1:0]           fcr_ir;             // fifo control reg
   wire   [`LEGACY_RW-1:0]           fcr;                // actual fifo
                                                         // control reg
   reg    [`LEGACY_RW-1:0]           lcr_ir;             // line control reg
   wire   [`LEGACY_RW-1:0]           lcr;                // actual line
                                                         // control reg
   reg    [`MCR_RW-1:0]              mcr_ir;             // modem control reg
   wire   [`MCR_RW-1:0]              mcr;                // actual modem
                                                         // control reg
   wire   [`LEGACY_RW-1:0]           lsr;                // line status reg
   wire   [`LEGACY_RW-1:0]           msr;                // modem status reg
   reg    [`LEGACY_RW-1:0]           scr;                // scratchpad reg
   wire   [`LEGACY_RW-1:0]           srbr;               // shadow receive buffer reg
   reg    [`FAR_RW-1:0]              far_ir;             // fifo access reg
   wire   [`FAR_RW-1:0]              far;                // actual fifo access reg
   wire   [`TFR_RW-1:0]              tfr;                // transmit fifo read reg
   wire   [`RFW_RW-1:0]              rfw;                // receive fifo write reg
   wire   [`LEGACY_RW-1:0]           usr;                // uart status reg
   reg    [`MAX_TFL_RW-1:0]          tfl_ir;             // transmit fifo
                                                         // level reg
   wire   [`TFL_RW-1:0]              tfl;                // actual transmit
                                                         // fifo level reg
   reg    [`MAX_RFL_RW-1:0]          rfl_ir;             // receive fifo
                                                         // level reg
   wire   [`RFL_RW-1:0]              rfl;                // actual receive fifo
                                                         // level reg
   reg    [`HTX_RW-1:0]              htx_ir;             // halt tx reg
   wire   [`HTX_RW-1:0]              htx;                // actual halt reg

   // ------------------------------------------------------
   // -- Misc wires and regs
   // ------------------------------------------------------
   reg                               rx_push_en_ed;      // edge detect register
   reg                               dly_rbr_empty;      // edge detect register
   reg                               thr_ir_empty;       // transmit holding reg
                                                         // register empty
   reg                               tx_in_prog;         // transmission
                                                         // in progress
   reg                               rbr_ir_empty;       // RBR register empty
   reg                               been_seen;          // error in current 
                                                         // rx fifo char has
                                                         // been seen
   reg                               rx_fifo_err;        // rx fifo error
   reg                               dly_fen;            // edge detect register
   reg                               dly_char_to;        // edge detect register
   reg                               char_to_reg;        // character timeout reg
   reg                               dly_bi_det;         // edge detect register
   reg                               bi;                 // break interrupt
   reg                               rbr_been_seen;      // error in current 
                                                         // RBR char has been
                                                         // seen
   reg                               auto_rts_ctrl;      // auto rts control
   reg                               thre_not_masked;    // thre not masked
   reg                               int_thre_intr;      // internal thre interrupt
   reg                               busy_det_intr;      // busy detect interrupt
   reg                               fe;                 // framing error
   reg                               pe;                 // parity error
   reg                               oe;                 // overrun error
   reg                               dly_dcd;            // edge detect register
   reg                               ddcd;               // delta dcd
   reg                               dly_ri;             // edge detect register
   reg                               teri;               // trailing edge of ri
   reg                               dly_dsr;            // edge detect register
   reg                               ddsr;               // delta dsr
   reg                               dly_cts;            // edge detect register
   reg                               dcts;               // delta cts
   reg                               divsr_wd;           // baud clock divisor
                                                         // write detect
   reg                               char_info_wd;       // char_info
                                                         // write detect
   reg                               intr;               // interrupt
   reg                               dma_tx_req;         // dma_tx_req
   reg                               dma_tx_single;      // dma_tx_single
   reg                               dma_rx_req;         // dma_rx_req
   reg                               dma_rx_single;      // dma_rx_single
   reg                               dly_line_stat_intr; // delayed line_stat_intr
   reg                               dly_data_avail_intr;// delayed data_avail_intr
   reg                               dly_char_to_intr;   // delayed char_to_intr
   reg                               dly_thre_intr;      // delayed thre_intr
   reg                               dly_modem_stat_intr;// delayed modem_stat_intr
   reg                               dly_busy_det_intr;  // delayed busy_det_intr
   reg                               dly_rx_pop;         // delayed rx_pop
   reg                               dly_tx_empty;       // delayed tx_empty
   reg                               dly_fifo_access;    // delayed fifo_access
   reg                               dly_lb_mode;        // delayed lb_mode
   reg                               dly_rx_empty;       // delayed rx_empty
   reg                               dly_rx_empty_fed;   // delayed rx_empty_fed
   reg                               dly2_rx_pop;        // delayed dly_rx_pop
   reg                               dly_tx_finish;      // delayed tx_finish
   reg                               dly_rx_finish;      // delayed rx_finish
   reg                               dly_far;            // delayed far
   reg                               dly_break;          // delayed break
   reg                               dly_thr_empty;      // delayed thr_empty
   reg                               dly_tx_in_prog;     // delayed tx_in_prog
   reg                               int_rx_fifo_rst;    // internal receiver
                                                         // fifo reset
   reg                               int_tx_fifo_rst;    // internal transmit
                                                         // fifo reset
   
   reg    [`MAX_APB_DATA_WIDTH-1:0]  iprdata;            // internal prdata bus
   reg    [`RFL_RW-1:0]              rx_fifo_trig;       // rx fifo trigger
   reg    [`TFL_RW-1:0]              tx_empty_trig;      // tx empty trigger
   reg    [`RFL_RW-1:0]              rx_fe_cnt;          // receive fifo error counter
   reg    [7:0]                      rfw_shdw;           // RFW shadow register for byte 0
   reg    [3:0]                      tfl_shdw;           // TFL shadow register for bits[11:8] 
   reg    [`TFL_RW-1:0]              tfl_cnt;            // transmit fifo level counter
   reg    [3:0]                      rfl_shdw;           // RFL shadow register for bits[11:8] 
   reg    [`RFL_RW-1:0]              rfl_cnt;            // receive fifo level counter
   reg    [`MAX_TFL_RW-1:0]          int_tfl_cnt;        // internal tfl counter
   reg    [`MAX_RFL_RW-1:0]          int_rfl_cnt;        // internal rfl counter
   reg    [1:0]                      ext_rx_err;         // external rx fifo
                                                         // memory error bits
   reg    [7:0]                      ext_rx_data;        // external rx fifo
                                                         // memory data

   wire                              dlab;               // divisor latch access
   wire                              fifo_en;            // fifo enable (FCR[0])
   wire                              dma_mode;           // dma mode
   wire                              fifo_access;        // fifo access mode enable (FAR[0])
   wire                              ptime;              // programmable thre interrupt mode enable
   wire                              line_stat_intr;     // receiver line status interrupt
   wire                              data_avail_intr;    // receiver data available interrupt
   wire                              char_to_intr;       // character timeout interrupt
   wire                              thre_intr;          // transmit holding register empty interrupt  
   wire                              modem_stat_intr;    // modem status interrupt
   wire                              char_to_ed;         // character timeout
                                                         // edge detect
   wire                              rx_push_en;         // rx push enable
   wire                              rx_push;            // rx fifo push
   wire                              int_rfw_en;         // internal receive fifo
                                                         // write, enable
   wire                              rx_push_pulse;      // rx push enable pos edge detect
   wire                              rx_pop;             // rx fifo pop
   wire                              rx_pop_en;          // rx pop enable
   wire                              int_srbr_en;        // internal shadow receive
                                                         // buffer reg, enable
   wire                              tx_push_en;         // tx push enable
   wire                              int_sthr_en;        // internal shadow transmit
                                                         // holding reg, enable
   wire                              tx_pop_en;          // tx pop enable
   wire                              rbr_empty;          // RBR empty
   wire                              int_tfr_en;         // internal transmit fifo
                                                         // read, enable
   wire                              tx_pop;             // tx fifo pop
   wire                              tx_start;           // start serial transmission
   wire                              thr_empty;          // transmit holding reg empty
   wire                              tx_push;            // tx fifo push
   wire                              set_not_masked;     // set for thre not masked
   wire                              sir_en;             // serial infrared enable
   wire                              lb_mode;            // loopback mode
   wire                              lb_en;              // loopback enable
   wire                              int_break;          // internal break control
   wire                              break;              // break control
   wire                              afc_en;             // auto flow control enable
   wire                              dtr_n;              // data terminal ready,
                                                         // active low
   wire                              rts_n;              // request to send,
                                                         // active low
   wire                              out1_n;             // programmable output1,
                                                         // active low
   wire                              out2_n;             // programmable output2,
                                                         // active low
   wire                              inc_rx_fe_cnt;      // increment rx_fe_cnt
   wire                              dec_rx_fe_cnt;      // decrement rx_fe_cnt
   wire                              temt;               // transmitter empty
   wire                              thre;               // transmit holding reg empty
   wire                              bi_det;             // break interrupt
                                                         // detect
   wire                              bi_det_pulse;       // break interrupt
                                                         // detect pos edge detect
   wire                              fe_det;             // framing error detect
   wire                              pe_det;             // parity error detect
   wire                              rcvr_err_seen;      // receiver error seen
   wire                              oe_det;             // overrun error detect
   wire                              rbr_overflow;       // RBR reg overflow
   wire                              dr;                 // data ready
   wire                              dcd;                // data carrier detect
   wire                              ri;                 // ring indicator
   wire                              dsr;                // data set ready
   wire                              cts;                // clear to send
   wire                              auto_cts;           // auto flow cts
   wire                              dcd_ed;             // data carrier
                                                         // detect edge detect
   wire                              ri_ed;              // ring indicator 
                                                         // neg edge detect
   wire                              dsr_ed;             // data set ready
                                                         // edge detect
   wire                              cts_ed;             // clear to send
                                                         // edge detect
   wire                              uart_busy;          // uart busy - serial
                                                         // transfer in progress
   wire                              int_srr_en;         // internal software
                                                         // reset reg, enable
   wire                              tx_fifo_rst;        // transmit fifo reset
   wire                              rx_fifo_rst;        // receiver fifo reset
   wire                              fen_ed;             // fifo enable edge
                                                         // detect
   wire                              int_srts_we;        // internal shadow
                                                         // request to send,
                                                         // write enable
   wire                              int_sbcr_we;        // internal shadow
                                                         // break control reg,
                                                         // write enable
   wire                              int_srt_we;         // internal shadow
                                                         // RCVR trigger,
                                                         // write enable
   wire                              int_stet_we;        // internal shadow
                                                         // TX empty trigger,
                                                         // write enable
   wire                              int_sdmam_we;       // internal shadow
                                                         // DMA mode, write
                                                         // enable
   wire                              int_sfe_we;         // internal shadow
                                                         // FIFO enable,
                                                         // write enable
   wire                              add_feat;           // additional_features
                                                         // parameter
   wire                              afce_mode;          // afce_mode parameter
   wire                              add_encod_parm;     // uart_add_encoded_parms
                                                         // parameter
   wire                              fifo_acc;           // fifo_access parameter
   wire                              fifo_stat;          // fifo_stat parameter
   wire                              shadow;             // shadow parameter
   wire                              sir_mode;           // sir_mode parameter
   wire                              sir_lp_mode;        // sir_lp_mode parameter
   wire                              thre_mode;          // thre_mode parameter
   wire                              dma_extra;          // dma_extra parameter
   wire                              dma_tx_req_n;       // TX buffer ready,
                                                         // active low
   wire                              int_dma_tx_ack;     // internal dma_tx_ack
   wire                              dma_tx_single_n;    // DMA TX FIFO single,
                                                         // active low
   wire                              dma_rx_req_n;       // RX buffer ready,
                                                         // active low
   wire                              int_dma_rx_ack;     // internal dma_rx_ack
   wire                              dma_rx_single_n;    // DMA RX FIFO single,
                                                         // active low
   wire                              sw_rst_dec;         // SW reset decode
   wire                              rbr_empty_fed;      // rbr empty failling
                                                         // edge detect
   wire                              tx_data_avail;      // tx data available
   wire                              fifo_access_ed;     // fifo access edge
                                                         // detect
   wire                              valid_char_to;      // valid character
                                                         // timeout
   wire                              lb_mode_ed;         // loopback mode
                                                         // edge detect
   wire                              rx_err_check_oe;    // rx error check
                                                         // output enable
   wire                              rx_empty_fed;       // rx_empty falling
                                                         // edge detect
   wire                              clear_lp_req_pclk;  // clear for UART low
                                                         // power request from
                                                         // the pclk domain
   wire                              int_tx_finish;      // internal tx_finish
   wire                              tx_finish_ed;       // tx finish edge
                                                         // detect
   wire                              int_rx_finish;      // internal rx_finish
   wire                              rx_finish_ed;       // rx finish edge
                                                         // detect
   wire                              cnt_ens_ed;         // counter enables
                                                         // edge detect
   wire                              cge_cnt_en;         // clock gate enable
                                                         // count enable
   wire                              far_ed;             // far edge detect
   wire                              break_ed;           // break edge
                                                         // detect
   wire                              thr_empty_ed;       // thr_empty
                                                         // edge detect
   wire                              tx_in_prog_ed;      // tx_in_prog
                                                         // edge detect
   wire                              rbr_empty_ed;       // rbr_empty
                                                         // edge detect
   wire                              rx_pop_ed;          // rx pop edge detect
   wire                              int_dmasa_en;       // internal dmasa_en
   wire                              dma_sw_ack;         // dma software
                                                         // acknowledge
   wire                              sw_tx_fifo_rst;     // software tx
                                                         // fifo reset
   wire                              sw_rx_fifo_rst;     // software rx
                                                         // fifo reset
   wire   [7:0]                      valid_rx_data;      // valid rx data
   wire   [1:0]                      rx_err;             // receiver error bits
   wire   [15:0]                     divsr;              // baud clock divisor
   wire   [9:0]                      rx_push_data;       // data to the tx fifo
   wire   [7:0]                      tx_data;            // data to be
                                                         // transmitted
   wire   [7:0]                      tx_push_data;       // data to the tx fifo
   wire   [4:0]                      int_char_info;      // Overrides register
                                                         // setting in IrDa mode
   wire   [`TO_DET_CNT_ENS_WIDTH-1:0] to_det_cnt_ens;    // timeout detect
                                                         // count enables
   wire   [`SRTS_RW-1:0]             srts;               // shadow request
                                                         // to send
   wire   [`SBCR_RW-1:0]             sbcr;               // shadow break
                                                         // control reg
   wire   [`SDMAM_RW-1:0]            sdmam;              // shadow dma mode
   wire   [`SFE_RW-1:0]              sfe;                // shadow fifo enable
   wire   [`SRT_RW-1:0]              srt;                // shadow rcvr trigger
   wire   [`STET_RW-1:0]             stet;               // shadow tx empty
                                                         // trigger
   wire   [31:0]                     uart_cpr;           // component parameter reg
   wire   [31:0]                     uart_cv;            // component version
   wire   [31:0]                     uart_ctr;           // component type reg
   
//synopsys dc_script_begin
//set_design_license {DesignWare} -quiet
//set_attribute current_design "DesignWare_version" "1.0a" -type string -quiet
//synopsys dc_script_end

   // ------------------------------------------------------
   // -- Address decoder
   //
   //  Decodes the register address offset input (reg_addr)
   //  to produce enable (select) signals for each of the
   //  SW-registers in the macro-cell
   // ------------------------------------------------------
   assign rbr_en      = (reg_addr == `RBR_OFFSET && dlab == 1'b0 && rd_en == 1'b1) ? 
                        1'b1 : 1'b0;
   assign thr_en      = (reg_addr == `THR_OFFSET && dlab == 1'b0 && wr_enx == 1'b1) ?
                        1'b1 : 1'b0;
   assign dll_en      = (reg_addr == `DLL_OFFSET && dlab == 1'b1) ? 1'b1 : 1'b0;
   assign dlh_en      = (reg_addr == `DLH_OFFSET && dlab == 1'b1) ? 1'b1 : 1'b0;
   assign ier_en      = (reg_addr == `IER_OFFSET && dlab == 1'b0) ? 1'b1 : 1'b0;
   assign iir_en      = (reg_addr == `IIR_OFFSET) ? 1'b1 : 1'b0;
   assign fcr_en      = (reg_addr == `FCR_OFFSET && wr_en == 1'b1 & byte_en[0]) ?
                        1'b1 : 1'b0;
   assign lcr_en      = (reg_addr == `LCR_OFFSET) ? 1'b1 : 1'b0;
   assign mcr_en      = (reg_addr == `MCR_OFFSET) ? 1'b1 : 1'b0;
   assign lsr_en      = (reg_addr == `LSR_OFFSET) ? 1'b1 : 1'b0;
   assign msr_en      = (reg_addr == `MSR_OFFSET) ? 1'b1 : 1'b0;
   assign scr_en      = (reg_addr == `SCR_OFFSET) ? 1'b1 : 1'b0;

   // The shadow RBR and THR register for the UART occupies 16 32-bit
   // locations of the memory map.  This is to allow AHB burst transfers
   // to the one FIFO location.  This is the reason for HIGH and LOW
   // address offsets for this register.
   assign srbr_en     = (reg_addr >= `SRBR_LOW_OFFSET && reg_addr <= `SRBR_HIGH_OFFSET 
                        && dlab == 1'b0 && rd_en == 1'b1)  ? 1'b1 : 1'b0;
   assign sthr_en     = (reg_addr >= `STHR_LOW_OFFSET && reg_addr <= `STHR_HIGH_OFFSET 
                        && dlab == 1'b0 && wr_enx == 1'b1) ? 1'b1 : 1'b0;
   assign far_en      = (reg_addr == `FAR_OFFSET) ? 1'b1 : 1'b0;
   assign tfr_en      = (reg_addr == `TFR_OFFSET && rd_en  == 1'b1) ? 1'b1 : 1'b0;
   assign rfw_en      = (reg_addr == `RFW_OFFSET && wr_enx == 1'b1) ? 1'b1 : 1'b0;
   assign usr_en      = (reg_addr == `USR_OFFSET) ? 1'b1 : 1'b0;
   assign tfl_en      = (reg_addr == `TFL_OFFSET) ? 1'b1 : 1'b0;
   assign rfl_en      = (reg_addr == `RFL_OFFSET) ? 1'b1 : 1'b0;
   assign srr_en      = (reg_addr == `SRR_OFFSET && wr_en == 1'b1 && byte_en[0]) ?
                        1'b1 : 1'b0;
   assign srts_en     = (reg_addr == `SRTS_OFFSET) ? 1'b1 : 1'b0;
   assign sbcr_en     = (reg_addr == `SBCR_OFFSET) ? 1'b1 : 1'b0;
   assign sdmam_en    = (reg_addr == `SDMAM_OFFSET) ? 1'b1 : 1'b0;
   assign sfe_en      = (reg_addr == `SFE_OFFSET) ? 1'b1 : 1'b0;
   assign srt_en      = (reg_addr == `SRT_OFFSET) ? 1'b1 : 1'b0;
   assign stet_en     = (reg_addr == `STET_OFFSET) ? 1'b1 : 1'b0;
   assign htx_en      = (reg_addr == `HTX_OFFSET) ? 1'b1 : 1'b0;
   assign dmasa_en    = (reg_addr == `DMASA_OFFSET && wr_en == 1'b1 && byte_en[0]) ?
                        1'b1 : 1'b0;
   assign uart_cpr_en = (reg_addr == `UART_CPR_OFFSET ) ? 1'b1 : 1'b0;
   assign uart_cv_en  = (reg_addr == `UART_CV_OFFSET )  ? 1'b1 : 1'b0;
   assign uart_ctr_en = (reg_addr == `UART_CTR_OFFSET ) ? 1'b1 : 1'b0;
 
   // ------------------------------------------------------
   // -- Write enable signals
   //
   //  Write enable signals for writable SW-registers.
   // ------------------------------------------------------
   assign dll_we   = dll_en   & wr_en  & byte_en[0];
   assign dlh_we   = dlh_en   & wr_en  & byte_en[0];
   assign ier_we   = ier_en   & wr_en  & byte_en[0];
   assign lcr_we   = lcr_en   & wr_en  & byte_en[0];
   assign mcr_we   = mcr_en   & wr_enx & byte_en[0];
   assign scr_we   = scr_en   & wr_en  & byte_en[0];
   assign far_we   = far_en   & wr_en  & byte_en[0];
   assign srts_we  = srts_en  & wr_enx & byte_en[0];
   assign sbcr_we  = sbcr_en  & wr_en  & byte_en[0];
   assign sdmam_we = sdmam_en & wr_en  & byte_en[0];
   assign sfe_we   = sfe_en   & wr_en  & byte_en[0];
   assign srt_we   = srt_en   & wr_en  & byte_en[0];
   assign stet_we  = stet_en  & wr_en  & byte_en[0];
   assign htx_we   = htx_en   & wr_en  & byte_en[0];
 
   // ------------------------------------------------------
   // -- Receive Buffer Register - Read Only
   //
   // -- When FIFO's are not implemented or FIFO's are 
   // -- disabled then the received data and line status
   // -- is stored in the RBR instead of the RX FIFO
   // ------------------------------------------------------
   
   // If FIFO access mode is implemented and enabled then the
   // RX push enable signal will assert when a write to the RFR
   // is performed. else it will assert when serial reception of
   // the current character is complete
   assign rx_push_en = fifo_access ? int_rfw_en : int_rx_finish;

   // Internal RX finish, is asserted when the RX finish edge detect
   // signal is asserted when the DW_apb_uart is configured to have two
   // clocks, else it is asserted when the RX finish signal is asserted
   assign int_rx_finish = (`CLOCK_MODE == 2) ? rx_finish_ed : rx_finish;

   // RX finish rising edge detect
   assign rx_finish_ed = rx_finish & (~dly_rx_finish);

   // RX finish edge detect register
   always @(posedge pclk or negedge presetn)
     begin : dly_rx_finish_PROC
       if(presetn == 1'b0)
         begin
           dly_rx_finish <= 1'b0;
         end 
       else 
         begin
           dly_rx_finish <= rx_finish;
         end
     end // block: dly_rx_finish_PROC
   
   // data will only be loaded into the RBR when FIFO's are disabled
   // and the RX push enable signal is asserted
   always @(posedge pclk or negedge presetn)
     begin : rbr_ir_PROC
       if(presetn == 1'b0) 
         begin
           rbr_ir     <= {`RXFIFO_RW{1'b0}};
         end 
       else 
         begin
           if((~fifo_en) & rx_push_en)
             begin
               rbr_ir <= rx_push_data;
             end 
         end
     end // block: rbr_ir_PROC

   // If FIFO access mode is enabled then RX push data is the value
   // written to the RFW, else it the received data
   assign rx_push_data = fifo_access ? rfw : rx_data;

   // When FIFO's are implemented and enabled then the framing error
   // detect signal is asserted when bit[1] of the RX error bits is set
   // to one, else it is asserted when when bit[9] of the RBR is set to
   // one. note, because it is possible for the RAM (or RBR) to have data 
   // containing an error at a previously read location we need to
   // check that the RBR is not empty before asserting the fe_det signal
   assign fe_det    = (fifo_en ? rx_err[1] : rbr_ir[9]) & (~rbr_empty);

   // When FIFO's are implemented and enabled then the parity error
   // detect signal is asserted when bit[0] of the RX error bits is set
   // to one, else it is asserted when when bit[8] of the RBR is set to
   // one. Note, because it is possible for the RAM (or RBR) to have
   // data containing an error at a previously read location we need to
   // check that the RBR is not empty before asserting the pe_det signal
   assign pe_det    = (fifo_en ? rx_err[0] : rbr_ir[8]) & (~rbr_empty);

   // When the UART is configured to use external FIFO memories the RX
   // error bits are assigned to bits[1:0] of the external RX FIFO memory
   // error bits. When the UART is configured to use internal FIFO memories
   // the RX error bits are assigned to bits[9:8] of the data at the top
   // of the RX FIFO (RX pop data)
   assign rx_err = (`MEM_SELECT == 0) ? ext_rx_err[1:0] : rx_pop_data[9:8];

   // The external RX FIFO memory error bits are assigned to bits[9:8] of
   // the data at the top of the RX FIFO (RX pop data) when the RX error
   // check output enable signal is asserted, this is done due to the fact
   // that the external memories use an output enable signal, hence data
   // from the RX FIFO will only be valid when the output enable is asserted
   always @(posedge pclk or negedge presetn)
     begin : ext_rx_err_PROC
       if(presetn == 1'b0)
         begin
           ext_rx_err <= 2'b0;
         end
       else 
         begin
           if(rx_err_check_oe)
             begin
               ext_rx_err <= rx_pop_data[9:8];
             end
           else
             begin
               ext_rx_err <= 2'b0;
             end
         end
     end // block: ext_rx_err_PROC

   // The RX error check output enable signal gets asserted when there is
   // a character containing an error in the FIFO (indicated by the RX FIFO
   // error counter being non-zero) AND this is the first entry into the
   // RX FIFO (i.e. the character is at the TOP of the FIFO) OR it will
   // get asserted after each pop of the FIFO while the errors remain in
   // the FIFO. This signal will cause the assertion of the external
   // RX FIFO memory output enable signal so that the characters
   // containing errors will be seen when they are at the TOP of the FIFO,
   // as expected and not just when a read of the data is performed.
   // Note: The reason that the delayed RX empty falling edge detect is
   // used, instead of the edge detect itself, is due to the fact that the
   // chip enable is asserted when an RX FIFO access is made (so that a
   // pre-fetch can be performed) and the edge detect would coincide with
   // this. Thus, the corresponding output enable would give unknown data
   // from the RAM as the data would not be valid until the cycle after
   // the chip enable assertion, hence the use of the delay.
   assign rx_err_check_oe = (rx_fe_cnt != 0) & (dly_rx_empty_fed | dly2_rx_pop);

   // Delayed RX empty falling edge detect
   always @(posedge pclk or negedge presetn)
     begin : dly_rx_empty_fed_PROC
       if(presetn == 1'b0)
         begin
           dly_rx_empty_fed <= 1'b0;
         end 
       else 
         begin
           dly_rx_empty_fed <= rx_empty_fed;
         end
     end // block: dly_rx_empty_fed_PROC

   // RX empty falling edge detect
   assign rx_empty_fed = (~rx_empty) & dly_rx_empty;

   // RX empty edge detect register
   always @(posedge pclk or negedge presetn)
     begin : dly_rx_empty_PROC
       if(presetn == 1'b0)
         begin
           dly_rx_empty <= 1'b0;
         end 
       else 
         begin
           dly_rx_empty <= rx_empty;
         end
     end // block: dly_rx_empty_PROC

   // Delayed RX empty falling edge detect
   always @(posedge pclk or negedge presetn)
     begin : dly2_rx_popdly_rx_empty_fed_PROC
       if(presetn == 1'b0)
         begin
           dly2_rx_pop <= 1'b0;
         end 
       else 
         begin
           dly2_rx_pop <= dly_rx_pop;
         end
     end // block: dly2_rx_pop_PROC

   // Receive data selection between the receive FIFO (when implemented
   // and enabled) and the receive buffer register
   assign rbr       = fifo_en ? rx_pop_data[7:0] : rbr_ir[7:0];

   // When FIFO's are implemented and enabled then the RBR empty signal
   // is asserted when the RX FIFO is empty, else it is asserted when
   // the RBR (rbr_ir) is empty
   assign rbr_empty = fifo_en ? rx_empty : rbr_ir_empty;

   // The RBR (rbr_ir register) is empty when FIFO's are not enabled AND
   // data is read from the RBR or SRBR, OR a change on the FIFO enable
   // has occurred (FIFO enable edge detect, fen_ed, is asserted). It is
   // de-asserted when FIFO's are not enabled AND data is loaded to the
   // RBR
   always @(posedge pclk or negedge presetn)
     begin : rbr_ir_empty_PROC
       if(presetn == 1'b0) 
         begin
           rbr_ir_empty     <= 1'b1;
         end 
       else 
         begin
           if(((~fifo_en) & rx_pop_en) | fen_ed)
             begin
               rbr_ir_empty <= 1'b1;
             end
           else if((~fifo_en) & rx_push_en)
             begin
               rbr_ir_empty <= 1'b0;
             end 
         end
     end // block: rbr_ir_empty_PROC

   // When FIFO's are implemented and enabled then the RX push signal
   // will assert for one pclk cycle to indicate when RX push enable
   // is asserted a RX FIFO push request
   assign rx_push = fifo_en ? rx_push_pulse : 1'b0;

   // RX push enable pos edge detect
   assign rx_push_pulse = rx_push_en & (~rx_push_en_ed);

   // RX push enable edge detect register
   always @(posedge pclk or negedge presetn)
     begin : rx_push_en_ed_PROC
       if(presetn == 1'b0)
         begin
           rx_push_en_ed <= 1'b0;
         end 
       else 
         begin
           rx_push_en_ed <= rx_push_en;
         end
     end // block: rx_push_en_ed_PROC

   // When FIFO's are implemented and enabled, and a read of the RBR
   // is performed then RX pop will be asserted for one pclk cycle so
   // that the next value in the FIFO will be at the top
   assign rx_pop = fifo_en ? rx_pop_en : 1'b0;

   // Delayed RX pop
   always @(posedge pclk or negedge presetn)
     begin : dly_rx_pop_PROC
       if(presetn == 1'b0)
         begin
           dly_rx_pop <= 1'b0;
         end 
       else 
         begin
           dly_rx_pop <= rx_pop;
         end
     end // block: dly_rx_pop_PROC

   // The RX pop enable signal will be asserted if either the RBR is
   // read or the SRBR is implemented and read and and byte enable bit[0]
   // is asserted
   assign rx_pop_en = (rbr_en | int_srbr_en) & byte_en[0];

   // ------------------------------------------------------
   // -- Transmit Holding Register - Write Only
   //
   // -- When FIFO's are not implemented or FIFO's are 
   // -- disabled then the data to be transmitted is stored
   // -- in the THR instead of the TX FIFO
   // ------------------------------------------------------
   
   // The TX push enable signal will be asserted when either the THR
   // enable signal is asserted or the internal STHR enable signal is
   // asserted and and byte enable bit[0] is asserted
   assign tx_push_en = (thr_en | int_sthr_en) & byte_en[0];
   
   // Data will only be loaded into the THR when FIFO's are disabled
   // and the TX push enable signal is asserted
   always @(posedge pclk or negedge presetn)
     begin : thr_ir_PROC
       if(presetn == 1'b0) 
         begin
           thr_ir     <= {`LEGACY_RW{1'b0}};
         end 
       else 
         begin
           if((~fifo_en) & tx_push_en)
             begin
               thr_ir <= ipwdata[7:0];
             end 
         end
     end // block: thr_ir_PROC
                
   // If FIFO's are implemented and enabled then the data to be
   // transmitted (tx_data) is the data at the top of the TX FIFO,
   // else it is the data stored in the transmit holding register
   assign tx_data = fifo_en ? tx_pop_data : thr_ir;

   // If FIFO access mode is implemented and enabled then the TX pop
   // enable signal will assert when a read of the TFR is performed.
   // else it will assert when the data in the TX FIFO has been transfered
   // to the serial transmitter shift register (tx_start asserted)
   assign tx_pop_en = fifo_access ? int_tfr_en : tx_start;

   // When FIFO's are implemented and enabled then the TX pop signal
   // will assert for one pclk cycle when TX pop enable is asserted
   // to indicate a TX FIFO pop request
   assign tx_pop = fifo_en ? tx_pop_en : 1'b0;

   // If the halt TX register bit is set then the TX start signal is not
   // asserted so that no data will be transmitted from the TX FIFO
   // while in this mode.
   // If FIFO access mode is implemented and enabled then the TX start
   // signal is not asserted, so that no data will be transmitted from
   // the transmit holding register or TX FIFO while in this mode.
   // Else TX start will be asserted for one pclk cycle when THR or TX 
   // FIFO has data to transmit and there is not already a serial transmission
   // in progress and if auto cts is asserted and the break control signal
   // is not asserted and the baud clock divisor is not set to zero (i.e.
   // a baud clock will be generated and hence a transmission may occur)
   // when the programming of the baud divisor registers (DLL and DLH) is
   // complete as indicated by the dlab signal being low (DLAB bit, LCR[7],
   // being set to zero).
   // Note that when auto flow control is implemented and enabled the
   // transmission of data is held off while cts_n is inactive low
   // (auto_cts set to zero)
   assign tx_start = htx ? 1'b0 : (fifo_access ? 1'b0 : (~tx_in_prog) & tx_data_avail &
                                   auto_cts & (~break) & (divsr != 16'b0 & (~dlab)));

   // Indicates if a serial transmission is in progress
   // gets asserted when tx_start is asserted, and gets de-asserted
   // when tx_finish is asserted
   always @(posedge pclk or negedge presetn)
     begin : tx_in_prog_PROC
       if(presetn == 1'b0)
         begin
           tx_in_prog   <= 1'b0;
         end
       else
         if(tx_start)
           begin
             tx_in_prog <= 1'b1;
           end
         else if(int_tx_finish)
           begin
             tx_in_prog <= 1'b0;
           end
     end // block: tx_in_prog_PROC

   // Internal TX finish, is asserted when the TX finish edge detect
   // signal is asserted when the DW_apb_uart is configured to have two
   // clocks, else it is asserted when the TX finish signal is asserted
   assign int_tx_finish = (`CLOCK_MODE == 2) ? tx_finish_ed : tx_finish;

   // TX finish rising edge detect
   assign tx_finish_ed = tx_finish & (~dly_tx_finish);

   // TX finish edge detect register
   always @(posedge pclk or negedge presetn)
     begin : dly_tx_finish_PROC
       if(presetn == 1'b0)
         begin
           dly_tx_finish <= 1'b0;
         end 
       else 
         begin
           dly_tx_finish <= tx_finish;
         end
     end // block: dly_tx_finish_PROC 

   // Indicates if the THR or TX FIFO has data to transmit, that is they
   // are not empty. If the UART has been configured to use external FIFO
   // memory and FIFO's are enabled then the TX data available signal will
   // be asserted when the delayed TX empty signal is not asserted. This
   // delay of one cycle is required due to the time required after the 
   // first write for the data to be seen on the read data port, given
   // the signaling method used to control the external memories (chip
   // enable etc). Else then the TX data available signal will be
   // asserted when the THR empty signal is not asserted
   assign tx_data_avail = ((`MEM_SELECT == 0) & fifo_en ? (~dly_tx_empty) : (~thr_empty));

   // Delayed TX empty
   always @(posedge pclk or negedge presetn)
     begin : dly_tx_empty_PROC
       if(presetn == 1'b0) 
         begin
           dly_tx_empty <= 1'b0;
         end 
       else
         begin
           dly_tx_empty <= tx_empty;
         end
     end // block: dly_tx_empty_PROC

   // If FIFO's are implemented and enabled the THR empty signal will
   // assert when the TX FIFO is empty, else it will assert when the
   // thr_ir_empty signal is asserted
   assign thr_empty = fifo_en ? tx_empty : thr_ir_empty;

   // If FIFO's are not implemented or FIFO's are disabled then, the THR
   // register empty signal gets asserted when the data in the THR has been
   // transfered to the serial transmitter shift register (tx_start
   // asserted), OR a change on the FIFO enable has occurred (FIFO enable
   // edge detect, fen_ed, is asserted). It will be de-asserted when new
   // data has been written to the THR (tx_push_en asserted)
   always @(posedge pclk or negedge presetn)
     begin : thr_ir_empty_PROC
       if(presetn == 1'b0) 
         begin
           thr_ir_empty         <= 1'b1;
         end 
       else 
         begin
           if(~fifo_en)
             begin
               if(tx_start | fen_ed)
                 begin
                   thr_ir_empty <= 1'b1;
                 end
               else if(tx_push_en)
                 begin
                   thr_ir_empty <= 1'b0;
                 end
             end
         end
     end // block: thr_ir_empty_PROC

   // The data written to the TX FIFO will be the lower 8 bits of
   // the write data bus
   assign tx_push_data = ipwdata[7:0];

   // When FIFO's are implemented and enabled then the TX push signal
   // will assert for one pclk cycle when TX push enable is asserted
   // to indicate a TX FIFO push request
   assign tx_push = fifo_en ? tx_push_en : 1'b0;

   // ------------------------------------------------------
   // -- Divisor Latch Low
   // -- This is a 8bit register
   // --
   // -- This register makes up the lower 8-bits of a 16-bit
   // -- Divisor latch register that contains the baud rate
   // -- divisor for the UART. This register may only be
   // -- accessed when dlab (i.e. LCR[7]) is asserted, see
   // -- address decode
   // ------------------------------------------------------

   // The divisor latch low is loaded with data from the write data bus
   // when the divisor latch low write enable is asserted
   always @(posedge pclk or negedge presetn)
     begin : dll_PROC
       if(presetn == 1'b0) 
         begin
           dll     <= {`LEGACY_RW{1'b0}};
         end 
       else 
         begin
           if(dll_we)
             begin
               dll <= ipwdata[`LEGACY_RW-1:0];
             end
         end
     end // block: dll_PROC

   // ------------------------------------------------------
   // -- Divisor Latch High
   // -- This is a 8bit register
   // --
   // -- This register makes up the upper 8-bits of a 16-bit
   // -- Divisor latch register that contains the baud rate
   // -- divisor for the UART. This register may only be
   // -- accessed when dlab (i.e. LCR[7]) is asserted, see
   // -- address decode
   // ------------------------------------------------------

   // The divisor latch high is loaded with data from the write data bus
   // when the divisor latch high write enable is asserted
   always @(posedge pclk or negedge presetn)
     begin : dlh_PROC
       if(presetn == 1'b0) 
         begin
           dlh     <= {`LEGACY_RW{1'b0}};
         end 
       else 
         begin
           if(dlh_we)
             begin
               dlh <= ipwdata[`LEGACY_RW-1:0];
             end
         end
     end // block: dlh_PROC

   // ------------------------------------
   // 16bit baud clock divisor and enable
   // ------------------------------------
   assign divsr    = {dlh, dll};

   always @(posedge pclk or negedge presetn)
     begin : divsr_wd_PROC
       if(presetn == 1'b0) 
         begin
           divsr_wd <= 1'b0;
         end
       else if(dll_we | dlh_we)
         begin
           divsr_wd <= 1'b1;
         end
       else
         begin
           divsr_wd <= 1'b0;
         end
     end // block: divsr_wd_PROC

   // ------------------------------------------------------
   // -- Interrupt Enable Register
   // -- This is a 5bit register
   // --
   // -- This register is split into the following bit fields
   //
   //    [7]   - PTIME - Programmable THRE Interrupt Mode Enable
   //    [6:4] -       - Reserved
   //    [3]   - EDSSI - Enable Modem Status Interrupt
   //    [2]   - ELSI  - Enable Receiver Line Status Interrupt
   //    [1]   - ETBEI - Enable THR Empty Interrupt
   //    [0]   - ERBFI - Enable receive Data available Interrupt
   // ------------------------------------------------------

   // The interrupt enable register internal register is loaded with data
   // from the write data bus when the interrupt enabled register write enable
   // is asserted
   always @(posedge pclk or negedge presetn)
     begin : ier_ir_PROC
       if(presetn == 1'b0) 
         begin
           ier_ir     <= {`LEGACY_RW{1'b0}};
         end 
       else 
         begin
           if(ier_we)
             begin
               ier_ir <= ipwdata[`LEGACY_RW-1:0];
             end
         end
     end // block: ier_ir_PROC

   // If the UART is configured not to have programmable THRE interrupt
   // mode, bit[7] is always set to zero thus removing this register bit
   assign ier[7]   = (`THRE_MODE == 1) ? ier_ir[7] : 1'b0;
   
   assign ier[6:4] = 3'b000;
   assign ier[3:0] = ier_ir[3:0];

   // Programmable thre interrupt mode enable
   assign ptime = ier[7];

   // ------------------------------------------------------
   // -- Interrupt Identification Register - Read Only
   // -- This is a 6bit register
   // --
   // -- This register is split into the following bit fields
   //
   //    [7:6] - FIFOSE - FIFO's Enabled
   //    [5:4] -        - Reserved
   //    [3:0] - IID    - Interrupt ID
   // ------------------------------------------------------

   // The FIFOSE bits indicate whether or not FIFO's are enabled.
   // IID bits indicate the highest priority pending interrupt, which
   // can be one of the following types: receiver line status, receiver
   // data available, character timeout, transmit holding register empty,
   // modem status, busy detect or no interrupt pending
   always @(fifo_en             or
            dly_line_stat_intr  or
            dly_data_avail_intr or
            dly_char_to_intr    or
            dly_thre_intr       or
            dly_modem_stat_intr or
            dly_busy_det_intr 
            )
     begin : iir_PROC

       iir = {`LEGACY_RW{1'b0}};

       if(fifo_en)
         begin
           iir[7:6] = 2'b11;
         end
       
       if(dly_line_stat_intr)
         begin
           iir[3:0] = 4'b0110;
         end
       else if(dly_data_avail_intr)
         begin
           iir[3:0] = 4'b0100;
         end
       else if(dly_char_to_intr)
         begin
           iir[3:0] = 4'b1100;
         end
       else if(dly_thre_intr)
         begin
           iir[3:0] = 4'b0010;
         end
       else if(dly_modem_stat_intr)
         begin
           iir[3:0] = 4'b0000;
         end
       else if(dly_busy_det_intr)
         begin
           iir[3:0] = 4'b0111;
         end
       else
         begin
           iir[3:0] = 4'b0001;
         end
     end // block: iir_PROC

   // ---------------------
   // Interrupt generation
   // ---------------------

   // Delayed receiver line status interrupt
   always @(posedge pclk or negedge presetn)
     begin : dly_line_stat_intr_PROC
       if(presetn == 1'b0) 
         begin
           dly_line_stat_intr <= 1'b0;
         end 
       else
         begin
           dly_line_stat_intr <= line_stat_intr;
         end
     end // block: dly_line_stat_intr_PROC
   
   // Receiver line status interrupt is asserted if it is enabled via
   // IER[2] (ELSI bit) and a break interrupt or framing error or parity
   // error or overrun error has occurred
   assign line_stat_intr = ier[2] & (bi | fe | pe | oe);

   // Delayed receiver data_avail interrupt
   always @(posedge pclk or negedge presetn)
     begin : dly_data_avail_intr_PROC
       if(presetn == 1'b0) 
         begin
           dly_data_avail_intr <= 1'b0;
         end 
       else
         begin
           dly_data_avail_intr <= data_avail_intr;
         end
     end // block: dly_data_avail_intr_PROC

   // Receiver data available interrupt is asserted if it is enabled via
   // IER[0] (ERBFI bit) and (1) RX FIFO trigger level is reached, if
   // FIFO's are enabled, or (2) RBR is not empty, FIFO's disabled
   assign data_avail_intr = ier[0] & (fifo_en ? ((rfl_cnt >= rx_fifo_trig) ? 1'b1 : 1'b0) : (~rbr_ir_empty));

   // Delayed character timeout interrupt
   always @(posedge pclk or negedge presetn)
     begin : dly_char_to_intr_PROC
       if(presetn == 1'b0) 
         begin
           dly_char_to_intr <= 1'b0;
         end 
       else
         begin
           dly_char_to_intr <= char_to_intr;
         end
     end // block: dly_char_to_intr_PROC

   // If FIFO's are implemented and enabled then the character timeout
   // interrupt is asserted if it is enabled via IER[0] (ERBFI bit) and
   // the character timeout reg signal is asserted
   assign char_to_intr = fifo_en ? (ier[0] & char_to_reg) : 1'b0;

   // The character timeout reg signal gets asserted , when a valid
   // character timeout occurs, it is de-asserted when a read of RBR
   // or SRBR is performed
   always @(posedge pclk or negedge presetn)
     begin : char_to_reg_PROC
       if(presetn == 1'b0) 
         begin
           char_to_reg     <= 1'b0;
         end 
       else 
         begin
           if(valid_char_to)
             begin
               char_to_reg <= 1'b1;
             end
           else if(rx_pop_en)
             begin
               char_to_reg <= 1'b0;
             end
         end
     end // block: char_to_reg_PROC

   // The valid character timeout signal gets asserted when a change on the
   // character timeout (toggle) input, char_to, is seen (i.e. an edge
   // detect) and the DR bit is set
   assign valid_char_to = char_to_ed & dr;
   
   // Character timeout edge detect
   assign char_to_ed = char_to ^ dly_char_to;

   // Character timeout edge detect register
   always @(posedge pclk or negedge presetn)
     begin : dly_char_to_PROC
       if(presetn == 1'b0) 
         begin
           dly_char_to <= 1'b0;
         end 
       else 
         begin
           dly_char_to <= char_to;
         end
     end // block: dly_char_to_PROC

   // Delayed THRE interrupt
   always @(posedge pclk or negedge presetn)
     begin : dly_thre_intr_PROC
       if(presetn == 1'b0) 
         begin
           dly_thre_intr <= 1'b0;
         end 
       else
         begin
           dly_thre_intr <= thre_intr;
         end
     end // block: dly_thre_intr_PROC

   // The THRE interrupt is asserted if it is enabled via IER[1]
   // (ETBEI bit) and the THRE is not not masked and internal THRE
   // interrupt signal is asserted
   assign thre_intr = ier[1] & thre_not_masked & int_thre_intr;

   // If programmable THRE interrupt mode is implemented and enabled
   // (ptime asserted) and FIFO's are enabled (must be for prog. THRE
   // mode functionality to operate) then the internal THRE interrupt
   // gets asserted when the TX FIFO level is at or below the TX empty
   // trigger, it is de-asserted when the TX FIFO level goes above the TX
   // empty level.
   // If programmable THRE interrupt mode is not implemented or not enabled
   // (ptime de-asserted) or FIFO's are not enabled then the internal THRE
   // interrupt gets asserted when the THR or TX FIFO (FIFO's enabled) is
   // empty, it is de-asserted when the THR reg or TX FIFO (FIFO's enabled)
   // is no longer empty.
   always @(ptime     or fifo_en       or
            tfl_cnt   or tx_empty_trig or
            thr_empty
            )
     begin : int_thre_intr_PROC
       if(ptime && fifo_en)
         begin
           if(tfl_cnt <= tx_empty_trig)
             begin
               int_thre_intr = 1'b1;
             end
           else
             begin
               int_thre_intr = 1'b0;
             end
         end
       else
         begin
           int_thre_intr = thr_empty;
         end
     end // block: int_thre_intr_PROC

   // The THRE not masked signal is used to mask out the THRE interrupt
   // if a read of the IIR register is performed and the THRE interrupt
   // was the source of the interrupt, that is once a read occurs then the
   // THRE not masked signal is de-asserted hence masking out the internal
   // THRE interrupt
   always @(posedge pclk or negedge presetn)
     begin : thre_not_masked_PROC
       if(presetn == 1'b0) 
         begin
           thre_not_masked <= 1'b1;
         end 
       else 
         begin
           if(set_not_masked)
             begin
               thre_not_masked <= 1'b1;
             end
           else if((iir_en && rd_en && byte_en[0]) && (iir[3:0] == 4'b0010))
             begin
               thre_not_masked <= 1'b0;
             end
         end
     end // block: thre_not_masked_PROC

   // If programmable THRE interrupt mode is implemented and enabled
   // (ptime asserted) and FIFO's are enabled (must be for prog. THRE
   // mode functionality to operate) then the set not mask signal will
   // assert when the TX start signal is asserted. This is done so that
   // after a read of the IIR has masked the THRE interrupt, if the TX
   // FIFO is still below the TX empty trigger at the start of each serial
   // transfer the THRE not masked signal will be asserted again and hence
   // the THRE interrupt will be asserted at the start of each transfer (if
   // there is data in the TX FIFO). Else the set not mask signal will
   // assert when the THR or TX FIFO (in FIFO mode) is not empty
   assign set_not_masked = (ptime & fifo_en) ? tx_start : (~thr_empty);

   // Delayed modem status interrupt
   always @(posedge pclk or negedge presetn)
     begin : dly_modem_stat_intr_PROC
       if(presetn == 1'b0) 
         begin
           dly_modem_stat_intr <= 1'b0;
         end 
       else
         begin
           dly_modem_stat_intr <= modem_stat_intr;
         end
     end // block: dly_modem_stat_intr_PROC
   
   // The modem status interrupt is asserted if it is enabled via IER[3]
   // (EDSSI bit) and delta DCD is set or trailing edge of RI is set or
   // delta DSR is set or (delta CTS is set and auto flow control mode is
   // not enabled)
   assign modem_stat_intr = ier[3] & (ddcd | teri | ddsr | (dcts & ~(afc_en & fifo_en)));

   // Delayed busy detect interrupt
   always @(posedge pclk or negedge presetn)
     begin : dly_busy_det_intr_PROC
       if(presetn == 1'b0) 
         begin
           dly_busy_det_intr <= 1'b0;
         end 
       else
         begin
           dly_busy_det_intr <= busy_det_intr;
         end
     end // block: dly_busy_det_intr_PROC

   // The busy detect interrupt is asserted if a write to the LCR is
   // performed and the UART is busy, it is de-asserted if a read of the
   // USR is performed
   always @(posedge pclk or negedge presetn)
     begin : busy_det_intr_PROC
       if(presetn == 1'b0) 
         begin
           busy_det_intr     <= 1'b0;
         end 
       else 
         begin
           if(lcr_we && uart_busy)
             begin
               busy_det_intr <= 1'b1;
             end
           else if(usr_en && rd_en)
             begin
               busy_det_intr <= 1'b0;
             end
         end
     end // block: busy_det_intr_PROC

   // The interrupt signal is asserted if there is an interrupt pending
   always @(posedge pclk or negedge presetn)
     begin : intr_PROC
       if(presetn == 1'b0) 
         begin
           intr <= 1'b0;
         end 
       else if(line_stat_intr | data_avail_intr | char_to_intr |
               thre_intr      | modem_stat_intr | busy_det_intr)
         begin
           intr <= 1'b1;
         end
       else
         begin
           intr <= 1'b0;
         end
     end // block: intr_PROC
     
   // ------------------------------------------------------
   // -- FIFO Control Register - Write Only
   // -- This is a 7/8bit register
   // --
   // -- Only valid when FIFO Access are implemented
   // -- (FIFO_MODE_UART != NONE)
   // -- This register is split into the following bit fields
   //
   //    [7:6] - RT     - RCVR Trigger
   //    [5:4] - TET    - TX Empty Trigger
   //    [3]   - DMAM   - DMA Mode
   //    [2]   - XFIFOR - XMIT FIFO Reset
   //    [1]   - RFIFOR - RCVR FIFO reset
   //    [0]   - FIFOE  - FIFO Enable
   // ------------------------------------------------------

   // The FIFO control register internal register is loaded with data
   // from the write data bus when the FIFO control register enable
   // is asserted, also bits[7:6] (RT bits) will be loaded with a new value
   // if the internal shadow RCVR trigger write enable is asserted,
   // indicating a write to the SRT register. Bits[5:4] (TET bits) will be
   // loaded with a new value if the internal shadow TX empty trigger write
   // enable is asserted, indicating a write to the STET register.
   // Also bit[3] (DMAM bit) will be loaded with a new value if the internal
   // shadow DMA mode write enable is asserted, indicating a write to the
   // SDMAM register. Also bit[0] (FIFOE bit) will be loaded with a new
   // value if the internal shadow FIFO enable write enable is asserted,
   // indicating a write to the SFE register
   always @(posedge pclk or negedge presetn)
     begin : fcr_ir_PROC
       if(presetn == 1'b0) 
         begin
           fcr_ir          <= {`LEGACY_RW{1'b0}};
         end 
       else 
         begin
           if(fcr_en)
             begin
               fcr_ir      <= ipwdata[`LEGACY_RW-1:0];
             end
           else if(int_srt_we)
             begin
               fcr_ir[7:6] <= ipwdata[1:0];
             end
           else if(int_stet_we)
             begin
               fcr_ir[5:4] <= ipwdata[1:0];
             end
           else if(int_sdmam_we)
             begin
               fcr_ir[3]   <= ipwdata[0];
             end
           else if(int_sfe_we)
             begin
               fcr_ir[0]   <= ipwdata[0];
             end
         end
     end // block: fcr_ir_PROC

   // If the UART is configured not to have FIFO implemented, remove
   // the FIFO control register
   assign fcr[7:6] = (`FIFO_MODE_UART != 0) ? fcr_ir[7:6] : 2'b00;

   // The receiver FIFO trigger can be one of four values which is
   // determined by the RT bits of the FCR (bit[7:6]), these are as
   // follows:
   //         FCR[7:6] | receiver FIFO trigger level
   //         ---------|-----------------------------
   //            00    |  1 character in the RX FIFO
   //            01    |  RX FIFO 1/4 full
   //            10    |  RX FIFO 1/2 full
   //            11    |  RX FIFO 2 less than full
   //
   always @(fcr)
     begin : rx_fifo_trig_PROC
       case(fcr[7:6])
         2'b01   : rx_fifo_trig = (`FIFO_MODE_UART/4);
         2'b10   : rx_fifo_trig = (`FIFO_MODE_UART/2);
         2'b11   : rx_fifo_trig = (`FIFO_MODE_UART - 2);
         default : rx_fifo_trig = 1;
       endcase
     end // block: rx_fifo_trig_PROC

   // If programmable THRE interrupt mode has not been implemented then
   // remove these bits from the register
   assign fcr[5:4] = (`FIFO_MODE_UART != 0 && `THRE_MODE == 1) ? fcr_ir[5:4] : 2'b00;

   // The transmitter empty trigger can be one of four values which is
   // determined by the TET bits of the FCR (bit[5:4]), these are as
   // follows:
   //         FCR[5:4] | transmitter empty trigger level
   //         ---------|-----------------------------
   //            00    |  TX FIFO empty
   //            01    |  2 characters in the TX FIFO 
   //            10    |  TX FIFO 1/4 full
   //            11    |  TX FIFO 1/2 full
   //
   always @(fcr)
     begin : tx_empty_trig_PROC
       case(fcr[5:4])
         2'b01   : tx_empty_trig = 2;
         2'b10   : tx_empty_trig = (`FIFO_MODE_UART/4);
         2'b11   : tx_empty_trig = (`FIFO_MODE_UART/2);
         default : tx_empty_trig = 0;
       endcase
     end // block: tx_empty_trig_PROC

   // If FIFO's are not implemented then the register bit is removed from
   // register
   assign fcr[3]   = (`FIFO_MODE_UART != 0) ? fcr_ir[3] : 1'b0;

   // If FIFO's are not implemented then the register bit is removed from
   // register
   assign fcr[0]   = (`FIFO_MODE_UART != 0) ? fcr_ir[0] : 1'b0;

   // If FIFO's are not enabled then only DMA mode 0 is available, hence
   // force DMA mode to zero
   assign dma_mode = fifo_en ? fcr[3] : 1'b0;

   // The physical register bits for the XFIFOR and RFIFOR are not used
   // as these are self clearing bits and thus no actual register bits
   // are required
   assign fcr[2:1] = 2'b00;

   // Transmit FIFO reset (XFIFOR)
   // If FIFO's are implemented the software transmit FIFO reset is
   // asserted if the FIFO control register enable is asserted OR the
   // internal software reset register enable is asserted and the value
   // written to the XMIT FIFO reset bit (bit[2]) is one
   assign sw_tx_fifo_rst = ((`FIFO_MODE_UART != 0 && (fcr_en == 1'b1 || int_srr_en)) ? ipwdata[2] : 1'b0);
   
   // The internal transmit FIFO reset is asserted if the software
   // transmit FIFO reset is asserted OR FIFO enable edge detect is
   // asserted, OR presetn is asserted (set to zero), OR the FIFO access
   // register edge detect is asserted
   always @(posedge pclk or negedge presetn)
     begin : int_tx_fifo_rst_PROC
       if(presetn == 1'b0) 
         begin
           int_tx_fifo_rst     <= 1'b0;
         end 
       else 
         begin
	   if(sw_tx_fifo_rst || fen_ed || fifo_access_ed)
	     begin
               int_tx_fifo_rst <= 1'b1;
	     end
	   else
             begin
               int_tx_fifo_rst <= 1'b0;
             end 
	 end
     end // block: int_tx_fifo_rst_PROC

   // Receive FIFO reset (RFIFOR)
   // If FIFO's are implemented the software receive FIFO reset is
   // asserted if the FIFO control register enable is asserted OR the
   // internal software reset register enable is asserted and the value
   // written to the RCVR FIFO reset bit (bit[1]) is one
   assign sw_rx_fifo_rst = ((`FIFO_MODE_UART != 0 && (fcr_en == 1'b1 || int_srr_en)) ? ipwdata[1] : 1'b0);

   // The internal receive FIFO reset is asserted if the software
   // receive FIFO reset is asserted OR FIFO enable edge detect is
   // asserted, OR presetn is asserted (set to zero), OR the FIFO access
   // register edge detect is asserted
   always @(posedge pclk or negedge presetn)
     begin : int_rx_fifo_rst_PROC
       if(presetn == 1'b0) 
         begin
           int_rx_fifo_rst     <= 1'b0;
         end 
       else 
         begin
	   if(sw_rx_fifo_rst || fen_ed || fifo_access_ed)
	     begin
               int_rx_fifo_rst <= 1'b1;
	     end
	   else
             begin
               int_rx_fifo_rst <= 1'b0;
             end 
	 end
     end // block: int_rx_fifo_rst_PROC
   
   assign tx_fifo_rst = scan_mode ? (~presetn) : (int_tx_fifo_rst | (~presetn));
   assign rx_fifo_rst = scan_mode ? (~presetn) : (int_rx_fifo_rst | (~presetn));

   // FIFO enable
   assign fifo_en = fcr[0];

   // Debug, upper unused bit are set to zero while bit[13] is the RX
   // push enable, bit[12] is the TX pop enable, bits[11:10] are the
   // receiver trigger level, bits[9:8] are the TX empty trigger level,
   // bit[7] is the DMA mode and bits[6:1] are the individual interrupt
   // sources and bit[0] is the FIFO enable bit
   assign debug[31:14] = 18'b0;
   assign debug[13]    = rx_push_en;
   assign debug[12]    = tx_pop_en;
   assign debug[11:10] = fcr[7:6];  // RCVR Trigger
   assign debug[9:8]   = fcr[5:4];  // TX EMPTY trigger
   assign debug[7]     = fcr[3];    // DMA mode
   assign debug[6:0]   = {dly_line_stat_intr,  dly_data_avail_intr,
                          dly_char_to_intr,    dly_thre_intr,
                          dly_modem_stat_intr, dly_busy_det_intr,
                          fcr[0]};


   // Edge detect register for FIFO enable
   always @(posedge pclk or negedge presetn)
     begin : dly_fen_PROC
       if(presetn == 1'b0) 
         begin
           dly_fen <= 1'b0;
         end
       else
         begin
           dly_fen <= fifo_en;
         end
     end // block: dly_fen_PROC

   // FIFO edge detect
   // Whenever the FIFO enable signal changes, indicating a change between
   // FIFO and non FIFO mode of operation or vice versa, the FIFO edge
   // detect signal will assert. the assertion of this signals will cause
   // the reset of the controller portions of the FIFO's (if present) and
   // the THR and RBR
   assign fen_ed = fifo_en ^ dly_fen;

   // ------------------------------------------------------
   // -- Line Control Register
   // -- This is a 7bit register
   // -- 
   // -- This register is split into the following bit fields
   //
   //    [7]   - DLAB - Divisor Latch Access Bit
   //    [6]   - BC   - Break Control bit
   //    [5]   -      - Reserved
   //    [4]   - EPS  - Even Parity Select
   //    [3]   - PEN  - Parity Enable
   //    [2]   - STOP - Number of stop bits
   //    [1:0] - DLS  - Data Length Select
   // ------------------------------------------------------

   // The modem control register is loaded with data from the write data
   // bus when the line control register write enable is asserted, however
   // there is a restriction on changing bits[7] and [4:0] and this may
   // only occur when the UART is not busy (USR[0] is zero). The break
   // control bit may be changed even when the UART is busy. This bit
   // will also be loaded with a new value if the internal shadow break
   // control reg write enable is asserted, indicating a write to the
   // SBCR register
   always @(posedge pclk or negedge presetn)
     begin : lcr_ir_PROC
       if(presetn == 1'b0) 
         begin
           lcr_ir              <= {`LEGACY_RW{1'b0}};
         end 
       else 
         begin
           if(lcr_we)
             begin
               lcr_ir[6]       <= ipwdata[6];
                
               if(~uart_busy)
                 begin
                   lcr_ir[7]   <= ipwdata[7];
                   lcr_ir[4:0] <= ipwdata[4:0];
                 end
             end
           else if(int_sbcr_we)
             begin
               lcr_ir[6]       <= ipwdata[0];
             end
         end
     end // block: lcr_ir_PROC

   // Bit[5] is reserved and read back as zero so no actual register
   // is required for it
   assign lcr = {lcr_ir[7:6], 1'b0, lcr_ir[4:0]};

   // Divisor latch access enable
   assign dlab      = lcr[7];

   // Internal break control
   assign int_break = lcr[6];

   // The break control signal is asserted if the internal break control
   // is asserted (i.e. LCR[6] is set) and there is no serial transmission
   // in progress
   assign break     = int_break & (~tx_in_prog);

   // Character information, such as data length, number of stop bits,
   // parity enable and parity type (even or odd), that is required by
   // the serial transmitter and receiver. If serial infrared mode is
   // enabled then the character makeup is fixed to 8 data bits, no
   // parity and only one stop bit, regardless of what is programmed
   assign int_char_info  = lcr[4:0];
   assign char_info[4]   =                  int_char_info[4];
   assign char_info[3]   = sir_en ? 1'b0  : int_char_info[3];
   assign char_info[2]   = sir_en ? 1'b0  : int_char_info[2];
   assign char_info[1:0] = sir_en ? 2'b11 : int_char_info[1:0];

   // Character information write detect
   always @(posedge pclk or negedge presetn)
     begin : char_info_wd_PROC
       if(presetn == 1'b0) 
         begin
           char_info_wd <= 1'b0;
         end
       else if(lcr_we)
         begin
           char_info_wd <= 1'b1;
         end
       else
         begin
           char_info_wd <= 1'b0;
         end
     end // block: char_info_wd_PROC

   // ------------------------------------------------------
   // -- Modem Control Register
   // -- This is a 5-7bit register
   // -- 
   // -- This register is split into the following bit fields
   //
   //    [6] - SIRE - SIR Mode Enable
   //    [5] - AFCE - Auto Flow Control Enable
   //    [4] - LB   - Loopback
   //    [3] - OUT2 - Output 2
   //    [2] - OUT1 - Output 1
   //    [1] - RTS  - Request to Send
   //    [0] - DTR  - Data Terminal Ready
   // ------------------------------------------------------

   // The modem control register internal register is loaded with data
   // from the write data bus when the modem control register write enable
   // is asserted, also bit[1] (RTS bit) will be loaded with a new value
   // if the internal shadow request to send write enable is asserted,
   // indicating a write to the SRTS register
   always @(posedge pclk or negedge presetn)
     begin : mcr_ir_PROC
       if(presetn == 1'b0) 
         begin
           mcr_ir        <= {`MCR_RW{1'b0}};
         end 
       else 
         begin
           if(mcr_we)
             begin
               mcr_ir    <= ipwdata[`MCR_RW-1:0];
             end
           else if(int_srts_we)
             begin
               mcr_ir[1] <= ipwdata[0];
             end
         end
     end // block: mcr_ir_PROC

   // If the UART is configured not to have SIR mode, bit[6] is always
   // set to zero thus removing this register bit
   assign mcr[6]   = (`SIR_MODE == 1) ? mcr_ir[6] : 1'b0;

   // If the UART is configured not to have Auto Flow Control, bit[5] is
   // always set to zero thus removing this register bit
   assign mcr[5]   = (`AFCE_MODE == 1) ? mcr_ir[5] : 1'b0;

   assign mcr[4:0] = mcr_ir[4:0];

   // Serial IR enable
   assign sir_en = mcr[6];

   // Auto flow control enable
   // If SIR mode is enabled then auto flow control is not defined and
   // hence only normal operation of the modem control signals will be
   // used
   assign afc_en = mcr[5] & ~sir_en;

   // Loopback mode, indicates that the UART is in loopback mode
   assign lb_mode = mcr[4];

   // Loopback enable
   // If the UART is configured not to have FIFO access mode and it is
   // enabled then the UART loopback enable will be asserted, however
   // this loopback will only take effect on the serial output to input
   // operation and not the modem control signals, as this signal is only
   // used by the transmitter and receiver. This will prevent the UART
   // from receiving anything as the transmissions will not occur when in
   // FIFO access mode
   assign lb_en  = lb_mode | fifo_access;

   // The active low modem control signals are the inverse of their
   // corresponding MCR bits
   assign out2_n = ~mcr[3] | lb_mode;
   assign out1_n = ~mcr[2] | lb_mode;

   // Auto flow control functionality for auto RTS
   // If auto flow control is implemented and enabled AND FIFO's are
   // enabled (i.e. auto RTS is enabled) then rts_n is asserted when RTS 
   // bit of MCR is active and auto_rts_ctrl is asserted, else rts_n is
   // asserted when the RTS bit is set. in loopback mode the rts_n is
   // driven high
   assign rts_n  = ((afc_en & fifo_en) ? ~(mcr[1] & auto_rts_ctrl) : ~mcr[1]) | lb_mode;

   // The auto RTS control signal is asserted when the RX FIFO is empty,
   // it is de-asserted when the RX FIFO level is equal to the RX FIFO
   // trigger
   always @(posedge pclk or negedge presetn)
     begin : auto_rts_ctrl_PROC
       if(presetn == 1'b0)
         begin
           auto_rts_ctrl     <= 1'b1;
         end 
       else
         begin
           // RX FIFO must be completely empty for the auto RTS
           // control signal to be set once it has been de-asserted
           // thus allowing the rts_n signal to again go active (low),
           // signaling the device on the other end (i.e. another UART)
           // to continue sending data
           if(rx_empty)
             begin
               auto_rts_ctrl <= 1'b1;
             end
           else if(rfl_cnt == rx_fifo_trig)
             begin
               auto_rts_ctrl <= 1'b0;
             end
         end
     end // block: auto_rts_ctrl_PROC
   
   assign dtr_n  = ~mcr[0] | lb_mode;

   // ------------------------------------------------------
   // -- Line Status Register - Read Only
   // -- This is a 7/8bit register
   // -- 
   // -- This register is split into the following bit fields
   //
   //    [7] - RFE  - Receiver FIFO Error
   //    [6] - TEMT - Transmitter Empty
   //    [5] - THRE - Transmit Holding Register Empty
   //    [4] - BI   - Break Interrupt
   //    [3] - FE   - Framing Error
   //    [2] - PE   - Parity Error
   //    [1] - OE   - Overrun Error
   //    [0] - DR   - Data Ready
   // ------------------------------------------------------

   // ------------------------------------------------------
   // LSR[7] - RFE (receive FIFO error) related functionality
   // ------------------------------------------------------

   // Receiver FIFO error counter
   always @(posedge pclk or negedge presetn)
     begin : rx_fe_cnt_PROC
       if(presetn == 1'b0)
         begin
           rx_fe_cnt     <= {`RFL_RW{1'b0}};
         end 
       else
         begin
            
           // Reset to zero it RX FIFO controller is reset
           if(int_rx_fifo_rst == 1'b1)
             begin
               rx_fe_cnt <= {`RFL_RW{1'b0}};
             end
            
           // Increment the counter each time the RX FIFO
           // receives data containing a framing error
           // (rx_push_data[9] == 1) or a parity error
           // (rx_push_data[8] == 1)
           else if(inc_rx_fe_cnt && (~dec_rx_fe_cnt) && (~rx_full))
             begin
               rx_fe_cnt <= rx_fe_cnt + 1'b1;
             end
            
           // Decrement the counter when a data character
           // containing an error is at the top of the RX FIFO
           // and is the first time this data has been seen,
           // that is its new data
           else if(dec_rx_fe_cnt && (~inc_rx_fe_cnt) && (rx_fe_cnt != {`RFL_RW{1'b0}}))
             begin
               rx_fe_cnt <= rx_fe_cnt - 1'b1;
             end
         end
     end // block: rx_fe_cnt_PROC

   assign inc_rx_fe_cnt = rx_push & (|rx_push_data[9:8]);

   assign dec_rx_fe_cnt = (`MEM_SELECT == 0) ? (|rx_err[1:0]) : ((|rx_err[1:0]) & (~been_seen));

   // Indicates whether or not the current RX FIFO data character has
   // been seen or not (for the first time) so that the RX FIFO error
   // counter will not perform multiple decrements for the same data
   // character.
   always @(posedge pclk or negedge presetn)
     begin : been_seen_PROC
       if(presetn == 1'b0)
         begin
           been_seen     <= 1'b0;
         end 
       else
         begin
           if((|rx_err[1:0]) && (rbr_empty_fed || dly_rx_pop))
             begin
               been_seen <= 1'b1;
             end
           else if(rx_pop || (rx_push && rx_empty))
             begin
               been_seen <= 1'b0;
             end
         end
     end // block: been_seen_PROC

   // RBR empty falling edge detect
   assign rbr_empty_fed = (~rbr_empty) & dly_rbr_empty;

   // RBR empty edge detect register
   always @(posedge pclk or negedge presetn)
     begin : dly_rbr_empty_PROC
        if(presetn == 1'b0)
          begin
            dly_rbr_empty <= 1'b0;
          end 
        else 
          begin
            dly_rbr_empty <= rbr_empty;
          end
     end // block: dly_rbr_empty

   // The RX FIFO error signal is asserted when the RX FIFO error counter
   // is greater than zero. it is de-asserted when the counter is zero
   // and a read of the LSR has been performed
   always @(posedge pclk or negedge presetn)
     begin : rx_fifo_err_PROC
       if(presetn == 1'b0)
         begin
           rx_fifo_err   <= 1'b0;
         end
       else
         if(rx_fe_cnt > {`RFL_RW{1'b0}})
           begin
             rx_fifo_err <= 1'b1;
           end
         else if(lsr_en && rd_en)
           begin
             rx_fifo_err <= 1'b0;
           end
     end // block: rx_fifo_err_PROC

   // ------------------------------------------------------
   // LSR[6] - TEMT (transmitter empty) related functionality
   // ------------------------------------------------------

   // The transmitter empty is asserted whenever there is no serial
   // transmission in progress (transmitter shift register is empty)
   // and the THR or TX FIFO (in FIFO mode) is empty
   assign temt = (~tx_in_prog) & thr_empty;

   // ------------------------------------------------------
   // LSR[5] - THRE (transmit holding register empty) 
   //          related functionality
   // ------------------------------------------------------

   // If programmable THRE interrupt mode is implemented and enabled,
   // then if FIFO's are enabled the thre signal will be asserted when
   // the TX FIFO is full. If FIFO's are not enabled it will be asserted
   // then the THR register (thr_ir) is empty. Otherwise it will be
   // asserted when the THR empty is asserted
   assign thre = ptime ? (fifo_en ? tx_full : thr_ir_empty) : thr_empty;

   // ------------------------------------------------------
   // LSR[4] - BI (break interrupt) related functionality
   // ------------------------------------------------------

   // The break interrupt detect signal gets asserted if the current
   // received data (from RBR or top of the RX FIFO) is all zero and a
   // a framing error has occurred
   assign bi_det = (valid_rx_data == {8{1'b0}} && fe_det == 1'b1) ? 1'b1 : 1'b0;

   // When the UART is configured to use external FIFO memories the valid
   // RX data is assigned to the external RX FIFO memory data when FIFO's
   // are enabled. If the FIFO's are disabled the valid RX data is assigned
   // to the RBR register. When the UART is configured to use internal FIFO
   // memories the valid RX data is assigned to the RBR
   assign valid_rx_data = (`MEM_SELECT == 0) ? (fifo_en ? ext_rx_data[7:0] : rbr_ir[7:0]) : rbr[7:0];

   // The external RX FIFO memory data is assigned to bits[7:0] of the
   // data at the top of the RX FIFO (RX pop data) when the RX error check
   // output enable signal is asserted, this is done due to the fact that
   // the external memories use an output enable signal, hence data from
   // the RX FIFO memory will only be valid when the output enable is
   // asserted
   always @(posedge pclk or negedge presetn)
     begin : ext_rx_data_PROC
       if(presetn == 1'b0)
         begin
           ext_rx_data <= 8'b0;
         end
       else 
         begin
           if(rx_err_check_oe)
             begin
               ext_rx_data <= rx_pop_data[7:0];
             end
           else
             begin
               ext_rx_data <= 8'b0;
             end
         end
     end // block: ext_rx_data_PROC
   
   // Edge detect register for break interrupt detect
   always @(posedge pclk or negedge presetn)
     begin : dly_bi_det_PROC
       if(presetn == 1'b0) 
         begin
           dly_bi_det <= 1'b0;
         end
       else
         begin
           dly_bi_det <= bi_det;
         end
     end // block: dly_bi_det_PROC

   // Pos edge detect of break interrupt detect
   assign bi_det_pulse = bi_det & (~dly_bi_det);

   // The break interrupt signal is asserted when the break interrupt
   // detect is asserted. It is de-asserted when a read of the LSR has
   // been performed or when a read of the RBR or SRBR has been performed
   // if FIFO's are implemented and enabled (rx_pop asserted), as the
   // error is associated with the character in the FIFO it applies to
   always @(posedge pclk or negedge presetn)
     begin : bi_PROC
       if(presetn == 1'b0) 
         begin
           bi     <= 1'b0;
         end
       else
         begin
           if(bi_det_pulse)
             begin
               bi <= 1'b1;
             end
           else if((lsr_en && rd_en) || rx_pop)
             begin
               bi <= 1'b0;
             end
         end
     end // block: bi_PROC

   // ------------------------------------------------------
   // LSR[3] - FE (framing error) related functionality
   // ------------------------------------------------------

   // Indicates whether or not errors in the current data character in
   // the RBR has been seen or not (for the first time) so that the
   // the error status bit will not be set again, when cleared, for the
   // same data character
   // The RBR been seen signal gets asserted if either a framing error
   // (rbr_ir[9] == 1) or a parity error (rbr_ir[8] == 1) is seen in the
   // RBR and the RBR empty falling edge detect signal is asserted, it is
   // de-asserted when a read of the RBR or the SRBR is performed
   always @(posedge pclk or negedge presetn)
     begin : rbr_been_seen_PROC
       if(presetn == 1'b0)
         begin
           rbr_been_seen     <= 1'b0;
         end 
       else
         begin
           if(|rbr_ir[9:8] && rbr_empty_fed)
             begin
               rbr_been_seen <= 1'b1;
             end
           else if(rx_pop_en)
             begin
               rbr_been_seen <= 1'b0;
             end
         end
     end // block: rbr_been_seen_PROC
   
   // When FIFO's are implemented and enabled then the receiver error
   // seen signal is asserted when been_seen is asserted, else it is
   // asserted when RBR been seen is asserted
   assign rcvr_err_seen = fifo_en ? been_seen : rbr_been_seen;

   // The framing error signal is asserted when a framing error has been
   // detected in the RX FIFO or RBR and is seen for the first time, it
   // is de-asserted when a read of the LSR has been performed or when
   // a read of the RBR or SRBR has been performed if FIFO's are
   // implemented and enabled (rx_pop asserted), as the error is
   // associated with the character in the FIFO it applies to
   always @(posedge pclk or negedge presetn)
     begin : fe_PROC
       if(presetn == 1'b0)
         begin
           fe     <= 1'b0;
         end 
       else
         begin
           if(fe_det & (~rcvr_err_seen))
             begin
               fe <= 1'b1;
             end
           else if((lsr_en && rd_en) || rx_pop)
             begin
               fe <= 1'b0;
             end
         end
     end // block: fe_PROC

   // ------------------------------------------------------
   // LSR[2] - PE (parity error) related functionality
   // ------------------------------------------------------

   // The parity error signal is asserted when a parity error has been
   // detected in the RX FIFO or RBR and is seen for the first time, it
   // is de-asserted when a read of the LSR has been performed or when
   // a read of the RBR or SRBR has been performed if FIFO's are
   // implemented and enabled (rx_pop asserted), as the error is
   // associated with the character in the FIFO it applies to
   always @(posedge pclk or negedge presetn)
     begin : pe_PROC
       if(presetn == 1'b0)
         begin
           pe     <= 1'b0;
         end 
       else
         begin
           if(pe_det & (~rcvr_err_seen))
             begin
               pe <= 1'b1;
             end
           else if((lsr_en && rd_en) || rx_pop)
             begin
               pe <= 1'b0;
             end
         end
     end // block: pe_PROC

   // ------------------------------------------------------
   // LSR[1] - OE (overrun error) related functionality
   // ------------------------------------------------------

   // when FIFO's are implemented and enabled then the overflow error
   // detect signal is asserted when an overflow has been seen in the RX
   // FIFO, else it is asserted if an overflow is seen in the RBR
   assign oe_det = fifo_en ? rx_overflow : rbr_overflow;

   // An RBR overflow occurs if FIFO's are disables and a new character
   // is received before the previous character was read from the RBR (RBR
   // not empty)
   assign rbr_overflow = (~fifo_en) & rx_push_en & (~rbr_empty);

   // The overrun error signal is asserted when an overrun error has
   // been detected in the RX FIFO or RBR , it is de-asserted when a read
   // of the LSR has been performed
   always @(posedge pclk or negedge presetn)
     begin : oe_PROC
       if(presetn == 1'b0)
         begin
           oe     <= 1'b0;
         end 
       else
         begin
           if(oe_det)
             begin
               oe <= 1'b1;
             end
           else if(lsr_en && rd_en)
             begin
               oe <= 1'b0;
             end
         end
     end // block: oe_PROC

   // ------------------------------------------------------
   // LSR[0] - DR (data ready) related functionality
   // ------------------------------------------------------

   // The data ready signal is asserted when the RBR is not empty
   assign dr = ~rbr_empty;

   // If the UART is configured not to have FIFO's, bit[7] is always set
   // to zero thus removing this register bit
   assign lsr[7]   = fifo_en ? rx_fifo_err : 1'b0;

   assign lsr[6:0] = {temt, thre, bi, fe, pe, oe, dr};

   // ------------------------------------------------------
   // -- Modem Status Register - Read Only
   // -- This is a 8bit register
   // -- 
   // -- This register is split into the following bit fields
   //
   //    [7] - DCD  - Data Carrier Detect
   //    [6] - RI   - Ring Indicator
   //    [5] - DSR  - Data Set Ready
   //    [4] - CTS  - Clear to Send
   //    [3] - DDCD - Delta Data Carrier Detect
   //    [2] - TERI - Trailing Edge of Ring Indicator
   //    [1] - DDSR - Delta Data Set Ready
   //    [0] - DCTS - Delta Clear to Send
   // ------------------------------------------------------

   // ------------------------------------------------------
   // MSR[7] - DCD (data carrier detect) related functionality
   // ------------------------------------------------------

   // If in loopback mode (lb_mode asserted) DCD is the same as MCR[3]
   // (out2), else it is the complement of the modem control line dcd_n
   assign dcd = lb_mode ? mcr[3] : ~dcd_n;

   // ------------------------------------------------------
   // MSR[6] - RI (ring indicator) related functionality
   // ------------------------------------------------------

   // If in loopback mode (lb_mode asserted) RI is the same as MCR[2]
   // (out1), else it is the complement of the modem control line ri_n
   assign ri  = lb_mode ? mcr[2] : ~ri_n;

   // ------------------------------------------------------
   // MSR[5] - DSR (data set ready) related functionality
   // ------------------------------------------------------

   // If in loopback mode (lb_mode asserted) DSR is the same as MCR[0]
   // (DTR), else it is the complement of the modem control line dsr_n
   assign dsr = lb_mode ? mcr[0] : ~dsr_n;

   // ------------------------------------------------------
   // MSR[4] - CTS (clear to send) related functionality
   // ------------------------------------------------------

   // If in loopback mode (lb_mode asserted) CTS is the same as MCR[1]
   // (RTS), else it is the complement of the modem control line cts_n
   assign cts = lb_mode ? mcr[1] : ~cts_n;

   // Auto flow control functionality for auto CTS
   // If auto flow control is implemented and enabled AND FIFO's are
   // enabled then auto CTS is asserted when CTS is asserted indicating
   // that cts_n is active, also when cts_n goes inactive auto CTS will
   // de-assert which in turn will halt the transmission of any new data
   // characters from the UART until cts_n goes active (low) again.
   // If auto flow control is not implemented or not enabled AND FIFO's
   // are not enabled then auto CTS is set to one and hence has no effect
   // on the transmission of the serial data characters
   assign auto_cts = (afc_en & fifo_en) ? cts : 1'b1;

   // ------------------------------------------------------
   // MSR[3] - DDCD (delta data carrier detect) related 
   //          functionality
   // ------------------------------------------------------

   // Edge detect register for data carrier detect
   always @(posedge pclk or negedge presetn)
     begin : dly_dcd_PROC
       if(presetn == 1'b0) 
         begin
           dly_dcd <= 1'b0;
         end
       else
         begin
           dly_dcd <= dcd;
         end
     end // block: dly_dcd_PROC

   // Edge detect of data carrier detect
   assign dcd_ed = dcd ^ dly_dcd;

   // The delta DCD signal is asserted when a change in DCD has occurred
   // (that is, the modem control line dcd_n has changed) AND the loopback
   // enable edge detect signal is not asserted (to prevent false assertions
   // when changing between loopback and non-loopback mode or vice versa),
   // it is de-asserted when a read of the MSR has been performed
   // Note, that in loopback mode DDCD actually reflects  changes on MCR[3]
   // (out2)
   always @(posedge pclk or negedge presetn)
     begin : ddcd_PROC
       if(presetn == 1'b0)
         begin
           ddcd     <= 1'b0;
         end
       else
         begin
           if(dcd_ed && (~lb_mode_ed))
             begin
               ddcd <= 1'b1;
             end
           else if(msr_en && rd_en)
             begin
               ddcd <= 1'b0;
             end
         end
     end // block: ddcd_PROC

   // Edge detect register for loopback enable
   always @(posedge pclk or negedge presetn)
     begin : dly_lb_mode_PROC
       if(presetn == 1'b0) 
         begin
           dly_lb_mode <= 1'b0;
         end
       else
         begin
           dly_lb_mode <= lb_mode;
         end
     end // block: dly_lb_mode_PROC

   // Edge detect of loopback enable
   assign lb_mode_ed = lb_mode ^ dly_lb_mode;

   // ------------------------------------------------------
   // MSR[2] - TERI (tailing edge of ring indicator) related 
   //          functionality
   // ------------------------------------------------------

   // Edge detect register for ring indicator
   always @(posedge pclk or negedge presetn)
     begin : dly_ri_PROC
       if(presetn == 1'b0) 
         begin
           dly_ri <= 1'b0;
         end
       else
         begin
           dly_ri <= ri;
         end
     end // block: dly_ri_PROC

   // Neg edge detect of ring indicator
   assign ri_ed = (~ri) & dly_ri;

   // The teri signal is asserted when a high to low change in RI has
   // occurred (that is, the modem control line ri_n has changed from an
   // active low to an inactive high) AND the loopback enable edge detect
   // signal is not asserted (to prevent false assertions when changing
   // between loopback and non-loopback mode or vice versa), it is
   // de-asserted when a read of the MSR has been performed
   // Note, that in loopback mode TERI actually reflects when MCR[2]
   // (out1) has changed state from high to low
   always @(posedge pclk or negedge presetn)
     begin : teri_PROC
       if(presetn == 1'b0)
         begin
           teri     <= 1'b0;
         end 
       else
         begin
           if(ri_ed && (~lb_mode_ed))
             begin
               teri <= 1'b1;
             end
           else if(msr_en && rd_en)
             begin
               teri <= 1'b0;
             end
         end
     end // block: teri_PROC

   // ------------------------------------------------------
   // MSR[1] - DDSR (delta data set ready) related 
   //          functionality
   // ------------------------------------------------------

   // Edge detect register for data set ready
   always @(posedge pclk or negedge presetn)
     begin : dly_dsr_PROC
       if(presetn == 1'b0) 
         begin
           dly_dsr <= 1'b0;
         end
       else
         begin
           dly_dsr <= dsr;
         end
     end // block: dly_dsr_PROC

   // Edge detect of data set ready
   assign dsr_ed = dsr ^ dly_dsr;

   // The delta DSR signal is asserted when a change in DSR has occurred
   // (that is, the modem control line dsr_n has changed) AND the loopback
   // enable edge detect signal is not asserted (to prevent false assertions
   // when changing between loopback and non-loopback mode or vice versa),
   // it is de-asserted when a read of the MSR has been performed
   // Note, that in loopback mode DDSR actually reflects  changes on MCR[0]
   // (DTR)
   always @(posedge pclk or negedge presetn)
     begin : ddsr_PROC
       if(presetn == 1'b0)
         begin
           ddsr     <= 1'b0;
         end 
       else
         begin
           if(dsr_ed && (~lb_mode_ed))
             begin
               ddsr <= 1'b1;
             end
           else if(msr_en && rd_en)
             begin
               ddsr <= 1'b0;
             end
         end
     end // block: ddsr_PROC

   // ------------------------------------------------------
   // MSR[0] - DCTS (delta clear to send) related 
   //          functionality
   // ------------------------------------------------------

   // Edge detect register for clear to send
   always @(posedge pclk or negedge presetn)
     begin : dly_cts_PROC
       if(presetn == 1'b0) 
         begin
           dly_cts <= 1'b0;
         end
       else
         begin
           dly_cts <= cts;
         end
     end // block: dly_cts_PROC

   // Edge detect of clear to send
   assign cts_ed = cts ^ dly_cts;

   // The delta CTS signal is asserted when a change in CTS has occurred
   // (that is, the modem control line cts_n has changed) AND the loopback
   // enable edge detect signal is not asserted (to prevent false assertions
   // when changing between loopback and non-loopback mode or vice versa),
   // it is de-asserted when a read of the MSR has been performed
   // Note, that in loopback mode DCTS actually reflects  changes on MCR[1]
   // (RTS)
   always @(posedge pclk or negedge presetn)
     begin : dcts_PROC
       if(presetn == 1'b0)
         begin
           dcts     <= 1'b0;
         end 
       else
         begin
           if(cts_ed && (~lb_mode_ed))
             begin
               dcts <= 1'b1;
             end
           else if(msr_en && rd_en)
             begin
               dcts <= 1'b0;
             end
         end
     end // block: dcts_PROC

   assign msr[7:0] = {dcd, ri, dsr, cts, ddcd, teri, ddsr, dcts};

   // ------------------------------------------------------
   // -- Scratchpad Register
   // -- This is a 8bit register
   //
   // -- This register is for programmers to use as a
   // -- temporary storage space. It has no defined purpose
   // -- in the DW_apb_uart
   // ------------------------------------------------------

   // The scratchpad register will be loaded if the scratchpad register
   // write enable signal is asserted
   always @(posedge pclk or negedge presetn)
     begin : scr_PROC
       if(presetn == 1'b0) 
         begin
           scr     <= {`LEGACY_RW{1'b0}};
         end 
       else 
         begin
           if(scr_we)
             begin
               scr <= ipwdata[7:0];
             end
         end
     end // block: scr_PROC

   // ------------------------------------------------------
   // -- Shadow Receive Buffer Register - Read Only
   // -- This is a 8bit register
   //
   // -- No physical register needed
   // -- Only valid when the UART is configured to have
   // -- shadow registers (SHADOW == 1'b1)
   // ------------------------------------------------------

   // If the UART has been configured to have the SRBR then the internal
   // shadow receive buffer register enable is asserted when srbr_en is
   // asserted
   assign int_srbr_en = (`SHADOW == 1) ? srbr_en : 1'b0;

   // If the UART has been configured to have the SRBR then reading from
   // it will give the current received character in the RBR reg or at
   // of the RX FIFO
   assign srbr = (`SHADOW == 1) ? rbr : {`LEGACY_RW{1'b0}};

   // ------------------------------------------------------
   // -- Shadow Transmit Holding Register - Write Only
   // -- This is a 8bit register
   //
   // -- No physical register needed
   // -- Only valid when the UART is configured to have
   // -- shadow registers (SHADOW == 1'b1)
   // ------------------------------------------------------

   // If the UART has been configured to have the STHR then the internal
   // shadow transmit holding register enable is asserted when sthr_en is
   // asserted
   assign int_sthr_en = (`SHADOW == 1) ? sthr_en : 1'b0;
   
   // ------------------------------------------------------
   // -- FIFO Access Register
   // -- This is a 1bit register
   //
   // -- Only valid when FIFO Access mode is implemented
   // -- (FIFO_ACCESS == 1)
   // ------------------------------------------------------

   // The FIFO access register will be loaded if the FIFO access write
   // enable signal is asserted
   always @(posedge pclk or negedge presetn)
     begin : far_ir_PROC
       if(presetn == 1'b0) 
         begin
           far_ir     <= {`FAR_RW{1'b0}};
         end 
       else 
         begin
           if(far_we)
             begin
               far_ir <= ipwdata[0];
             end
         end
     end // block: far_ir_PROC

   // If the UART is configured not to have FIFO access mode, remove 
   // the FIFO access register
   assign far = (`FIFO_ACCESS == 1) ? far_ir : {`FAR_RW{1'b0}};

   assign fifo_access = far;

   // Edge detect register for FIFO access
   always @(posedge pclk or negedge presetn)
     begin : dly_fifo_access_PROC
       if(presetn == 1'b0) 
         begin
           dly_fifo_access <= 1'b0;
         end
       else
         begin
           dly_fifo_access <= fifo_access;
         end
     end // block: dly_fifo_access_PROC

   // FIFO access edge detect
   // Whenever the FIFO access signal changes, indicating a change between
   // FIFO access mode and non FIFO access mode of operation or vice versa,
   // the FIFO access edge detect signal will assert. the assertion of
   // this signals will cause the reset of the controller portions of the
   // FIFO's (if present) and the THR and RBR
   assign fifo_access_ed = (`FIFO_ACCESS == 1) ? (fifo_access ^ dly_fifo_access) : 1'b0;

   // ------------------------------------------------------
   // -- Transmit FIFO Read - Read Only
   //
   // -- No physical register needed
   // -- Only valid when FIFO Access mode is implemented and
   // -- enabled (fifo_access == 1)
   // ------------------------------------------------------

   // If FIFO access mode is implemented and enabled then accessing the
   // TFR gives the data in the transmit holding register or the data
   // at the top of the TX FIFO (in FIFO mode)
   assign tfr = fifo_access ? tx_data : {`LEGACY_RW{1'b0}};

   // The internal enable is asserted if FIFO access mode is enabled
   // and the transmit FIFO read enable is asserted
   assign int_tfr_en = fifo_access ? tfr_en & byte_en[0] : 1'b0;

   // ------------------------------------------------------
   // -- Receive FIFO Write - Write Only
   //
   // -- No physical register needed unless Coherency is
   // -- required
   // -- Only valid when FIFO Access mode is implemented and
   // -- enabled (fifo_access == 1)
   // ------------------------------------------------------
   
   // To maintain write coherency a shadow register is required when
   // the width of the APB data bus is 8 to store the first write data,
   // when the second write is performed the 10 bits will be written to
   // the RBR or RX FIFO depending on the mode of operation
   always @(posedge pclk or negedge presetn)
     begin : rfw_shdw_PROC
       if(presetn == 1'b0) 
         begin
           rfw_shdw     <= {`LEGACY_RW{1'b0}};
         end 
       else 
         begin
           if(byte_en[0])
             begin
               rfw_shdw <= ipwdata[7:0];
             end 
         end
     end // block: rfw_shdw_PROC

   // Remove shadow register if FIFO access mode has not been selected
   // or if the APB data width is not 8
   assign rfw = fifo_access ? (`APB_DATA_WIDTH == 8) ? {ipwdata[1:0], rfw_shdw} : ipwdata[9:0] : {`RFW_RW{1'b0}};

   // If FIFO access mode is enabled, then when the APB data bus
   // is 8 the internal enable is asserted on the second write to the
   // RFW, else it is asserted on the first
   assign int_rfw_en = fifo_access ? (`APB_DATA_WIDTH == 8) ? (rfw_en & (byte_en == 4'b0010)) : rfw_en : 1'b0;

   // ------------------------------------------------------
   // -- UART Status Register - Read Only
   // -- This is a 1/5bit register
   // --
   // -- Bits[4:1] are only valid when the UART is configured
   // -- to have additional FIFO status registers
   // -- (FIFO_STAT == 1)
   //
   // -- This register is split into the following bit fields
   //
   //    [4] - RFF  - Receive FIFO Full
   //    [3] - RFNE - Receive FIFO Not Empty
   //    [2] - TFE  - Transmit FIFO Empty
   //    [1] - TFNF - Transmit FIFO Not Full
   //    [0] - BUSY - UART Busy
   // ------------------------------------------------------

   // ------------------------------------------------------
   // USR[7:5] - reserved and read back as zero
   // ------------------------------------------------------
   assign usr[7:5] = 3'b0;

   // ------------------------------------------------------
   // USR[4] - RFF (receive FIFO full) related functionality
   // ------------------------------------------------------
   assign usr[4] = (`FIFO_STAT == 1) ? rx_full     : 1'b0;

   // ------------------------------------------------------
   // USR[3] - RFNE (receive FIFO not empty) related
   //          functionality
   // ------------------------------------------------------
   assign usr[3] = (`FIFO_STAT == 1) ? (~rx_empty) : 1'b0;

   // ------------------------------------------------------
   // USR[2] - TFE (transmit FIFO empty) related functionality
   // ------------------------------------------------------
   assign usr[2] = (`FIFO_STAT == 1) ? tx_empty    : 1'b0;

   // ------------------------------------------------------
   // USR[1] - TFNF (transmit FIFO not full) related
   //          functionality
   // ------------------------------------------------------
   assign usr[1] = (`FIFO_STAT == 1) ? (~tx_full)  : 1'b0;

   // ------------------------------------------------------
   // USR[0] - BUSY (UART busy) related functionality
   // ------------------------------------------------------
   assign usr[0] = uart_busy;

   // The UART is busy if there is a serial TX in progress OR a serial
   // RX in progress when not in FIFO access mode OR if the THR is not
   // empty when the baud clock divisor is not zero and not in FIFO
   // access mode OR the RBR is not empty when not in FIFO access mode
   assign uart_busy = tx_in_prog | (rx_in_prog & (~fifo_access)) | ((~thr_empty) & ((divsr != 16'b0 & (~dlab)) | (~fifo_access))) | 
                      ((~rbr_empty) & (~fifo_access));

   // ------------------------------------------------------
   // -- Transmit FIFO Level - Read Only
   //
   // -- This register contains the number of valid data
   // -- entries in the transmit FIFO buffer.
   // -- Coherency maybe required
   // -- Only valid when the UART is configured to have
   // -- additional FIFO status registers (FIFO_STAT == 1)
   // ------------------------------------------------------

   // Transmit FIFO level counter
   always @(posedge pclk or negedge presetn)
     begin : tfl_cnt_PROC
       if(presetn == 1'b0)
         begin
           tfl_cnt     <= {`TFL_RW{1'b0}};
         end 
       else
         begin
            
           // Reset to zero if TX FIFO controller is reset
           if(int_tx_fifo_rst == 1'b1)
             begin
               tfl_cnt <= {`TFL_RW{1'b0}};
             end
           else if(tx_push == 1'b1 && tx_pop == 1'b0 && (~tx_full))
             begin
               tfl_cnt <= tfl_cnt + 1'b1;
             end
           else if(tx_push == 1'b0 && tx_pop == 1'b1 && tfl_cnt != {`TFL_RW{1'b0}})
             begin
               tfl_cnt <= tfl_cnt - 1'b1;
             end
         end
     end // block: tfl_cnt_PROC

   // Set all unused bits of int_tfl_cnt to zero for 
   // optimization reasons
   always @ (tfl_cnt) 
     begin : int_tfl_cnt_PROC
       int_tfl_cnt = 0;
       int_tfl_cnt[`TFL_RW-1:0] = tfl_cnt;
     end

   // To maintain read coherency shadow registers are required when
   // the width of the counter exceeds that of the APB data bus
   always @ (posedge pclk or negedge presetn)
     begin : tfl_shdw_PROC
       if(presetn == 1'b0)
         begin
           tfl_shdw <= 4'b0;
         end
       else
         begin
           if(tfl_en && rd_en)
             begin
               if(byte_en[0])
                 begin
                   tfl_shdw <= int_tfl_cnt[11:8];
                 end
             end
         end
     end // block: tfl_shdw_PROC

   // Calculates which bits (if any) require shadow registers and remove
   // unnecessary shadow register bits
   always @ (int_tfl_cnt or tfl_shdw)
     begin : tfl_ir_PROC
       tfl_ir                  = {`MAX_TFL_RW{1'b0}};

       if(`FIFO_ADDR_WIDTH > 7 && `APB_DATA_WIDTH == 8)
         begin
           tfl_ir[7:0]         = int_tfl_cnt[7:0];
           
           if(`FIFO_ADDR_WIDTH == 11)
             begin
               tfl_ir[11:8]    = tfl_shdw[3:0];
             end
           else if(`FIFO_ADDR_WIDTH == 10)
             begin
               tfl_ir[10:8]    = tfl_shdw[2:0];
             end
           else if(`FIFO_ADDR_WIDTH == 9)
             begin
               tfl_ir[9:8]     = tfl_shdw[1:0];
             end
           else
             begin
               tfl_ir[8]       = tfl_shdw[0];
             end
         end
       else
         begin
           tfl_ir[`TFL_RW-1:0] = int_tfl_cnt[`TFL_RW-1:0];
         end
        
     end // block: tfl_ir_PROC

   // If the UART is configured not to have additional FIFO status
   // registers, remove the transmit FIFO level register
   assign tfl = (`FIFO_STAT == 1) ? tfl_ir[`TFL_RW-1:0] : {`TFL_RW{1'b0}};

   // ------------------------------------------------------
   // -- Receive FIFO Level - Read Only
   //
   // -- This register contains the number of valid data
   // -- entries in the receive FIFO buffer.
   // -- Coherency maybe required
   // -- Only valid when the UART is configured to have
   // -- additional FIFO status registers (FIFO_STAT == 1)
   // ------------------------------------------------------

   // Receive FIFO level counter
   always @(posedge pclk or negedge presetn)
     begin : rfl_cnt_PROC
       if(presetn == 1'b0)
         begin
           rfl_cnt     <= {`RFL_RW{1'b0}};
         end 
       else
         begin
            
           // Reset to zero if RX FIFO controller is reset
           if(int_rx_fifo_rst == 1'b1)
             begin
               rfl_cnt <= {`RFL_RW{1'b0}};
             end
           else if(rx_push == 1'b1 && rx_pop == 1'b0 && (~rx_full))
             begin
               rfl_cnt <= rfl_cnt + 1'b1;
             end
           else if(rx_push == 1'b0 && rx_pop == 1'b1 && rfl_cnt != {`RFL_RW{1'b0}})
             begin
               rfl_cnt <= rfl_cnt - 1'b1;
             end
         end
     end // block: rfl_cnt_PROC

   // Set all unused bits of int_rfl_cnt to zero for 
   // optimization reasons
   always @ (rfl_cnt) 
     begin : int_rfl_cnt_PROC
       int_rfl_cnt = 0;
       int_rfl_cnt[`RFL_RW-1:0] = rfl_cnt;
     end

   // To maintain read coherency shadow registers are required when
   // the width of the counter exceeds that of the APB data bus
   always @ (posedge pclk or negedge presetn)
     begin : rfl_shdw_PROC
       if(presetn == 1'b0)
         begin
           rfl_shdw <= 4'b0;
         end
       else
         begin
           if(rfl_en && rd_en)
             begin
               if(byte_en[0])
                 begin
                   rfl_shdw <= int_rfl_cnt[11:8];
                 end
             end
         end
     end // block: rfl_shdw_PROC

   // Calculates which bits (if any) require shadow registers and remove
   // unnecessary shadow register bits
   always @ (int_rfl_cnt or rfl_shdw)
     begin : rfl_ir_PROC
       rfl_ir                  = {`MAX_RFL_RW{1'b0}};

       if(`FIFO_ADDR_WIDTH > 7 && `APB_DATA_WIDTH == 8)
         begin
           rfl_ir[7:0]         = int_rfl_cnt[7:0];
           
           if(`FIFO_ADDR_WIDTH == 11)
             begin
               rfl_ir[11:8]    = rfl_shdw[3:0];
             end
           else if(`FIFO_ADDR_WIDTH == 10)
             begin
               rfl_ir[10:8]    = rfl_shdw[2:0];
             end
           else if(`FIFO_ADDR_WIDTH == 9)
             begin
               rfl_ir[9:8]     = rfl_shdw[1:0];
             end
           else
             begin
               rfl_ir[8]       = rfl_shdw[0];
             end
         end
       else
         begin
           rfl_ir[`RFL_RW-1:0] = int_rfl_cnt[`RFL_RW-1:0];
         end
        
     end // block: rfl_ir_PROC

   // If the UART is configured not to have additional FIFO status
   // registers, remove the receive FIFO level register
   assign rfl = (`FIFO_STAT == 1) ? rfl_ir[`RFL_RW-1:0] : {`RFL_RW{1'b0}};

   // ------------------------------------------------------
   // -- Software Reset Register - Write Only
   // -- This is a 1/3bit register
   //
   // -- No physical register needed
   // -- Only valid when the UART is configured to have
   // -- shadow registers (SHADOW == 1'b1), also writing to
   // -- bits[2:1] will only have effect if FIFO's are
   // -- implemented (FIFO_MODE_UART != NONE)
   //
   // -- This register is split into the following bit fields
   //
   //    [2] - XFR - XMIT FIFO reset
   //    [1] - RFR - RCVR FIFO reset
   //    [0] - UR  - UART reset
   // ------------------------------------------------------

   // If the UART has been configured to have the SRR then the internal
   // software reset register enable is asserted when ssr_en is asserted
   assign int_srr_en = (`SHADOW == 1) ? srr_en : 1'b0;

   // NOTE: if FIFO's are implemented the transmit FIFO reset is asserted
   // if the internal software reset register enable is asserted and the
   // value written to the XMIT FIFO reset bit (bit[2]) is one, see FCR
   // tx_fifo_rst assertion

   // NOTE: if FIFO's are implemented the receiver FIFO reset is asserted
   // if the internal software reset register enable is asserted and the
   // value written to the RCVR FIFO reset bit (bit[1]) is one, see FCR
   // rx_fifo_rst assertion

   // ------------------------------------------------------
   // SRR[0] - UR (UART reset) related signals
   // ------------------------------------------------------

   // Software reset decode
   assign sw_rst_dec = int_srr_en ? (ipwdata[0]) : 1'b0;

   // ------------------------------------------------------
   // -- Shadow Request to Send
   // -- This is a 1bit register
   //
   // -- No physical register needed
   // -- Only valid when the UART is configured to have
   // -- shadow registers (SHADOW == 1'b1)
   //
   // ------------------------------------------------------

   // If the UART has been configured to have the SRTS then the internal
   // shadow request to send write enable is asserted when srts_we is
   // asserted
   assign int_srts_we = (`SHADOW == 1) ? srts_we : 1'b0;

   // If the UART has been configured to have the SRTS then reading from
   // it will give the current value of the RTS bit of the MCR (bit[1])
   assign srts = (`SHADOW == 1) ? mcr[1] : 1'b0;

   // ------------------------------------------------------
   // -- Shadow Break Control Register
   // -- This is a 1bit register
   //
   // -- No physical register needed
   // -- Only valid when the UART is configured to have
   // -- shadow registers (SHADOW == 1'b1)
   //
   // ------------------------------------------------------

   // If the UART has been configured to have the SBCR then the internal
   // shadow break control register write enable is asserted when sbcr_we
   // is asserted
   assign int_sbcr_we = (`SHADOW == 1) ? sbcr_we : 1'b0;

   // If the UART has been configured to have the SBCR then reading from
   // it will give the current value of the BC bit of the LCR (bit[6])
   assign sbcr = (`SHADOW == 1) ? lcr[6] : 1'b0;

   // ------------------------------------------------------
   // -- Shadow DMA Mode
   // -- This is a 1bit register
   //
   // -- No physical register needed
   // -- Only valid when the UART is configured to have
   // -- shadow registers (SHADOW == 1'b1)
   //
   // ------------------------------------------------------

   // If the UART has been configured to have the SDMAM then the internal
   // shadow DMA mode write enable is asserted when sdmam_we is asserted
   assign int_sdmam_we = (`FIFO_MODE_UART != 0 && `SHADOW == 1) ? sdmam_we : 1'b0;

   // If the UART has been configured to have the SDMAM then reading from
   // it will give the current value of the DMAM bit of the FCR (bit[3])
   assign sdmam = (`FIFO_MODE_UART != 0 && `SHADOW == 1) ? fcr[3] : 1'b0;

   // ------------------------------------------------------
   // -- Shadow FIFO Enable
   // -- This is a 1bit register
   //
   // -- No physical register needed
   // -- Only valid when the UART is configured to have
   // -- shadow registers (SHADOW == 1'b1)
   //
   // ------------------------------------------------------

   // If the UART has been configured to have the SFE then the internal
   // shadow FIFO enable write enable is asserted when sfe_we is
   // asserted
   assign int_sfe_we = (`SHADOW == 1) ? sfe_we : 1'b0;

   // If the UART has been configured to have the SFE then reading from
   // it will give the current value of the FE bit of the FCR (bit[0])
   assign sfe = (`SHADOW == 1) ? fcr[0] : 1'b0;

   // ------------------------------------------------------
   // -- Shadow RCVR Trigger
   // -- This is a 2bit register
   //
   // -- No physical register needed
   // -- Only valid when the UART is configured to have
   // -- shadow registers (SHADOW == 1'b1)
   //
   // ------------------------------------------------------

   // If the UART has been configured to have the SRT then the internal
   // shadow RCVR trigger write enable is asserted when srt_we is
   // asserted
   assign int_srt_we = (`SHADOW == 1) ? srt_we : 1'b0;

   // If the UART has been configured to have the SRT then reading from
   // it will give the current value of the RT bits of the FCR (bit[7:6])
   assign srt = (`SHADOW == 1) ? fcr[7:6] : 2'b00;

   // ------------------------------------------------------
   // -- Shadow TX Empty Trigger
   // -- This is a 2bit register
   //
   // -- No physical register needed
   // -- Only valid when the UART is configured to have
   // -- shadow registers (SHADOW == 1'b1)
   //
   // ------------------------------------------------------

   // If the UART has been configured to have the STET then the internal
   // shadow TX empty trigger write enable is asserted when stet_we is
   // asserted
   assign int_stet_we = (`SHADOW == 1) ? stet_we : 1'b0;

   // If the UART has been configured to have the STET then reading from
   // it will give the current value of the TET bits of the FCR (bit[5:4])
   assign stet = (`SHADOW == 1) ? fcr[5:4] : 2'b00;

   // ------------------------------------------------------
   // -- Halt TX Register
   // -- This is a 1bit register
   //
   // -- Only valid when FIFO are implemented (FIFO_MODE_UART > 0)
   // ------------------------------------------------------

   // The halt TX register will be loaded if the halt TX write
   // enable signal is asserted
   always @(posedge pclk or negedge presetn)
     begin : htx_ir_PROC
       if(presetn == 1'b0) 
         begin
           htx_ir     <= {`HTX_RW{1'b0}};
         end 
       else 
         begin
           if(htx_we)
             begin
               htx_ir <= ipwdata[0];
             end
         end
     end // block: htx_ir_PROC

   // If the UART is configured not to have FIFO's, remove the halt
   // TX register
   assign htx = (`FIFO_MODE_UART > 0) ? (fifo_en ? htx_ir : {`HTX_RW{1'b0}}) : {`HTX_RW{1'b0}};

   // ------------------------------------------------------
   // -- Software Acknowledge - Write Only
   // -- This is a 1bit register
   //
   // -- No physical register needed
   // -- Only valid when the UART is configured to have
   // -- the additional DMA handshaking signals
   // -- (DMA_EXTRA == 1'b1)
   // ------------------------------------------------------

   // If the UART has been configured to have the DMASA then the internal
   // DMA software acknowledge enable is asserted when dmasa_en is
   // asserted
   assign int_dmasa_en = (`DMA_EXTRA == 1) ? dmasa_en : 1'b0;

   // DMA software acknowledge
   // The DMA software acknowledge is asserted if the internal DMA
   // software acknowledge enable is asserted and the value written to
   // bit[0] of the write data bus is one
   assign dma_sw_ack = int_dmasa_en ? ipwdata[0] : 1'b0;

   // ------------------------------------------------------
   // -- Component Parameter Register - Read Only
   // -- This is a 32bit register
   //
   // -- No physical register needed
   //
   // ------------------------------------------------------
   assign dma_extra      = `DMA_EXTRA;
   assign add_encod_parm = `UART_ADD_ENCODED_PARAMS;
   assign shadow         = `SHADOW;
   assign fifo_stat      = `FIFO_STAT;
   assign fifo_acc       = `FIFO_ACCESS;
   assign add_feat       = `ADDITIONAL_FEATURES;
   assign sir_lp_mode    = `SIR_LP_MODE;
   assign sir_mode       = `SIR_MODE;
   assign thre_mode      = `THRE_MODE;
   assign afce_mode      = `AFCE_MODE;

   assign uart_cpr = (add_encod_parm == 1) ? {8'b0, `UART_ENCODED_FIFO_MODE,
                      2'b0, dma_extra, add_encod_parm, shadow, fifo_stat,
                      fifo_acc, add_feat, sir_lp_mode, sir_mode, thre_mode,
                      afce_mode, 2'b0, `UART_ENCODED_APB_WIDTH} :
                      {`MAX_APB_DATA_WIDTH{1'b0}};
   
   // ------------------------------------------------------
   // -- Component Version - Read Only
   // -- This is a 32bit register
   //
   // -- No physical register needed
   //
   // ------------------------------------------------------
   assign uart_cv = add_feat ? `UART_COMP_VERSION : {`MAX_APB_DATA_WIDTH{1'b0}};
   
   // ------------------------------------------------------
   // -- Component Type Register - Read Only
   // -- This is a 32bit register
   //
   // -- No physical register needed
   //
   // ------------------------------------------------------
   assign uart_ctr = add_feat ? `UART_COMP_TYPE : {`MAX_APB_DATA_WIDTH{1'b0}};

   // ------------------------------------
   // Timeout detection signals
   // ------------------------------------

   // The timeout detect counter enables is a bus of all the signals
   // required to make up both the character timeout counter enable
   // signal and the clock gate enable counter enable. This method of
   // passing all signals over to the timeout detect module is used
   // for synchronization reasons when the UART is configured to have
   // two clocks and hence the data sync module can be used in the
   // DW_apb_uart sync module
   assign to_det_cnt_ens = (`CLK_GATE_EN == 1) ? {lb_mode, far, break, thr_empty, tx_in_prog, rbr_empty, fifo_en, rx_pop} :
                            {rbr_empty, fifo_en, rx_pop};

   // The counter enables edge detect signal gets asserted whenever
   // a change on the signals that make up the timeout detect counter
   // enables occurs
   assign cnt_ens_ed = (`CLK_GATE_EN == 1) ? (lb_mode_ed | far_ed | break_ed | thr_empty_ed | tx_in_prog_ed | rbr_empty_ed | fen_ed | rx_pop_ed) :
                        (rbr_empty_ed | fen_ed | rx_pop_ed);

   // FIFO access register edge detect
   assign far_ed = far_we & (far ^ ipwdata[0]);

   // Break edge detect
   assign break_ed = break ^ dly_break;

   // Edge detect register for break
   always @(posedge pclk or negedge presetn)
     begin : dly_break_PROC
       if(presetn == 1'b0) 
         begin
           dly_break <= 1'b0;
         end
       else
         begin
           dly_break <= break;
         end
     end // block: dly_break_PROC

   // THR empty edge detect
   assign thr_empty_ed = thr_empty ^ dly_thr_empty;

   // Edge detect register for THR empty
   always @(posedge pclk or negedge presetn)
     begin : dly_thr_empty_PROC
       if(presetn == 1'b0) 
         begin
           dly_thr_empty <= 1'b0;
         end
       else
         begin
           dly_thr_empty <= thr_empty;
         end
     end // block: dly_thr_empty_PROC

   // TX in progress edge detect
   assign tx_in_prog_ed = tx_in_prog ^ dly_tx_in_prog;

   // Edge detect register for TX in progress
   always @(posedge pclk or negedge presetn)
     begin : dly_tx_in_prog_PROC
       if(presetn == 1'b0) 
         begin
           dly_tx_in_prog <= 1'b0;
         end
       else
         begin
           dly_tx_in_prog <= tx_in_prog;
         end
     end // block: dly_tx_in_prog_PROC

   // RBR empty edge detect
   assign rbr_empty_ed = rbr_empty ^ dly_rbr_empty;

   // RX pop edge detect
   assign rx_pop_ed = rx_pop ^ dly_rx_pop;

   // pclk domain clear for the UART low power request (clock gate enable)
   // When we do a write we should restart the clocks as some value may
   // have changed.
   assign clear_lp_req_pclk = (`CLK_GATE_EN == 1) ? (wr_en | wr_enx | (~cge_cnt_en)) : 1'b0;

   // If the UART has been configured to have a clock gate enable output(s)
   // on the interface to indicate that the device is inactive, so clocks
   // may be gated then the clock gate enable counter enable signal gets
   // asserted when the THR or TX TX FIFO (in FIFO mode) is empty and the
   // RBR or RX FIFO (in FIFO mode) is empty and there is no serial
   // transmission in progress and loopback operation is not enabled and
   // FIFO access mode is not in operation and a break is not being TX'ed.
   // This is an internal signal and is replicited in the timeout detect module
   assign cge_cnt_en = (`CLK_GATE_EN == 1) ? ((~lb_mode) & (~far) & (~break) &
                        thr_empty & rbr_empty & (~tx_in_prog)) : 1'b0;

   // ------------------------------------
   // DMA signaling
   // ------------------------------------

   // DMA TX request, active low
   assign dma_tx_req_n = ~dma_tx_req;

   // DMA TX request, active high
   always @ (posedge pclk or negedge presetn)
     begin : dma_tx_req_PROC
       if(presetn == 1'b0)
         begin
           dma_tx_req <= 1'b0;
         end
       else
         begin
           if(`DMA_EXTRA == 1)
             begin

               // de-assert if and ack from the DMA is received or
               // a software ack has been given or the FIFO has
               // been reset
               if(int_dma_tx_ack || dma_sw_ack || sw_tx_fifo_rst)
                 begin
                   dma_tx_req <= 1'b0;
                 end
               else
                 begin
                   
                   // Programmable THRE interrupt mode enabled
                   if(ptime)
                     begin
                       if(fifo_en)
                         begin

                           // Assert when TX FIFO is at or below
                           // programmed threshold
                           if(tfl_cnt <= tx_empty_trig)
                             begin
                               dma_tx_req <= 1'b1;
                             end
                         end

                       // FIFO's not enabled
                       else
                         begin

                           // Assert if THR is empty
                           if(thr_ir_empty)
                             begin
                               dma_tx_req <= 1'b1;
                             end
                         end
                     end // if (ptime)
                   else
                     begin
                       if(thr_empty)
                         begin
                           dma_tx_req <= 1'b1;
                         end
                     end
                 end
             end
           else
             begin
                
               // DMA mode 1
               if(dma_mode)
                 begin
                   if(tx_full)
                     begin
                       dma_tx_req <= 1'b0;
                     end
                   else
                     begin
                       
                       // Programmable THRE interrupt mode enabled
                       if(ptime)
                         begin
                           if(tfl_cnt <= tx_empty_trig)
                             begin
                               dma_tx_req <= 1'b1;
                             end
                         end // if (ptime)
                    
                       // Programmable THRE interrupt mode disabled
                       else
                         begin
                           if(tx_empty)
                             begin
                               dma_tx_req <= 1'b1;
                             end
                         end
                     end
                 end
                
               // DMA mode 0
               else
                 begin
                   
                   // Programmable THRE interrupt mode enabled
                   if(ptime)
                     begin
                       if(fifo_en)
                         begin
                           if(tfl_cnt <= tx_empty_trig)
                             begin
                               dma_tx_req <= 1'b1;
                             end
                           else
                             begin
                               dma_tx_req <= 1'b0;
                             end
                         end
                       else
                         begin
                           dma_tx_req <= thr_ir_empty;
                         end
                     end // if (ptime)
                    
                   // Programmable THRE interrupt mode disabled
                   else
                     begin
                       dma_tx_req <= thr_empty;
                     end
                 end // else: !if(dma_mode)
             end // else: !if(`DMA_EXTRA == 1)
         end
     end // block: dma_tx_req_PROC

   // If the UART is configure to have the additional DMA signals on the
   // interface then the internal DMA TX acknowledge signal is assigned
   // either the DMA TX acknowledge signal or its inverse, depending on
   // the configured polarity of the DMA signals
   assign int_dma_tx_ack = (`DMA_EXTRA == 1) ? ((`DMA_POL == 1) ? ~dma_tx_ack : dma_tx_ack) : 1'b0;

   // DMA RX request, active low
   assign dma_rx_req_n = ~dma_rx_req;
   
   // DMA RX request, active high
   always @ (posedge pclk or negedge presetn)
     begin : dma_rx_req_PROC
       if(presetn == 1'b0)
         begin
           dma_rx_req <= 1'b0;
         end
       else
         begin
           if(`DMA_EXTRA == 1)
             begin

               // de-assert if and ack from the DMA is received or
               // a software ack has been given or the FIFO has
               // been reset
               if(int_dma_rx_ack || dma_sw_ack || sw_rx_fifo_rst)
                 begin
                   dma_rx_req <= 1'b0;
                 end
               else
                 begin
                   if(fifo_en)
                     begin

                       // Set when the RX FIFO level greater than or equal to the
                       // programmed RX FIFO trigger level
                       if(rfl_cnt >= rx_fifo_trig)
                         begin
                           dma_rx_req <= 1'b1;
                         end
                     end
                   else
                     begin

                       // Set when there a single character available in the RBR
                       if(~rbr_ir_empty)
                         begin
                           dma_rx_req <= 1'b1;
                         end
                     end
                 end
             end // if (`DMA_EXTRA == 1)
           else
             begin
               
               // DMA mode 1
               if(dma_mode)
                 begin

                   // Clear when the RBR or RX FIFO (when FIFO's implemented
                   // and enabled) is empty
                   if(rx_empty)
                     begin
                       dma_rx_req <= 1'b0;
                     end
                   
                   // Set when the RX FIFO level greater than or equal to the
                   // programmed RX FIFO trigger level or a character timeout
                   // occurs
                   else if((rfl_cnt >= rx_fifo_trig) || valid_char_to)
                     begin
                      dma_rx_req <= 1'b1;
                     end
                 end
               
               // DMA mode 0
               // Set when there a single character available in the RBR or
               // RX FIFO (when FIFO's implemented and enabled) and clear
               // (de-asseret) when the RBR or RX FIFO is empty
               else
                 begin
                   dma_rx_req <= ~rbr_empty;
                 end
             end // else: !if(`DMA_EXTRA == 1)
         end
     end // block: dma_rx_req_PROC

   // If the UART is configure to have the additional DMA signals on the
   // interface then the internal DMA RX acknowledge signal is assigned
   // either the DMA RX acknowledge signal or its inverse, depending on
   // the configured polarity of the DMA signals
   assign int_dma_rx_ack = (`DMA_EXTRA == 1) ? ((`DMA_POL == 1) ? ~dma_rx_ack : dma_rx_ack) : 1'b0;

   // DMA TX single
   // If the UART is configure to have the additional DMA signals on the
   // interface then the active low DMA TX single signal is assigned the
   // inverse of the active high DMA TX single signal
   assign dma_tx_single_n = (`DMA_EXTRA == 1) ? ~dma_tx_single : 1'b0;

   always @ (posedge pclk or negedge presetn)
     begin : dma_tx_single_PROC
       if(presetn == 1'b0)
         begin
           dma_tx_single <= 1'b0;
         end
       else if(`DMA_EXTRA == 1)
         begin

           // de-assert if and ack from the DMA is received or
           // a software ack has been given or the FIFO has
           // been reset
           if(int_dma_tx_ack || dma_sw_ack || sw_tx_fifo_rst)
             begin
               dma_tx_single <= 1'b0;
             end
           else if((~tx_full & fifo_en) || (thr_ir_empty & ~fifo_en))
             begin
               dma_tx_single <= 1'b1;
             end
         end
       else
         begin
           dma_tx_single <= 1'b0;
         end
     end // block: dma_tx_single_PROC

   // DMA RX single
   // If the UART is configure to have the additional DMA signals on the
   // interface then the active low DMA RX single signal is assigned the
   // inverse of the active high DMA RX single signal
   assign dma_rx_single_n = (`DMA_EXTRA == 1) ? ~dma_rx_single : 1'b0;

   always @ (posedge pclk or negedge presetn)
     begin : dma_rx_single_PROC
       if(presetn == 1'b0)
         begin
           dma_rx_single <= 1'b0;
         end
       else if(`DMA_EXTRA == 1)
         begin

           // de-assert if and ack from the DMA is received or
           // a software ack has been given or the FIFO has
           // been reset
           if(int_dma_rx_ack || dma_sw_ack || sw_rx_fifo_rst)
             begin
               dma_rx_single <= 1'b0;
             end
           else if(~rbr_empty)
             begin
               dma_rx_single <= 1'b1;
             end
         end
       else
         begin
           dma_rx_single <= 1'b0;
         end
     end // block: dma_rx_single_PROC
   
   // ------------------------------------------------------
   // -- APB read data mux
   //
   // -- The data from the selected register is
   // -- placed on a zero-padded 32-bit read data bus.
   // ------------------------------------------------------
   always @(rbr_en      or rbr      or
            dll_en      or dll      or
            dlh_en      or dlh      or
            ier_en      or ier      or
            iir_en      or iir      or
            lcr_en      or lcr      or
            mcr_en      or mcr      or
            lsr_en      or lsr      or
            msr_en      or msr      or
            scr_en      or scr      or
            srbr_en     or srbr     or
            far_en      or far      or
            tfr_en      or tfr      or
            usr_en      or usr      or
            tfl_en      or tfl      or
            rfl_en      or rfl      or
            srts_en     or srts     or
            sbcr_en     or sbcr     or
            sdmam_en    or sdmam    or
            sfe_en      or sfe      or
            srt_en      or srt      or
            stet_en     or stet     or
            htx_en      or htx      or
            uart_cpr_en or uart_cpr or
            uart_cv_en  or uart_cv  or
            uart_ctr_en or uart_ctr
            ) 
     begin : iprdata_PROC
      
      iprdata = {32{1'b0}};

      case(1'b1)

        rbr_en      : iprdata[`LEGACY_RW-1:0]  = rbr[`LEGACY_RW-1:0];
        dll_en      : iprdata[`LEGACY_RW-1:0]  = dll[`LEGACY_RW-1:0];
        dlh_en      : iprdata[`LEGACY_RW-1:0]  = dlh[`LEGACY_RW-1:0];
        ier_en      : iprdata[`LEGACY_RW-1:0]  = ier[`LEGACY_RW-1:0];
        iir_en      : iprdata[`LEGACY_RW-1:0]  = iir[`LEGACY_RW-1:0];
        lcr_en      : iprdata[`LEGACY_RW-1:0]  = lcr[`LEGACY_RW-1:0];
        mcr_en      : iprdata[`MCR_RW-1:0]     = mcr[`MCR_RW-1:0];
        lsr_en      : iprdata[`LEGACY_RW-1:0]  = lsr[`LEGACY_RW-1:0];
        msr_en      : iprdata[`LEGACY_RW-1:0]  = msr[`LEGACY_RW-1:0];
        scr_en      : iprdata[`LEGACY_RW-1:0]  = scr[`LEGACY_RW-1:0];
        srbr_en     : iprdata[`LEGACY_RW-1:0]  = srbr[`LEGACY_RW-1:0];
        far_en      : iprdata[`FAR_RW-1:0]     = far[`FAR_RW-1:0];
        tfr_en      : iprdata[`LEGACY_RW-1:0]  = tfr[`LEGACY_RW-1:0];
        usr_en      : iprdata[`LEGACY_RW-1:0]  = usr[`LEGACY_RW-1:0];
        tfl_en      : iprdata[`TFL_RW-1:0]     = tfl[`TFL_RW-1:0];
        rfl_en      : iprdata[`RFL_RW-1:0]     = rfl[`TFL_RW-1:0];
        srts_en     : iprdata[`SRTS_RW-1:0]    = srts[`SRTS_RW-1:0];
        sbcr_en     : iprdata[`SBCR_RW-1:0]    = sbcr[`SBCR_RW-1:0];
        sdmam_en    : iprdata[`SDMAM_RW-1:0]   = sdmam[`SDMAM_RW-1:0];
        sfe_en      : iprdata[`SFE_RW-1:0]     = sfe[`SFE_RW-1:0];
        srt_en      : iprdata[`SRT_RW-1:0]     = srt[`SRT_RW-1:0];
        stet_en     : iprdata[`STET_RW-1:0]    = stet[`STET_RW-1:0];
        htx_en      : iprdata[`HTX_RW-1:0]     = htx[`HTX_RW-1:0];
        uart_cpr_en : iprdata                  = uart_cpr;
        uart_cv_en  : iprdata                  = uart_cv;
        uart_ctr_en : iprdata                  = uart_ctr;

      endcase // block: iprdata_PROC
    
     end // block: iprdata_PROC

endmodule // DW_apb_uart_regfile
