`timescale 1ns/1ps
 
module tb_ripple_adder;
    parameter ADDR_WIDTH = 8;  // Now works with any width
    parameter INPUT_A_FILE = "Operand_A_Binary_.csv";
    parameter INPUT_B_FILE = "Operand_B_Binary_.csv";
    parameter INPUT_OP_FILE = "Operation_binary.csv";
    parameter INPUT_MODE_FILE = "Format_binary.csv";
    parameter EXPECTED_SUM_FILE = "Binary_Result.csv";
    parameter EXPECTED_CARRY_FILE = "Carry.csv";
    // Declare signals
    reg [ADDR_WIDTH-1:0] A, B;
    reg add_sub_sel, sm2sel;
    wire [ADDR_WIDTH-1:0] fa_sum;
    wire fa_carry;
    // Testbench variables (CHANGED TO INTEGER)
    integer fa, fb, fop, fmode, fsum, fcarry;
    integer test_count = 0;
    integer error_count = 0;
    integer scan_ret;
    // Instantiate DUT
  farc_addsub #(.ADDER_WIDTH(ADDR_WIDTH)) uut (
        .fa_a_in(A),
        .fa_b_in(B),
        .addsub_sel(add_sub_sel),
    	.sm2c_sel(~sm2sel),
        .fa_sum_out(fa_sum),
    	.fa_carry_out(fa_carry),
    	.fa_overflow()    
    );
 
    // Clock generation
    reg clk = 0;
    always #5 clk = ~clk;
 
    initial begin
        reg [ADDR_WIDTH-1:0] expected_sum;
        reg expected_carry;
        // Open files with proper mode (CHANGED TO "r")
        fa = $fopen(INPUT_A_FILE, "r");
        fb = $fopen(INPUT_B_FILE, "r");
        fop = $fopen(INPUT_OP_FILE, "r");
        fmode = $fopen(INPUT_MODE_FILE, "r");
        fsum = $fopen(EXPECTED_SUM_FILE, "r");
        fcarry = $fopen(EXPECTED_CARRY_FILE, "r");
 
        // Enhanced error checking
        if (!fa) $display("Error opening %s", INPUT_A_FILE);
        if (!fb) $display("Error opening %s", INPUT_B_FILE);
        if (!fop) $display("Error opening %s", INPUT_OP_FILE);
        if (!fmode) $display("Error opening %s", INPUT_MODE_FILE);
        if (!fsum) $display("Error opening %s", EXPECTED_SUM_FILE);
        if (!fcarry) $display("Error opening %s", EXPECTED_CARRY_FILE);
        if (!fa || !fb || !fop || !fmode || !fsum || !fcarry) $finish;
 
        // Main test loop (FIXED CONDITION)
        while (!$feof(fa) && !$feof(fb)) begin
            @(negedge clk);
            // Read inputs (ADDED COMMA HANDLING)
            scan_ret = $fscanf(fa, "%b", A);
            scan_ret = $fscanf(fb, "%b", B);
            scan_ret = $fscanf(fop, "%b", add_sub_sel);
            scan_ret = $fscanf(fmode, "%b", sm2sel);
            // Read expected outputs
            scan_ret = $fscanf(fsum, "%b", expected_sum);
            scan_ret = $fscanf(fcarry, "%b", expected_carry);
            @(posedge clk);
            #1;
            // Verification
            test_count++;
            if (fa_sum !== expected_sum || fa_carry !== expected_carry) begin
                error_count++;
                $display("[ERROR] Test %0d:", test_count);
                $display("Inputs: A=%b B=%b OP=%b MODE=%b", 
                        A, B, add_sub_sel, sm2sel);
                $display("Expected: SUM=%b CARRY=%b", 
                        expected_sum, expected_carry);
                $display("Received:  SUM=%b CARRY=%b", 
                        fa_sum, fa_carry);
            end
        end
 
        // Cleanup
        $fclose(fa);
        $fclose(fb);
        $fclose(fop);
        $fclose(fmode);
        $fclose(fsum);
        $fclose(fcarry);
 
        // Results
        $display("\nTest Complete: %0d/%0d passed", 
                test_count-error_count, test_count);
        $finish;
    end
endmodule