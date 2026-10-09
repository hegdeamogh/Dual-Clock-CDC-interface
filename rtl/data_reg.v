// data_reg.v
//
// Destination-domain data capture register, gated by the RXE pulse
// from edge_detect_sync on the REQ path.

module data_reg #(
    parameter DATA_WIDTH = 8
) (
    input  wire                  clk,
    input  wire                  rst_n,
    input  wire                  capture_en,  // rxe
    input  wire [DATA_WIDTH-1:0] data_in,     // s_data (static bus)
    output reg  [DATA_WIDTH-1:0] data_out     // r_data
);

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n)
            data_out <= {DATA_WIDTH{1'b0}};
        else if (capture_en)
            data_out <= data_in;
    end

endmodule