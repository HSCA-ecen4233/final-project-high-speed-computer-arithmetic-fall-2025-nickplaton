module fmaadd (Am, Pm, Ze, Pe, Ps, KillProd,
                   ASticky, AmInv, PmKilled, InvA,
                   Sm, Se, Ss);

    input logic [33:0] Am;
    input logic [21:0] Pm;
    input logic [4:0] Ze;
    input logic [6:0] Pe;
    input logic Ps, KillProd, ASticky, InvA;

    output logic [33:0] AmInv;
    output logic [21:0] PmKilled;
    output logic Ss;
    output logic [6:0] Se;
    output logic [33:0] Sm;

    logic [33:0] PreSum, NegPreSum;
    logic NegSum;
    logic [23:0] PmKext;

    assign AmInv = ~InvA ? Am : ~Am;
    assign PmKilled = Pm & {22{(~KillProd)}};
    assign PmKext = {PmKilled, 2'b00};
    assign PreSum = {10'b0, PmKext} + AmInv + {33'b0,(~ASticky|KillProd)&InvA};
    assign NegPreSum = Am + {10'b0, ~PmKilled, 2'b0} + {33'b0, (~ASticky|~KillProd)};
    assign NegSum = PreSum[33];

    assign Ss = Ps ^ NegSum;
    assign Se = ~KillProd ? Pe : {2'b0, Ze};
    assign Sm = ~NegSum ? PreSum : NegPreSum;

endmodule