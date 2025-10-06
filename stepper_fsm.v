module stepper_fsm (
    input clk,
    input reset,
    input step_en,
    output reg [3:0] motor_out
);
    parameter S0 = 2'b00;
    parameter S1 = 2'b01;
    parameter S2 = 2'b10;
    parameter S3 = 2'b11;

    reg [1:0] current_state;
    reg [1:0] next_state;

    always @(*) begin
        next_state = current_state;
        if (step_en) begin
            case (current_state)
                S0: next_state = S1;
                S1: next_state = S2;
                S2: next_state = S3;
                S3: next_state = S0;
                default: next_state = S0;
            endcase
        end
    end

    always @(posedge clk or posedge reset) begin
        if (reset) begin
            current_state <= S0;
        end else begin
            current_state <= next_state;
        end
    end

    always @(*) begin
        case (current_state)
            S0: motor_out = 4'b1000;
            S1: motor_out = 4'b0100;
            S2: motor_out = 4'b0010;
            S3: motor_out = 4'b0001;
            default: motor_out = 4'b0000;
        endcase
    end
endmodule

module stepper_fsm_tb;
    reg clk;
    reg reset;
    reg step_en;
    wire [3:0] motor_out;

    stepper_fsm dut (
        .clk(clk),
        .reset(reset),
        .step_en(step_en),
        .motor_out(motor_out)
    );

    initial begin
        clk = 0;
        forever #50 clk = ~clk;
    end

    initial begin
        $dumpfile("stepper_waveform.vcd");
        $dumpvars(0, stepper_fsm_tb);

        reset = 1;
        step_en = 0;
        #100;
        reset = 0;

        #10;
        step_en = 1;
        #800;

        step_en = 0;
        #100;

        $finish;
    end
endmodule
