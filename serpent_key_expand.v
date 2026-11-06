`timescale 1ns/1ps

module serpent_key_expand (
    input wire clk,
    input wire rst,
    input wire start,

    input wire[127:0] key,

    output reg busy,
    output reg ready,

    output reg key_we,
    output reg[5:0] key_addr,
    output reg[127:0] key_data
);

//==================================================
// FSM STATES
//==================================================

localparam IDLE     = 2'd0;
localparam PREKEY   = 2'd1;
localparam ROUNDKEY = 2'd2;
localparam FINISH   = 2'd3;

reg[1:0] state;

//==================================================
// PREKEY MEMORY
//==================================================

reg[31:0] w[0:139];

reg[7:0] count;

reg[5:0] round_count;

//==================================================
// ROTATE LEFT 11
//==================================================

function[31:0] rotl11;
    input[31:0] x;

    begin
        rotl11 = {x[20:0], x[31:21]};
    end
endfunction

//==================================================
// PREKEY GENERATION

wire [31:0] next_word;

assign next_word = rotl11(
    w[count] ^ w[count+3] ^ w[count+5] ^ w[count+7] ^ 32'h9E3779B9 ^ {24'd0, count}
);

//==================================================
// ROUND KEY INPUT
//==================================================
wire[127:0] sbox_input;
wire[127:0] sbox_output;
wire[2:0] sbox_select;

assign sbox_input = {
    w[8 + 4*round_count + 3],
    w[8 + 4*round_count + 2],
    w[8 + 4*round_count + 1],
    w[8 + 4*round_count]
};

//==================================================
// ROUND KEY S-BOX SELECTION
   
assign sbox_select = (3'd3 - round_count[2:0]);

//==================================================
// SHARED SERPENT S-BOX
//==================================================

serpent_sbox SBOX (
    .data_in(sbox_input),
    .box_sel(sbox_select),
    .data_out(sbox_output)
);

//==================================================
// CONTROLLER
//==================================================

integer i;

always @(posedge clk or posedge rst) begin

    if (rst) begin
        state <= IDLE;

        busy <= 1'b0;
        ready <= 1'b0;

        key_we <= 1'b0;

        key_addr <= 6'd0;
        key_data <= 128'd0;

        count <= 8'd0;
        round_count <= 6'd0;

        for (i = 0; i < 140; i = i + 1)
            w[i] <= 32'd0;
    end

    else begin
        // Default pulse signals.
        key_we <= 1'b0;

        case (state)

//==================================================
// IDLE
//==================================================

        IDLE: begin
            busy <= 1'b0;
            ready <= 1'b0;

            if (start) begin
                busy <= 1'b1;

                // Serpent-128 key padding.
                //
                // Four key words followed by
                // the padding bit and zeros.
                //
                // Words are interpreted
                // little-endian.

                w[0] <= {
    key[103:96],
    key[111:104],
    key[119:112],
    key[127:120]
};

w[1] <= {
    key[71:64],
    key[79:72],
    key[87:80],
    key[95:88]
};

w[2] <= {
    key[39:32],
    key[47:40],
    key[55:48],
    key[63:56]
};

w[3] <= {
    key[7:0],
    key[15:8],
    key[23:16],
    key[31:24]
};

                w[4] <= 32'h00000001;
                w[5] <= 32'h00000000;
                w[6] <= 32'h00000000;
                w[7] <= 32'h00000000;

                count <= 8'd0;
                round_count <= 6'd0;

                state <= PREKEY;
            end
        end

//==================================================
// PREKEY GENERATION
//
// Generate w[8] through w[139].
//
//==================================================

        PREKEY: begin
            w[count+8] <= next_word;

            if (count == 8'd131) begin
                round_count <= 6'd0;
                state <= ROUNDKEY;
            end

            else begin
                count <= count + 1'b1;
            end
        end

//==================================================
// ROUND KEY GENERATION
//
// Generate K0 through K32.
//
//==================================================

        ROUNDKEY: begin
            key_we <= 1'b1;
            key_addr <= round_count;
            key_data <= sbox_output;

            if (round_count == 6'd32) begin
                state <= FINISH;
            end

            else begin
                round_count <= round_count + 1'b1;
            end
        end // case: ROUNDKEY

//==================================================
// FINISH
//==================================================

        FINISH: begin
            busy <= 1'b0;
            ready <= 1'b1;
            state <= IDLE;
        end

//==================================================
// DEFAULT
//==================================================

        default: begin
            state <= IDLE;
            busy <= 1'b0;
            ready <= 1'b0;
        end

        endcase
    end
end

endmodule // serpent_key_expand
