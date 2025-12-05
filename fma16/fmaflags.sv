module fmaflags (input logic Xs, Ys, Zs, Xsnan, Ysnan, Zsnan, Xnan, Ynan, Znan, Xinf, Yinf, Zinf, XZero, YZero, ZZero, ASticky, logic [35:0] Smnorm, logic [6:0] Senorm, logic [15:0] int_result,
                output logic [15:0] adjusted_result, logic flag_nv, flag_of, flag_uf, flag_nx);

    always_comb begin
        // At least one signaling NaN - result = NaN, flag_nv = 1
        if (Xsnan | Ysnan | Zsnan) begin
            adjusted_result = 16'h7e00;
            flag_nv = 1'b1;
            flag_of = 1'b0;
        end
        // At least one NaN - result = NaN, flag_nv = 0
        else if (Xnan | Ynan | Znan) begin
            adjusted_result = 16'h7e00;
            flag_nv = 1'b0;
            flag_of = 1'b0;
        end
        // At least one inf and Z is inf of opposite sign - result = NaN, flag_nv = 1
        else if ((Xinf | Yinf) & Zinf & (Xs^Ys^Zs)) begin
            adjusted_result = 16'h7e00;
            flag_nv = 1'b1;
            flag_of = 1'b0;
        end
        // One 0 and one inf with normal Z - result = NaN, flag_nv = 1
        else if ((Xinf & YZero) | (XZero & Yinf)) begin
            adjusted_result = 16'h7e00;
            flag_nv = 1'b1;
            flag_of = 1'b0;
        end
        // At least one inf - result = inf, flag_nv = 0
        else if (Xinf | Yinf) begin
            adjusted_result = {Xs^Ys, 5'h1f, 10'b0};
            flag_nv = 1'b0;
            flag_of = 1'b0;
        end
        else if (Zinf) begin
            adjusted_result = {Zs, 5'h1f, 10'b0};
            flag_nv = 1'b0;
            flag_of = 1'b0;
        end
        // Otherwise just take normal value
        else if (Senorm >= 5'd31) begin
            flag_of = 1'b1;
            adjusted_result = {int_result[15], 15'b111101111111111};
            flag_nv = 1'b0;
        end
        else begin
            adjusted_result = int_result;
            flag_nv = 1'b0;
            flag_of = 1'b0;
        end
      /*else if (Xinf | Yinf) begin
         if (Zinf & (Ps ^ Zs)) begin
            result = 16'h7e00;
            flags[3] = 1'b1;
         end
         else begin
            result = {Ps, 5'h1f, 10'b0};
         end
      end
      else if (Zinf) begin
         result = {Zs, 5'h1f, 10'b0};
      end*/
    end
    // L = Smnorm[25]
    // G = Smnorm[24]
    // R = Smnorm[23]
    // S = ASticky
    assign flag_nx = (ASticky|Smnorm[24]|flag_of|Smnorm[23])&~(Xinf|Yinf|Zinf|Xnan|Ynan|Znan|flag_nv);
    assign flag_uf = ($signed(Senorm) <= 0) & ASticky;

endmodule