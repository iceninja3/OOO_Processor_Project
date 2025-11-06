`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 11/06/2025 12:39:06 AM
// Design Name: 
// Module Name: decode_tb
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: 
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////

module decoder_tb;

    // --- Signals to connect to the DUT ---
    logic [31:0] instruction_in;

    logic [4:0]  rs1_addr_out;
    logic [4:0]  rs2_addr_out;
    logic [4:0]  rd_addr_out;
    logic [31:0] immediate_out; // <-- Corrected to 32 bits
    logic        ALUSrc_out;
    logic [2:0]  ALUOp_out;
    logic        Branch_en_out;
    logic        Jump_en_out;
    logic        MemRead_out;
    logic        MemWrite_out;
    logic        RegWrite_out;
    logic        MemToReg_out;
    
    // --- Instantiate the Device Under Test (DUT) ---
    // (Assuming your file is named 'decoder_logic.sv')
    decode dut (
        .instruction_in(instruction_in),
        .rs1_addr_out(rs1_addr_out),
        .rs2_addr_out(rs2_addr_out),
        .rd_addr_out(rd_addr_out),
        .immediate_out(immediate_out),
        .ALUSrc_out(ALUSrc_out),
        .ALUOp_out(ALUOp_out),
        .Branch_en_out(Branch_en_out),
        .Jump_en_out(Jump_en_out),
        .MemRead_out(MemRead_out),
        .MemWrite_out(MemWrite_out),
        .RegWrite_out(RegWrite_out),
        .MemToReg_out(MemToReg_out)
    );

    // --- Re-usable Test Task ---
    // This is the professional way to do this.
    // It checks every single output for a given instruction.
    task check_instruction(
        // Inputs
        string   test_name,
        logic [31:0] inst,
        // Expected Outputs
        logic [4:0]  exp_rs1, logic [4:0]  exp_rs2, logic [4:0]  exp_rd,
        logic [31:0] exp_imm, logic exp_ALUSrc, logic [2:0]  exp_ALUOp,
        logic exp_Branch, logic exp_Jump, logic exp_MemRead,
        logic exp_MemWrite, logic exp_RegWrite, logic exp_MemToReg
    );
        begin
            $display("--- TEST: %s ---", test_name);
            instruction_in = inst;
            #10; // Wait 10ns for combinational logic to settle

            // Assertions: Check every output signal
            assert (rs1_addr_out == exp_rs1) else $error("rs1_addr failed. Got %h, expected %h", rs1_addr_out, exp_rs1);
            assert (rs2_addr_out == exp_rs2) else $error("rs2_addr failed. Got %h, expected %h", rs2_addr_out, exp_rs2);
            assert (rd_addr_out  == exp_rd)  else $error("rd_addr failed. Got %h, expected %h", rd_addr_out, exp_rd);
            assert (immediate_out == exp_imm) else $error("immediate failed. Got %h, expected %h", immediate_out, exp_imm);
            assert (ALUSrc_out   == exp_ALUSrc) else $error("ALUSrc failed. Got %b, expected %b", ALUSrc_out, exp_ALUSrc);
            assert (ALUOp_out    == exp_ALUOp)  else $error("ALUOp failed. Got %b, expected %b", ALUOp_out, exp_ALUOp);
            assert (Branch_en_out == exp_Branch) else $error("Branch_en failed. Got %b, expected %b", Branch_en_out, exp_Branch);
            assert (Jump_en_out   == exp_Jump) else $error("Jump_en failed. Got %b, expected %b", Jump_en_out, exp_Jump);
            assert (MemRead_out  == exp_MemRead) else $error("MemRead failed. Got %b, expected %b", MemRead_out, exp_MemRead);
            assert (MemWrite_out == exp_MemWrite) else $error("MemWrite failed. Got %b, expected %b", MemWrite_out, exp_MemWrite);
            assert (RegWrite_out == exp_RegWrite) else $error("RegWrite failed. Got %b, expected %b", RegWrite_out, exp_RegWrite);
            assert (MemToReg_out == exp_MemToReg) else $error("MemToReg failed. Got %b, expected %b", MemToReg_out, exp_MemToReg);
        end
    endtask

    // --- Main Test Thread ---
    initial begin
        $display("--- Starting Decoder Testbench ---");

        // Call the task for each of your 13 instructions + NOP
        // Format: check_instruction(name, inst, rs1, rs2, rd, imm, ALUSrc, ALUOp, Br, J, MR, MW, RW, MTR);

        // NOP (all zeros)
        check_instruction("NOP", 32'h00000000, 0, 0, 0, 0, 0, 3'b111, 0, 0, 0, 0, 0, 0);

        // ADDI x5, x0, 154
        check_instruction("ADDI", 32'h09A00293, 0, 0, 5, 32'd154, 1, 3'b010, 0, 0, 0, 0, 1, 0);

        // LUI x2, 0xBEEF
        check_instruction("LUI", 32'h000BEEF37, 0, 0, 2, 32'hBEEF000, 0, 3'b100, 0, 0, 0, 0, 1, 0);
        
        // ORI x3, x0, 0xBAD
        check_instruction("ORI", 32'hBAD00193, 0, 0, 3, 32'h00000BAD, 1, 3'b010, 0, 0, 0, 0, 1, 0);
        
        // SLTIU x4, x0, 0x1
        check_instruction("SLTIU", 32'h00103213, 0, 0, 4, 32'd1, 1, 3'b010, 0, 0, 0, 0, 1, 0);
        
        // SRA x7, x6, x5
        check_instruction("SRA", 32'h405353B3, 6, 5, 7, 0, 0, 3'b001, 0, 0, 0, 0, 1, 0);
        
        // SUB x8, x7, x6
        check_instruction("SUB", 32'h40638433, 7, 6, 8, 0, 0, 3'b001, 0, 0, 0, 0, 1, 0);
        
        // AND x9, x8, x7
        check_instruction("AND", 32'h007474B3, 8, 7, 9, 0, 0, 3'b001, 0, 0, 0, 0, 1, 0);
        
        // LBU x10, 16(x1)
        check_instruction("LBU", 32'h0100C503, 1, 0, 10, 32'd16, 1, 3'b000, 0, 0, 1, 0, 1, 1);
        
        // LW x11, 32(x1)
        check_instruction("LW", 32'h0200A583, 1, 0, 11, 32'd32, 1, 3'b000, 0, 0, 1, 0, 1, 1);
        
        // SH x5, 8(x6)
        check_instruction("SH", 32'h00531423, 6, 5, 0, 32'd8, 1, 3'b000, 0, 0, 0, 1, 0, 0);
        
        // SW x7, 12(x6)
        check_instruction("SW", 32'h00732623, 6, 7, 0, 32'd12, 1, 3'b000, 0, 0, 0, 1, 0, 0);
        
        // BNE x1, x0, -8 (PC-relative)
        check_instruction("BNE", 32'hFF009CE3, 1, 0, 0, 32'hFFFFFFE0, 0, 3'b011, 1, 0, 0, 0, 0, 0);
        
        // JALR x1, x0, 123 (I-type)
        check_instruction("JALR", 32'h07B000E7, 0, 0, 1, 32'd123, 1, 3'b101, 0, 1, 0, 0, 1, 0);
        
        
        $display("--- All Decoder Tests Passed! ---");
        $finish;
    end
endmodule