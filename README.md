# CMOD-S7-MIPS-SINGLE

> **Status:** Completed on 2026-06-18

Digilent Cmod S7-25 보드를 대상으로 단일 사이클 32-bit MIPS Processor를 Verilog RTL로 구현하고, Vivado 기반 기능 검증 및 FPGA timing analysis를 수행한 프로젝트입니다.

## 개발 환경

* Board: Digilent Cmod S7-25
* FPGA: Xilinx Spartan-7
* Tool: Xilinx Vivado 2019.2
* HDL: Verilog

## 프로젝트 목표

1. Logisim에서 설계 및 검증한 단일 사이클 32-bit MIPS Processor를 Verilog RTL로 재구성
2. 기본 명령어 및 사용자 정의 명령어에 대한 behavioral simulation 검증
3. Cmod S7-25 FPGA 환경에서 synthesis 및 implementation 기반 timing analysis 수행
4. Clock period 변화에 따른 WNS, pass/fail, 최대 동작 주파수 추정

## 지원 명령어

본 단일 사이클 MIPS Processor는 다음 명령어를 지원합니다.

* R-type: sub, or, slt, abs
* I-type: lw, sw, beq, bne, addi, ori
* J-type: j

## 주요 RTL 모듈

* alu: AND, OR, ADD, SUB, SLT, ABS 연산 수행
* alu_decoder: ALUOp와 funct 필드를 해석하여 ALUControl 생성
* main_decoder: opcode를 해석하여 주요 제어 신호 생성
* controller: main_decoder와 alu_decoder를 통합한 제어부
* regfile: 32개의 32-bit 범용 레지스터 구현
* imem: basic_test.hex 기반 instruction memory
* dmem: load/store 명령어를 위한 data memory
* datapath: PC, register file, ALU, immediate extension, branch/jump 경로 구성
* top_mips: 단일 사이클 MIPS Processor core 최상위 모듈
* top_mips_timing: FPGA 보드 I/O 및 timing constraint 적용을 위한 wrapper 모듈

## 테스트 프로그램

basic_test.hex에는 15개 명령어로 구성된 테스트 프로그램을 저장하였습니다. 해당 프로그램은 다음 기능을 검증합니다.

* addi를 통한 상수 및 음수 immediate 처리
* abs 사용자 정의 명령어 검증
* ori의 zero extension 검증
* R-type 연산 sub, or, slt 검증
* sw/lw를 통한 data memory write/read 검증
* beq, bne에 의한 branch 동작 검증
* j 명령어에 의한 jump 및 skip 동작 검증

## Behavioral Simulation

테스트벤치 tb_top_mips를 사용하여 top_mips를 DUT로 검증하였습니다.

검증 항목은 다음과 같습니다.

* reset 이후 PC, register file, data memory 초기화 확인
* basic_test.hex instruction memory 적재 확인
* PC 증가 및 instruction fetch 확인
* ALU 결과 및 register write-back 확인
* sw/lw memory access 확인
* beq, bne, j에 의한 control flow 변경 확인
* skip되어야 하는 명령어가 register file에 write하지 않는지 확인

최종적으로 register file과 data memory의 결과가 예상값과 일치하여 behavioral simulation을 통과하였습니다.

## FPGA Constraint

Cmod S7-25 보드의 XDC constraint를 사용하여 top_mips_timing의 포트를 보드 I/O에 연결하였습니다.

* clk: 보드 system clock 입력 gclk
* reset: push button btn[0]
* done: 실행 완료 표시용 LED led[1]

Clock period constraint를 변경하며 synthesis 및 implementation timing analysis를 수행하였습니다.

## Synthesis Timing Result

Synthesis 기반 timing analysis에서는 clock period를 단계적으로 줄이며 WNS를 확인하였습니다.

| 순번 | Clock Period (ns) | Clock Frequency (MHz) | WNS (ns) | Pass/Fail |
| -: | ----------------: | --------------------: | -------: | --------- |
|  1 |             83.33 |                 12.00 |   71.155 | Pass      |
|  2 |             15.00 |                 66.67 |    2.825 | Pass      |
|  3 |             12.50 |                 80.00 |    0.325 | Pass      |
|  4 |             12.00 |                 83.33 |   -0.175 | Fail      |

Synthesis 기준 최대 동작 주파수는 약 82.14 MHz로 추정됩니다.

## Implementation Timing Result

Implementation 기반 timing analysis에서는 placement와 routing이 반영된 실제 FPGA 구현 조건에서 timing을 확인하였습니다.

| 순번 | Clock Period (ns) | Clock Frequency (MHz) | WNS (ns) | Pass/Fail |
| -: | ----------------: | --------------------: | -------: | --------- |
|  1 |             12.50 |                 80.00 |    0.391 | Pass      |
|  2 |             12.25 |                 81.63 |    0.016 | Pass      |
|  3 |             12.00 |                 83.33 |   -0.667 | Fail      |

Implementation 기준 최대 동작 주파수는 81.63 MHz와 83.33 MHz 사이에 존재하며, 약 82 MHz 수준으로 판단됩니다.

## 현재 진행 상황

* Cmod S7-25 Vivado 프로젝트 구성 완료
* XDC constraint 설정 완료
* basic_test.hex 작성 완료
* 단일 사이클 MIPS RTL 모듈 작성 완료
* top_mips 기반 behavioral simulation 완료
* top_mips_timing wrapper 작성 완료
* synthesis timing analysis 완료
* implementation timing analysis 완료
* 단일 사이클 MIPS Processor 기능 및 timing 검증 완료

## 향후 작업

* 비트스트림 FPGA 보드 다운로드 및 검증