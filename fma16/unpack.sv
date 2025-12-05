module unpack (Xin, Xs, Xe, Xm, Xsubnorm, XZero, Xinf, Xnan, Xsnan);
    
    input logic [15:0] Xin;

    output logic Xs;
    output logic [4:0] Xe;
    output logic [10:0] Xm;
    output logic Xsubnorm, XZero, Xinf, Xnan, Xsnan;

    logic Xemax, Xenonz, Xfzero;
    logic [9:0] Xf;

    // Intermediate Signals
    assign Xemax = &Xin[14:10];
    assign Xenonz = |Xin[14:10];
    assign Xf = Xin[9:0];
    assign Xfzero = ~|Xf;

    // Output Signals
    assign Xs = Xin[15];
    assign Xe = Xin[14:10] + {4'b0, (~Xenonz)};
    assign Xm = {Xenonz, Xf};

    assign Xsubnorm = (~Xenonz) & (~Xfzero);
    assign XZero = (~Xenonz) & Xfzero;
    assign Xinf = Xemax & Xfzero;
    assign Xnan = Xemax & (~Xfzero);
    assign Xsnan = Xnan & (~Xf[9]);

endmodule