//SPDX-License-Identifier: Apache License 2.0

// Solidity files have to start with this pragma.
// It will be used by the Solidity compiler to validate its version.
pragma solidity ^0.8.0;

import "./bn128_field_elements.sol";

contract bn128_curve is bn128_field_elements {
    int internal constant curve_order = 21888242871839275222246405745257275088548364400416034343698204186575808495617;

    struct PointFQ {
        FQ x;
        FQ y;
    }
    struct PointFQP2 {
        FQP2 x;
        FQP2 y;
    }
    struct PointFQP12 {
        FQP12 x;
        FQP12 y;
    }

    constructor() bn128_field_elements() {
        // Curve is y**2 = x**3 + 3
        // Generator for curve over FQ
        PointFQ memory g1 = PointFQ(FQ(1), FQ(2));
        // Generator for twisted curve over FQ2
        FQP2 memory x = FQP2([FQ(10857046999023057135944570762232829481370756359578518086990519993285655852781), FQ(11559732032986387107991004021392285783925812861821192530917403151452391805634)], 
            [FQ(1), FQ(0)], 2);
        FQP2 memory y = FQP2([FQ(8495653923123431417604973247489272438418190587263600148770280649306958101930), FQ(11559732032986387107991004021392285783925812861821192530917403151452391805634)], 
            [FQ(1), FQ(0)], 2);
        PointFQP2 memory g2 = PointFQP2(x, y);
        // Generator for curve over FQ12
        PointFQP12 memory g12 = twist(g2);

        assert(2 ** uint(curve_order) % uint(curve_order) == 2);
        assert((uint(field_mod) ** 12 - 1) % uint(curve_order) == 0);
        assert(is_on(g1));
        assert(is_on(g2));
        assert(is_on(g12));
    }

    // Check if a point is the point at infinity
    function is_inf (PointFQ memory pt) internal pure returns (bool) {
        return pt.x.n == 0 && pt.y.n == 0;
    }

    function is_inf (PointFQP2 memory pt) internal pure returns (bool) {
        for (uint i = 0; i < 2; i++) {
            if (pt.x.coefficients[i].n != 0 || pt.y.coefficients[i].n != 0) {
                return false;
            }
        }
        return true;
    }

    function is_inf (PointFQP12 memory pt) internal pure returns (bool) {
        for (uint i = 0; i < 12; i++) {
            if (pt.x.coefficients[i].n != 0 || pt.y.coefficients[i].n != 0) {
                return false;
            }
        }
        return true;
    }

    // Check that a point is on the curve defined by y**2 == x**3 + b
    function is_on(PointFQ memory pt) internal pure returns (bool) {
        if (is_inf(pt)) {
            return true;
        }
        return pow(pt.y, FQ(2)).n - pow(pt.x, FQ(3)).n == 3;
    }

    function is_on(PointFQP2 memory pt) internal pure returns (bool) {
        if (is_inf(pt)) {
            return true;
        }
        // Twisted curve over FQ**2
        FQP2 memory b2_1 = FQP2([FQ(3), FQ(0)], [FQ(1), FQ(0)], 2);
        FQP2 memory b2_2 = FQP2([FQ(9), FQ(1)], [FQ(1), FQ(0)], 2);
        FQP2 memory b2 = div(b2_1, b2_2);

        return eq(sub(pow(pt.y, FQ(2)), pow(pt.x, FQ(3))), b2);
    }

    function is_on(PointFQP12 memory pt) internal pure returns (bool) {
        if (is_inf(pt)) {
            return true;
        }
        // Extension curve over FQ**12; same b value as over FQ
        FQP12 memory b12 = FQP12([FQ(3), FQ(0), FQ(0), FQ(0), FQ(0), FQ(0), FQ(0), FQ(0), FQ(0), FQ(0), FQ(0), FQ(0)],
            [FQ(82), FQ(0), FQ(0), FQ(0), FQ(0), FQ(0), FQ(field_mod - 18), FQ(0), FQ(0), FQ(0), FQ(0), FQ(0)],
            12);   

        return eq(sub(pow(pt.y, FQ(2)), pow(pt.x, FQ(3))), b12);
    }

    // "Twist" a point in E(FQ2) into a point in E(FQ12)
    function twist(PointFQP2 memory pt) internal pure returns (PointFQP12 memory) {
        FQ[12] memory field_mod_fq12 = [FQ(82), FQ(0), FQ(0), FQ(0), FQ(0), FQ(0), FQ(-18), FQ(0), FQ(0), FQ(0), FQ(0), FQ(0)];

        if (is_inf(pt)) {
            FQP12 memory x = inf_FQP12(field_mod_fq12);
            FQP12 memory y = inf_FQP12(field_mod_fq12);
            return PointFQP12(x, y);
        }
        // Field isomorphism from Z[p] / x**2 to Z[p] / x**2 - 18*x + 82
        pt.x.coefficients = [sub(pt.x.coefficients[0], mul(pt.x.coefficients[1], FQ(9))), pt.x.coefficients[1]];
        pt.y.coefficients = [sub(pt.y.coefficients[0], mul(pt.y.coefficients[1], FQ(9))), pt.y.coefficients[1]];
        // Isomorphism into subfield of Z[p] / w**12 - 18 * w**6 + 82, where w**6 = x
        FQP12 memory new_x = FQP12([pt.x.coefficients[0], FQ(0), FQ(0), FQ(0), FQ(0), FQ(0), pt.x.coefficients[1], FQ(0), FQ(0), FQ(0), FQ(0), FQ(0)], 
            field_mod_fq12, 12);
        FQP12 memory new_y = FQP12([pt.y.coefficients[0], FQ(0), FQ(0), FQ(0), FQ(0), FQ(0), pt.y.coefficients[1], FQ(0), FQ(0), FQ(0), FQ(0), FQ(0)], 
            field_mod_fq12, 12);
        FQP12 memory w = FQP12([FQ(0), FQ(1), FQ(0), FQ(0), FQ(0), FQ(0), FQ(0), FQ(0), FQ(0), FQ(0), FQ(0), FQ(0)],
            field_mod_fq12, 12);
        new_x = mul(new_x, pow(w, FQ(2)));
        new_y = mul(new_y, pow(w, FQ(3)));
        return PointFQP12(new_x, new_y);
    }

    // Elliptic curve doubling
    function double(PointFQ memory pt) internal pure returns (PointFQ memory) {
        FQ memory l = div(mul(FQ(3), pow(pt.x, FQ(2))), mul(FQ(2), pt.y));
        FQ memory new_x = sub(pow(l, FQ(2)), mul(FQ(2), pt.x));
        FQ memory new_y = sub(add(mul(neg(l), new_x), mul(l, pt.x)), pt.y);
        return PointFQ(new_x, new_y);
    }

    function double(PointFQP2 memory pt) internal pure returns (PointFQP2 memory) {
        FQP2 memory l = div(mul(pow(pt.x, FQ(2)), FQ(3)), mul(pt.y, FQ(2)));
        FQP2 memory new_x = sub(pow(l, FQ(2)), mul(pt.x, FQ(2)));
        FQP2 memory new_y = sub(add(mul(neg(l), new_x), mul(l, pt.x)), pt.y);
        return PointFQP2(new_x, new_y);
    }

    function double(PointFQP12 memory pt) internal pure returns (PointFQP12 memory) {
        FQP12 memory l = div(mul(pow(pt.x, FQ(2)), FQ(3)), mul(pt.y, FQ(2)));
        FQP12 memory new_x = sub(pow(l, FQ(2)), mul(pt.x, FQ(2)));
        FQP12 memory new_y = sub(add(mul(neg(l), new_x), mul(l, pt.x)), pt.y);
        return PointFQP12(new_x, new_y);
    }

    // Elliptic curve addition
    function add(PointFQ memory p1, PointFQ memory p2) internal pure returns (PointFQ memory) {
        (bool is_inf_p1, bool is_inf_p2) = (is_inf(p1), is_inf(p2));

        if (is_inf_p1 || is_inf_p2) {
            if (is_inf_p1) {
                return p2;
            } else {
                return p1;
            }
        }
        if (p1.x.n == p2.x.n && p1.y.n == p2.y.n) {
            return double(p1);
        } else if (p1.x.n == p2.x.n) {
            return PointFQ(FQ(0), FQ(0));
        } else {
            FQ memory l = div(sub(p2.y, p1.y), sub(p2.x, p1.x));
            FQ memory new_x = sub(sub(pow(l, FQ(2)), p1.x), p2.x);
            FQ memory new_y = sub(add(mul(neg(l), new_x), mul(l, p1.x)), p1.y);
            assert(new_y.n == sub(add(mul(neg(l), new_x), mul(l, p2.x)), p2.y).n);
            return PointFQ(new_x, new_y);
        }
    }

    function add(PointFQP2 memory p1, PointFQP2 memory p2) internal pure returns (PointFQP2 memory) {
        (bool is_inf_p1, bool is_inf_p2) = (is_inf(p1), is_inf(p2));

        if (is_inf_p1 || is_inf_p2) {
            if (is_inf_p1) {
                return p2;
            } else {
                return p1;
            }
        }
        if (eq(p1.x, p2.x) && eq(p1.y, p2.y)) {
            return double(p1);
        } else if (eq(p1.x, p2.x)) {
            return PointFQP2(inf_FQP2([FQ(1), FQ(0)]), inf_FQP2([FQ(1), FQ(0)]));
        } else {
            FQP2 memory l = div(sub(p2.y, p1.y), sub(p2.x, p1.x));
            FQP2 memory new_x = sub(sub(pow(l, FQ(2)), p1.x), p2.x);
            FQP2 memory new_y = sub(add(mul(neg(l), new_x), mul(l, p1.x)), p1.y);
            assert(eq(new_y, sub(add(mul(neg(l), new_x), mul(l, p2.x)), p2.y)));
            return PointFQP2(new_x, new_y);
        }
    }

    function add(PointFQP12 memory p1, PointFQP12 memory p2) internal pure returns (PointFQP12 memory) {
        (bool is_inf_p1, bool is_inf_p2) = (is_inf(p1), is_inf(p2));

        if (is_inf_p1 || is_inf_p2) {
            if (is_inf_p1) {
                return p2;
            } else {
                return p1;
            }
        }
        if (eq(p1.x, p2.x) && eq(p1.y, p2.y)) {
            return double(p1);
        } else if (eq(p1.x, p2.x)) {
            FQ[12] memory field_mod_fq12 = [FQ(82), FQ(0), FQ(0), FQ(0), FQ(0), FQ(0), FQ(-18), FQ(0), FQ(0), FQ(0), FQ(0), FQ(0)];
            return PointFQP12(inf_FQP12(field_mod_fq12), inf_FQP12(field_mod_fq12));
        } else {
            FQP12 memory l = div(sub(p2.y, p1.y), sub(p2.x, p1.x));
            FQP12 memory new_x = sub(sub(pow(l, FQ(2)), p1.x), p2.x);
            FQP12 memory new_y = sub(add(mul(neg(l), new_x), mul(l, p1.x)), p1.y);
            assert(eq(new_y, sub(add(mul(neg(l), new_x), mul(l, p2.x)), p2.y)));
            return PointFQP12(new_x, new_y);
        }
    }

    // Elliptic curve point multiplication
    function multiply(PointFQ memory pt, int n) internal pure returns (PointFQ memory) {
        if (n == 0) {
            return PointFQ(FQ(0), FQ(0));
        } else if (n == 1) {
            return pt;
        } else if ((n % 2) == 0) {
            return multiply(double(pt), n / 2);
        } else {
            return add(multiply(double(pt), n / 2), pt);
        }
    }

    // Elliptic curve point multiplication
    function multiply(PointFQP2 memory pt, int n) internal pure returns (PointFQP2 memory) {
        if (n == 0) {
            return PointFQP2(inf_FQP2([FQ(1), FQ(0)]), inf_FQP2([FQ(1), FQ(0)]));
        } else if (n == 1) {
            return pt;
        } else if ((n % 2) == 0) {
            return multiply(double(pt), n / 2);
        } else {
            return add(multiply(double(pt), n / 2), pt);
        }
    }

    function multiply(PointFQP12 memory pt, int n) internal pure returns (PointFQP12 memory) {
        if (n == 0) {
            FQ[12] memory field_mod_fq12 = [FQ(82), FQ(0), FQ(0), FQ(0), FQ(0), FQ(0), FQ(-18), FQ(0), FQ(0), FQ(0), FQ(0), FQ(0)];
            return PointFQP12(inf_FQP12(field_mod_fq12), inf_FQP12(field_mod_fq12));
        } else if (n == 1) {
            return pt;
        } else if ((n % 2) == 0) {
            return multiply(double(pt), n / 2);
        } else {
            return add(multiply(double(pt), n / 2), pt);
        }
    }

    // Convert P => -P
    function neg(PointFQ memory pt) internal pure returns (PointFQ memory) {
        if (pt.x.n == 0 && pt.y.n ==0) {
            return pt;
        }
        return PointFQ(pt.x, neg(pt.y));
    }

    function neg(PointFQP2 memory pt) internal pure returns (PointFQP2 memory) {
        if (is_inf(pt)) {
            return pt;
        }
        return PointFQP2(pt.x, neg(pt.y));
    }

    function neg(PointFQP12 memory pt) internal pure returns (PointFQP12 memory) {
        if (is_inf(pt)) {
            return pt;
        }
        return PointFQP12(pt.x, neg(pt.y));
    }

    function eq(PointFQ memory p1, PointFQ memory p2) internal pure returns (bool) {
        return p1.x.n == p2.x.n && p1.y.n == p2.y.n;
    }

    function eq(PointFQP2 memory p1, PointFQP2 memory p2) internal pure returns (bool) {
        return eq(p1.x, p2.x) && eq(p1.y, p2.y);
    }

    function eq(PointFQP12 memory p1, PointFQP12 memory p2) internal pure returns (bool) {
        return eq(p1.x, p2.x) && eq(p1.y, p2.y);
    }
}
