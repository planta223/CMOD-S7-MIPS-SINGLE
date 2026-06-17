module top_mips (
    input  wire        clk,
    input  wire        reset,

    // debug outputs
    output wire [31:0] pc,
    output wire [31:0] instr,
    output wire [31:0] aluout,
    output wire [31:0] writedata,
    output wire [31:0] readdata
);

    // controller <-> datapath
    wire [5:0] op;
    wire [5:0] funct;

    wire       memtoreg;
    wire       memwrite;
    wire       branch;
    wire       branchneq;
    wire       alusrc;
    wire       regdst;
    wire       regwrite;
    wire       jump;
    wire       zeroext;
    wire [2:0] alucontrol;

    // instruction memory
    wire [23:0] imem_addr;

    // -------------------------
    // Controller
    // -------------------------
    controller controller_inst (
        .op(op),
        .funct(funct),

        .memtoreg(memtoreg),
        .memwrite(memwrite),
        .branch(branch),
        .branchneq(branchneq),
        .alusrc(alusrc),
        .regdst(regdst),
        .regwrite(regwrite),
        .jump(jump),
        .zeroext(zeroext),
        .alucontrol(alucontrol)
    );

    // -------------------------
    // Datapath
    // -------------------------
    datapath datapath_inst (
        .clk(clk),
        .reset(reset),

        .memtoreg(memtoreg),
        .branch(branch),
        .branchneq(branchneq),
        .alusrc(alusrc),
        .regdst(regdst),
        .regwrite(regwrite),
        .jump(jump),
        .zeroext(zeroext),
        .alucontrol(alucontrol),

        .imem_addr(imem_addr),
        .instr(instr),

        .aluout(aluout),
        .writedata(writedata),
        .readdata(readdata),

        .op(op),
        .funct(funct),

        .pc(pc)
    );

    // -------------------------
    // Instruction Memory
    // -------------------------
    imem imem_inst (
        .addr(imem_addr),
        .instr(instr)
    );

    // -------------------------
    // Data Memory
    // -------------------------
    dmem dmem_inst (
        .clk(clk),
        .we(memwrite),
        .addr(aluout[7:0]),
        .wd(writedata),
        .rd(readdata)
    );

endmodule