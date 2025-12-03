module fmaexpadd (input  logic [4:0] Xe, Ye,
                  input  logic XZero, YZero,
                  output logic [6:0] Pe);
    
    assign Pe = (XZero || YZero) ? 0 : Xe + Ye - 15;

endmodule