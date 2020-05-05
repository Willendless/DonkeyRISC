`include "conv2D_pe.v"
`include "../EECS151.v"
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

    // Scalar input signals
    input  [31:0] fm_dim,
    input  [31:0] wt_offset,
    input  [31:0] ifm_offset,
    input  [31:0] ofm_offset,

    // Read Request Address channel
    output [AWIDTH-1:0]  req_read_addr,
    output               req_read_addr_valid,
    input                req_read_addr_ready,
    output [31:0]        req_read_len, // burst length

    // Read Request Data channel
    input  [DWIDTH-1:0] rdata,
    input               rdata_valid,
    output              rdata_ready,

    // Write Request Address channel
    output [AWIDTH-1:0]  req_write_addr,
    output               req_write_addr_valid,
    input                req_write_addr_ready,
    output [31:0]        req_write_len, // burst length

    // Write Request Data channel
    output [DWIDTH-1:0]  req_write_data,
    output               req_write_data_valid,
    input                req_write_data_ready,

    // Write Response channel
    input                resp_write_status,
    input                resp_write_status_valid,
    output               resp_write_status_ready 
);

    // read data from io_mem
    wire [DWIDTH-1:0] fifo_deq_read_data;
    wire fifo_deq_read_data_valid, fifo_deq_read_data_ready;
    wire fifo_rdata_fire;
    fifo #(.WIDTH(DWIDTH), .LOGDEPTH(10)) data_in_fifo(
        .clk(clk),
        .rst(rst),

        .enq_valid(rdata_valid),
        .enq_data(rdata),
        .enq_ready(rdata_ready),

        .deq_valid(fifo_deq_read_data_valid),
        .deq_data(fifo_deq_read_data),
        .deq_ready(fifo_deq_read_data_ready)
    );

    // write data to io_mem
    wire [DWIDTH-1:0] fifo_enq_write_data;
    wire fifo_enq_write_data_valid, fifo_enq_write_data_ready;
    fifo #(.WIDTH(DWIDTH), .LOGDEPTH(10)) data_out_fifo(
        .clk(clk),
        .rst(rst),

        .enq_valid(fifo_enq_write_data_valid),
        .enq_data(fifo_enq_write_data),
        .enq_ready(fifo_enq_write_data_ready),

        .deq_valid(req_write_data_valid),
        .deq_data(req_write_data),
        .deq_ready(req_write_data_ready)
    );


    localparam STATE_IDLE       = 3'b000;
    localparam STATE_LOAD_WT    = 3'b001;
    localparam STATE_LOAD_FM    = 3'b010;
    localparam STATE_LAST_WRITE = 3'b011;
    localparam STATE_STORE_FM   = 3'b100;

    // state register
    wire [2:0] state_q;
    reg  [2:0] state_d;

    REGISTER_R #(.N(3), .INIT(STATE_IDLE)) state_reg (
        .q(state_q),
        .d(state_d),
        .rst(rst),
        .clk(clk)
    );

   // m index register: 0 --> WT_DIM - 1
    wire [31:0] m_cnt_d, m_cnt_q;
    wire m_cnt_ce, m_cnt_rst;

    REGISTER_R_CE #(.N(32), .INIT(0)) m_cnt_reg (
        .q(m_cnt_q),
        .d(m_cnt_d),
        .ce(m_cnt_ce),
        .rst(m_cnt_rst),
        .clk(clk)
    );

    wire [31:0] n_cnt_d, n_cnt_q;
    wire n_cnt_ce, n_cnt_rst;

    REGISTER_R_CE #(.N(32), .INIT(0)) n_cnt_reg (
        .q(n_cnt_q),
        .d(n_cnt_d),
        .ce(n_cnt_ce),
        .rst(n_cnt_rst),
        .clk(clk)
    );

    wire [31:0] x_cnt_d, x_cnt_q;
    wire x_cnt_ce, x_cnt_rst;
    REGISTER_R_CE #(.N(32), .INIT(0)) x_cnt_reg (
        .q(x_cnt_q),
        .d(x_cnt_d),
        .ce(x_cnt_ce),
        .rst(x_cnt_rst),
        .clk(clk)
    );

    wire [31:0] y_cnt_d, y_cnt_q;
    wire y_cnt_ce, y_cnt_rst;
    REGISTER_R_CE #(.N(32), .INIT(0)) y_cnt_reg (
        .q(y_cnt_q),
        .d(y_cnt_d),
        .ce(y_cnt_ce),
        .rst(y_cnt_rst),
        .clk(clk)
    );


    wire [31:0] write_counter_d, write_counter_q;
    wire write_counter_ce, write_counter_rst;
    REGISTER_R_CE #(.N(32)) write_counter (
        .q(write_coutner_q),
        .d(write_counter_d),
        .ce(write_coutner_ce),
        .rst(write_coutner_rst),
        .clk(clk)
    );

    wire rdata_addr_valid_reg_d, rdata_addr_valid_reg_q;
    wire rdata_addr_valid_reg_rst, rdata_addr_valid_reg_ce;
    REGISTER_R_CE #(.N(1)) rdata_addr_valid_reg (
        .q(rdata_addr_valid_req_q),
        .d(rdata_addr_valid_reg_d),
        .ce(rdata_addr_valid_reg_ce),
        .rst(rdata_addr_valid_reg_rst),
        .clk(clk)
    );

    wire wdata_addr_valid_reg_d, wdata_addr_valid_reg_q;
    wire wdata_addr_valid_reg_rst, wdata_addr_valid_reg_ce;
    REGISTER_R_CE #(.N(1)) wdata_reg (
        .q(wdata_addr_valid_reg_q),
        .d(wdata_addr_valid_reg_d),
        .ce(wdata_addr_valid_reg_ce),
        .rst(wdata_addr_valid_reg_rst),
        .clk(clk)
    );

    // Generate instances of PE
    wire [DWIDTH-1:0] pe_weight_data, pe_fm_data;
    wire pe_fm_data_valid;

    wire [DWIDTH-1:0] pe_data_outputs[WT_DIM-1:0];
    wire pe_data_valids[WT_DIM-1:0];
    wire pe_rst;
    genvar i;
    generate
        for (i = 0; i < WT_DIM; i = i + 1) begin:PE
            conv2D_pe #(.AWIDTH(AWIDTH),
                        .DWIDTH(DWIDTH),
                        .WT_DIM(WT_DIM)) pe (
                            .clk(clk),
                            .rst(pe_rst),
                            .index_i(i),
                            .fm_dim(fm_dim),
                            .pe_weight_data_i(pe_weight_data),
                            .pe_weight_data_valid(pe_weight_data_valid),
                            .pe_fm_data_i(pe_fm_data),
                            .pe_fm_data_valid(pe_fm_data_valid),
                            .pe_data_o(pe_data_outputs[i]),
                            .pe_data_valid(pe_data_valids[i]));
        end
    endgenerate

    // Generate fifo for each pe
    // LOGDEPTH: 2^5 = 32
    // enq
    wire pe_fifo_enq_ready[WT_DIM-1:0] ;
    // deq
    wire pe_fifo_deq_ready[WT_DIM-1:0];
    wire pe_fifo_deq_valids[WT_DIM-1:0];
    wire [DWIDTH-1:0] pe_fifo_deq_datas[WT_DIM-1:0];

    generate
        for (i = 0; i < WT_DIM; i = i + 1) begin:FIFO
            fifo #(.WIDTH(32), .LOGDEPTH(5)) fifo (
                .clk(clk),
                .rst(rst),

                .enq_valid(pe_data_valids[i]),
                .enq_data(pe_data_outputs[i]),
                .enq_ready(pe_fifo_enq_ready[i]),

                .deq_valid(pe_fifo_deq_valids[i]),
                .deq_data(pe_fifo_deq_datas[i]),
                .deq_ready(pe_fifo_deq_ready[i]));
        end
    endgenerate


    wire halo       = x_cnt_q <= 0 | x_cnt_q > fm_dim | y_cnt_q <= 0 | y_cnt_q > fm_dim;


    always @(*) begin
        state_d = state_q;
        case (state_q)
            STATE_IDLE: begin
                if (start)
                    state_d = STATE_LOAD_WT;
            end
            STATE_LOAD_WT: begin
                if (n_cnt_q == WT_DIM - 1 & m_cnt_q == WT_DIM - 1 & fifo_rdata_fire)
                    state_d = STATE_LOAD_FM;
            end
            STATE_LOAD_FM: begin
                if (x_cnt_q == fm_dim + 1 & y_cnt_q == fm_dim + 1 & (fifo_rdata_fire | halo))
                    state_d = STATE_LAST_WRITE;
            end
            STATE_LAST_WRITE: begin
                if (write_counter_rst)
                    state_d = STATE_STORE_FM;
            end
            STATE_STORE_FM: begin
                if (~req_write_data_valid)
                    state_d = STATE_IDLE;
            end
        endcase
    end

    // READ DATA CHANNEL
    assign rdata_addr_valid_reg_d = 1;
    assign rdata_addr_valid_reg_ce = (state_d == STATE_LOAD_WT & state_q == STATE_IDLE)
                                    | (state_d == STATE_LOAD_FM & state_q == STATE_LOAD_WT);
    assign rdata_addr_valid_reg_rst = rdata_addr_valid_reg_q & req_read_addr_ready;

    assign req_read_addr            = (state_q == STATE_LOAD_WT) ? wt_offset
                                        : (state_q == STATE_LOAD_FM) ? ifm_offset : 0;
    assign req_read_addr_valid      = rdata_addr_valid_reg_q;
    assign req_read_len             = (state_q == STATE_LOAD_WT) ? WT_DIM * WT_DIM
                                        : (state_q == STATE_LOAD_FM) ? fm_dim * fm_dim : 0;

    // data from read fifo to pe
    assign fifo_rdata_fire            = fifo_deq_read_data_ready & fifo_deq_read_data_valid;
    assign fifo_deq_read_data_ready = (state_q == STATE_LOAD_WT)
                                        | (state_q == STATE_LOAD_FM & ~halo);
    // load weight
    assign pe_weight_data_valid     = (state_q == STATE_LOAD_WT)
                                        & fifo_rdata_fire;
    assign pe_weight_data           = fifo_deq_read_data;

    assign m_cnt_d      = m_cnt_q + 1;
    assign m_cnt_ce     = (state_q == STATE_LOAD_WT) & fifo_rdata_fire;
    assign m_cnt_rst    = ((n_cnt_q == WT_DIM - 1) & (m_cnt_q == WT_DIM - 1) & fifo_rdata_fire) | rst;

    assign n_cnt_d      = n_cnt_q + 1;
    assign n_cnt_ce     = (state_q == STATE_LOAD_WT) & fifo_rdata_fire;
    assign n_cnt_rst    = (n_cnt_q == WT_DIM - 1 & fifo_rdata_fire) | rst;


    // load fm
    assign pe_fm_data_valid         = ((state_q == STATE_LOAD_FM) && (state_q == STATE_LAST_WRITE))
                                        & fifo_rdata_fire;
    assign pe_fm_data               = fifo_deq_read_data;

    assign halo         = (x_cnt_q == 32'b0) | (y_cnt_q == 32'b0) | (x_cnt_q == fm_dim + 1) | (y_cnt_q == fm_dim + 1);

    assign x_cnt_d      = x_cnt_q + 1;
    assign x_cnt_ce     = (state_q == STATE_LOAD_FM) & (fifo_rdata_fire | halo);
    assign x_cnt_rst    = (state_q == STATE_LOAD_FM & x_cnt_q == fm_dim + 1 & (fifo_rdata_fire | halo)) | rst;

    assign y_cnt_d      = y_cnt_q + 1;
    assign y_cnt_ce     = (state_q == STATE_LOAD_FM) & (x_cnt_q == fm_dim + 1) & (fifo_rdata_fire | halo);
    assign y_cnt_rst    = (state_q == STATE_LOAD_FM & x_cnt_q == fm_dim + 1 & y_cnt_q == fm_dim + 1 & (fifo_rdata_fire | halo)) | rst;

    // data from pe to pe_fifo
    generate
        for (i = 0; i < WT_DIM; i = i + 1) begin
            assign pe_fifo_enq_ready[i] = (state_q == STATE_LAST_WRITE) | (state_q == STATE_LOAD_FM);
        end
    endgenerate

    // data from pe_fifo to write fifo
    reg pe_data_valid;
    reg [DWIDTH-1:0] pe_data_out;
    wire pe_data_fire;

    integer j;
    always @(*) begin
        pe_data_valid = 1'b0;
        for (j = 0; j < WT_DIM; j = j + 1) begin
            pe_data_valid = pe_data_valid & pe_fifo_deq_valids[i];
        end
    end

    generate
        for (i = 0; i < WT_DIM; i = i + 1) begin
            assign pe_fifo_deq_ready[i] = ((state_q == STATE_LOAD_FM)
                                       | (state_q == STATE_LAST_WRITE))
                                       & pe_data_valid
                                       & fifo_enq_write_data_ready;
        end
    endgenerate

    always @(*) begin
        pe_data_out = 32'b0;
        for (j = 0; j < WT_DIM; j = j + 1) begin
            pe_data_out = pe_fifo_deq_datas[j];
        end
        
    end

    assign pe_data_fire                 = pe_data_valid
                                          & ((state_q == STATE_LOAD_FM) | (state_q == STATE_LAST_WRITE))
                                          & fifo_enq_write_data_ready;
    assign fifo_enq_write_data          = pe_data_out;
    assign fifo_enq_write_data_valid    = pe_data_valid;

    // write counter
    assign write_counter_d      = write_coutner_q + 1;
    assign write_counter_ce     = pe_data_fire;
    assign write_coutner_rst    = (write_counter_q == fm_dim * fm_dim & pe_data_fire) | rst;
    
    
    // data from write fifo to mem
    assign wdata_addr_valid_reg_d   = 1;
    assign wdata_addr_valid_reg_ce  = (state_d == STATE_STORE_FM & state_q == STATE_LAST_WRITE); 
    assign wdata_addr_valid_reg_rst = wdata_addr_valid_reg_d & req_write_addr_ready;


    assign req_write_addr       = ofm_offset;
    assign req_write_addr_valid = wdata_addr_valid_reg_q;
    assign req_write_addr_len   = fm_dim * fm_dim;



    assign req_write_data_valid  = (state_q == STATE_STORE_FM);
    assign req_write_len         = fm_dim * fm_dim; 
    
endmodule // conv2D_opt_compute