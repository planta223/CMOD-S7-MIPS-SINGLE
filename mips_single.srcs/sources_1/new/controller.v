module controller (
    input  wire [5:0] op,
    input  wire [5:0] funct,
    input  wire       zero,

    output wire       memtoreg,
    output wire       memwrite,
    output wire       pcsrc,
    output wire       alusrc,
    output wire       regdst,
    output wire       regwrite,
    output wire       jump,
    output wire       zeroext,
    output wire [2:0] alucontrol
);

    wire [1:0] aluop;
    wire branch;
    wire branchneq;

    main_decoder md (
        .op(op),
        .regwrite(regwrite),
        .regdst(regdst),
        .alusrc(alusrc),
        .branch(branch),
        .branchneq(branchneq),
        .memwrite(memwrite),
        .memtoreg(memtoreg),
        .aluop(aluop),
        .jump(jump),
        .zeroext(zeroext)
    );

    alu_decoder ad (
        .aluop(aluop),
        .funct(funct),
        .alucontrol(alucontrol)
    );

    assign pcsrc = (branch & zero) | (branchneq & ~zero);

endmodule