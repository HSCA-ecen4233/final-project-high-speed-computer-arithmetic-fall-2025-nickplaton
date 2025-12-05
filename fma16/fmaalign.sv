module fmaalign (Ze, Zm,
                 XZero, YZero, ZZero,
                 Xe, Ye,
                 Am, ASticky, KillProd);

    input logic [4:0] Ze, Xe, Ye;
    input logic XZero, YZero, ZZero;
    input logic [10:0] Zm;

    output logic [35:0] Am; // 35:0 36 bits?
    output logic ASticky;
    output logic KillProd;
    
    // Internal Signals
    logic [6:0] Acnt; // (Xe + Ye - bias) - Ze + Nf + 2
    logic KillZ; // = (Acnt > 3*Nf + 3)
    logic [45:0] Zmpresh; // Zm << (Nf + 2)
    logic [45:0] Zmshift; // 46 bits 45:0 for this and presh?

    //assign Acnt = ({2'b0, Xe} + {2'b0, Ye} - 7'd15) - {2'b0, Ze} + 7'd12;
    assign Acnt = ({2'b0, Xe} + {2'b0, Ye} - 7'd15) - {2'b0, Ze} + 7'd13;
    //assign KillZ  = Acnt > 33;
    assign KillZ  = $signed(Acnt) > $signed(7'd35);
    //assign Zmpresh = {2'b0, Zm} << 12;
    //assign Zmpresh = {Zm, 2'b0};
    assign Zmpresh = {Zm, 35'b0};
    
    assign KillProd = (Acnt[6] & ~ZZero) | XZero | YZero;

    always_comb begin
        if (KillProd) begin
            Zmshift = {13'b0, Zm, 22'b0};
            ASticky = ~(XZero|YZero);
        end
        else if (KillZ) begin
            Zmshift = 46'b0;
            ASticky = ~ZZero;
        end
        else begin
            Zmshift = Zmpresh >> Acnt;
            ASticky = |(Zmshift[9:0]);
        end
    end

    //assign Zmshift = KillProd ? {12'b0, Zm, 21'b0} : (KillZ ? 44'b0 : ({Zmpresh, 31'b0} >> Acnt));

    //assign ASticky = KillProd ? ~(XZero|YZero) : (KillZ ? ~ZZero : (|(Zmshift[9:0])));

    //assign Am = {Zmshift >> 10}[33:0]; // or Zmshift[43:10] ?
    assign Am = Zmshift[45:10]; // This works for some reason.

endmodule