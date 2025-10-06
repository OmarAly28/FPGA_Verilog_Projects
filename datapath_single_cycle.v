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
            registers[0] <= 4'b0;
            registers[1] <= 4'b0;
            registers[2] <= 4'b0;
            registers[3] <= 4'b0;
        end else if (write_en) begin
            registers[write_addr] <= write_data;
        end
    end
endmodule

module datapath (
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

    register_file rf (
        .clk(clk),
        .reset(reset),
        .read_addr1(read_addr1),
        .read_addr2(read_addr2),
        .read_data1(reg_read_data1),
        .read_data2(reg_read_data2),
        .write_addr(write_addr),
        .write_data(alu_result_wire),
        .write_en(write_en)
    );

    ALU alu (
        .A(reg_read_data1),
        .B(reg_read_data2),
        .alu_op(alu_op),
        .Result(alu_result_wire)
    );
endmodule

module datapath_tb;
    reg clk;
    reg reset;
    reg [1:0] read_addr1, read_addr2;
    reg [1:0] write_addr;
    reg write_en;
    reg alu_op;

    datapath dut (
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
        $dumpfile("datapath_single_cycle.vcd");
        $dumpvars(0, datapath_tb);

        reset = 1; write_en = 0;
        #10;
        reset = 0;

        dut.rf.registers[1] = 4'b0101;
        dut.rf.registers[2] = 4'b0011;

        #20;

        $display("Time=%0t: Instruction: R3 = R1 + R2 (5 + 3 = 8)", $time);
        read_addr1 = 2'b01;
        read_addr2 = 2'b10;
        alu_op = 0;
        write_addr = 2'b11;
        write_en = 1;
        #10;

        $display("Time=%0t: Instruction: R0 = R3 - R2 (8 - 3 = 5)", $time);
        read_addr1 = 2'b11;
        read_addr2 = 2'b10;
        alu_op = 1;
        write_addr = 2'b00;
        write_en = 1;
        #10;

        $display("Time=%0t: Instruction: R1 = R0 + R3 (5 + 8 = 13)", $time);
        read_addr1 = 2'b00;
        read_addr2 = 2'b11;
        alu_op = 0;
        write_addr = 2'b01;
        write_en = 1;
        #10;

        #20;
        $finish;
    end
endmodule
