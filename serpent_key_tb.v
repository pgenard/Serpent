`timescale 1ns/1ps

module serpent_key_tb;

reg clk;
reg rst;
reg start;

reg[127:0] key;
reg[127:0] captured_keys[0:32];

wire busy;
wire ready;

wire key_we;
wire[5:0] key_addr;
wire[127:0] key_data;

integer count;

//===========================================
// DUT
//===========================================

serpent_key_expand DUT (
    .clk(clk),
    .rst(rst),
    .start(start),
    .key(key),
    .busy(busy),
    .ready(ready),
    .key_we(key_we),
    .key_addr(key_addr),
    .key_data(key_data)
);

//===========================================
// CLOCK
//===========================================

initial begin
    clk = 0;
    forever #5 clk = ~clk;
end

//===========================================
// MONITOR ROUND KEYS
//===========================================

always @(negedge clk) begin

    if(key_we) begin
        captured_keys[key_addr] = key_data;

        $display(
            "ROUND KEY %02d = %032h",
            key_addr,
            key_data
        );
    end
end // always @ (negedge clk)

//===========================================
// TEST
//===========================================

initial begin
    rst = 1;
    start = 0;
    key = 128'h00000000000000000000000000000000;
    count = 0;
   
    repeat(4) @(negedge clk);
   
    rst = 0;

    repeat(2) @(negedge clk);

    $display("");
    $display("======================================");
    $display(" SERPENT-128 KEY EXPANSION TEST");
    $display("======================================");

    $display("KEY = %032h",key);

    start = 1;
   
    @(negedge clk);
   
    start = 0;

    while(!ready && count < 200) begin
        @(negedge clk);
        count = count + 1;
    end

    if(ready) begin
        $display("");
        $display("KEY EXPANSION: PASS");

        $display("");
$display("FIRST FIVE ROUND KEYS");

for(count=0; count<5; count=count+1) begin
    $display(
        "K%02d = %032h",
        count,
        captured_keys[count]
    );
end
    end

    else begin
        $display("");
        $display("KEY EXPANSION: TIMEOUT");
    end

    $display("======================================");

    $finish;

end

endmodule // serpent_key_tb
