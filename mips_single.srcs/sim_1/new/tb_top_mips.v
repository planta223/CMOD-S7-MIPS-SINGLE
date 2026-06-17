`timescale 1ns/1ps

module tb_top_mips;

    reg clk;
    reg reset;

    wire [31:0] pc;
    wire [31:0] instr;
    wire [31:0] aluout;
    wire [31:0] writedata;
    wire [31:0] readdata;

    integer cycle;
    integer errors;
    integer wrote_r9;
    integer wrote_r10;

    top_mips dut (
        .clk(clk),
        .reset(reset),
        .pc(pc),
        .instr(instr),
        .aluout(aluout),
        .writedata(writedata),
        .readdata(readdata)
    );

    // 100 MHz clock: period = 10 ns
    initial begin
        clk = 1'b0;
        forever #5 clk = ~clk;
    end

    // 실행 trace 및 오류 검출용 감시
    always @(posedge clk) begin
        if (reset) begin
            cycle     <= 0;
            wrote_r9  <= 0;
            wrote_r10 <= 0;
        end else begin
            cycle <= cycle + 1;

            // 해당 posedge에서 regwrite가 1이면 현재 명령어 결과가 register file에 write됨
            if (dut.datapath_inst.regwrite &&
                (dut.datapath_inst.writereg == 5'd9)) begin

                wrote_r9 <= 1;
                $display("[ERROR] unexpected write to $9 at cycle=%0d pc=%h instr=%h wd=%h",
                         cycle, pc, instr, dut.datapath_inst.result);
            end

            if (dut.datapath_inst.regwrite &&
                (dut.datapath_inst.writereg == 5'd10)) begin

                wrote_r10 <= 1;
                $display("[ERROR] unexpected write to $10 at cycle=%0d pc=%h instr=%h wd=%h",
                         cycle, pc, instr, dut.datapath_inst.result);
            end
        end
    end

    // 사람이 waveform 없이도 흐름을 볼 수 있는 trace
    always @(negedge clk) begin
        if (!reset) begin
            $display("cycle=%0d pc=%h instr=%h aluout=%h wd=%h rd=%h regwrite=%b memwrite=%b branch=%b bne=%b jump=%b",
                     cycle,
                     pc,
                     instr,
                     aluout,
                     writedata,
                     readdata,
                     dut.datapath_inst.regwrite,
                     dut.dmem_inst.we,
                     dut.datapath_inst.branch,
                     dut.datapath_inst.branchneq,
                     dut.datapath_inst.jump);
        end
    end

    initial begin
        errors    = 0;
        cycle     = 0;
        wrote_r9  = 0;
        wrote_r10 = 0;

        reset = 1'b1;

        // initial block 및 async reset 반영 대기
        #1;

        // -------------------------
        // 초기 상태 검증
        // -------------------------
        check_initial_state();

        // reset 유지 후 해제
        #19;
        reset = 1'b0;

        // 정상이라면 0x38의 addi $11,$0,777 실행 후 다음 PC는 0x3C가 됨.
        wait_until_pc_3c_or_timeout(40);

        // nonblocking assignment 반영 대기
        #1;

        // -------------------------
        // 최종 레지스터 상태 검증
        // -------------------------
        check_reg( 0, 32'h00000000);
        check_reg( 1, 32'h0000000A);
        check_reg( 2, 32'hFFFFFFFB);
        check_reg( 3, 32'h00000005);
        check_reg( 4, 32'h000000F0);
        check_reg( 5, 32'h000000FA);
        check_reg( 6, 32'h00000005);
        check_reg( 7, 32'h00000001);
        check_reg( 8, 32'h00000001);
        check_reg( 9, 32'h00000000);
        check_reg(10, 32'h00000000);
        check_reg(11, 32'h00000309);

        // -------------------------
        // 최종 데이터 메모리 검증
        // -------------------------
        check_mem(8'h00, 32'h00000001);

        // -------------------------
        // skip 명령어 실행 여부 검증
        // -------------------------
        if (wrote_r9 !== 0) begin
            errors = errors + 1;
            $display("[FAIL] $9 was written. beq branch did not skip PC=0x2C correctly.");
        end

        if (wrote_r10 !== 0) begin
            errors = errors + 1;
            $display("[FAIL] $10 was written. jump did not skip PC=0x34 correctly.");
        end

        // -------------------------
        // 최종 PC 검증
        // -------------------------
        if (pc !== 32'h0000003C) begin
            errors = errors + 1;
            $display("[FAIL] final PC expected=0000003C actual=%h", pc);
        end

        // -------------------------
        // 최종 판정
        // -------------------------
        if (errors == 0) begin
            $display("========================================");
            $display("[PASS] Single-cycle MIPS basic_test passed.");
            $display("========================================");
        end else begin
            $display("========================================");
            $display("[FAIL] Single-cycle MIPS basic_test failed. errors=%0d", errors);
            $display("========================================");
            $fatal;
        end

        $stop;
    end

    // -------------------------
    // 초기 상태 검증 task
    // -------------------------
    task check_initial_state;
        begin
            $display("========================================");
            $display("[INFO] Checking initial state...");
            $display("========================================");

            // PC reset 확인
            if (pc !== 32'h00000000) begin
                errors = errors + 1;
                $display("[FAIL] initial PC expected=00000000 actual=%h", pc);
            end else begin
                $display("[ OK ] initial PC = %h", pc);
            end

            // imem 프로그램 로드 확인
            check_imem(6'd0,  32'h2001000A); // addi $1, $0, 10
            check_imem(6'd1,  32'h2002FFFB); // addi $2, $0, -5
            check_imem(6'd2,  32'h00401823); // abs  $3, $2
            check_imem(6'd3,  32'h340400F0); // ori  $4, $0, 240
            check_imem(6'd4,  32'h00242825); // or   $5, $1, $4
            check_imem(6'd5,  32'h00233022); // sub  $6, $1, $3
            check_imem(6'd6,  32'h00C1382A); // slt  $7, $6, $1
            check_imem(6'd7,  32'hAC070000); // sw   $7, 0($0)
            check_imem(6'd8,  32'h8C080000); // lw   $8, 0($0)
            check_imem(6'd9,  32'h15070001); // bne  $8, $7, 1
            check_imem(6'd10, 32'h11070001); // beq  $8, $7, 1
            check_imem(6'd11, 32'h200903E7); // addi $9, $0, 999
            check_imem(6'd12, 32'h0800000E); // j 14
            check_imem(6'd13, 32'h200A0378); // addi $10, $0, 888
            check_imem(6'd14, 32'h200B0309); // addi $11, $0, 777

            // regfile 초기화 확인
            check_reg(0,  32'h00000000);
            check_reg(1,  32'h00000000);
            check_reg(2,  32'h00000000);
            check_reg(9,  32'h00000000);
            check_reg(10, 32'h00000000);
            check_reg(11, 32'h00000000);

            // dmem 초기화 확인
            check_mem(8'h00, 32'h00000000);
        end
    endtask

    // -------------------------
    // Register File 검증 task
    // -------------------------
    task check_reg;
        input [4:0] idx;
        input [31:0] expected;
        reg [31:0] actual;
        begin
            if (idx == 5'd0) begin
                actual = 32'h00000000;
            end else begin
                actual = dut.datapath_inst.rf.rf[idx];
            end

            if (actual !== expected) begin
                errors = errors + 1;
                $display("[FAIL] reg[%0d] expected=%h actual=%h", idx, expected, actual);
            end else begin
                $display("[ OK ] reg[%0d] = %h", idx, actual);
            end
        end
    endtask

    // -------------------------
    // Data Memory 검증 task
    // -------------------------
    task check_mem;
        input [7:0] idx;
        input [31:0] expected;
        reg [31:0] actual;
        begin
            actual = dut.dmem_inst.ram[idx];

            if (actual !== expected) begin
                errors = errors + 1;
                $display("[FAIL] dmem[%0d] expected=%h actual=%h", idx, expected, actual);
            end else begin
                $display("[ OK ] dmem[%0d] = %h", idx, actual);
            end
        end
    endtask

    // -------------------------
    // Instruction Memory 검증 task
    // -------------------------
    task check_imem;
        input [5:0] idx;
        input [31:0] expected;
        reg [31:0] actual;
        begin
            actual = dut.imem_inst.rom[idx];

            if (actual !== expected) begin
                errors = errors + 1;
                $display("[FAIL] imem[%0d] expected=%h actual=%h", idx, expected, actual);
            end else begin
                $display("[ OK ] imem[%0d] = %h", idx, actual);
            end
        end
    endtask

    // -------------------------
    // PC 도달 대기 task
    // -------------------------
    task wait_until_pc_3c_or_timeout;
        input integer max_cycles;
        integer k;
        begin
            k = 0;

            while ((pc !== 32'h0000003C) && (k < max_cycles)) begin
                @(posedge clk);
                #1;
                k = k + 1;
            end

            if (pc !== 32'h0000003C) begin
                errors = errors + 1;
                $display("[FAIL] timeout: PC did not reach 0x3C within %0d cycles. final pc=%h",
                         max_cycles, pc);
            end
        end
    endtask

endmodule