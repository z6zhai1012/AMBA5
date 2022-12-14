/*-------------------------------------------------------------
-- modified by xlinxdu, 2022/05/27
-- pclk 50MHz
-- APB3,No pslverr signal
-- cmd_i:56bit;[55:48]:r/w ,8'b0 -> read,8'b1 -> write
               [47:32]:paddr ,
               [31:0]:pwdata
-------------------------------------------------------------*/
module apb
#(
  parameter RD_FLAG        = 8'b0           ,
  parameter WR_FLAG        = 8'b1           ,
  parameter CMD_RW_WIDTH   = 8              ,
  parameter CMD_ADDR_WIDTH = 16             ,
  parameter CMD_DATA_WIDTH = 32             ,
  parameter CMD_WIDTH      = CMD_RW_WIDTH   + 
                             CMD_ADDR_WIDTH + 
                             CMD_DATA_WIDTH
)(
//-- system signal
  input                           pclk_i       ,
  input                           prst_n_i     ,

//-- cmd_in
  input      [CMD_WIDTH-1:0]      cmd_i        ,
  input                           cmd_vld_i    ,
  output reg [CMD_DATA_WIDTH-1:0] cmd_rd_data_o,

//-- apb interface
  output reg [CMD_ADDR_WIDTH-1:0] paddr_o      ,
  output reg                      pwrite_o     ,
  output reg                      psel_o       ,
  output reg                      penable_o    ,
  output reg [CMD_DATA_WIDTH-1:0] pwdata_o     ,
  input      [CMD_DATA_WIDTH-1:0] prdata_i     ,
  input                           pready_i     ,
  input                           pslverr_i
);

//-- FSM state
parameter IDLE   = 3'b001;
parameter SETUP  = 3'b010;
parameter ACCESS = 3'b100;

//-- current state and next state
reg [2:0] cur_state;
reg [2:0] nxt_state;

//-- data buf
reg                      start_flag     ;
reg [CMD_WIDTH-1:0]      cmd_in_buf     ;
reg [CMD_DATA_WIDTH-1:0] cmd_rd_data_buf;


/*-----------------------------------------------\
 --             update cmd_in_buf              --
\-----------------------------------------------*/
always @ (posedge pclk_i or negedge prst_n_i) begin
  if (!prst_n_i) begin
    cmd_in_buf <= {(CMD_WIDTH){1'b0}};
  end
  else if (cmd_vld_i && pready_i) begin
    cmd_in_buf <= cmd_i;
  end
end

/*-----------------------------------------------\
 --             start flag of transfer         --
\-----------------------------------------------*/
always @ (posedge pclk_i or negedge prst_n_i) begin
  if (!prst_n_i) begin
    start_flag <= 1'b0;
  end
  else if (cmd_vld_i && pready_i) begin
    start_flag <= 1'b1;
  end
  else begin
    start_flag <= 1'b0;
  end
end

/*-----------------------------------------------\
 --           update current state             --
\-----------------------------------------------*/
always @ (posedge pclk_i or negedge prst_n_i) begin
  if (!prst_n_i) begin
    cur_state <= IDLE;
  end
  else begin
    cur_state <= nxt_state;
  end
end

/*-----------------------------------------------\
 --               update next state            --
\-----------------------------------------------*/
always @ (*) begin
  case(cur_state)
    IDLE  :if(start_flag)begin
             nxt_state = SETUP;
           end
           else begin
             nxt_state = IDLE;
           end

    SETUP :nxt_state = ACCESS;
          
    ACCESS:if (!pready_i)begin
             nxt_state = ACCESS;
           end
           else if(start_flag)begin
             nxt_state = SETUP;
           end
           else if(!cmd_vld_i && pready_i)begin
             nxt_state = IDLE;
           end
  endcase
end

/*-----------------------------------------------\
 --         update signal of output            --
\-----------------------------------------------*/
always @ (posedge pclk_i or negedge prst_n_i) begin
  if (!prst_n_i) begin
    pwrite_o  <= 1'b0;
    psel_o    <= 1'b0;
    penable_o <= 1'b0;
    paddr_o   <= {(CMD_ADDR_WIDTH){1'b0}};
    pwdata_o  <= {(CMD_DATA_WIDTH){1'b0}};
  end
  
  else if (nxt_state == IDLE) begin
    psel_o    <= 1'b0;
    penable_o <= 1'b0;
  end

  else if(nxt_state == SETUP)begin
    psel_o    <= 1'b1;
    penable_o <= 1'b0;
    paddr_o   <= cmd_in_buf[CMD_WIDTH-CMD_RW_WIDTH-1:CMD_DATA_WIDTH];
    //-- read
    if(cmd_in_buf[CMD_WIDTH-1:CMD_WIDTH-8] == RD_FLAG)begin
      pwrite_o <= 1'b0;
    end
    //-- write
    else begin
      pwrite_o  <= 1'b1;
      pwdata_o  <= cmd_in_buf[CMD_DATA_WIDTH-1:0];
    end
  end

  else if(nxt_state == ACCESS)begin
    penable_o <= 1'b1;
  end
end

/*-----------------------------------------------\
 --            update cmd_rd_data_buf          --
\-----------------------------------------------*/
always @ (posedge pclk_i or negedge prst_n_i) begin
  if (!prst_n_i) begin
    cmd_rd_data_buf <= {(CMD_DATA_WIDTH){1'b0}};
  end
  else if (pready_i && psel_o && penable_o) begin
    cmd_rd_data_buf <= prdata_i;
  end
end

/*-----------------------------------------------\
 --            update cmd_rd_data_o            --
\-----------------------------------------------*/
always @ (posedge pclk_i or negedge prst_n_i) begin
  if (!prst_n_i) begin
    cmd_rd_data_o <= {(CMD_DATA_WIDTH){1'b0}};
  end
  else begin
    cmd_rd_data_o <= cmd_rd_data_buf;
  end
end

endmodule
