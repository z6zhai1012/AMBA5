//-- modified by xlinxdu, 2022/05/28
`timescale 1ns/1ns
module tb_apb;
  reg         pclk_i       ;
  reg         prst_n_i     ;
                          
  reg  [55:0] cmd_i        ;
  reg         cmd_vld_i    ;
  wire [31:0] cmd_rd_data_o;
                          
  wire [15:0] paddr_o      ;
  wire        pwrite_o     ;
  wire        psel_o       ;
  wire        penable_o    ;
  wire [31:0] pwdata_o     ;
  reg  [31:0] prdata_i     ;
  reg         pready_i     ;
  reg         pslverr_i    ;

initial begin
 // rst; 
  pclk_i   = 0;
  prst_n_i = 1;
  pslverr_i = 0;
  cmd_i = 56'b0;
  cmd_vld_i = 0;
  prdata_i = 32'b0;
  pready_i = 1;
  #20 prst_n_i = 0;
  #20 prst_n_i = 1;

 // cmd_in_wr(cmd_i,56'h01_FF_EE_DD_CC_BB_AA);
    cmd_i     = 56'h01_FF_EE_DD_CC_BB_AA;
    cmd_vld_i = 1   ;
    #20 cmd_vld_i = 0;
    #31 pready_i = 0;
    #80 pready_i = 1;

  #90;
  //cmd_in_rd(cmd_i,56'h00_AA_BB_CC_DD_EE_FF,prdata_i,32'h12_34_56_78);
    cmd_i = 56'h00_AA_BB_CC_DD_EE_FF;
    cmd_vld_i = 1;
    #20 cmd_vld_i = 0;
    #30 pready_i = 0;

    #60 pready_i = 1;
        prdata_i = 32'h12_34_56_78;

    cmd_i = 56'h00_AA_BB_CC_DD_EE_FF;
    cmd_vld_i = 1;
    #20 cmd_vld_i = 0;
    #30 pready_i = 0;

    #50 pready_i = 1;
        prdata_i = 32'h11_22_33_44;


end

always #10 pclk_i = ~pclk_i;

//-- RST
task rst;
  begin
    pclk_i   = 1;
    prst_n_i = 1;
    pslverr_i = 0;
    cmd_i = 56'b0;
    cmd_vld_i = 0;
    prdata_i = 32'b0;
    pready_i = 1;
    #20 prst_n_i = 0;
    #10 prst_n_i = 1;
    //cmd_i = 56'h01_FF_EE_DD_CC_BB_Ab;
  end
endtask

//-- write
task cmd_in_wr;
  output [55:0] cmd;
  input  [55:0] data;

  begin
    cmd     = data;
    cmd_vld_i = 1   ;
    #20 cmd_vld_i = 0;
    #20 pready_i = 0;
    #40 pready_i = 1;
  end
endtask

//-- read
task cmd_in_rd;
  output [55:0] cmd;
  input  [55:0] data ;
  output [31:0] prdata;
  input  [31:0] rd_data;

  begin
    cmd = data;
    cmd_vld_i = 1;
    #20 cmd_vld_i = 0;
    #20 pready_i = 0;
    #40 pready_i = 1;
        prdata = rd_data;
  end
endtask
initial begin
  #1000 $finish;
end
apb tb_apb(
            .pclk_i       (pclk_i       ),
            .prst_n_i     (prst_n_i     ),
            .cmd_i        (cmd_i        ),
            .cmd_vld_i    (cmd_vld_i    ),
            .cmd_rd_data_o(cmd_rd_data_o),
            .paddr_o      (paddr_o      ),
            .pwrite_o     (pwrite_o     ),
            .psel_o       (psel_o       ),
            .penable_o    (penable_o    ),
            .pwdata_o     (pwdata_o     ),
            .prdata_i     (prdata_i     ),
            .pready_i     (pready_i     ),
            .pslverr_i    (pslverr_i    )
          );


initial begin
  $fsdbDumpfile("apb.fsdb");
  $fsdbDumpvars            ;
  $fsdbDumpMDA             ;
end

endmodule
