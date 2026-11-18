// ============================================================
// Traffic Light Controller (FSM + counter)
// Sequence : RED -> GREEN -> YELLOW -> RED ...
// Timing   : RED = 100 ns, GREEN = 80 ns, YELLOW = 20 ns
// Clock    : 10 ns period (100 MHz)  =>  10 / 8 / 2 clock cycles
// ============================================================
`timescale 1ns/1ps

module traffic_light #(
    parameter CLK_PERIOD_NS = 10,
    parameter RED_NS        = 100,
    parameter GREEN_NS      = 80,
    parameter YELLOW_NS     = 20
)(
    input  wire clk,
    input  wire rst,        // synchronous, active-high
    output reg  red,
    output reg  yellow,
    output reg  green
);

    // Durations converted to clock cycles
    localparam RED_CYC    = RED_NS    / CLK_PERIOD_NS;
    localparam GREEN_CYC  = GREEN_NS  / CLK_PERIOD_NS;
    localparam YELLOW_CYC = YELLOW_NS / CLK_PERIOD_NS;

    // State encoding
    localparam [1:0] S_RED    = 2'b00,
                     S_GREEN  = 2'b01,
                     S_YELLOW = 2'b10;

    reg [1:0] state, next_state;
    reg [7:0] count;          // time spent in current state (in cycles)
    reg [7:0] limit;          // cycles required for current state

    // Duration of the current state
    always @(*) begin
        case (state)
            S_RED:    limit = RED_CYC;
            S_GREEN:  limit = GREEN_CYC;
            S_YELLOW: limit = YELLOW_CYC;
            default:  limit = RED_CYC;
        endcase
    end

    // Next-state logic
    always @(*) begin
        case (state)
            S_RED:    next_state = S_GREEN;
            S_GREEN:  next_state = S_YELLOW;
            S_YELLOW: next_state = S_RED;
            default:  next_state = S_RED;   // illegal-state recovery
        endcase
    end

    // State register + counter
    always @(posedge clk) begin
        if (rst) begin
            state <= S_RED;
            count <= 8'd0;
        end else if (count == limit - 1) begin
            state <= next_state;
            count <= 8'd0;
        end else begin
            count <= count + 8'd1;
        end
    end

    // Moore outputs (depend on state only)
    always @(*) begin
        red = 1'b0; yellow = 1'b0; green = 1'b0;
        case (state)
            S_RED:    red    = 1'b1;
            S_GREEN:  green  = 1'b1;
            S_YELLOW: yellow = 1'b1;
            default:  red    = 1'b1;
        endcase
    end

endmodule
