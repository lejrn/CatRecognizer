//
// Verilog Module CTRCG_lib.CTRCG_Slow
//
// Created:
//          by - USER.UNKNOWN (ASUS-UX430UQ)
//          at - 01:53:46 10/01/2020
//
// using Mentor Graphics HDL Designer(TM) 2019.2 (Build 5)
//

`resetall
`timescale 1ns/10ps
`include "GlobalParameters.v"

module CTRCG_Slow(   
    // Port Declarations
    input wire AsyncRst,
    input wire Clk,
    input wire pSelect,
    input wire pEnable, 
    input wire pWrite,
    input wire [`AMBA_ADDR_DEPTH-1:0] pAddr,
    input wire [`AMBA_WORD-1:0] pWData,
    output wire [`AMBA_WORD-1:0] pRData,
    output wire pReady,
    output wire catrecout
);

    // Declaration of Parameters
   parameter 
        IDLE   = 2'd0,
        SETUP  = 2'd1,
        ACCESS = 2'd2;

    // Declaration of Wires, Regs and Variables
    wire pDone, startWork;
    wire [`WEIGHT_BIAS_PRECISION-1:0] Bias;
    wire [`NUMBER_OF_PIXELS*`PIXEL_PRECISION-1:0] PixData;
    wire [`NUMBER_OF_PIXELS*`WEIGHT_BIAS_PRECISION-1:0] Weights;
    
    // Lower Level Instantiation
    RST_Unit Reset(
          .Clk(Clk),
          .AsyncRst(AsyncRst),
          .SyncRst(Rst)
        );

    APB_Unit #(2'd0,2'd1,2'd2) APB_Slave(
        .Rst       (Rst),
        .Clk       (Clk),
        .pSelect   (pSelect),
        .pEnable   (pEnable),
        .pWrite    (pWrite),
        .pDone    (pDone),
        .pAddr     (pAddr),
        .pWData    (pWData),
        .pRData    (pRData),
        .Bias      (Bias),
        .PixData   (PixData),
        .Weights   (Weights),
        .startWork (startWork),
        .pReady    (pReady)
    );

    SlowMAC_Unit Slow_MAC(
        .Rst     (Rst),
        .Clk     (Clk),
        .startWork (startWork),
        .Bias    (Bias),
        .PixData (PixData),
        .Weights (Weights),
        .pDone (pDone),
        .SigmoidZ (catrecout)
    );

    // Continuous Assignments

    // Procedural Blocks

    // Generate Blocks
endmodule
