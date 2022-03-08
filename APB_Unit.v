//
// Verilog Module CTRCG_lib.APB_Unit
//
// Created:
//          by - USER.UNKNOWN (ASUS-UX430UQ)
//          at - 01:00:39 05/01/2020
//
// using Mentor Graphics HDL Designer(TM) 2019.2 (Build 5)
//

`resetall
`timescale 1ns/10ps
`include "GlobalParameters.v"

module APB_Unit(   
    // Port Declarations
    input wire Rst,
    input wire Clk,
    input wire pSelect,
    input wire pEnable, 
    input wire pWrite,
    input wire pDone,
    input wire [`AMBA_ADDR_DEPTH-1:0] pAddr,
    input wire [`AMBA_WORD-1:0] pWData,
    output reg [`AMBA_WORD-1:0] pRData,
    output reg [`WEIGHT_BIAS_PRECISION-1:0] Bias,
    output wire [`NUMBER_OF_PIXELS*`PIXEL_PRECISION-1:0] PixData, 
    output reg [`NUMBER_OF_PIXELS*`WEIGHT_BIAS_PRECISION-1:0] Weights,
    output reg startWork, pReady
);
    // Declaration of Parameters
    parameter 
          IDLE   = 2'd0,
          SETUP  = 2'd1,
          ACCESS = 2'd2;

    // Declaration of Wires, Regs and Variables
    reg [1:0] Current_State, Next_State;
    reg [`AMBA_WORD-1:0] RF [2**`AMBA_ADDR_DEPTH-1:0];
    reg [`AMBA_ADDR_DEPTH-1:0] tAddr;
    reg [`AMBA_WORD-1:0] tWData;
    reg tWrite;
    //wire [`AMBA_WORD*(2**`AMBA_ADDR_DEPTH-1)-1:0] PixDataWire;

    // Lower Level Instantiation

    // Continuous Assignments

    // Procedural Blocks
    always @(negedge Rst) begin: Reset
        if(!Rst) begin
            Bias <= $ceil(3);
            `include "Weights5Bit_8PXL.v"
        end
    end

    always @(*) begin: WorkFlow
        if(startWork == 1 & pDone == 0) begin
            pReady <= 0;
        end
        else if(RF[0][0] == 0 & pDone == 1) begin
            pReady <= 1;
            startWork <= 0;
        end
        else if(RF[0][0] == 1) begin
            pReady <= 0;
            if(pDone == 1)
                startWork<=1;
        end
    end

    always @(posedge Clk, negedge Rst) begin: CurrentState
        if (!Rst) begin
            Current_State <= IDLE;
        end
        else 
            Current_State <= Next_State;
    end // Clocked Current_State Block

    always @(Current_State, pEnable, pReady, pSelect) begin: FSM
        case (Current_State) 
            IDLE: begin
                if (pSelect == 1 & pEnable == 0)
                    Next_State = SETUP;
                else
                    Next_State = IDLE;
            end
            SETUP: begin
                if(pSelect == 0)
                    Next_State = IDLE;
                else if (pSelect == 1 & pEnable == 1)
                    Next_State = ACCESS;
                else
                    Next_State = SETUP;
            end
            ACCESS: begin
                if (pSelect == 0)
                    Next_State = IDLE;
                else if (pSelect == 1 & pEnable == 0 & pReady == 1)
                    Next_State = SETUP;
                else
                    Next_State = ACCESS;
            end
            default:
                Next_State = IDLE;
        endcase
    end // Next State Block

    always @(posedge Clk) begin: Transfer
        if(Current_State == IDLE) begin
            RF[0] <= 0;
            pRData <= 0;
            tAddr <= 0;
            tWData <= 0;
            tWrite <= 0;
        end
        else if(Current_State == SETUP) begin
                tAddr <= pAddr;
                tWData <= pWData;
                tWrite <= pWrite;
        end
        else if(Current_State == ACCESS) begin
            if(pReady)
                if(tWrite) begin
                    RF[tAddr] <= tWData;
                    tAddr <= 0;
                    tWData <= 0;
                    tWrite <= 0;
                end
                else
                    pRData <= RF[tAddr];
            else
                RF[0]<=0;
        end
    end

    // Generate Blocks
    genvar row,col; 
    generate
        for(row=0; row<$ceil(`NUMBER_OF_PIXELS*`PIXEL_PRECISION/`AMBA_WORD); row=row+1)
            for(col=0; col<(`AMBA_WORD/`PIXEL_PRECISION); col=col+1)
                assign PixData[`AMBA_WORD*row+`PIXEL_PRECISION*(col+1)-1-:`PIXEL_PRECISION] = RF[row+1][`PIXEL_PRECISION*(col+1)-1-:`PIXEL_PRECISION];
    endgenerate

endmodule // APB_Unit
