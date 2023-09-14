//SPDX-License-Identifier: Apache License 2.0

// Solidity files have to start with this pragma.
// It will be used by the Solidity compiler to validate its version.
pragma solidity ^0.8.0;

import "./bn128_curve.sol";

contract bn128_pairing is bn128_curve {
    int private constant ate_loop_count = 29793968203157093288;
    int private constant log_ate_loop_count = 63;

    constructor() bn128_curve() {
        // Check consistency of the "line function"
        // Generator for twisted curve over FQ2
        FQP2 memory x = FQP2([FQ(10857046999023057135944570762232829481370756359578518086990519993285655852781), FQ(11559732032986387107991004021392285783925812861821192530917403151452391805634)], 
            [FQ(1), FQ(0)], 2);
        FQP2 memory y = FQP2([FQ(8495653923123431417604973247489272438418190587263600148770280649306958101930), FQ(11559732032986387107991004021392285783925812861821192530917403151452391805634)], 
            [FQ(1), FQ(0)], 2);
        PointFQP2 memory g2 = PointFQP2(x, y);
        // Generator for curve over FQ12
        PointFQP12 memory g12 = twist(g2);
        PointFQP12 memory g12_2 = double(g12);
        PointFQP12 memory g12_3 = multiply(g12, 3);
        PointFQP12 memory neg_g12 = multiply(g12, curve_order - 1);
        PointFQP12 memory neg_g12_2 = multiply(g12, curve_order - 2);
        PointFQP12 memory neg_g12_3 = multiply(g12, curve_order - 3);
        FQ[12] memory field_mod_fq12 = [FQ(82), FQ(0), FQ(0), FQ(0), FQ(0), FQ(0), FQ(field_mod - 18), FQ(0), FQ(0), FQ(0), FQ(0), FQ(0)];

        assert(eq(linefunc(g12, g12_2, g12), inf_FQP12(field_mod_fq12)));
        assert(eq(linefunc(g12, g12_2, g12_2), inf_FQP12(field_mod_fq12)));
        assert(!eq(linefunc(g12, g12_2, g12_3), inf_FQP12(field_mod_fq12)));
        assert(eq(linefunc(g12, g12_2, neg_g12_3), inf_FQP12(field_mod_fq12)));
        assert(eq(linefunc(g12, neg_g12, neg_g12), inf_FQP12(field_mod_fq12)));
        assert(eq(linefunc(g12, neg_g12, neg_g12), inf_FQP12(field_mod_fq12)));
        assert(!eq(linefunc(g12, neg_g12, g12_2), inf_FQP12(field_mod_fq12)));
        assert(eq(linefunc(g12, g12, g12), inf_FQP12(field_mod_fq12)));
        assert(!eq(linefunc(g12, g12, g12_2), inf_FQP12(field_mod_fq12)));
        assert(eq(linefunc(g12, g12, neg_g12_2), inf_FQP12(field_mod_fq12)));
    }

    // Create a function representing the line between P1 and P2, and evaluate it at T
    function linefunc(PointFQP12 memory p1, PointFQP12 memory p2, PointFQP12 memory t) internal pure returns (FQP12 memory) {
        assert(!is_inf(p1) && !is_inf(p2) && !is_inf(t));
        if (!eq(p1.x, p2.x)) {
            FQP12 memory m = div(sub(p2.y, p1.y), sub(p2.x, p1.x));
            return sub(mul(m, sub(t.x, p1.x)), sub(t.y, p1.y));
        } else if (eq(p1.y, p2.y)) {
            FQP12 memory m = div(mul(pow(p1.x, FQ(2)), FQ(3)), mul(p1.y, FQ(2)));
            return sub(mul(m, sub(t.x, p1.x)), sub(t.y, p1.y));
        } else {
            return sub(t.x, p1.x);
        }
    }

    function cast_point_to_fq12(PointFQ memory pt) internal pure returns (PointFQP12 memory) {
        if (is_inf(pt)) {
            return PointFQP12(inf_FQP12([FQ(82), FQ(0), FQ(0), FQ(0), FQ(0), FQ(0), FQ(-18), FQ(0), FQ(0), FQ(0), FQ(0), FQ(0)]),
             inf_FQP12([FQ(82), FQ(0), FQ(0), FQ(0), FQ(0), FQ(0), FQ(-18), FQ(0), FQ(0), FQ(0), FQ(0), FQ(0)]));
        }
        FQ[12] memory field_mod_fq12 = [FQ(82), FQ(0), FQ(0), FQ(0), FQ(0), FQ(0), FQ(field_mod - 18), FQ(0), FQ(0), FQ(0), FQ(0), FQ(0)];
        FQP12 memory new_x = FQP12([pt.x, FQ(0), FQ(0), FQ(0), FQ(0), FQ(0), FQ(0), FQ(0), FQ(0), FQ(0), FQ(0), FQ(0)],
        field_mod_fq12, 12);
        FQP12 memory new_y = FQP12([pt.y, FQ(0), FQ(0), FQ(0), FQ(0), FQ(0), FQ(0), FQ(0), FQ(0), FQ(0), FQ(0), FQ(0)],
        field_mod_fq12, 12);
        return PointFQP12(new_x, new_y);
    }

    // Main miller loop
    function miller_loop(PointFQP12 memory q, PointFQP12 memory p) internal pure returns (FQP12 memory) {
        FQ[12] memory field_mod_fq12 = [FQ(82), FQ(0), FQ(0), FQ(0), FQ(0), FQ(0), FQ(-18), FQ(0), FQ(0), FQ(0), FQ(0), FQ(0)];

        if (is_inf(q) || is_inf(p)) {
            return one(field_mod_fq12);
        }
        PointFQP12 memory r = q;
        FQP12 memory f = one(field_mod_fq12);

        for (int i = log_ate_loop_count; i > -1; i--) {
            f = mul(f, mul(f, linefunc(r, r, p)));
            r = double(r);

            if ((uint(ate_loop_count) & (2 ** uint(i))) != 0) {
                f = mul(f, linefunc(r, q, p));
                r = add(r, q);
            }
        }
        assert(eq(r, multiply(q, ate_loop_count)));
        PointFQP12 memory q1 = PointFQP12(pow(q.x, FQ(field_mod)), pow(q.y, FQ(field_mod)));
        assert(is_on(q1));
        PointFQP12 memory nq2 = PointFQP12(pow(q1.x, FQ(field_mod)), pow(neg(q1.y), FQ(field_mod)));
        assert(is_on(nq2));
        f = mul(f, linefunc(r, q1, p));
        r = add(r, q1);
        f = mul(f, linefunc(r, nq2, p));
        r = add(r, nq2);
        return pow(f, div(sub(pow(FQ(field_mod), FQ(12)), FQ(1)), FQ(curve_order)));
    }

    // Pairing computation
    function pairing(PointFQP2 memory q, PointFQ memory p) internal pure returns (FQP12 memory) {
        assert(is_on(q));
        assert(is_on(p));
        return miller_loop(twist(q), cast_point_to_fq12(p));
    }
}