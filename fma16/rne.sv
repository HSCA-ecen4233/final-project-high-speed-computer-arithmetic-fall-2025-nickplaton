module rne (Smnorm, Senorm, ASticky, Smrnd, Sernd);

    input logic [35:0] Smnorm;
    input logic [6:0] Senorm;
    input logic ASticky;

    output logic [9:0] Smrnd;
    output logic [6:0] Sernd;

    logic rnd;

    // RND = G & (R | L | S)
    // L = Smnorm[25]
    // G = Smnorm[24]
    // R = Smnorm[23]
    // S = ASticky
    assign rnd = Smnorm[24] & (Smnorm[23]|Smnorm[25]|ASticky);

    always_comb begin
        if (rnd) begin
            if (&Smnorm[34:25]) begin
                Sernd = Senorm + 1;
                Smrnd = 10'b0;
            end
            else begin
                Sernd = Senorm;
                Smrnd = Smnorm[34:25] + 10'd1;
            end
        end
        else begin
            Sernd = Senorm;
            Smrnd = Smnorm[34:25];
        end
    end
    
endmodule