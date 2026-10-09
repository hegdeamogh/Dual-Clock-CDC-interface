// tx_fsm.v
//
// Sender-side FSM for the four-phase CDC handshake.
// Drives REQ, waits for SNT (ack-received pulse) to drop REQ,
// then waits for A2 (synchronized ack level) to fall back to 0
// before allowing the next transfer - proper 4-phase return-to-zero.

module tx_fsm (
    input  wire clk,
    input  wire rst_n,
    input  wire start,   // pulse: new data ready to send
    input  wire snt,     // pulse: ack received (from edge_detect_sync on ACK path)
    input  wire a2,      // synchronized ack level (from same block)
    output reg  req,     // request line to receiver
    output reg  busy,    // high while a transfer is in flight
    output reg  ready    // high when FSM can accept a new 'start'
);

    localparam IDLE         = 2'd0;
    localparam WAIT_SNT     = 2'd1;
    localparam WAIT_ACK_LOW = 2'd2;

    reg [1:0] state, next_state;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n)
            state <= IDLE;
        else
            state <= next_state;
    end

    always @(*) begin
        next_state = state;
        case (state)
            IDLE:         if (start) next_state = WAIT_SNT;
            WAIT_SNT:     if (snt)   next_state = WAIT_ACK_LOW;
            WAIT_ACK_LOW: if (!a2)   next_state = IDLE;
            default:      next_state = IDLE;
        endcase
    end

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            req <= 1'b0;
        end else begin
            case (state)
                IDLE:     if (start) req <= 1'b1;
                WAIT_SNT: if (snt)   req <= 1'b0;
                default:  req <= req;
            endcase
        end
    end

    always @(*) begin
        busy  = (state != IDLE);
        ready = (state == IDLE);
    end

endmodule