// Ports:
// Name                         I/O  size props
// led                            O     1 reg
// clk                            I     1 clock
// rst_n                          I     1 reset
//
// No combinational paths from inputs to outputs
//
//

`ifdef BSV_ASSIGNMENT_DELAY
`else
  `define BSV_ASSIGNMENT_DELAY
`endif

`ifdef BSV_POSITIVE_RESET
  `define BSV_RESET_VALUE 1'b1
  `define BSV_RESET_EDGE posedge
`else
  `define BSV_RESET_VALUE 1'b0
  `define BSV_RESET_EDGE negedge
`endif

module top (
    clk,
    rst_n,

    led
);
    input clk;
    input rst_n;

    // value method led
    output led;

    // signals for module outputs
    wire led;

    // register r_counter
    reg [31 : 0] r_counter;
    wire [31 : 0] r_counter$D_IN;
    wire r_counter$EN;

    // register r_led
    reg r_led;
    wire r_led$D_IN, r_led$EN;

    // remaining internal signals
    wire [31 : 0] x__h98;
    wire r_counter_read_ULT_10000000___d2;

    // value method led
    assign led = r_led;

    // register r_counter
    assign r_counter$D_IN = r_counter_read_ULT_10000000___d2 ? x__h98 : 32'd0;
    assign r_counter$EN = 1'd1;

    // register r_led
    assign r_led$D_IN = ~r_led;
    assign r_led$EN = !r_counter_read_ULT_10000000___d2;

    // remaining internal signals
    assign r_counter_read_ULT_10000000___d2 = r_counter < 32'd10000000;
    assign x__h98 = r_counter + 32'd1;

    // handling of inlined registers
    always @(posedge clk) begin
        if (rst_n == `BSV_RESET_VALUE) begin
            r_counter <= 32'd0;
            r_led <= 1'd0;
        end else begin
            if (r_counter$EN) r_counter <= r_counter$D_IN;
            if (r_led$EN) r_led <= r_led$D_IN;
        end
    end

    // synopsys translate_off
`ifdef BSV_NO_INITIAL_BLOCKS
`else  // not BSV_NO_INITIAL_BLOCKS
    initial begin
        r_counter = 32'hAAAAAAAA;
        r_led = 1'h0;
    end
`endif  // BSV_NO_INITIAL_BLOCKS
    // synopsys translate_on
endmodule  // top

