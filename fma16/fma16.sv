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
      .Xsubnorm(Xsubnorm), .Xzero(XZero),
      .Xinf(Xinf), .Xnan(Xnan), .Xsnan(Xsnan)
   );
   unpack Yunpack (
      .Xin(y), .Xs(Ys), .Xe(Ye), .Xm(Ym),
      .Xsubnorm(Ysubnorm), .Xzero(YZero),
      .Xinf(Yinf), .Xnan(Ynan), .Xsnan(Ysnan)
   );
   unpack Zunpack (
      .Xin(z), .Xs(Zs), .Xe(Ze), .Xm(Zm),
      .Xsubnorm(Zsubnorm), .Xzero(ZZero),
      .Xinf(Zinf), .Xnan(Znan), .Xsnan(Zsnan)
   );

   //assign XZero = (Xe == 0 && Xm == 0);
   //assign YZero = (Ye == 0 && Ym == 0);
   //assign ZZero = (Ze == 0 && Zm == 0);

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
   assign Smnorm = Sm << Mcnt;
   assign Senorm = Se - Mcnt + 7'd13;

   logic [9:0] Smrnd;
   logic [6:0] Sernd;
   rne round (.Smnorm(Smnorm), .Senorm(Senorm), .ASticky(ASticky), .Smrnd(Smrnd), .Sernd(Sernd));

   assign result = {Ss, Sernd[4:0], Smrnd};
   //assign result = {Ss, Senorm[4:0], Smnorm[34:25]};

   // fmalza lza (.A(AmInv), .Pm(PmKilled), .Cin(InvA & (~ASticky | KillProd)), .sub(InvA), .SCnt);

 
endmodule

