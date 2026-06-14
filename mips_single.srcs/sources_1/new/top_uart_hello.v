module top_uart_hello (
    input  wire clk,
    output wire uart_tx
);

    reg rst = 1'b1;
    reg [15:0] reset_cnt = 16'd0;

    always @(posedge clk) begin
        if (reset_cnt < 16'd50000) begin
            reset_cnt <= reset_cnt + 1;
            rst <= 1'b1;
        end else begin
            rst <= 1'b0;
        end
    end

    reg start;
    reg [7:0] tx_data;
    wire busy;

    uart_tx #(
        .CLK_FREQ(12000000),
        .BAUD(115200)
    ) uart0 (
        .clk(clk),
        .rst(rst),
        .start(start),
        .data(tx_data),
        .tx(uart_tx),
        .busy(busy)
    );

    localparam MSG_LEN = 12;

    reg [7:0] msg [0:MSG_LEN-1];

    initial begin
        msg[0]  = "H";
        msg[1]  = "E";
        msg[2]  = "L";
        msg[3]  = "L";
        msg[4]  = "O";
        msg[5]  = " ";
        msg[6]  = "M";
        msg[7]  = "I";
        msg[8]  = "P";
        msg[9]  = "S";
        msg[10] = "\r";
        msg[11] = "\n";
    end

    reg [3:0] index;
    reg [23:0] delay_cnt;
    reg [1:0] state;

    localparam S_WAIT  = 2'd0;
    localparam S_SEND  = 2'd1;
    localparam S_HOLD  = 2'd2;
    localparam S_DELAY = 2'd3;

    always @(posedge clk) begin
        if (rst) begin
            start     <= 1'b0;
            tx_data   <= 8'd0;
            index     <= 4'd0;
            delay_cnt <= 24'd0;
            state     <= S_WAIT;
        end else begin
            start <= 1'b0;

            case (state)
                S_WAIT: begin
                    if (!busy) begin
                        tx_data <= msg[index];
                        start   <= 1'b1;
                        state   <= S_HOLD;
                    end
                end

                S_HOLD: begin
                    state <= S_SEND;
                end

                S_SEND: begin
                    if (!busy) begin
                        if (index == MSG_LEN - 1) begin
                            index <= 4'd0;
                            state <= S_DELAY;
                        end else begin
                            index <= index + 1;
                            state <= S_WAIT;
                        end
                    end
                end

                S_DELAY: begin
                    if (delay_cnt == 24'd12000000) begin
                        delay_cnt <= 24'd0;
                        state     <= S_WAIT;
                    end else begin
                        delay_cnt <= delay_cnt + 1;
                    end
                end

                default: begin
                    state <= S_WAIT;
                end
            endcase
        end
    end

endmodule