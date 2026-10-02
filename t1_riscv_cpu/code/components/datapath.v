
// datapath.v
module datapath (
    input         clk, reset,
    input [1:0]   ResultSrc,
    input         PCSrc, ALUSrc,
    input         RegWrite,
    input [1:0]   ImmSrc,
    input [2:0]   ALUControl,
    output        Zero,
    output [31:0] PC,
    input  [31:0] Instr,
    output [31:0] Mem_WrAddr, Mem_WrData,
    input  [31:0] ReadData,
    output [31:0] Result
);
wire [31:0] PCNext, PCPlus4, PCTarget;
wire        is_lui, is_auipc, is_jalr;
wire [31:0] ImmExt, UImm, SrcA, SrcB, WriteData, ALUResult;
wire [31:0] ALUSrcA, ALUImm, JALRTarget;
 
assign is_lui   = (Instr[6:0] == 7'b0110111);
assign is_auipc = (Instr[6:0] == 7'b0010111);
assign is_jalr  = (Instr[6:0] == 7'b1100111);
 
assign UImm = {Instr[31:12], 12'b0};

// next PC logic
reset_ff #(32) pcreg(clk, reset, PCNext, PC);
adder          pcadd4(PC, 32'd4, PCPlus4);
adder          pcaddbranch(PC, ImmExt, PCTarget);
assign JALRTarget = {ALUResult[31:1], 1'b0};
mux2 #(32)     pcmux(PCPlus4, is_jalr ? JALRTarget : PCTarget, PCSrc, PCNext);

// register file logic
reg_file       rf (clk, RegWrite, Instr[19:15], Instr[24:20], Instr[11:7], Result, SrcA, WriteData);
imm_extend     ext (Instr[31:7], ImmSrc, ImmExt);

// ALU logic
assign ALUSrcA = is_lui ? 32'b0 : (is_auipc ? PC : SrcA);
assign ALUImm  = (is_lui || is_auipc) ? UImm : ImmExt;

mux2 #(32)     srcbmux(WriteData, ALUImm, ALUSrc, SrcB);
alu            alu (ALUSrcA, SrcB, ALUControl, ALUResult, Zero);
mux3 #(32)     resultmux(ALUResult, ReadData, PCPlus4, ResultSrc, Result);

assign Mem_WrData = WriteData;
assign Mem_WrAddr = ALUResult;

endmodule

