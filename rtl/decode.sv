`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 11/06/2025 12:31:41 AM
// Design Name: 
// Module Name: decode
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


module decode (
    input logic [31:0] inst, //32 bit input isntruciton

    output logic [4:0]  rs1,
    output logic [4:0]  rs2, //there are 16 registers
    output logic [4:0]  rd, 


    output logic [31:0] imm, // immediate gets sign extended to 32 bits

    // control signals for EX stage
    output logic ALUSrc,        // 0: ALU B-src=RS2, 1: ALU B-src=Immediate
    output logic [2:0]  ALUOp,  // specifies operation to run for the ALU Controller
    output logic branch,     // 1: Instruction is BNE
    output logic jump,       // 1: Instruction is JALR

    // control Signals for MEM Stage
    output logic MemRead,       // 1: Read from data memory (LW, LBU)
    output logic MemWrite,      // 1: Write to data memory (SW, SH)

    // control Signals for WB Stage
    output logic RegWrite,      // 1: Write result to register file
    output logic MemToReg       // 0: WB result=ALU result, 1: WB result=Mem
);

    logic [6:0] opcode;
    logic [2:0] funct3;
    logic [6:0] funct7;

    assign opcode = inst[6:0];
    assign rd = inst[11:7]; // rd is always in the same place
    assign funct3 = inst[14:12];
    assign rs1 = inst[19:15]; // rs1 is always in the same place
    assign rs2 = inst[24:20]; // rs2 is always in the same place
    assign funct7 = inst[31:25];


    // opcodes for each instruction
    localparam opcode_LUI   = 7'b0110111;
    localparam opcode_ITYPE = 7'b0010011; // ADDI, ORI, SLTIU
    localparam opcode_RTYPE = 7'b0110011; // SUB, SRA, AND
    localparam opcode_LOAD  = 7'b0000011; // LW, LBU
    localparam opcode_STORE = 7'b0100011; // SW, SH
    localparam opcode_BRANCH = 7'b1100011; // BNE
    localparam opcode_JALR  = 7'b1100111;

//13 commands to implement from CA spec

    // combo logic block
    always_comb begin
        // default values for all control signals
        ALUSrc    = 1'b0;
        ALUOp     = 3'b111;
        branch = 1'b0;
        jump   = 1'b0;
        MemRead   = 1'b0;
        MemWrite  = 1'b0;
        RegWrite  = 1'b0;
        MemToReg  = 1'b0;
        imm = 32'b0;

        // set control signals based on opcode of instruction
        case (opcode)
            opcode_LUI: begin
                RegWrite  = 1'b1;
                // Note: ALUSrc is 0, but ALUOp tells ALU to "pass B"
                ALUOp     = 3'b100; // 'LUI' contract
            end

            opcode_ITYPE: begin // ADDI, ORI, SLTIU
                RegWrite  = 1'b1;
                ALUSrc    = 1'b1; // B-src is Immediate
                ALUOp     = 3'b010; // 'I-Type' contract
            end

            opcode_RTYPE: begin // SUB, SRA, AND
                RegWrite  = 1'b1;
                ALUSrc    = 1'b0; // B-src is RS2
                ALUOp     = 3'b001; // 'R-Type' contract
            end

            opcode_LOAD: begin // LW, LBU
                RegWrite  = 1'b1;
                ALUSrc    = 1'b1; // B-src is Immediate
                MemRead   = 1'b1;
                MemToReg  = 1'b1; // Result comes from Memory
                ALUOp     = 3'b000; // 'Load/Store Add' contract
            end

            opcode_STORE: begin // SW, SH
                // RegWrite is 0 (default)
                ALUSrc    = 1'b1; // B-src is Immediate
                MemWrite  = 1'b1;
                ALUOp     = 3'b000; // 'Load/Store Add' contract
            end

            opcode_BRANCH: begin // BNE
                // RegWrite is 0 (default)
                ALUSrc    = 1'b0; // B-src is RS2 (for comparison)
                branch = 1'b1;
                ALUOp     = 3'b011; // 'Branch' contract
            end

            opcode_JALR: begin
                RegWrite  = 1'b1;
                ALUSrc    = 1'b1; // B-src is Immediate
                jump   = 1'b1;
                ALUOp     = 3'b101; // 'JALR Add' contract
            end

            default: begin

            end
        endcase


        // generating Immediate based on diff opcodes
        case (opcode)
            opcode_LUI:
                // U-Type: { imm[31:12], 12'b0 }
                imm = { inst[31:12], 12'b0 };

            opcode_ITYPE,
            opcode_LOAD,
            opcode_JALR:
                // I-Type: Sign-extend imm[11:0]
                imm = { {20{inst[31]}}, inst[31:20] };

            opcode_STORE:
                // S-Type: Sign-extend { imm[11:5], imm[4:0] }
                imm = { {20{inst[31]}}, inst[31:25], inst[11:7] };

            opcode_BRANCH:
                // B-Type: Sign-extend { imm[12], imm[10:5], imm[4:1], 1'b0 }
                imm = { {19{inst[31]}}, inst[31], inst[7], inst[30:25], inst[11:8], 1'b0 };

            // imm set to 0 if R type (which is default here)
            default:
                imm = 32'b0;
        endcase
    end

endmodule