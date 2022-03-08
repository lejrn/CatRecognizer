//
// Verilog Module CTRCG_lib.MAC_Unit
//
// Created:
//          by - USER.UNKNOWN (ASUS-UX430UQ)
//          at - 00:35:13 26/12/2019
//
// using Mentor Graphics HDL Designer(TM) 2019.2 (Build 5)
//

`resetall
`timescale 1ns/10ps
`include "GlobalParameters.v"

module SlowMAC_Unit( 
     // Port Declarations
    input wire Rst,
    input wire Clk, 
    input wire startWork,
    input wire signed [`WEIGHT_BIAS_PRECISION-1:0] Bias, 
    input wire signed [`NUMBER_OF_PIXELS*`PIXEL_PRECISION-1:0] PixData, 
    input wire signed [`NUMBER_OF_PIXELS*`WEIGHT_BIAS_PRECISION-1:0] Weights,
    output wire pDone,
    output reg SigmoidZ
    );

        // Declaration of Wires, Regs and Variables
        reg signed [`PIXEL_PRECISION-1:0] Pixel; // one more bit for the sign, though there's no need for singed pixel
        reg signed [`WEIGHT_BIAS_PRECISION-1:0] Weight;
        reg signed [19:0] Accumulator,Result; // On average, 19 is the extreme case of biggest number
        reg Done, FirstRun;
        reg [13:0] n; // Counts up to n=12288
        
        // Lower Level Instantiations

        // Continuous Assignments
        assign pDone = Done;

        // Procedural Blocks
        always @ (posedge Clk, negedge Rst) 
        begin: Counter
                if(!Rst) 
                        n<=0;
                else if(startWork) 
                        begin
                        if(n < `NUMBER_OF_PIXELS)
                                n <= n+1;
                        else
                                n <= 0;
                        end
        end


        always @ (posedge Clk, negedge Rst) 
        begin: MAC
                if(!Rst) 
                begin
                        Pixel <=0;
                        Weight <=0;
                        Accumulator <= 0;
                        Result <= Bias;
                        SigmoidZ <= 0;
                        Done <= 1;
                        FirstRun <= 0;
                end
                else if(startWork)
                        begin
                        FirstRun <= 1;
                        if(n == 0)
                                begin
                                Done <= 0;
                                Pixel <= PixData[`PIXEL_PRECISION*(n+1)-1-:`PIXEL_PRECISION];
                                Weight <= Weights[`WEIGHT_BIAS_PRECISION*(n+1)-1-:`WEIGHT_BIAS_PRECISION];
                                end
                        else if(0 < n & n < `NUMBER_OF_PIXELS) 
                                begin
                                //Done <= 0;
                                Pixel <= PixData[`PIXEL_PRECISION*(n+1)-1-:`PIXEL_PRECISION];
                                Weight <= Weights[`WEIGHT_BIAS_PRECISION*(n+1)-1-:`WEIGHT_BIAS_PRECISION];
                                Accumulator <= Accumulator + Pixel*Weight;
                                end
                        else
                                begin
                                Done <= 1;
                                Result <= Result + Accumulator;
                                Pixel <=0;
                                Weight <=0;
                                Accumulator <= 0;
                                end
                        end
                else 
                        begin
                        if(Done & FirstRun)
                                SigmoidZ <= ~Result[19];
                         else 
                                SigmoidZ <= 0;
                        Result <= Bias;
                        end     
        end
endmodule






