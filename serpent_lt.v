`timescale 1ns/1ps

module serpent_lt (
    input wire[127:0] data_in,
    output wire[127:0] data_out
);

function [31:0] rotl;
    input[31:0] x;
    input integer n;
    begin
        rotl=(x<<n)|(x>>(32-n));
    end
endfunction

reg [31:0] x0,x1,x2,x3;

always @(*) begin
    x0=data_in[31:0];
    x1=data_in[63:32];
    x2=data_in[95:64];
    x3=data_in[127:96];
   
    x0=rotl(x0,13);
    x2=rotl(x2,3);
   
    x1=x1^x0^x2;
    x3=x3^x2^(x0<<3);

    x1=rotl(x1,1);
    x3=rotl(x3,7);

    x0=x0^x1^x3;
    x2=x2^x3^(x1<<7);

    x0=rotl(x0,5);
    x2=rotl(x2,22);
end

assign data_out={x3,x2,x1,x0};

endmodule // serpent_lt
