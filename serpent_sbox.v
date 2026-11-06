`timescale 1ns/1ps

module serpent_sbox (
    input wire[127:0] data_in,
    input wire[2:0] box_sel,
    output reg[127:0] data_out
);

function [3:0] sb;
    input [3:0] x;
    input [2:0] s;

    begin
        case(s)
        0: case(x)
         0:sb=3;  1:sb=8;  2:sb=15; 3:sb=1;
         4:sb=10; 5:sb=6;  6:sb=5;  7:sb=11;
         8:sb=14; 9:sb=13; 10:sb=4; 11:sb=2;
         12:sb=7; 13:sb=0; 14:sb=9; 15:sb=12;
        endcase

        1: case(x)
         0:sb=15; 1:sb=12; 2:sb=2;  3:sb=7;
         4:sb=9;  5:sb=0;  6:sb=5;  7:sb=10;
         8:sb=1;  9:sb=11; 10:sb=14; 11:sb=8;
         12:sb=6; 13:sb=13; 14:sb=3; 15:sb=4;
        endcase

        2: case(x)
         0:sb=8;  1:sb=6;  2:sb=7;  3:sb=9;
         4:sb=3;  5:sb=12; 6:sb=10; 7:sb=15;
         8:sb=13; 9:sb=1; 10:sb=14; 11:sb=4;
         12:sb=0; 13:sb=11; 14:sb=5; 15:sb=2;
        endcase

        3: case(x)
         0:sb=0;  1:sb=15; 2:sb=11; 3:sb=8;
         4:sb=12; 5:sb=9;  6:sb=6;  7:sb=3;
         8:sb=13; 9:sb=1; 10:sb=2; 11:sb=4;
         12:sb=10;13:sb=7; 14:sb=5; 15:sb=14;
        endcase

        4: case(x)
         0:sb=1;  1:sb=15; 2:sb=8;  3:sb=3;
         4:sb=12; 5:sb=0;  6:sb=11; 7:sb=6;
         8:sb=2;  9:sb=5; 10:sb=4; 11:sb=10;
         12:sb=9; 13:sb=14;14:sb=7; 15:sb=13;
        endcase

        5: case(x)
         0:sb=15; 1:sb=5;  2:sb=2;  3:sb=11;
         4:sb=4;  5:sb=10; 6:sb=9;  7:sb=12;
         8:sb=0;  9:sb=3; 10:sb=14; 11:sb=8;
         12:sb=13;13:sb=6; 14:sb=7; 15:sb=1;
        endcase

        6: case(x)
         0:sb=7;  1:sb=2;  2:sb=12; 3:sb=5;
         4:sb=8;  5:sb=4;  6:sb=6;  7:sb=11;
         8:sb=14; 9:sb=9; 10:sb=1; 11:sb=15;
         12:sb=13;13:sb=3; 14:sb=10;15:sb=0;
        endcase

        7: case(x)
         0:sb=1;  1:sb=13; 2:sb=15; 3:sb=0;
         4:sb=14; 5:sb=8;  6:sb=2;  7:sb=11;
         8:sb=7;  9:sb=4; 10:sb=12; 11:sb=10;
         12:sb=9; 13:sb=3; 14:sb=5; 15:sb=6;
        endcase

        default: sb=4'd0;
        endcase
    end
endfunction // sb

integer i;
reg[3:0] v;
reg[31:0] y0,y1,y2,y3;

always @(*) begin
    y0 = 32'd0;
    y1 = 32'd0;
    y2 = 32'd0;
    y3 = 32'd0;

    for(i=0; i<32; i=i+1) begin
        // Correct Serpent bit-slice input ordering
        v = sb({
            data_in[i+96],
            data_in[i+64],
            data_in[i+32],
            data_in[i]
        }, box_sel);

        // Correct output bit ordering
        y0[i] = v[0];
        y1[i] = v[1];
        y2[i] = v[2];
        y3[i] = v[3];
    end

    data_out = {y3,y2,y1,y0};
end

endmodule // serpent_sbox
