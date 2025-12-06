# High Speed Computer Arithmetic Final Project Fall 2025

###### Thomas Parsley

## Introduction
**Completed FMA Block Diagram:**  
  

**Explanation of Architecture:**  
  In this design, there are 11 major blocks that perform functions of the FMA:

- *fma16.sv*: Contains instantiations of all other modules, connecting each of the blocks and returning the result.
- *unpack.sv*: Unpacks X, Y, and Z into their sign, exponent, and mantissa components. While doing this, it follows IEEE steps, such as adding 1'b1 to the mantissa for the hidden bit and keeping the exponent normalized. Handles signals such as Xsubnorm, Xzero, Xinf, XNaN, and XsNaN.
- *fmaexpadd.sv*: Adds the exponents of each multiplicand and removes the bias according to the IEEE half precision floating point number bias.
- *fmamult.sv*: Multiplies the mantissa's of X and Y.
- *fmasign.sv*: Uses an XOR to find the sign of the product of X and Y and uses the sign of Z to decide addition or subraction. Then, InvA is set as the XOR of those two outcomes.
- *fmaalign.sv*: Aligns the product and Z to be added later. There are three separate calculations for this module, one for when the product is insignificant, one for when Z is insignificant, and one wher both are significant. A "sticky" bit is calculated for as well, keeping track of any precision lost in alignment.
- *fmaadd.sv*: Using the aligned values from fmaalign.sv, this module adds the values together. The module calculates for both addition and subtraction and uses the InvA from before to decide whether the output is the added or subtracted value.
- *lzc.lzc.sv*: Counts the amount of leading zeros in the mantissa.
- *lzc.normalizer.sv*: Shifts the matntissa the amount decided by the lzc module to normalize the manitssa. The amount it was shifted is added to the exponent.
- *round.sv*: Rounds the values according to the rounding mode. Implemented is both RNE and RZ, with roundmode 2'b00 signifying RZ and everything else signifying RNE. The RZ values are generated suing truncation, while the RNE values are generated using LSB, guard, sticky, and round bits. Importantly, the RNE value has to make sure it is normalized in the case that a result has an overflow after rounding. This is done by shifting the result back and adding one to the exponenet.
-*fmaflags.sv*: Handles all special cases and flags using the values from the unpack and round modules.

**Summary of Major Optimizations:**  
  No major optimizations were performed. However, for some use cases, a Round-to-Zero (RZ) round mode can be used. Depending on the application this could help reduce timing as long as the rounding does not need to be as detailed as RNE.

---

## Test Results
Overall, the design passed all tests given. The only test that did not pass was the *baby_torture.sv* test. I believe it is likely to be a problem how the test vectors themselves are input rather than the design.

**Lint Status:**  
  The design is clean. No errors or warnings when running it through the QuestaSim simulation or synthesis.

**Test Coverage:**  
| Test Name | Status |
|-----------|--------|
| fmul_0    | Passed |
| fmul_1    | Passed |
| fmul_2    | Passed |
| fadd_0    | Passed |
| fadd_1    | Passed |
| fadd_2    | Passed |
| fma_0     | Passed |
| fma_1     | Passed |
| fma_2     | Passed |
| fma_special_rz     | Passed |
| fma_special_rne    | Passed |
| baby_torture     | Failed |

**Results on Torture.tv:**  
  The design failed *baby_torture.sv*. This is believed to be beacuse of its 

---

## Synthesis Results
The design was moved to a different repository to do the synthesis. This repository contains the reports from the synthesis and the exact files used in the synthesis.

**Hierarchical Area Report:**  
  

**Timing Report:**  
    

**Critical Path Annotated on Block Diagram:**  
   

**Power Report:**  
  

**Energy-Delay Product (EDP):**  
  

---

## Project Management
Most of the work on the project was done in the last few weeks of the allotted time, due to various reasons. 

**Weekly Time Spent Table:**

| Week (Monday) | Hours |
|---------------|-------|
| 1 (10/27)     | 0     |
| 2 (11/3)      | 0     |
| 3 (11/10)     | 0     |
| 4 (11/17)     | 1     |
| 5 (11/24)     | 6     |
| 6 (12/1)      | 50    |

**Reflections on Lessons Learned:**  
  Through the process of completing this project, I have come to realize the amount of time it takes to deubg faulty code. Through the semester, I had to put off this project to prioritize other classes. This resulted in needing to quickly debug code within a short amount of time. In the future, I hope to be able to estimate the time it will take to complete a hardware design project with a higher accuracy, possibly overestimating the time it takes so that the process is not as stressful.

---

## Conclusion
The FMA design was almost successfully simulated. Errors occur in the special cases for a half precision FMA. However, the faulty FMA was able to synthesize, resulting in PPA reports for the design.

