# CMOD-S7-MIPS-SINGLE

Digilent Cmod S7-25 보드를 사용하여 MIPS Single Processor를 구현합니다.


## 개발 환경

- Board: Digilent Cmod S7-25
- FPGA: Xilinx Spartan-7
- Tool: Xilinx Vivado 2019.2
- HDL: Verilog


## 프로젝트 목표

목표 1. 기본 명령어 기능 검증
목표 2. FPGA 합성/구현 기반 타이밍 검증
목표 3. 사용자 정의 벤치마크 프로그램 검증


## 현재 진행 상황

top_uart_mips, top_uart_hello, uart_tx 모듈 작성 및 비트스트림 테스트 완료 - 전체적 기능 파악 및 보드 검증 필요
mem/basic_test.hex 작성 - 추후 테스트 시나리오
alu, main_decoder, alu_decoder, controller 모듈 작성 - 전체적 기능 검증 필요