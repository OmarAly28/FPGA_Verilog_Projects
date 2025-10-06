module pwm_controller (
    input clk,
    input reset,
    input [3:0] duty_cycle_in,
    output reg pwm_out
);
    parameter PWM_PERIOD = 4'd15;
    reg [3:0] cycle_counter;

    always @(posedge clk or posedge reset) begin
        if (reset) begin
            cycle_counter <= 4'b0;
        end else begin
            if (cycle_counter == PWM_PERIOD) begin
                cycle_counter <= 4'b0;
            end else begin
                cycle_counter <= cycle_counter + 1;
            end
        end
    end

    always @(*) begin
        if (cycle_counter < duty_cycle_in) begin
            pwm_out = 1'b1;
        end else begin
            pwm_out = 1'b0;
        end
    end
endmodule

module pwm_controller_tb;
    reg clk;
    reg reset;
    reg [3:0] duty_cycle_in;
    wire pwm_out;

    pwm_controller dut (
        .clk(clk),
        .reset(reset),
        .duty_cycle_in(duty_cycle_in),
        .pwm_out(pwm_out)
    );

    initial begin
        clk = 0;
        forever #25 clk = ~clk;
    end

    initial begin
        $dumpfile("pwm_waveform.vcd");
        $dumpvars(0, pwm_controller_tb);

        reset = 1;
        duty_cycle_in = 4'd0;
        #100;
        reset = 0;

        duty_cycle_in = 4'd4;
        #800;

        duty_cycle_in = 4'd12;
        #800;

        duty_cycle_in = 4'd0;
        #800;

        $finish;
    end
endmodule
