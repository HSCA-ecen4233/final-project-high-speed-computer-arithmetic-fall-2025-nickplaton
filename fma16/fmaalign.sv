module fmaalign (Ze, Zm,
                 XZero, YZero, ZZero,
                 Xe, Ye,
                 Am, ASticky, KillProd);

    input logic [4:0] Ze, Xe, Ye;
    input logic XZero, YZero, ZZero;
    input logic [10:0] Zm;

    output logic [33:0] Am;
    output logic ASticky;
    output logic KillProd;
    
    // Internal Signals
    logic [6:0] Acnt; // (Xe + Ye - bias) - Ze + Nf + 2
    logic KillZ; // = (Acnt > 3*Nf + 3)
    logic [12:0] Zmpresh; // Zm << (Nf + 2)
    logic [43:0] Zmshift;

    assign Acnt = ({2'b0, Xe} + {2'b0, Ye} - 7'd15) - {2'b0, Ze} + 7'd12;
    assign KillZ  = Acnt > 33;
    assign Zmpresh = {2'b0, Zm} << 12;
    
    assign KillProd = Acnt[6] | XZero | YZero;

    assign Zmshift = KillProd ? {12'b0, Zm, 21'b0} : (KillZ ? 0 : ({Zmpresh, 31'b0} >> Acnt));

    assign ASticky = KillProd ? ~(XZero|YZero) : (KillZ ? ~ZZero : (|(Zmshift[9:0])));

    assign Am = {Zmshift >> 10}[33:0];

endmodule