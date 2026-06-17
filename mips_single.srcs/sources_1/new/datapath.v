module datapath (
    input  wire        clk,
    input  wire        reset,

    // control signals
    input  wire        memtoreg,
    input  wire        branch,
    input  wire        branchneq,
    input  wire        alusrc,
    input  wire        regdst,
    input  wire        regwrite,
    input  wire        jump,
    input  wire        zeroext,
    input  wire [2:0]  alucontrol,

    // instruction memory interface
    output wire [23:0] imem_addr,
    input  wire [31:0] instr,

    // data memory interface
    output wire [31:0] aluout,
    output wire [31:0] writedata,
    input  wire [31:0] readdata,

    // outputs to controller
    output wire [5:0]  op,
    output wire [5:0]  funct,

    // debug
    output wire [31:0] pc
);

    // PC
    reg [31:0] pc_reg;

    wire [31:0] pc_next;
    wire [31:0] pc_plus4;
    wire [31:0] pc_branch;
    wire [31:0] pc_jump;
    wire [31:0] pc_after_branch;

    // instruction fields
    wire [4:0] rs;
    wire [4:0] rt;
    wire [4:0] rd;
    wire [15:0] imm;
    wire [25:0] jump_addr;

    // register file signals
    wire [4:0]  writereg;
    wire [31:0] rd1;
    wire [31:0] rd2;
    wire [31:0] result;

    // immediate signals
    wire [31:0] signimm;
    wire [31:0] zeroimm;
    wire [31:0] extimm;
    wire [31:0] signimm_shifted;

    // ALU signals
    wire [31:0] srca;
    wire [31:0] srcb;
    wire        zero;

    // branch control
    wire pcsrc;

    // -------------------------
    // PC register
    // -------------------------
    always @(posedge clk or posedge reset) begin
        if (reset) begin
            pc_reg <= 32'd0;
        end else begin
            pc_reg <= pc_next;
        end
    end

    assign pc = pc_reg;

    // Logisim과 동일:
    // PC[31:24]는 버리고, PC[23:0]을 logical right shift 2 하여 Instruction ROM 주소로 사용
    assign imem_addr = pc_reg[23:0] >> 2;

    // -------------------------
    // instruction field decode
    // -------------------------
    assign op        = instr[31:26];
    assign rs        = instr[25:21];
    assign rt        = instr[20:16];
    assign rd        = instr[15:11];
    assign imm       = instr[15:0];
    assign jump_addr = instr[25:0];
    assign funct     = instr[5:0];

    // -------------------------
    // immediate extension
    // -------------------------
    assign signimm = {{16{imm[15]}}, imm};
    assign zeroimm = {16'b0, imm};

    // addi, lw, sw, beq, bne: sign extension
    // ori: zero extension
    assign extimm = zeroext ? zeroimm : signimm;

    // branch offset은 항상 sign-extended immediate를 shift left 2
    assign signimm_shifted = signimm << 2;

    // -------------------------
    // register file
    // -------------------------
    assign writereg = regdst ? rd : rt;
    assign result   = memtoreg ? readdata : aluout;

    regfile rf (
        .clk(clk),
        .we3(regwrite),
        .a1(rs),
        .a2(rt),
        .a3(writereg),
        .wd3(result),
        .rd1(rd1),
        .rd2(rd2)
    );

    assign writedata = rd2;

    // -------------------------
    // ALU
    // -------------------------
    assign srca = rd1;
    assign srcb = alusrc ? extimm : rd2;

    alu alu_inst (
        .a(srca),
        .b(srcb),
        .alucontrol(alucontrol),
        .result(aluout),
        .zero(zero)
    );

    // -------------------------
    // PC next logic
    // -------------------------
    assign pc_plus4  = pc_reg + 32'd4;
    assign pc_branch = pc_plus4 + signimm_shifted;
    assign pc_jump   = {pc_plus4[31:28], jump_addr, 2'b00};

    assign pcsrc = (branch & zero) | (branchneq & ~zero);

    assign pc_after_branch = pcsrc ? pc_branch : pc_plus4;
    assign pc_next         = jump ? pc_jump : pc_after_branch;

endmodule