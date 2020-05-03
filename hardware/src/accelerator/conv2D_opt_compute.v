`include "conv2D_pe.v"

module conv2D_opt_compute #(
    parameter AWIDTH = 32,
    parameter DWIDTH = 32,
    parameter WT_DIM = 3
) (
    input clk,
    input rst,

    // Control/status signals
    input start,
    output idle,

    // Current OFM(y, x)
    input [31:0] x,
    input [31:0] y,

    // Feature map dimension
    input [31:0] fm_dim,

    // Read data from DMem
    input [DWIDTH-1:0]  rdata,
    input               rdata_valid,
    output              rdata_ready,

    // Write data to mem_opt_if
    output [DWIDTH-1:0] wdata,
    output              wdata_valid 
);

    localparam STATE_IDLE       = 2'b00;
    localparam STATE_READ_WT    = 2'b01;
    localparam STATE_COMPUTE    = 2'b10;
    localparam STATE_DONE       = 2'b11;

    // state register
    wire [1:0] state_q;
    reg  [1:0] state_d;

    REGISTER_R #(.N(2), .INIT(STATE_IDLE)) state_reg (
        .q(state_q),
        .d(state_d),
        .rst(rst),
        .clk(clk)
    );

    wire rdata_fire = rdata_valid & rdata_ready;
    wire halo       = x <= 0 | x > fm_dim | y <= 0 | y > fm_dim;

    always @(*) begin
        state_d = state_q;
        case (state_q)
            STATE_IDLE: begin
                if (start)
                    state_d = STATE_READ_WT;
            end
            // Load WT_DIM x WT_DIM weight elements from DMem
            STATE_READ_WT: begin
                if (x == WT_DIM - 1 & y == WT_DIM - 1 & rdata_fire)
                    state_d = STATE_COMPUTE;
            end
            // One sliding window computation
            STATE_COMPUTE: begin
                if (n_cnt_q == WT_DIM - 1 & m_cnt_q == WT_DIM - 1 & (halo | rdata_fire))
                    state_d = STATE_DONE;
            end
            // Produce OFM(y, x)
            STATE_DONE: begin
                if (x == fm_dim - 1 & y == fm_dim - 1)
                    state_d = STATE_IDLE;
                else
                    state_d = STATE_COMPUTE;
            end
        endcase
    end








    // Generate instances of PE
    genvar i;
    generate
        for (i = 0; i < WT_DIM; i = i + 1) begin:pe
            conv2D_pe #(.AWIDTH(AWIDTH),
                        .DWIDTH(DWIDTH),
                        .WT_DIM(WT_DIM)) pe (

                            .clk(clk),
                            .rst(rst),
                            .state_i(state_q),
                            .x(),
                            .y(),
                            //.load_weights_en(),
                            .index_i(i),
                            .pe_data_i(),
                            .read_data_valid(),
                            .pe_data_o(),
                            .pe_data_valid());
        end
    endgenerate

    // Generate fifo for each pe
    // LOGDEPTH: 2^5 = 32
    generate
        for (i = 0; i < WT_DIM; i = i + 1) begin:FIFO
            fifo #(.WIDTH(32), .LOGDEPTH(5)) fifo (
                .clk(clk),
                .rst(rst),
                .enq_valid(),
                .enq_data(),
                .enq_ready(),
                .deq_valid(),
                .deq_data(),
                .deq_ready());
        end
    endgenerate

    // independent logic to calculate ofm





endmodule // conv2D_opt_compute