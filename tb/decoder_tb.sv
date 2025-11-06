`timescale 1ns/1ps

module decoder_tb;

    // setting up signals to connect to DUT
    logic [31:0] test_instruction;
    logic        test_failed = 1'b0; // Flag to track errors

    // wires to capture DUT's outputs
    logic [4:0]  rs1_out;
    logic [4:0]  rs2_out;
    logic [4:0]  rd_out;
    logic [31:0] imm_out;
    logic        ALUSrc_out;
    logic [2:0]  ALUOp_out;
    logic        branch_out;
    logic        jump_out;
    logic        MemRead_out;
    logic        MemWrite_out;
    logic        RegWrite_out;
    logic        MemToReg_out;
    
    // instantiate DUT
    decode dut (
        .inst(test_instruction),
        .rs1(rs1_out),
        .rs2(rs2_out),
        .rd(rd_out),
        .imm(imm_out),
        .ALUSrc(ALUSrc_out),
        .ALUOp(ALUOp_out),
        .branch(branch_out),
        .jump(jump_out),
        .MemRead(MemRead_out),
        .MemWrite(MemWrite_out),
        .RegWrite(RegWrite_out),
        .MemToReg(MemToReg_out)
    );

    // --- Re-usable Test Task ---
    task check_instruction(
        // Inputs
        string   test_name,
        logic [31:0] inst_in,
        // Expected Outputs
        logic [4:0]  exp_rs1, logic [4:0]  exp_rs2, logic [4:0]  exp_rd,
        logic [31:0] exp_imm, logic exp_ALUSrc, logic [2:0]  exp_ALUOp,
        logic exp_branch, logic exp_jump, logic exp_MemRead,
        logic exp_MemWrite, logic exp_RegWrite, logic exp_MemToReg
    );
        begin
            $display("--- TEST: %s ---", test_name);
            test_instruction = inst_in; // Drive the DUT's input
            #10; // Wait 10ns for combinational logic to settle

            // Assertions: Check every output signal
            assert (rs1_out == exp_rs1) else begin $error("rs1 failed. Got %h, expected %h", rs1_out, exp_rs1); test_failed = 1'b1; end
            assert (rs2_out == exp_rs2) else begin $error("rs2 failed. Got %h, expected %h", rs2_out, exp_rs2); test_failed = 1'b1; end
            assert (rd_out  == exp_rd)  else begin $error("rd failed. Got %h, expected %h", rd_out, exp_rd); test_failed = 1'b1; end
            assert (imm_out == exp_imm) else begin $error("imm failed. Got %h, expected %h", imm_out, exp_imm); test_failed = 1'b1; end
            assert (ALUSrc_out   == exp_ALUSrc) else begin $error("ALUSrc failed. Got %b, expected %b", ALUSrc_out, exp_ALUSrc); test_failed = 1'b1; end
            assert (ALUOp_out    == exp_ALUOp)  else begin $error("ALUOp failed. Got %b, expected %b", ALUOp_out, exp_ALUOp); test_failed = 1'b1; end
            assert (branch_out == exp_branch) else begin $error("branch failed. Got %b, expected %b", branch_out, exp_branch); test_failed = 1'b1; end
            assert (jump_out   == exp_jump) else begin $error("jump failed. Got %b, expected %b", jump_out, exp_jump); test_failed = 1'b1; end
            assert (MemRead_out  == exp_MemRead) else begin $error("MemRead failed. Got %b, expected %b", MemRead_out, exp_MemRead); test_failed = 1'b1; end
            assert (MemWrite_out == exp_MemWrite) else begin $error("MemWrite failed. Got %b, expected %b", MemWrite_out, exp_MemWrite); test_failed = 1'b1; end
            assert (RegWrite_out == exp_RegWrite) else begin $error("RegWrite failed. Got %b, expected %b", RegWrite_out, exp_RegWrite); test_failed = 1'b1; end
            assert (MemToReg_out == exp_MemToReg) else begin $error("MemToReg failed. Got %b, expected %b", MemToReg_out, exp_MemToReg); test_failed = 1'b1; end
        end
    endtask


    initial begin
        $display("--- Starting Decoder Testbench ---");

        // Format: check_instruction(name, inst, rs1, rs2, rd, imm, ALUSrc, ALUOp, Br, J, MR, MW, RW, MTR);

        // NOP (all zeros)
        check_instruction("NOP", 32'h00000000, 0, 0, 0, 0, 0, 3'b111, 0, 0, 0, 0, 0, 0);

        // ADDI x5, x0, 154
        check_instruction("ADDI", 32'h09A00293, 0, 0, 5, 32'd154, 1, 3'b010, 0, 0, 0, 0, 1, 0);
        
        // **FIXED LUI INSTRUCTION**
        // LUI x2, 0xBEEF0
        check_instruction("LUI", 32'h0BEEF0137, 0, 0, 2, 32'hBEEF0000, 0, 3'b100, 0, 0, 0, 0, 1, 0);
        
        // ORI x3, x0, 0xBAD (testbench expects 0-extended imm)
        //check_instruction("ORI", 32'hBAD00193, 0, 0, 3, 32'h00000BAD, 1, 3'b010, 0, 0, 0, 0, 1, 0);
        check_instruction("ORI", 32'hBAD06193, 0, 0, 3, 32'h00000BAD, 1, 3'b010, 0, 0, 0, 0, 1, 0);
        
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
        
        // **FIXED BNE INSTRUCTION**
        // BNE x1, x0, -8 
        check_instruction("BNE", 32'hFE009CE3, 1, 0, 0, 32'hFFFFFFF8, 0, 3'b011, 1, 0, 0, 0, 0, 0);
        
        // JALR x1, x0, 123
        check_instruction("JALR", 32'h07B000E7, 0, 0, 1, 32'd123, 1, 3'b101, 0, 1, 0, 0, 1, 0);
        

        // This test now checks our BNE-only logic.
        // BEQ x1, x0, -8 (Should NOT branch)
        check_instruction("BEQ (Should not branch)", 32'hFE008CE3, 1, 0, 0, 32'hFFFFFFF8, 0, 3'b011, 0, 0, 0, 0, 0, 0);

        
        if (test_failed == 1'b0) begin
            $display("tests Passed!!!");
        end else begin
            $display("TESTS FAILED!!");
        end
        
        $finish;
    end
endmodule