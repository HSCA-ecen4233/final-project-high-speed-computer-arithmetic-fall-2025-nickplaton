module fmamult (input  logic [10:0]  Xm, Ym,
                output logic [21:0] Pm);

    assign Pm = Xm * Ym;
    
endmodule