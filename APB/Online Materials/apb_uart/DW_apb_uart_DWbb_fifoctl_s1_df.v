//-----------------------------------------------------------------------------
//
//       This confidential and proprietary software may be used only
//     as authorized by a licensing agreement from Synopsys Inc.
//     In the event of publication, the following notice is applicable:
//
//                    (C) COPYRIGHT 2004 SYNOPSYS INC.
//                           ALL RIGHTS RESERVED
//
//       The entire notice above must be reproduced on all authorized
//     copies.
//
// AUTHOR:    Rick Kelly         4/14/04
//
// VERSION:   Verilog Synthesis Model for DW_apb_uart_DWbb_fifoctl_s1_df
//
// DesignWare_version: 9f6978c6
//
//-----------------------------------------------------------------------------
`include "DW_apb_uart_cc_constants.v"
module DW_apb_uart_DWbb_fifoctl_s1_df (
    clk,
    rst_n,
    init_n,
    push_req_n,
    pop_req_n,
    diag_n,
    ae_level,
    af_thresh,
    we_n,
    empty,
    almost_empty,
    half_full,
    almost_full,
    full,
    error,
    wr_addr,
    rd_addr,
    wrd_count,
    nxt_empty_n,
    nxt_full,
    nxt_error
    );

parameter depth  = 4;
parameter err_mode  =  0 ;
parameter addr_width = 2;

input			clk;
input			rst_n;
input			init_n;
input			push_req_n;
input			pop_req_n;
input			diag_n;
input  [addr_width-1:0]	ae_level;
input  [addr_width-1:0]	af_thresh;
output			we_n;
output			empty;
output			almost_empty;
output			half_full;
output			almost_full;
output			full;
output			error;
output [addr_width-1:0]	wr_addr;
output [addr_width-1:0]	rd_addr;
output [addr_width-1:0]	wrd_count;
output			nxt_empty_n;
output			nxt_full;
output			nxt_error;


wire			IOII01OO;
reg			O1111OIO;
wire			Il1II0OO;
reg			II1II110;
wire			lllOlIIO;
reg			IIO1IOI1;
wire			OOOlII0I;
reg			IO11lI1I;
wire			OIOIOIl0;
reg			I1I0Il01;
wire			II11llOI;
reg			lII0I0IO;
wire   [addr_width-1:0]	O11II00I;
reg    [addr_width-1:0]	lO1I0O01;
wire			Il00Ol1I;
reg			lOOO0II0;
wire   [addr_width-1:0]	Il1lOlIO;
reg    [addr_width-1:0]	lIlIlI0I;
wire			lIOOlOOO;
reg			OI0IIlOI;
wire   [addr_width-1:0]	l0l1IIOI;
reg    [addr_width-1:0]	l00I11IO;
reg    [addr_width-1:0]	II10I1lO;

wire			IIIl1OII;
wire   [addr_width:0]	l1I0II01;
wire			OO0IIlII;
wire   [addr_width:0]	llOIllIO;
wire			OllOI0OO;
wire			I10O10lO;


  assign we_n = push_req_n | (I1I0Il01 & pop_req_n);


  assign IIIl1OII = ~(push_req_n | (I1I0Il01 & pop_req_n));

  assign OO0IIlII = ~pop_req_n  & O1111OIO;


  assign l1I0II01 = {lO1I0O01,IIIl1OII} + 1;
  assign O11II00I = (lOOO0II0  &IIIl1OII)?
				{addr_width{1'b0}} :
				l1I0II01[addr_width:1];

  assign llOIllIO = {lIlIlI0I,OO0IIlII} + 1;
  assign Il1lOlIO = ((OI0IIlOI & OO0IIlII) ||
			    ((diag_n==1'b0)&&(err_mode == 0)))?
				{addr_width{1'b0}} :
				llOIllIO[addr_width:1];


  assign lIOOlOOO = ((Il1lOlIO & depth-1) == depth-1)? 1'b1 : 1'b0;

  assign Il00Ol1I = ((O11II00I & depth-1) == depth-1)? 1'b1 : 1'b0;

  assign OllOI0OO = ~push_req_n & pop_req_n & ~I1I0Il01 |
			  ~push_req_n & ~O1111OIO;

  assign I10O10lO = push_req_n & ~pop_req_n & O1111OIO;

  always @ (l00I11IO or I10O10lO) begin : I0l100lO
    if (I10O10lO)
      II10I1lO = l00I11IO - 1;
    else
      II10I1lO = l00I11IO + 1;
  end

  assign l0l1IIOI = ((OllOI0OO | I10O10lO) == 1'b0)?
				l00I11IO : II10I1lO;

  assign OIOIOIl0 =	((l00I11IO == depth-1)? ~push_req_n & pop_req_n : 1'b0) |
			(I1I0Il01 & push_req_n & pop_req_n) |
			(I1I0Il01 & ~push_req_n);

  assign IOII01OO = (l0l1IIOI == {addr_width{1'b0}})? OIOIOIl0 : 1'b1;


  assign lllOlIIO = (l0l1IIOI >= (depth+1)/2)? 1'b1 : OIOIOIl0;


  assign Il1II0OO = ~(((l0l1IIOI <= ae_level)? 1'b1 : 1'b0) &
				((1<<addr_width == depth)? ~OIOIOIl0 : 1'b1)) ;


  assign OOOlII0I = (l0l1IIOI >= af_thresh)? 1'b1 :
				OIOIOIl0;


  assign II11llOI = (~pop_req_n & ~O1111OIO) |
			(~push_req_n & pop_req_n & I1I0Il01) |
			((err_mode==0)? (( |(lO1I0O01 ^ lIlIlI0I)) ^ (O1111OIO & ~I1I0Il01)) : 1'b0) |
			((err_mode==2)? 1'b0 : lII0I0IO);


  always @ (posedge clk or negedge rst_n) begin : I1l0OIlI
    if (rst_n == 1'b0) begin
      O1111OIO          <= 1'b0;
      II1II110   <= 1'b0;
      IIO1IOI1    <= 1'b0;
      IO11lI1I  <= 1'b0;
      I1I0Il01         <= 1'b0;
      lII0I0IO        <= 1'b0;
      lO1I0O01      <= {addr_width{1'b0}};
      OI0IIlOI   <= 1'b0;
      lOOO0II0   <= 1'b0;
      lIlIlI0I      <= {addr_width{1'b0}};
      l00I11IO       <= {addr_width{1'b0}};
    end else if (init_n == 1'b0) begin
      O1111OIO          <= 1'b0;
      II1II110   <= 1'b0;
      IIO1IOI1    <= 1'b0;
      IO11lI1I  <= 1'b0;
      I1I0Il01         <= 1'b0;
      lII0I0IO        <= 1'b0;
      OI0IIlOI   <= 1'b0;
      lOOO0II0   <= 1'b0;
      lO1I0O01      <= {addr_width{1'b0}};
      lIlIlI0I      <= {addr_width{1'b0}};
      l00I11IO       <= {addr_width{1'b0}};
    end else begin
      O1111OIO          <= IOII01OO;
      II1II110   <= Il1II0OO;
      IIO1IOI1    <= lllOlIIO;
      IO11lI1I  <= OOOlII0I;
      I1I0Il01         <= OIOIOIl0;
      lII0I0IO        <= II11llOI;
      OI0IIlOI   <= lIOOlOOO;
      lOOO0II0   <= Il00Ol1I;
      lO1I0O01      <= O11II00I;
      lIlIlI0I      <= Il1lOlIO;
      l00I11IO       <= l0l1IIOI;
    end
  end

  assign empty = ~O1111OIO;
  assign almost_empty = ~II1II110;
  assign half_full = IIO1IOI1;
  assign almost_full = IO11lI1I;
  assign full = I1I0Il01;
  assign error = lII0I0IO;
  assign wr_addr = lO1I0O01;
  assign rd_addr = lIlIlI0I;
  assign wrd_count = l00I11IO;
  assign nxt_empty_n = IOII01OO | ~init_n;
  assign nxt_full    = OIOIOIl0    &  init_n;
  assign nxt_error   = II11llOI   &  init_n;

endmodule
