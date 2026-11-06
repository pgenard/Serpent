`timescale 1ns/1ps

module serpent_tb;

//==================================================
// INPUTS AND OUTPUTS
//==================================================
reg clk;
reg rst;
reg start;

reg[127:0] key;
reg[127:0] plaintext;

wire[127:0] ciphertext;

wire busy;
wire done;

//==================================================
// TEST COUNTERS
//==================================================
integer test_number;
integer pass_count;
integer fail_count;
integer timeout_count;

//==================================================
// DUT INSTANTIATION
//==================================================

serpent_encrypt DUT (
    .clk(clk),
    .rst(rst),
    .start(start),
    .key(key),
    .plaintext(plaintext),
    .ciphertext(ciphertext),
    .busy(busy),
    .done(done)
);

//==================================================
// CLOCK GENERATION
//==================================================

initial begin
    clk = 0;
    forever #5 clk = ~clk;
end

//==================================================
// WAVEFORM GENERATION
//==================================================

initial begin
    $dumpfile("serpent_wave.vcd");
    $dumpvars(0, serpent_tb);
end

//==================================================
// AUTOMATIC TEST TASK
//==================================================

task run_test;

    input[127:0] test_key;
    input[127:0] test_plaintext;
    input[127:0] expected_ciphertext;

    integer cycles;
    reg completed;

    begin
        test_number = test_number + 1;

        // Apply inputs away from active clock edge.
        @(negedge clk);

        key = test_key;
        plaintext = test_plaintext;
        start = 1'b1;

        @(negedge clk);

        start = 1'b0;

        // Wait for encryption completion.
        cycles = 0;
        completed = 0;

        while ((cycles < 250) && !completed) begin
            @(negedge clk);
            cycles = cycles + 1;

            if (done === 1'b1)
                completed = 1;
        end

        $display("");
        $display("----------------------------------------");
        $display("TEST VECTOR %0d",test_number);
        $display("----------------------------------------");

        $display("KEY      = %032h",test_key);

        $display("PLAINTEXT= %032h",test_plaintext);

        $display("EXPECTED = %032h",expected_ciphertext);

        if (!completed) begin
            $display("ACTUAL   = TIMEOUT");
            $display("RESULT   = FAIL");

            fail_count = fail_count + 1;
            timeout_count = timeout_count + 1;
        end

        else begin
            $display("ACTUAL   = %032h",ciphertext);

            if (ciphertext === expected_ciphertext) begin
                $display("RESULT   = PASS");
                pass_count = pass_count + 1;
            end

            else begin
                $display("RESULT   = FAIL");
                fail_count = fail_count + 1;
            end
        end

        // Allow DUT to return to IDLE.
        @(negedge clk);
    end
endtask

//==================================================
// MAIN TEST SEQUENCE
//==================================================

initial begin

    test_number = 0;
    pass_count = 0;
    fail_count = 0;
    timeout_count = 0;

    rst = 1'b1;
    start = 1'b0;

    key = 128'd0;
    plaintext = 128'd0;

    repeat(4) @(negedge clk);

    rst = 1'b0;

    repeat(2) @(negedge clk);

    $display("");
    $display("========================================");
    $display("       SERPENT-128 MULTI-VECTOR TEST");
    $display("========================================");

    //==============================================
    // VECTOR 0: ZERO KEY / ZERO PLAINTEXT
    //==============================================

    run_test(
        128'h00000000000000000000000000000000,
        128'h00000000000000000000000000000000,
        128'h3620B17AE6A993D09618B8768266BAE9
    );

    //==============================================
    // VECTOR 1: VARIABLE KEY
    //==============================================

    run_test(
        128'h00000000000000000000000000000080,
        128'h00000000000000000000000000000000,
        128'hDDD26B98A5FFD82C05345A9DADBFAF49
    );

    //==============================================
    // VECTOR 2: VARIABLE KEY
    //==============================================

    run_test(
        128'h00000000000000000000000000000001,
        128'h00000000000000000000000000000000,
        128'hF668C7091F81B2827DA77DD419B708E1
    );

    //==============================================
    // VECTOR 3: VARIABLE KEY AND PLAINTEXT
    //==============================================

    run_test(
        128'h000102030405060708090A0B0C0D0E0F,
128'h000102030405060708090A0B0C0D0E0F,
128'h4C7D8A328072A22C823E4A1F3ACDA16D
    );

    //==============================================
    // FINAL REPORT
    //==============================================

    $display("");
    $display("========================================");
    $display("       SERPENT-128 TEST SUMMARY");
    $display("========================================");

    $display("TOTAL TESTS : %0d",test_number);

    $display("PASSED      : %0d",pass_count);

    $display("FAILED      : %0d",fail_count);

    $display("TIMEOUTS    : %0d",timeout_count);

    $display("----------------------------------------");

    if (fail_count == 0) begin
        $display("OVERALL RESULT: PASS");
    end

    else begin
        $display("OVERALL RESULT: FAIL");
    end

    $display("========================================");

    if (fail_count != 0)
        $fatal(1,"Serpent-128 verification failed");
    $finish;

end

endmodule // serpent_tb
