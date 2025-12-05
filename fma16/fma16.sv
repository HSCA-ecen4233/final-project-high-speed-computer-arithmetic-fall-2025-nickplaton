// fma16.sv
// David_Harris@hmc.edu 26 February 2022

// Operation: general purpose multiply, add, fma, with optional negation
//   If mul=1, p = x * y.  Else p = x.
//   If add=1, result = p + z.  Else result = p.
//   If negr or negz = 1, negate result or z to handle negations and subtractions
//   fadd: mul = 0, add = 1, negr = negz = 0
//   fsub: mul = 0, add = 1, negr = 0, negz = 1
//   fmul: mul = 1, add = 0, negr = 0, negz = 0
//   fmadd:  mul = 1, add = 1, negr = 0, negz = 0
//   fmsub:  mul = 1, add = 1, negr = 0, negz = 1
//   fnmadd: mul = 1, add = 1, negr = 1, negz = 0
//   fnmsub: mul = 1, add = 1, negr = 1, negz = 1

module fma16 (x, y, z, mul, add, negr, negz,
	      roundmode, result, flags); // should just be x y z result 5flags
   
   input logic [15:0]  x, y, z;   
   input logic 	       mul, add, negr, negz;
   input logic [1:0]   roundmode;
   
   output logic [15:0] result;
   output logic [3:0]  flags;

   logic [4:0] 	         Xe, Ye, Ze;
   logic [10:0] 	         Xm, Ym, Zm;
   logic 	               Xs, Ys, Zs;
   logic          XZero, YZero, ZZero;
   logic Xsubnorm, Ysubnorm, Zsubnorm;
   logic             Xinf, Yinf, Zinf;
   logic             Xnan, Ynan, Znan;
   logic          Xsnan, Ysnan, Zsnan;

   unpack Xunpack (
      .Xin(x), .Xs(Xs), .Xe(Xe), .Xm(Xm),
      .Xsubnorm(Xsubnorm), .XZero(XZero),
      .Xinf(Xinf), .Xnan(Xnan), .Xsnan(Xsnan)
   );
   unpack Yunpack (
      .Xin(y), .Xs(Ys), .Xe(Ye), .Xm(Ym),
      .Xsubnorm(Ysubnorm), .XZero(YZero),
      .Xinf(Yinf), .Xnan(Ynan), .Xsnan(Ysnan)
   );
   unpack Zunpack (
      .Xin(z), .Xs(Zs), .Xe(Ze), .Xm(Zm),
      .Xsubnorm(Zsubnorm), .XZero(ZZero),
      .Xinf(Zinf), .Xnan(Znan), .Xsnan(Zsnan)
   );

   

   logic [6:0] Pe;
   fmaexpadd expadd(.Xe(Xe), .Ye(Ye), .XZero(XZero), .YZero(YZero), .Pe(Pe));
   
   logic [21:0] Pm;
   fmamult mult(.Xm(Xm), .Ym(Ym), .Pm(Pm));

   logic Ps, As, InvA;
   fmasign sign(.OpCtrl(negz), .Xs(Xs), .Ys(Ys), .Zs(Zs), .Ps(Ps), .As(As), .InvA(InvA));

   logic [35:0] Am;
   logic ASticky, KillProd;
   fmaalign align(.Ze(Ze), .Zm(Zm), .XZero(XZero), .YZero(YZero), .ZZero(ZZero), .Xe(Xe), .Ye(Ye), .Am, .ASticky, .KillProd);
   
   logic [35:0] AmInv;
   logic [21:0] PmKilled;
   logic Ss;
   logic [6:0] Se;
   logic [35:0] Sm;
   fmaadd finadd(.Am(Am), .Pm(Pm), .Ze(Ze), .Pe(Pe), .Ps(Ps), .KillProd(KillProd), .ASticky(ASticky), .AmInv(AmInv), .PmKilled(PmKilled), .InvA(InvA), .Sm(Sm), .Se(Se), .Ss(Ss));
   
   logic [6:0] Mcnt;
   lzc normalizer (.num(Sm), .ZeroCnt(Mcnt));
   
   logic [35:0] Smnorm;
   logic [6:0] Senorm;
   logic Smzero;
   assign Smzero = ~|Sm;
   assign Smnorm = ~Smzero ? (Sm << Mcnt) : 36'b0;
   logic [6:0] Setemp;
   assign Setemp = (Se - Mcnt + 13);
   assign Senorm = ~Smzero ? Setemp : 7'b0;

   logic [9:0] Smrnd;
   logic [6:0] Sernd;
   rne round (.Smnorm(Smnorm), .Senorm(Senorm), .ASticky(ASticky), .Smrnd(Smrnd), .Sernd(Sernd));

   //assign flags[0] = (ASticky|Guard|Overflow|Round)&~(InfIn|NaNIn|DivByZero|Invalid);
   //assign underflow = Setemp < 0;
   //assign flags[2] = (Senorm >= 5'd31);


   logic [15:0] int_result;
   always_comb begin
      if (roundmode == 2'b1) begin
         int_result = {Ss, Sernd[4:0], Smrnd};
      end
      else begin
         int_result = {(~Smzero ? Ss : 1'b0), Senorm[4:0], Smnorm[34:25]}; // broken
      end
   end

   fmaflags set_nv (Xs, Ys, Zs, Xsnan, Ysnan, Zsnan, Xnan, Ynan, Znan, Xinf, Yinf, Zinf, XZero, YZero, ZZero, ASticky, Smnorm, Senorm, int_result, result, flags[3], flags[2], flags[1], flags[0]);
   //assign result = {Ss, Sernd[4:0], Smrnd};
   //assign result = {Ss, Senorm[4:0], Smnorm[34:25]};

   // fmalza lza (.A(AmInv), .Pm(PmKilled), .Cin(InvA & (~ASticky | KillProd)), .sub(InvA), .SCnt);

 
endmodule

