module uart_receiver #(
    parameter CLOCK_FREQ = 125_000_000,
    parameter BAUD_RATE  = 115_200
) (
    input clk,
    input rst,

    // Dequeue the received character to the Sink
    output [7:0] data_out,
    output data_out_valid,
    input data_out_ready,

    // Serial bit input
    input serial_in
);
    // See diagram in the lab guide

    localparam SYMBOL_EDGE_TIME    = CLOCK_FREQ / BAUD_RATE;
    localparam SAMPLE_TIME         = SYMBOL_EDGE_TIME / 2;
    localparam CLOCK_COUNTER_WIDTH = $clog2(SYMBOL_EDGE_TIME);

    (* mark_debug = "true" *) wire [9:0] rx_shift_val;
    wire [9:0] rx_shift_next;
    wire rx_shift_ce;

    // LSB to MSB
    REGISTER_CE #(.N(10)) rx_shift (
        .q(rx_shift_val),
        .d(rx_shift_next),
        .ce(rx_shift_ce),
        .clk(clk)
    );

     (* mark_debug = "true" *) wire [3:0] bit_counter_val;
    wire [3:0] bit_counter_next;
    wire bit_counter_rst, bit_counter_ce;

    // Count to 10
    REGISTER_R_CE #(.N(4), .INIT(0)) bit_counter (
        .q(bit_counter_val),
        .d(bit_counter_next),
        .ce(bit_counter_ce),
        .rst(bit_counter_rst),
        .clk(clk)
    );

     (* mark_debug = "true" *) wire [CLOCK_COUNTER_WIDTH-1:0] clock_counter_val;
    wire [CLOCK_COUNTER_WIDTH-1:0] clock_counter_next;
    wire clock_counter_ce;
    wire clock_counter_rst;

    // Keep track of sample time and symbol edge time
    REGISTER_R_CE #(.N(CLOCK_COUNTER_WIDTH), .INIT(0)) clock_counter (
        .q(clock_counter_val),
        .d(clock_counter_next),
        .ce(clock_counter_ce),
        .rst(clock_counter_rst),
        .clk(clk)
    );

    wire is_symbol_edge = (clock_counter_val == SYMBOL_EDGE_TIME - 1);
    wire is_sample_time = (clock_counter_val == SAMPLE_TIME - 1);

    // Note that UART protocol is asynchronous, the dequeue logic should be
    // inpedendent of the symbol/bit sample logic. You don't have to implement
    // a back-pressure handling (i.e., if data_out_ready is LOW for a long time)
    wire data_out_fire = data_out_valid & data_out_ready;

    // UART receiver state machine

    localparam IDLE     = 2'b00; 
    localparam WORK     = 2'b01;
    localparam DONE     = 2'b11;
    
    wire [1:0] state_reg_val;
    reg [1:0] state_reg_next;

    REGISTER_R #(.N(2)) state (
        .q(state_reg_val), 
        .d(state_reg_next), 
        .clk(clk), 
        .rst(rst)
    );

    always @(*) begin
        state_reg_next = state_reg_val;
        case (state_reg_val)
        IDLE: begin
            if (serial_in == 1'b0) state_reg_next = WORK;
        end
        WORK: begin
            if (bit_counter_val == 9) state_reg_next = DONE; 
        end
        DONE: begin
            if (data_out_ready == 1'b1) state_reg_next = IDLE;
        end
        default: ;
        endcase
    end

    assign data_out_valid   = (state_reg_val == DONE);
    assign data_out         = rx_shift_val[8:1];
    
    // clock counter

    assign clock_counter_next   = clock_counter_val + 1;
    assign clock_counter_rst    = (is_symbol_edge == 1'b1);
    assign clock_counter_ce     = (state_reg_val == WORK);

    // bits shifter

    assign rx_shift_next    = serial_in == 1'b1 ? (rx_shift_val | (1'b1 << bit_counter_val))
                                : (rx_shift_val & ~(1'b1 << bit_counter_val));
    assign rx_shift_ce      = (state_reg_val == WORK && is_sample_time);
    
    // counter
    assign bit_counter_next = bit_counter_val + 1;
    assign bit_counter_ce   = (state_reg_val == WORK && is_symbol_edge == 1'b1 && bit_counter_val < 10);
    assign bit_counter_rst  = (state_reg_val == IDLE);
    
endmodule
