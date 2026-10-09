module edge_detect_sync #(
    parameter SYNC_STAGES = 2
) (
    input  wire clk,
    input  wire rst_n,      // async assert, sync deassert
    input  wire async_in,   // signal from the other clock domain
    output wire sync_level, // synchronized level
    output wire pulse_out   // one-cycle rising-edge pulse
);

    reg [SYNC_STAGES-1:0] sync_ff;
    reg                   delay_ff;
    reg  [1:0]            rst_sync_ff;
    wire                  rst_n_sync;

    // async assert / sync deassert reset, generated locally in this domain
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n)
            rst_sync_ff <= 2'b00;
        else
            rst_sync_ff <= {rst_sync_ff[0], 1'b1};
    end
    assign rst_n_sync = rst_sync_ff[1];

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n)
            sync_ff <= {SYNC_STAGES{1'b0}};
        else if (!rst_n_sync)
            sync_ff <= {SYNC_STAGES{1'b0}};
        else
            sync_ff <= {sync_ff[SYNC_STAGES-2:0], async_in};
    end

    assign sync_level = sync_ff[SYNC_STAGES-1];

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n)
            delay_ff <= 1'b0;
        else if (!rst_n_sync)
            delay_ff <= 1'b0;
        else
            delay_ff <= sync_level;
    end

    assign pulse_out = sync_level & ~delay_ff;

endmodule