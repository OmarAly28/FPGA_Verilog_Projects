// This module implements a 4-state traffic light controller as a Moore FSM.
module traffic_light_fsm (
    input clk,
    input reset,
    output reg [2:0] light_out
);

    parameter S_MAIN_GREEN   = 2'b00;
    parameter S_MAIN_YELLOW  = 2'b01;
    parameter S_CROSS_GREEN  = 2'b10;
    parameter S_CROSS_YELLOW = 2'b11;

    reg [1:0] current_state;
    reg [1:0] next_state;

    reg [2:0] timer_count;
    parameter GREEN_TIME  = 3'd4;
    parameter YELLOW_TIME = 3'd2;

    wire timer_done;
    assign timer_done = (timer_count == 3'd0);

    always @(posedge clk or posedge reset) begin
        if (reset) begin
            current_state <= S_MAIN_GREEN;
            timer_count <= GREEN_TIME;
        end else begin
            current_state <= next_state;
        end
    end

    always @(*) begin
        next_state = current_state;
        
        case(current_state)
            S_MAIN_GREEN: begin
                if (timer_done) begin
                    next_state = S_MAIN_YELLOW;
                end
            end
            S_MAIN_YELLOW: begin
                if (timer_done) begin
                    next_state = S_CROSS_GREEN;
                end
            end
            S_CROSS_GREEN: begin
                if (timer_done) begin
                    next_state = S_CROSS_YELLOW;
                end
            end
            S_CROSS_YELLOW: begin
                if (timer_done) begin
                    next_state = S_MAIN_GREEN;
                end
            end
            default: begin
                next_state = S_MAIN_GREEN;
            end
        endcase
    end
    
    always @(posedge clk or posedge reset) begin
        if (reset) begin
            timer_count <= GREEN_TIME;
        end else begin
            if (timer_done) begin
                if (next_state == S_MAIN_GREEN || next_state == S_CROSS_GREEN) begin
                    timer_count <= GREEN_TIME;
                end else begin
                    timer_count <= YELLOW_TIME;
                end
            end else begin
                timer_count <= timer_count - 1;
            end
        end
    end

    always @(*) begin
        case(current_state)
            S_MAIN_GREEN:   light_out =
//tb.v
// Code your testbench here
// or browse Examples
module traffic_light_fsm_tb;

    reg clk;
    reg reset;
    wire [2:0] light_out;

    traffic_light_fsm dut (
        .clk(clk),
        .reset(reset),
        .light_out(light_out)
    );

    initial begin
        clk = 0;
        forever #5 clk = ~clk;
    end

    initial begin
        $dumpfile("traffic_light_fsm.vcd");
        $dumpvars(0, traffic_light_fsm_tb);

        reset = 1;
        #10;
        reset = 0;

        #100;

        $finish;
    end
endmodule
