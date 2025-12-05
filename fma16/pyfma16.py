#!/usr/bin/env python3
# -*- coding: utf-8 -*-
###############################################################################
# File:        fma16.py
# Author:      James E. Stine, Oklahoma State University
# Description:
#     Python model of a Binary16 (half-precision) Floating-Point
#     Fused Multiply-Add (FMA) datapath with compact debugging.
#
#     Pipeline: unpack -> exponent add -> multiply -> align -> add/sub
#               -> normalize -> round-to-nearest-even -> pack
#
# Notes:
#   * fma_mult expects 11-bit significands (hidden-one already folded in).
#   * Z’s hidden-one is added in fma_align (now at bit 35 before ACnt).
#   * fmashiftcalc uses SCnt (no +1) to avoid off-by-one in exponent.
###############################################################################

BIAS = 15
EXPONENT_BITS = 5
MANTISSA_BITS = 10
MAX_EXPONENT = (1 << EXPONENT_BITS) - 1     # 31
MAX_MANTISSA = (1 << MANTISSA_BITS) - 1     # 1023

def _bits(n, width):
    return format(n & ((1 << width) - 1), f'0{width}b')

def _hex(n, width=None):
    if isinstance(n, bool):
        return str(int(n))
    if width is None:
        return f"0x{n:X}"
    return f"0x{n:0{width}X}"

def print_unpack(un):
    print("\nUnpack (binary16 fields):")
    print(" op   s   e(dec)  e(hex)   m(hex)   m(bin10)")
    for op in ("X", "Y", "Z"):
        s = un[f"{op}s"]
        e = un[f"{op}e"]
        m = un[f"{op}m"]
        print(f" {op}   {s:1d}     {e:2d}     {_hex(e,2):>5}   {_hex(m,3):>7}   {_bits(m,10)}")

    print("\nFlags:")
    print(" op   Zero  SubN  Inf  NaN  sNaN  ExpMax  PostBox")
    pbox_key = {"X": "XPostBox", "Y": "YPostBox", "Z": "ZPostBox"}
    for op in ("X", "Y", "Z"):
        zero   = un.get(f"{op}Zero", False)
        subn   = un.get(f"{op}Subnorm", False)
        inf    = un.get(f"{op}Inf", False)
        nan    = un.get(f"{op}NaN", False)
        snan   = un.get(f"{op}SNaN", False)
        expmax = (un[f"{op}e"] == MAX_EXPONENT)
        pbox   = un.get(pbox_key[op], False)
        b = lambda v: 1 if v else 0
        print(f" {op}     {b(zero):1d}     {b(subn):1d}    {b(inf):1d}    {b(nan):1d}     {b(snan):1d}      {b(expmax):1d}       {b(pbox):1d}")

def print_stage(name, **vals):
    parts = []
    for k, v in vals.items():
        if isinstance(v, bool):
            parts.append(f"{k}={int(v)}")
        elif isinstance(v, int):
            parts.append(f"{k}={v:,} ({_hex(v)})")
        else:
            parts.append(f"{k}={v}")
    print(f"{name}: " + "  ".join(parts), end="\n\n")        

def build_sig(e, m):
    """Return 11-bit significand with implicit 1 for normals, 0 for subnormals."""
    hidden = 1 if e != 0 else 0
    return ((hidden << MANTISSA_BITS) | (m & MAX_MANTISSA)) & ((1 << 11) - 1)

def unpack_binary16(x, y, z):
    def unpack_single(num):
        if not (0 <= num <= 0xFFFF):
            raise ValueError("Binary16 value out of range")
        sign = (num >> 15) & 1
        exponent = (num >> MANTISSA_BITS) & ((1 << EXPONENT_BITS) - 1)
        mantissa = num & MAX_MANTISSA
        is_zero = exponent == 0 and mantissa == 0
        is_subnorm = exponent == 0 and mantissa != 0
        is_inf = exponent == MAX_EXPONENT and mantissa == 0
        is_nan = exponent == MAX_EXPONENT and mantissa != 0
        is_snan = is_nan and (mantissa & (1 << (MANTISSA_BITS - 1))) == 0
        is_exp_max = exponent == MAX_EXPONENT
        post_box = 1 if not (is_zero or is_subnorm) else 0
        return {
            'sign': sign, 'exponent': exponent, 'mantissa': mantissa,
            'is_zero': is_zero, 'is_subnorm': is_subnorm, 'is_inf': is_inf,
            'is_nan': is_nan, 'is_snan': is_snan, 'is_exp_max': is_exp_max,
            'post_box': post_box
        }

    x_info = unpack_single(x)
    y_info = unpack_single(y)
    z_info = unpack_single(z)

    return {
        'Xs': x_info['sign'], 'Ys': y_info['sign'], 'Zs': z_info['sign'],
        'Xe': x_info['exponent'], 'Ye': y_info['exponent'], 'Ze': z_info['exponent'],
        'Xm': x_info['mantissa'], 'Ym': y_info['mantissa'], 'Zm': z_info['mantissa'],
        'XNaN': x_info['is_nan'], 'YNaN': y_info['is_nan'], 'ZNaN': z_info['is_nan'],
        'XSNaN': x_info['is_snan'], 'YSNaN': y_info['is_snan'], 'ZSNaN': z_info['is_snan'],
        'XSubnorm': x_info['is_subnorm'], 'YSubnorm': y_info['is_subnorm'], 'ZSubnorm': z_info['is_subnorm'],
        'XZero': x_info['is_zero'], 'YZero': y_info['is_zero'], 'ZZero': z_info['is_zero'],
        'XInf': x_info['is_inf'], 'YInf': y_info['is_inf'], 'ZInf': z_info['is_inf'],
        'XExpMax': x_info['is_exp_max'],
        'XPostBox': x_info['post_box'], 'YPostBox': y_info['post_box'], 'ZPostBox': z_info['post_box'],
        'Bias': BIAS
    }

def fma_expadd(Xe, Ye, XZero, YZero):
    BIAS_LOCAL = 0xF
    if XZero or YZero:
        return 0
    result = Xe + Ye - BIAS_LOCAL
    return result & ((1 << 7) - 1)  # 7-bit internal exponent

def fma_mult(Xm, Ym):
    """22-bit product of two 11-bit significands."""
    return (Xm & ((1 << 11) - 1)) * (Ym & ((1 << 11) - 1))

def fma_sign(FOpCtrl, Xs, Ys, Zs, Ps):
    As = Zs
    InvA = Ps != Zs
    return {'As': As, 'InvA': InvA}

def fma_align(Ze, Zm, XZero, YZero, ZZero, Xe, Ye):
    # Distance between product exponent window and Ze (7 bit)
    ACnt = (Xe + Ye - 15 + 13 - Ze) & 0x7F  
    ACnt_signed = ACnt if ACnt < 64 else ACnt - 128  # signed (-64..+63)

    # Include Z hidden-one (11-bit Z significand)
    Zsig = ((1 if Ze != 0 else 0) << MANTISSA_BITS) | (Zm & MAX_MANTISSA)  # 11b

    # Place hidden at bit 35, not 34
    ZsigPreshifted = Zsig << 35

    KillProd = (ACnt & 0x40 != 0 and not ZZero) or XZero or YZero
    KillZ    = ACnt_signed > (3 * 10 + 5)  # heuristic threshold

    if KillProd:
        ZsigShifted = (Zsig << 22) & ((1 << 48) - 1)  # coarse align when killing product
        ASticky = not (XZero or YZero)
    elif KillZ:
        ZsigShifted = 0
        ASticky = not ZZero
    else:
        shift_amount = max(0, ACnt_signed)
        ZsigShifted = ZsigPreshifted >> shift_amount
        # sticky proxy from low 10 bits
        ASticky = any(ZsigShifted & (1 << i) for i in range(10))

    Am = (ZsigShifted >> 10) & ((1 << 36) - 1)  # 36-bit addend to adder
    return {'Am': Am, 'ASticky': ASticky, 'KillProd': KillProd}

def fma_add(Am, Pm, Ze, Pe, Ps, KillProd, ASticky, AmInv, PmKilled, InvA):
    # Optional inversion of Am when InvA set
    AmInv = ~Am & ((1 << 36) - 1) if InvA else Am

    # Kill product if requested
    PmKilled = 0 if KillProd else Pm

    # Align product to adder (LSB align): product is 22b -> <<2 (guard bits)
    Pm_extended = PmKilled << 2

    # Build extended addend with a leading bit when subtracting (InvA)
    Am_extended = (InvA << 36) | (AmInv & ((1 << 36) - 1))

    # Carry-in rule
    carry_in = (not ASticky or KillProd) and InvA

    # Sum
    PreSum_total = Pm_extended + Am_extended + carry_in
    NegSum = (PreSum_total >> 36) & 0x1
    PreSum = PreSum_total & ((1 << 36) - 1)

    # Negative path (two's complement-like)
    PmKilled_inv = ~PmKilled & ((1 << 22) - 1)  # 22-bit mask
    term1 = ((0xFFF << (22 + 2)) | (PmKilled_inv << 2))
    term2 = ((int((not ASticky) or (not KillProd))) & 0x1) << 2
    NegPreSum = (Am + term1 + term2) & ((1 << 36) - 1)

    Sm = NegPreSum if NegSum else PreSum
    Ss = NegSum ^ Ps
    Se = Ze if KillProd else Pe  

    return {'Sm': Sm, 'Se': Se, 'Ss': Ss}

def fmashiftcalc(Se, Sm, SCnt):
    MASK7  = (1 << 7)  - 1  # 0x7F
    MASK6  = (1 << 6)  - 1  # 0x3F
    MASK36 = (1 << 36) - 1
    Se   = Se   & MASK7
    Sm   = Sm   & MASK36
    SCnt = SCnt & MASK6
    SZero = (Sm == 0)

    inv_SCnt_6 = (~SCnt) & MASK6
    ext_inv_SCnt_7 = (1 << 6) | inv_SCnt_6  # 7-bit number

    PreNormSumExp = (Se + ext_inv_SCnt_7 + 14) & MASK7
    NormSumExp = PreNormSumExp

    def to_s7(u7):
        u7 &= MASK7
        return u7 - 128 if (u7 & 0x40) else u7

    sPre = to_s7(PreNormSumExp)
    PreResultSubnorm = (sPre <= 0) and (sPre >= -10)

    if PreResultSubnorm:
        PreShiftAmt = ((Se & MASK6) + 13) & MASK6
    else:
        # Off-by-one fix: DO NOT add +1 here
        PreShiftAmt = (SCnt) & MASK6

    return {
        "NormSumExp": NormSumExp,        
        "SZero": SZero,                  
        "PreResultSubnorm": PreResultSubnorm,
        "PreShiftAmt": PreShiftAmt       
    }

def lzc36(x):
    if x == 0:
        return 36
    return 36 - x.bit_length()

def pack_from_sum(Sm, Se, Ss, verbose=True):
    """Normalize 36b sum Sm with base exponent Se, round-to-nearest-even, pack to binary16."""
    if Sm == 0:
        return (Ss << 15)  # +0/-0

    # Normalize window via LZC and fmashiftcalc policy
    SCnt = lzc36(Sm & ((1 << 36) - 1))
    calc = fmashiftcalc(Se, Sm, SCnt)
    if verbose:
        print(f"fmashiftcalc: "
          f"NormSumExp={calc['NormSumExp']} "
          f"SZero={calc['SZero']} "
          f"PreResultSubnorm={calc['PreResultSubnorm']} "
          f"PreShiftAmt={calc['PreShiftAmt']}")
    
    shift = calc["PreShiftAmt"] & 0x3F
    e7    = calc["NormSumExp"] & 0x7F
    sub   = bool(calc["PreResultSubnorm"])

    # Right-shift to expose: [ .. hidden | frac10 | G | R | sticky... ]
    Sm_shift = ((Sm << shift) & ((1 << 36) - 1)) if shift < 64 else 0

    # Extract rounding window: top 11 bits (hidden+10) + G R S
    frac11  = (Sm_shift >> 25) & 0x7FF          # bits 35..25
    mant10  =  frac11 & 0x3FF                   # 10 fraction bits
    guard   = (Sm_shift >> 24) & 0x1
    roundb  = (Sm_shift >> 23) & 0x1
    sticky  = 1 if (Sm_shift & ((1 << 23) - 1)) != 0 else 0

    # Round to nearest, ties-to-even
    tie     = (guard == 1 and roundb == 0 and sticky == 0)
    incr    = (guard and (roundb or sticky)) or (tie and (mant10 & 1))
    if incr:
        mant10 += 1
        if mant10 == (1 << 10):   # carry out -> renormalize
            mant10 = 0
            e7 = (e7 + 1) & 0x7F

    # Map internal 7b exponent to final 5b (clamp); subnormals emit exp=0
    if sub:
        exp5 = 0
    else:
        exp5 = max(0, min(31, e7 & 0x1F))

    # Overflow to \pm Inf (when exp saturates)
    if exp5 == 0x1F and not sub:
        return (Ss << 15) | (0x1F << 10)

    # Pack sign | exp | mant
    return (Ss << 15) | (exp5 << 10) | (mant10 & 0x3FF)

def fma_binary16(x, y, z, FOpCtrl=0, verbose=True):
    """Perform FMA with binary16 inputs; compact debug printing if verbose."""
    unpack_out = unpack_binary16(x, y, z)
    if verbose:
        print(f"\nTesting x=0x{x:04X} ({binary16_to_float(x)}), "
              f"y=0x{y:04X} ({binary16_to_float(y)}), "
              f"z=0x{z:04X} ({binary16_to_float(z)}):")
        print_unpack(unpack_out)

    # unpack
    if unpack_out['XNaN'] or unpack_out['YNaN'] or unpack_out['ZNaN']:
        if verbose: print_stage("SpecialCase", reason="NaN")
        return {'result': 0x7C00}
    if (unpack_out['XInf'] and unpack_out['YZero']) or (unpack_out['YInf'] and unpack_out['XZero']):
        if verbose: print_stage("SpecialCase", reason="Inf*Zero")
        return {'result': 0x7C00}
    if unpack_out['XInf'] or unpack_out['YInf']:
        Ps = unpack_out['Xs'] ^ unpack_out['Ys']
        if unpack_out['ZInf'] and (Ps != unpack_out['Zs']):
            if verbose: print_stage("SpecialCase", reason="Inf + (-Inf)")
            return {'result': 0x7C00}
        result_inf = (Ps << 15) | (MAX_EXPONENT << MANTISSA_BITS)
        if verbose: print_stage("SpecialCase", reason="Inf", result=result_inf)
        return {'result': result_inf}

    # Exponent add
    Pe = fma_expadd(unpack_out['Xe'], unpack_out['Ye'],
                    unpack_out['XZero'], unpack_out['YZero'])
    if verbose: print_stage("ExpAdd", Pe=Pe)

    # Build 11-bit significands with hidden-one before multiply
    Xsig = build_sig(unpack_out['Xe'], unpack_out['Xm'])
    Ysig = build_sig(unpack_out['Ye'], unpack_out['Ym'])

    # Multiplier (22-bit product)
    Pm = fma_mult(Xsig, Ysig)
    if verbose: print_stage("Mult", Pm=Pm)

    # Product sign
    Ps = unpack_out['Xs'] ^ unpack_out['Ys']
    sign_out = fma_sign(FOpCtrl, unpack_out['Xs'], unpack_out['Ys'], unpack_out['Zs'], Ps)
    if verbose: print_stage("Sign", Ps=Ps, As=sign_out['As'], InvA=sign_out['InvA'])

    # Align Z to product exponent window (with Z hidden-one)
    align_out = fma_align(unpack_out['Ze'], unpack_out['Zm'],
                          unpack_out['XZero'], unpack_out['YZero'], unpack_out['ZZero'],
                          unpack_out['Xe'], unpack_out['Ye'])
    if verbose: print_stage("Align", Am=align_out['Am'], ASticky=align_out['ASticky'], KillProd=align_out['KillProd'])

    # Add / subtract
    add_out = fma_add(align_out['Am'], Pm, unpack_out['Ze'], Pe, Ps,
                      align_out['KillProd'], align_out['ASticky'],
                      AmInv=0, PmKilled=0, InvA=sign_out['InvA'])
    if verbose: print_stage("Add", Sm=add_out['Sm'], Se=add_out['Se'], Ss=add_out['Ss'])

    # Normalize + round + pack
    packed = pack_from_sum(add_out['Sm'], add_out['Se'], add_out['Ss'])
    return {'result': packed}

def binary16_to_float(hex_val):
    """Convert a binary16 (half-precision) hex value to floating-point decimal."""
    sign = (hex_val >> 15) & 0x1
    exponent = (hex_val >> 10) & 0x1F
    fraction = hex_val & 0x3FF

    if exponent != 0:
        mantissa = 1.0 + fraction / 1024.0  # 1 + fraction/2^10
        value = (-1)**sign * mantissa * 2**(exponent - 15)
    else:
        mantissa = fraction / 1024.0
        value = (-1)**sign * mantissa * 2**(-14)
    return value

if __name__ == "__main__":
    x = 0x0400   # 2^-14 ≈ 6.1035e-05
    y = 0x3c00   # 32.0
    z = 0xb800   # 0.5
    out = fma_binary16(x, y, z, verbose=True)
    print(f"\nResult packed: 0x{out['result']:04X}")
    