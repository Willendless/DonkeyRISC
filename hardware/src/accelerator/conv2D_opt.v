module conv2D_opt #(
    parameter AWIDTH  = 32,
    parameter DWIDTH  = 32,
    parameter WT_DIM  = 3
) (
    input clk,
    input rst,

    // Control/Status signals
    input start,
    output idle,
    output done,

    // Scalar signals
    input  [31:0]       fm_dim,
    input  [31:0]       wt_offset,
    input  [31:0]       ifm_offset,
    input  [31:0]       ofm_offset,

    // Read Request Address channel
    output [AWIDTH-1:0] req_read_addr,
    output              req_read_addr_valid,
    input               req_read_addr_ready,
    output [31:0]       req_read_len, // burst length

    // Read Response channel
    input [DWIDTH-1:0]  resp_read_data,
    input               resp_read_data_valid,
    output              resp_read_data_ready,

    // Write Request Address channel
    output [AWIDTH-1:0] req_write_addr,
    output              req_write_addr_valid,
    input               req_write_addr_ready,
    output [31:0]       req_write_len, // burst length

    // Write Request Data channel
    output [DWIDTH-1:0] req_write_data,
    output              req_write_data_valid,
    input               req_write_data_ready,

    // Write Response channel
    input                resp_write_status,
    input                resp_write_status_valid,
    output               resp_write_status_ready
);

    wire compute_idle;
    // TODO: Your code to implement an optimized conv2D hardware generator
    wire start_q;
    REGISTER_R_CE #(.N(1), .INIT(0)) start_reg (
        .q(start_q),
        .d(1'b1),
        .ce(start),
        .rst(rst | (done & ~start)),
        .clk(clk)
    );

    REGISTER_R_CE #(.N(1), .INIT(0)) done_reg (
        .q(done),
        .d(1'b1),
        .ce(start_q & compute_idle),
        .rst(rst | (done & start)),
        .clk(clk)
    );

    assign idle = compute_idle;

    conv2D_opt_compute #(.AWIDTH(AWIDTH),
                         .DWIDTH(DWIDTH),
                         .WT_DIM(WT_DIM)
    ) conv2D (
        .clk(clk),
        .rst(rst | done & ~start),

        .start(start),
        .idle(compute_idle),

        .fm_dim(fm_dim),
        .wt_offset(wt_offset),
        .ifm_offset(ifm_offset),
        .ofm_offset(ofm_offset),

        .req_read_addr(req_read_addr),
        .req_read_addr_valid(req_read_addr_valid),
        .req_read_addr_ready(req_read_addr_ready),
        .req_read_len(req_read_len),

        .rdata(resp_read_data),
        .rdata_valid(resp_read_data_valid),
        .rdata_ready(resp_read_data_ready),

        .req_write_addr(req_write_addr),
        .req_write_addr_valid(req_write_addr_valid),
        .req_write_addr_ready(req_write_addr_ready),
        .req_write_len(req_write_len),

        .req_write_data(req_write_data),
        .req_write_data_valid(req_write_data_valid),
        .req_write_data_ready(req_write_data_ready),

        .resp_write_status(resp_write_status),
        .resp_write_status_valid(resp_write_status_valid),
        .resp_write_status_ready(resp_write_status_ready)
    );
// keep it simple

    assign resp_write_status_ready = 1'b1; // keep it simple

endmodule