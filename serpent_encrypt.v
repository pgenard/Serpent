`timescale 1ns/1ps

module serpent_encrypt (
    input wire clk,
    input wire rst,
    input wire start,

    input wire[127:0] key,
    input wire[127:0] plaintext,

    output reg[127:0] ciphertext,
    output reg busy,
    output reg done
);

//==================================================
// FSM STATES
//==================================================

localparam IDLE     = 3'd0;
localparam KEY_WAIT = 3'd1;
localparam ENC_LOAD = 3'd2;
localparam ENC_RUN  = 3'd3;
localparam FINISH   = 3'd4;

reg[2:0] state;

//==================================================
// KEY EXPANSION INTERFACE
//==================================================

reg key_start;

wire key_busy;
wire key_ready;

wire key_we;

wire[5:0] key_addr;
wire[127:0] key_data;

//==================================================
// ROUND KEY MEMORY
//==================================================

reg[127:0] round_keys[0:32];

//==================================================
// ENCRYPTION REGISTERS
//==================================================

reg[127:0] state_reg;
reg[127:0] plaintext_reg;

reg[4:0] round_count;

//==================================================
// KEY EXPANSION MODULE
//==================================================

serpent_key_expand KEY_EXPANDER (
    .clk(clk),
    .rst(rst),
    .start(key_start),
    .key(key),
    .busy(key_busy),
    .ready(key_ready),
    .key_we(key_we),
    .key_addr(key_addr),
    .key_data(key_data)
);

//==================================================
// STORE GENERATED ROUND KEYS
//==================================================

always @(posedge clk) begin
    if (key_we)
        round_keys[key_addr] <= key_data;
end

//==================================================
// SHARED S-BOX INTERFACE
//==================================================

wire[127:0] sbox_input;
wire[2:0] sbox_select;

wire[127:0] sbox_output;

//==================================================
// ENCRYPTION S-BOX INPUT
//==================================================

assign sbox_input =
    (state == ENC_RUN) ?
    (state_reg ^ round_keys[round_count]) :
    128'd0;

assign sbox_select =
    (state == ENC_RUN) ?
    round_count[2:0] :
    3'd0;

//==================================================
// SHARED S-BOX
//==================================================

serpent_sbox SBOX (
    .data_in(sbox_input),
    .box_sel(sbox_select),
    .data_out(sbox_output)
);

//==================================================
// SHARED LINEAR TRANSFORMATION
//==================================================

wire[127:0] lt_output;

serpent_lt LT (
    .data_in(sbox_output),
    .data_out(lt_output)
);

//==================================================
// FINAL ROUND
//==================================================

wire[127:0] final_result;

assign final_result =
    sbox_output ^ round_keys[32];

//==================================================
// FINAL BYTE ORDER CONVERSION
//==================================================

function[127:0] reverse_bytes;
    input[127:0] x;
    integer i;

    begin
        for(i=0;i<16;i=i+1)
            reverse_bytes[i*8 +:8] =
                x[127-i*8 -:8];
    end
endfunction

//==================================================
// MAIN CONTROLLER
//==================================================

always @(posedge clk or posedge rst) begin
    if(rst) begin
        state <= IDLE;
        key_start <= 0;
        ciphertext <= 0;
        state_reg <= 0;
        plaintext_reg <= 0;
        round_count <= 0;
        busy <= 0;
        done <= 0;
    end

    else begin
        // Default control signals.
        done <= 0;
        key_start <= 0;

        case(state)

//==================================================
// IDLE
//==================================================

        IDLE: begin
            busy <= 0;

            if(start) begin
                busy <= 1;
                plaintext_reg <= plaintext;
                key_start <= 1;

                state <= KEY_WAIT;
            end
        end

//==================================================
// WAIT FOR KEY EXPANSION
//==================================================

        KEY_WAIT: begin
            busy <= 1;

            if(key_ready) begin
                round_count <= 0;
                state <= ENC_LOAD;
            end
        end

//==================================================
// LOAD PLAINTEXT
//==================================================

        ENC_LOAD: begin
            state_reg <= reverse_bytes(plaintext_reg);
            round_count <= 0;
            state <= ENC_RUN;
        end

//==================================================
// ENCRYPTION ROUNDS
//==================================================

        ENC_RUN: begin
            if(round_count < 5'd31) begin
                // Rounds 0 through 30.
                state_reg <= lt_output;
                round_count <= round_count + 1'b1;
            end

            else begin
                // Final round 31.
                ciphertext <= reverse_bytes(final_result);
                state <= FINISH;
            end
        end

//==================================================
// FINISH
//==================================================

        FINISH: begin
            busy <= 0;
            done <= 1;
            state <= IDLE;
        end

//==================================================
// DEFAULT
//==================================================
        default: begin
            state <= IDLE;
            busy <= 0;
        end

        endcase
    end
end

endmodule // serpent_encrypt
