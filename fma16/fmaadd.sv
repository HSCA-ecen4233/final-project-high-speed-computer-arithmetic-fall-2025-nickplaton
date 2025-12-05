module fmaadd (Am, Pm, Ze, Pe, Ps, KillProd,
                   ASticky, AmInv, PmKilled, InvA,
                   Sm, Se, Ss);

    input logic [35:0] Am;
    input logic [21:0] Pm;
    input logic [4:0] Ze;
    input logic [6:0] Pe;
    input logic Ps, KillProd, ASticky, InvA;

    output logic [35:0] AmInv;
    output logic [21:0] PmKilled;
    output logic Ss;
    output logic [6:0] Se;
    output logic [35:0] Sm;

    logic [35:0] PreSum, NegPreSum;
    logic NegSum;

    assign AmInv = ~InvA ? Am : ~Am;
    assign PmKilled = ~KillProd ? Pm : 22'b0;
    assign {NegSum, PreSum} = {13'b0, PmKilled, 2'b0} + {InvA, AmInv} + {35'b0,(~ASticky|KillProd)&InvA};
    //assign NegPreSum = Am + {12'b1, ~PmKilled, 2'b0} + {33'b0, (~ASticky|~KillProd), 2'b0}; // Why does it trail with 2'b0?
    assign NegPreSum = Am + {{12{1'b1}}, ~PmKilled, 2'b0} + {33'b0, (~ASticky|~KillProd), 2'b0}; // Why does it trail with 2'b0?
    //assign NegSum = PreSum[33];
    //assign NegSum = PreSum[35];

    assign Ss = Ps ^ NegSum;
    assign Se = ~KillProd ? Pe : {2'b0, Ze};
    assign Sm = ~NegSum ? PreSum : NegPreSum;

endmodule