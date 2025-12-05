module lzc (input logic [35:0] num, output logic [6:0] ZeroCnt);

  integer i;
  
  always_comb begin
    i = 0;
    while ((i < 36) & ~num[35-i]) i = i+1;  // search for leading one
    ZeroCnt = i[6:0];
  end
endmodule
