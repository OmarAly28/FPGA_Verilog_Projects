module ALU (
    input [3:0] A,
    input [3:0] B,
    input alu_op,
    output [3:0] Result
);
    wire [3:0] B_inverted = B ^ {4{alu_op}};
    wire C_in_for_subtraction = alu_op;
    assign Result = A + B_inverted + C_in_for_subtraction;
endmodule

module register_file (
    input clk,
    input reset,
    input [1:0] read_addr1,
    input [1:0] read_addr2,
    output [3:0] read_data1,
    output [3:0] read_data2,
    input [1:0] write_addr,
    input [3:0] write_data,
    input write_en
);
    reg [3:0] registers [0:3];
    assign read_data1 = registers[read_addr1];
    assign read_data2 = registers[read_addr2];

    always @(posedge clk or posedge reset) begin
        if (reset) begin
            registers[0] <= 4'b0; registers[1] <= 4'b0;
            registers[2] <= 4'b0; registers[3] <= 4'b0;
        end else if (write_en) begin
            registers[write_addr] <= write_data;
        end
    end
endmodule

module Pipeline_Reg_IF_EX (
    input clk,
    input reset,
    input [3:0] in_data1,
    input [3:0] in_data2,
    input in_alu_op,
    input [1:0] in_write_addr,
    input in_write_en,
    output reg [3:0] out_data1,
    output reg [3:0] out_data2,
    output reg out_alu_op,
    output reg [1:0] out_write_addr,
    output reg out_write_en
);
    always @(posedge clk or posedge reset) begin
        if (reset) begin
            out_data1 <= 4'b0;
            out_data2 <= 4'b0;
            out_alu_op <= 1'b0;
            out_write_addr <= 2'b0;
            out_write_en <= 1'b0;
        end else begin
            out_data1 <= in_data1;
            out_data2 <= in_data2;
            out_alu_op <= in_alu_op;
            out_write_addr <= in_write_addr;
            out_write_en <= in_write_en;
        end
    end
endmodule

module datapath_pipelined (
    input clk,
    input reset,
    input [1:0] read_addr1,
    input [1:0] read_addr2,
    input [1:0] write_addr,
    input write_en,
    input alu_op
);
    wire [3:0] reg_read_data1, reg_read_data2;
    wire [3:0] alu_result_wire;

    wire [3:0] pipe_out_data1, pipe_out_data2;
    wire pipe_out_alu_op, pipe_out_write_en;
    wire [1:0] pipe_out_write_addr;

    register_file rf (
        .clk(clk),
        .reset(reset),
        .read_addr1(read_addr1),
        .read_addr2(read_addr2),
        .read_data1(reg_read_data1),
        .read_data2(reg_read_data2),
        .write_addr(pipe_out_write_addr),
        .write_data(alu_result_wire),
        .write_en(pipe_out_write_en)
    );

    Pipeline_Reg_IF_EX pipe_reg (
        .clk(clk),
        .reset(reset),
        .in_data1(reg_read_data1),
        .in_data2(reg_read_data2),
        .in_alu_op(alu_op),
        .in_write_addr(write_addr),
        .in_write_en(write_en),
        .out_data1(pipe_out_data1),
        .out_data2(pipe_out_data2),
        .out_alu_op(pipe_out_alu_op),
        .out_write_addr(pipe_out_write_addr),
        .out_write_en(pipe_out_write_en)
    );

    ALU alu (
        .A(pipe_out_data1),
        .B(pipe_out_data2),
        .alu_op(pipe_out_alu_op),
        .Result(alu_result_wire)
    );
endmodule

module datapath_pipelined_tb;
    reg clk;
    reg reset;
    reg [1:0] read_addr1, read_addr2;
    reg [1:0] write_addr;
    reg write_en;
    reg alu_op;

    datapath_pipelined dut (
        .clk(clk),
        .reset(reset),
        .read_addr1(read_addr1),
        .read_addr2(read_addr2),
        .write_addr(write_addr),
        .write_en(write_en),
        .alu_op(alu_op)
    );

    initial begin
        clk = 0;
        forever #5 clk = ~clk;
    end

    initial begin
        $dumpfile("datapath_pipelined.vcd");
        $dumpvars(0, datapath_pipelined_tb);

        reset = 1; write_en = 0;
        #10;
        reset = 0;

        dut.rf.registers[1] = 4'b0101;
        dut.rf.registers[2] = 4'b0011;

        #20;

        $display("Time=%0t: Instruction 1 (IF Stage): R3 = R1 + R2", $time);
        read_addr1 = 2'b01;
        read_addr2 = 2'b10;
        alu_op = 0;
        write_addr = 2'b11;
        write_en = 1;
        #10;

        $display("Time=%0t: Instruction 2 (IF Stage): R0 = R3 - R2 (Data Hazard!)", $time);
        read_addr1 = 2'b11;
        read_addr2 = 2'b10;
        alu_op = 1;
        write_addr = 2'b00;
        write_en = 1;
        #10;

        write_en = 0;
        #30;

        $finish;
    end
endmodule
