`timescale 1ns/1ps

module serpent_file_tb;

//==================================================
// SIGNALS
//==================================================

reg clk;
reg rst;
reg start;

reg[127:0] key;
reg[127:0] plaintext;

wire[127:0] ciphertext;
wire busy;
wire done;

reg[127:0] expected;

reg[127:0] file_key;
reg[127:0] file_plain;
reg[127:0] file_cipher;

integer fd;
integer scan_count;

integer total;
integer passed;
integer failed;
integer timeout_count;

integer cycles;

//==================================================
// DUT
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
    clk = 1'b0;
    forever #5 clk = ~clk;
end

//==================================================
// MAIN TEST PROCESS
//==================================================

initial begin

    rst = 1'b1;
    start = 1'b0;

    key = 128'd0;
    plaintext = 128'd0;
    expected = 128'd0;

    total = 0;
    passed = 0;
    failed = 0;
    timeout_count = 0;

    cycles = 0;

    // Reset DUT.
    repeat (5) @(negedge clk);
    rst = 1'b0;
    repeat (2) @(negedge clk);

    // Open vector file.

    fd = $fopen("serpent128_vectors.hex", "r");

    if (fd == 0) begin
        $display("ERROR: Cannot open serpent128_vectors.hex");
        $fatal(1);
    end

    $display("");
    $display("========================================");
    $display(" SERPENT-128 AUTOMATIC VECTOR TEST");
    $display("========================================");

    //==================================================
    // READ ALL VECTORS
    //==================================================

    while (!$feof(fd)) begin

        scan_count = $fscanf(
            fd,
            "%h %h %h",
            file_key,
            file_plain,
            file_cipher
        );

        if (scan_count == 3) begin

            total = total + 1;

            key = file_key;
            plaintext = file_plain;
            expected = file_cipher;

            $display("");
            $display("----------------------------------------");
            $display("VECTOR %0d", total);
            $display("----------------------------------------");

            $display("KEY      = %032h", key);
            $display("PLAINTEXT= %032h", plaintext);
            $display("EXPECTED = %032h", expected);

            //==================================================
            // START ENCRYPTION
            //==================================================

            @(negedge clk);

            start = 1'b1;

            @(negedge clk);

            start = 1'b0;

            //==================================================
            // WAIT FOR DONE
            //==================================================

            cycles = 0;

            while ((done !== 1'b1) && (cycles < 2000)) begin
                @(negedge clk);
                cycles = cycles + 1;
            end

            //==================================================
            // CHECK RESULT
            //==================================================

            if (done !== 1'b1) begin
                timeout_count = timeout_count + 1;
                failed = failed + 1;
                $display("RESULT   = TIMEOUT");

            end

            else begin

                $display("ACTUAL   = %032h", ciphertext);

                if (ciphertext === expected) begin
                    passed = passed + 1;
                    $display("RESULT   = PASS");
                end

                else begin
                    failed = failed + 1;
                    $display("RESULT   = FAIL");
                end
            end

            // Wait until DUT returns to IDLE.
            @(negedge clk);
            @(negedge clk);
        end
    end

    //==================================================
    // CLOSE FILE
    //==================================================

    $fclose(fd);

    //==================================================
    // FINAL SUMMARY
    //==================================================

    $display("");
    $display("========================================");
    $display(" SERPENT-128 TEST SUMMARY");
    $display("========================================");

    $display("TOTAL TESTS : %0d", total);
    $display("PASSED      : %0d", passed);
    $display("FAILED      : %0d", failed);
    $display("TIMEOUTS    : %0d", timeout_count);

    $display("----------------------------------------");

    if ((failed == 0) && (total > 0)) begin
        $display("OVERALL RESULT: PASS");
    end

    else begin
        $display("OVERALL RESULT: FAIL");
    end

    $display("========================================");

    if ((failed != 0) || (total == 0)) begin
        $fatal(1, "Serpent-128 verification failed");
    end

    $finish;
end

endmodule // serpent_file_tb
