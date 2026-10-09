// cdc_top.v
//
// Top-level wrapper: ties src_fsm, both edge_detect_sync instances,
// ACK generation, and data_reg together across the two clock domains.

module cdc_top #(
    parameter DATA_WIDTH = 8
) (
    // source (sender) domain
    input  wire                   src_clk,
    input  wire                   src_rst_n,
    input  wire                   start,          // pulse: new data ready
    input  wire [DATA_WIDTH-1:0]  s_data,
    output wire                   ready,          // FSM can accept next start
    output wire                   busy,

    // destination (receiver) domain
    input  wire                   dest_clk,
    input  wire                   dest_rst_n,
    output wire [DATA_WIDTH-1:0]  r_data,
    output wire                   vo              // valid-output pulse
);

    wire req;      // src domain, drives across to dest
    wire r2, rxe;  // dest domain: synchronized req, capture pulse
    wire ack_gen;  // dest domain: registered ack level, drives across to src
    wire a2, snt;  // src domain: synchronized ack, ack-received pulse

    // sender FSM
    tx_fsm src_fsm_inst (
        .clk   (src_clk),
        .rst_n (src_rst_n),
        .start (start),
        .snt   (snt),
        .a2    (a2),
        .req   (req),
        .busy  (busy),
        .ready (ready)
    );

    // REQ: src domain -> dest domain
    edge_detect_sync #(.SYNC_STAGES(2)) req_sync_inst (
        .clk        (dest_clk),
        .rst_n      (dest_rst_n),
        .async_in   (req),
        .sync_level (r2),
        .pulse_out  (rxe)
    );

    // ACK generation in dest domain: registered copy of r2, sent back
    reg ack_gen_reg;
    always @(posedge dest_clk or negedge dest_rst_n) begin
        if (!dest_rst_n)
            ack_gen_reg <= 1'b0;
        else
            ack_gen_reg <= r2;
    end
    assign ack_gen = ack_gen_reg;

    // ACK: dest domain -> src domain
    edge_detect_sync #(.SYNC_STAGES(2)) ack_sync_inst (
        .clk        (src_clk),
        .rst_n      (src_rst_n),
        .async_in   (ack_gen),
        .sync_level (a2),
        .pulse_out  (snt)
    );

    // data capture register, dest domain, gated by rxe
    data_reg #(.DATA_WIDTH(DATA_WIDTH)) data_reg_inst (
        .clk        (dest_clk),
        .rst_n      (dest_rst_n),
        .capture_en (rxe),
        .data_in    (s_data),
        .data_out   (r_data)
    );

    assign vo = rxe;

endmodule