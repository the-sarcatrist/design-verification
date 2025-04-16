// ========================================================================
//Filename        : farc_as_tb.v
//Author          : Rahul Prakash Joshi
//Date            : 14-03-2025
// ========================================================================
//Abstract   : Testbench
//             
// ========================================================================

`timescale 1ns/1ps

module farc_as_tb ();

//////////////////////////////////////
// Parameters
//////////////////////////////////////

  parameter CLK_HALF_PER = 10;
  parameter ADDER_WIDTH = 32;
  parameter SM2C = 1; // SM2C = 0 --> 2's Complement, SM2C = 1 --> Sign-Magnitude

//////////////////////////////////////
// reg and wire declaration
//////////////////////////////////////

  reg                         tb_ip_rst_n;   
  reg                         tb_ip_clk;    
  reg                         tb_start_test;
  reg                         tb_error;
  reg                         tb_error_r;
  reg                         adsb_sel_tb;
  reg  [ADDER_WIDTH-1:0]      sum_chk_tb;
  reg  [ADDER_WIDTH-1:0]      farc_a_tb;
  reg  [ADDER_WIDTH-1:0]      farc_b_tb;
  wire [ADDER_WIDTH-1:0]      farc_sum_tb;
  wire                        farc_cout_tb;
  wire [ADDER_WIDTH-1:0]      sm2c_sel_w;
  

  localparam TB_IDLE          = 4'b0000;
  localparam TB_APBP_ADD      = 4'b0001;
  localparam TB_APBN_ADD      = 4'b0010;
  localparam TB_ANBP_ADD      = 4'b0011;
  localparam TB_ANBN_ADD      = 4'b0100;
  localparam TB_APBP_AGBSUB   = 4'b0101;
  localparam TB_APBP_ALBSUB   = 4'b0110;
  localparam TB_ANBP_SUB      = 4'b0111;
  localparam TB_APBN_AGBSUB   = 4'b1000;
  localparam TB_ANBP_ALBSUB   = 4'b1001;
  localparam TB_ANBN_AGBSUB   = 4'b1010;
  localparam TB_ANBN_ALBSUB   = 4'b1011;
  localparam TB_END           = 4'b1100;
   
  reg [3:0] tb_fsm_ps, tb_fsm_ns;

//////////////////////////////////////
// DUT instance
//////////////////////////////////////

  assign sm2c_sel_w = SM2C;

  farc_addsub # (
    .SM2C(SM2C), // SM2C = 0 --> 2's Complement, SM2C = 1 --> Sign-Magnitude
    .ADDER_WIDTH(ADDER_WIDTH)
  ) 
  dut_farc_addsub
  (
    .fa_a_in(farc_a_tb),
    .fa_b_in(farc_b_tb),
    .sm2c_sel(sm2c_sel_w[0]),
    .addsub_sel(adsb_sel_tb),
    .fa_sum_out(farc_sum_tb),
    .fa_carry_out(farc_cout_tb)
  );  


////////////////////////////////////////////////////////////////////////////////
// Initial 
////////////////////////////////////////////////////////////////////////////////

  initial
  begin
    tb_ip_clk      = 1'b0;   
    tb_ip_rst_n    = 1'b0;
    tb_start_test  = 1'b0;
    sum_chk_tb     = 32'd0;
    adsb_sel_tb    = 1'b0;
    repeat(2)@(posedge tb_ip_clk);
    tsk_rst;    
    //repeat(500)@(posedge tb_ip_clk);    
    //$finish;
  end

  // reset
  task tsk_rst;
  begin
    tb_ip_rst_n = 1'b0;
    repeat(2)@(negedge tb_ip_clk);
    tb_ip_rst_n = 1'b1;
  end
  endtask

  // clock
  always
  begin
    # CLK_HALF_PER tb_ip_clk = ~tb_ip_clk; 
  end

  always @(posedge tb_ip_clk or negedge tb_ip_rst_n)
  begin
    if(!tb_ip_rst_n)
      tb_start_test <= 1'b0;
    else if (tb_fsm_ps == TB_END)
      tb_start_test <= 1'b0;
    else
      tb_start_test <= 1'b1;
  end

  always @(posedge tb_ip_clk or negedge tb_ip_rst_n)
  begin
    if(!tb_ip_rst_n)
      tb_error_r <= 1'b0;    
    else
      tb_error_r <= tb_error;
  end

  // TB FSM state transition logic
  always @(posedge tb_ip_clk or negedge tb_ip_rst_n)
  begin
    if(!tb_ip_rst_n)
      tb_fsm_ps <= TB_IDLE;
    else
      tb_fsm_ps <= tb_fsm_ns;
  end

  // FSM NSD and OD
  always @(tb_fsm_ps,tb_start_test,farc_a_tb,farc_b_tb,sum_chk_tb,farc_sum_tb)
  begin
    adsb_sel_tb  = 1'b0;
    farc_a_tb    = 32'd0;
    farc_b_tb    = 32'd0;
    tb_error     = 1'b0;    
    case (tb_fsm_ps)
      TB_IDLE: 
      begin
        if (tb_start_test)
          tb_fsm_ns = TB_APBP_ADD;
        else
          tb_fsm_ns = tb_fsm_ps;
      end

      TB_APBP_ADD:
      begin
        tb_fsm_ns    = TB_APBN_ADD;
        adsb_sel_tb  = 1'b0;
        farc_a_tb    = 32'h00000005;
        farc_b_tb    = 32'h00000003;
        sum_chk_tb   = farc_a_tb + farc_b_tb;
        if (sum_chk_tb == farc_sum_tb) // 0x00000008
          tb_error = 1'b0;
        else 
          tb_error = 1'b1;
      end

      TB_APBN_ADD:
      begin
        tb_fsm_ns    = TB_ANBP_ADD;
        adsb_sel_tb  = 1'b0;
        farc_a_tb    = 32'h00000005;
        farc_b_tb    = 32'h80000002; // -2 = 32'hFFFFFFFE (2C)
        sum_chk_tb   = farc_a_tb + farc_b_tb;
        if (sum_chk_tb == farc_sum_tb) // 0x00000003
          tb_error = 1'b0;
        else 
          tb_error = 1'b1;
      end

      TB_ANBP_ADD:
      begin
        tb_fsm_ns    = TB_ANBN_ADD;
        adsb_sel_tb  = 1'b0;
        farc_a_tb    = 32'h80000005; // -5 = 32'hFFFFFFFB (2C)
        farc_b_tb    = 32'h00000002;
        sum_chk_tb   = farc_a_tb + farc_b_tb;
        if (sum_chk_tb == farc_sum_tb) // 0xFFFFFFFD
          tb_error = 1'b0;
        else 
          tb_error = 1'b1;
      end

      TB_ANBN_ADD:
      begin
        tb_fsm_ns    = TB_APBP_AGBSUB;
        adsb_sel_tb  = 1'b0;
        farc_a_tb    = 32'h80000008; // -8 = 32'hFFFFFFF8 (2C)
        farc_b_tb    = 32'h80000004; // -4 = 32'hFFFFFFFC (2C)
        sum_chk_tb   = farc_a_tb + farc_b_tb;
        if (sum_chk_tb == farc_sum_tb) // 0xFFFFFFF4
          tb_error = 1'b0;
        else 
          tb_error = 1'b1;
      end

      TB_APBP_AGBSUB:
      begin
        tb_fsm_ns    = TB_APBP_ALBSUB;
        adsb_sel_tb  = 1'b1;
        farc_a_tb    = 32'h00000005;
        farc_b_tb    = 32'h00000003;
        sum_chk_tb   = farc_a_tb - farc_b_tb;
        if (sum_chk_tb == farc_sum_tb) // 0x00000002
          tb_error = 1'b0;
        else 
          tb_error = 1'b1;
      end

      TB_APBP_ALBSUB:
      begin
        tb_fsm_ns    = TB_ANBP_SUB;
        adsb_sel_tb  = 1'b1;
        farc_a_tb    = 32'h00000003;
        farc_b_tb    = 32'h00000005;
        sum_chk_tb   = farc_a_tb - farc_b_tb;
        if (sum_chk_tb == farc_sum_tb) // 0xFFFFFFFE
          tb_error = 1'b0;
        else 
          tb_error = 1'b1;
      end

      TB_ANBP_SUB:
      begin
        tb_fsm_ns    = TB_APBN_AGBSUB;
        adsb_sel_tb  = 1'b1;
        farc_a_tb    = 32'h00000009;
        farc_b_tb    = 32'h80000006; // -6 = 32'hFFFFFFFA (2C)
        sum_chk_tb   = farc_a_tb - farc_b_tb;
        if (sum_chk_tb == farc_sum_tb) // 0x0000000F
          tb_error = 1'b0;
        else 
          tb_error = 1'b1;
      end

      TB_APBN_AGBSUB:
      begin
        tb_fsm_ns    = TB_ANBP_ALBSUB;
        adsb_sel_tb  = 1'b1;
        farc_a_tb    = 32'h80000009; // -9 = 32'hFFFFFFF7 (2C)
        farc_b_tb    = 32'h00000006;
        sum_chk_tb   = farc_a_tb - farc_b_tb;
        if (sum_chk_tb == farc_sum_tb) // 0x0FFFFFF1
          tb_error = 1'b0;
        else 
          tb_error = 1'b1;
      end

      TB_ANBP_ALBSUB:
      begin
        tb_fsm_ns    = TB_ANBN_AGBSUB;
        adsb_sel_tb  = 1'b1;
        farc_a_tb    = 32'h80000004; // -4 = 32'hFFFFFFFC (2C)
        farc_b_tb    = 32'h00000009;
        sum_chk_tb   = farc_a_tb - farc_b_tb;
        if (sum_chk_tb == farc_sum_tb) // 0xFFFFFFF3
          tb_error = 1'b0;
        else 
          tb_error = 1'b1;
      end

      TB_ANBN_AGBSUB:
      begin
        tb_fsm_ns    = TB_ANBN_ALBSUB;
        adsb_sel_tb  = 1'b1;
        farc_a_tb    = 32'h80000009; // -9 = 32'hFFFFFFF7 (2C)
        farc_b_tb    = 32'h80000006; // -6 = 32'hFFFFFFFA (2C)
        sum_chk_tb   = farc_a_tb - farc_b_tb;
        if (sum_chk_tb == farc_sum_tb) // 0xFFFFFFFD
          tb_error = 1'b0;
        else 
          tb_error = 1'b1;
      end

      TB_ANBN_ALBSUB:
      begin
        tb_fsm_ns    = TB_END;
        adsb_sel_tb  = 1'b1;
        farc_a_tb    = 32'h80000006; // -6 = 32'hFFFFFFFA (2C)
        farc_b_tb    = 32'h80000009; // -9 = 32'hFFFFFFF7 (2C)
        sum_chk_tb   = farc_a_tb - farc_b_tb;
        if (sum_chk_tb == farc_sum_tb) // 0x00000003
          tb_error = 1'b0;
        else 
          tb_error = 1'b1;
      end

      TB_END:
      begin
        tb_fsm_ns    = TB_END;
        adsb_sel_tb  = 1'b0;
        farc_a_tb    = 32'h00000000;
        farc_b_tb    = 32'h00000000;
        sum_chk_tb   = farc_a_tb - farc_b_tb;
        if (sum_chk_tb == farc_sum_tb) // 0x00000000
          tb_error = 1'b0;
        else 
          tb_error = 1'b1;
      end

      default:
      begin
        tb_fsm_ns    = TB_IDLE;
        adsb_sel_tb  = 1'b1;
        farc_a_tb    = 32'h00000000;
        farc_b_tb    = 32'h00000000;
        tb_error     = 1'b0;
      end
    endcase
  end

endmodule
