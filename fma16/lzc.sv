module lzc (input logic [33:0] num, output logic [6:0] ZeroCnt);

  integer i;
  
  always_comb begin
    i = 0;
    while ((i < 34) & ~num[33-i]) i = i+1;  // search for leading one
    ZeroCnt = i[6:0];
  end
endmodule
