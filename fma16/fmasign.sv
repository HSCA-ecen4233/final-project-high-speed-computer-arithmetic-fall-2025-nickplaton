module fmasign (OpCtrl, Xs, Ys, Zs, Ps, As, InvA);

    input logic OpCtrl;
    input logic Xs, Ys, Zs;

    output logic Ps, As, InvA;

    assign Ps   =     Xs ^ Ys;
    assign As   = Zs ^ OpCtrl;
    assign InvA =     Ps ^ As;
    
endmodule