//SPDX-License-Identifier: Apache License 2.0

// Solidity files have to start with this pragma.
// It will be used by the Solidity compiler to validate its version.
pragma solidity ^0.8.0;

import "hardhat/console.sol";

contract bn128_field_elements {
    struct FQ {
        int n;
    }
    struct FQP {
        FQ[] coefficients;
        FQ[] mod_coefficients;
        uint degree;
    }
    struct FQP2 {
        FQ[2] coefficients;
        FQ[2] mod_coefficients;
        uint degree;
    }
    struct FQP12 {
        FQ[12] coefficients;
        FQ[12] mod_coefficients;
        uint degree;
    }

    int internal constant field_mod = 21888242871839275222246405745257275088696311157297823662689037894645226208583;

    constructor() {

    }
    
    function inv(int a) internal pure returns (FQ memory) {
        if (a == 0) {
            return FQ(0);
        }
        int lm = 1;
        int hm = 0;
        int low = a % field_mod;
        int high = field_mod;

        while (low > 1) {
            int r = high / low;
            int nm = hm - r * lm;
            int new_val = high - r * low;
            lm = nm;
            low = new_val;
            hm = lm;
            high = low;
        }
        return FQ(lm % field_mod);
    }

    function deg(FQ[] memory p) internal pure returns (uint) {
        uint d = p.length - 1;

        while (p[d].n == 0 && d > 0) {
            d -= 1;
        }
        return d;
    }

    function deg(FQ[2] memory p) internal pure returns (uint) {
        uint d = p.length - 1;

        while (p[d].n == 0 && d > 0) {
            d -= 1;
        }
        return d;
    }

    function deg(FQ[12] memory p) internal pure returns (uint) {
        uint d = p.length - 1;

        while (p[d].n == 0 && d > 0) {
            d -= 1;
        }
        return d;
    }

    function poly_rounded_div(FQ[] memory a, FQ[] memory b, uint degree) internal pure returns (FQ[] memory) {
        uint dega = deg(a);
        uint degb = deg(b);
        FQ[] memory temp = new FQ[](a.length);
        FQ[] memory o = new FQ[](degree + 1);

        for (uint i = 0; i < a.length; i++) {
            temp[i] = a[i];
            o[i] = a[i];
        }
        for (int i = int(dega) - int(degb); i > -1; i--) {
            o[uint(i)] = div(add(o[uint(i)], temp[degb + uint(i)]), b[degb]);

            for (uint j = 0; j < degb + 1; i++) {
                temp[j + uint(i)] = sub(temp[j + uint(i)], o[j]);
            }
        }
        FQ[] memory r = new FQ[](degree + 1);

        for (uint i = 0; i < degree + 1; i++) {
            r[i] = o[i];
        }
        return r;
    }

    function add(FQ memory elem, FQ memory other) internal pure returns (FQ memory) {
        elem.n = (elem.n + other.n) % field_mod;
        return elem;
    }

    function mul(FQ memory elem, FQ memory other) internal pure returns (FQ memory) {
        elem.n = (elem.n * other.n) % field_mod;
        return elem;
    }

    function sub(FQ memory elem, FQ memory other) internal pure returns (FQ memory) {
       elem.n = (elem.n - other.n) % field_mod;
       return elem;
    }

    function div(FQ memory elem, FQ memory other) internal pure returns (FQ memory) {
        elem.n = (elem.n * inv(other.n).n) % field_mod;
        return elem;
    }

    function pow(FQ memory elem, FQ memory other) internal pure returns (FQ memory) {
        if (other.n == 0) {
            elem.n = 1;
            return elem;
        } 
        else if (other.n == 1) {
            return elem;
        }
        else if (other.n % 2 == 0) {
            elem.n = (elem.n * elem.n) ** (uint(other.n) / 2);
            return elem;
        }
        else {
            elem.n = ((elem.n * elem.n) ** (uint(other.n) / 2)) * elem.n;
            return elem;
        }
    }

    function neg(FQ memory elem) internal pure returns (FQ memory) {
        elem.n = -elem.n;
        return elem;
    }

    function add(FQP2 memory elem, FQP2 memory other) internal pure returns (FQP2 memory) {
        for (uint i = 0; i < elem.coefficients.length; i++) {
            elem.coefficients[i] = add(elem.coefficients[i], other.coefficients[i]);
        }
        return elem;
    }

    function add(FQP12 memory elem, FQP12 memory other) internal pure returns (FQP12 memory) {
        for (uint i = 0; i < elem.coefficients.length; i++) {
            elem.coefficients[i] = add(elem.coefficients[i], other.coefficients[i]);
        }
        return elem;
    }

    function sub(FQP2 memory elem, FQP2 memory other) internal pure returns (FQP2 memory) {
        for (uint i = 0; i < elem.coefficients.length; i++) {
            elem.coefficients[i] = sub(elem.coefficients[i], other.coefficients[i]);
        }
        return elem;
    }

    function sub(FQP12 memory elem, FQP12 memory other) internal pure returns (FQP12 memory) {
        for (uint i = 0; i < elem.coefficients.length; i++) {
            elem.coefficients[i] = sub(elem.coefficients[i], other.coefficients[i]);
        }
        return elem;
    }
    

    function mul(FQP2 memory elem, FQ memory other) internal pure returns (FQP2 memory) {
        for (uint i = 0; i < elem.coefficients.length; i++) {
            elem.coefficients[i] = mul(elem.coefficients[i], other);
        }
        return elem;
    }

    function mul(FQP12 memory elem, FQ memory other) internal pure returns (FQP12 memory) {
        for (uint i = 0; i < elem.coefficients.length; i++) {
            elem.coefficients[i] = mul(elem.coefficients[i], other);
        }
        return elem;
    }

    function mul(FQP2 memory elem, FQP2 memory other) internal pure returns (FQP2 memory) {
        FQP memory b;
        FQ[] memory new_coeffs = new FQ[](elem.degree * 2 - 1);
        b.coefficients = new FQ[](elem.degree * 2 - 1);

        for (uint i = 0; i < elem.degree * 2 - 1; i++) {
            new_coeffs[i] = FQ(0);
        }
        for (uint i = 0; i < elem.degree; i++) {
            for (uint j = 0; j < elem.degree; j++) {
                new_coeffs[i + j] = add(b.coefficients[i + j], 
                    mul(elem.coefficients[i], other.coefficients[j]));
            }
        }
        while (deg(b.coefficients) > elem.degree) {
            uint exp = deg(new_coeffs) - elem.degree - 1;
            FQ memory top = b.coefficients[new_coeffs.length - 1];
            delete new_coeffs[new_coeffs.length - 1];

            for (uint i = 0; i < elem.degree; i++) {
                new_coeffs[exp + i] = sub(new_coeffs[exp + i], mul(top, elem.mod_coefficients[i]));
            }
        }
        for (uint i = 0; i < elem.degree; i++) {
            elem.coefficients[i] = b.coefficients[i];
        }
        return elem;
    }


    function mul(FQP12 memory elem, FQP12 memory other) internal pure returns (FQP12 memory) {
        FQP memory b;
        FQ[] memory new_coeffs = new FQ[](elem.degree * 2 - 1);
        b.coefficients = new FQ[](elem.degree * 2 - 1);

        for (uint i = 0; i < elem.degree * 2 - 1; i++) {
            new_coeffs[i] = FQ(0);
        }
        for (uint i = 0; i < elem.degree; i++) {
            for (uint j = 0; j < elem.degree; j++) {
                new_coeffs[i + j] = add(b.coefficients[i + j], 
                    mul(elem.coefficients[i], other.coefficients[j]));
            }
        }
        while (deg(b.coefficients) > elem.degree) {
            uint exp = deg(new_coeffs) - elem.degree - 1;
            FQ memory top = b.coefficients[new_coeffs.length - 1];
            delete new_coeffs[new_coeffs.length - 1];

            for (uint i = 0; i < elem.degree; i++) {
                new_coeffs[exp + i] = sub(new_coeffs[exp + i], mul(top, elem.mod_coefficients[i]));
            }
        }
        for (uint i = 0; i < elem.degree; i++) {
            elem.coefficients[i] = b.coefficients[i];
        }
        return elem;
    }

    function div(FQP2 memory elem, FQ memory other) internal pure returns (FQP2 memory) {
        for (uint i = 0; i < elem.coefficients.length; i++) {
            elem.coefficients[i] = div(elem.coefficients[i], other);
        }
        return elem;
    }

    function div(FQP12 memory elem, FQ memory other) internal pure returns (FQP12 memory) {
        for (uint i = 0; i < elem.coefficients.length; i++) {
            elem.coefficients[i] = div(elem.coefficients[i], other);
        }
        return elem;
    }

    function div(FQP2 memory elem, FQP2 memory other) internal pure returns (FQP2 memory) {
        return mul(elem, inv(other));
    }

    function div(FQP12 memory elem, FQP12 memory other) internal pure returns (FQP12 memory) {
        return mul(elem, inv(other));
    }

    function pow(FQP2 memory elem, FQ memory other) internal pure returns (FQP2 memory) {
        if (other.n == 0) {
            elem.coefficients[0] = FQ(1);
            
            for (uint i = 0; i < elem.degree - 1; i++) {
                elem.coefficients[i] = FQ(0);
            }
            return elem;
        }
        else if (other.n == 1) {
            return elem;
        }
        else if (other.n % 2 == 0) {
            return pow(mul(elem, elem), div(other, FQ(2)));
        }
        else {
            FQP2 memory cpy = FQP2(elem.coefficients, elem.mod_coefficients, elem.degree);
            return mul(pow(mul(elem, elem), div(other, FQ(2))), cpy);
        }
    }


    function pow(FQP12 memory elem, FQ memory other) internal pure returns (FQP12 memory) {
        if (other.n == 0) {
            elem.coefficients[0] = FQ(1);
            
            for (uint i = 0; i < elem.degree - 1; i++) {
                elem.coefficients[i] = FQ(0);
            }
            return elem;
        }
        else if (other.n == 1) {
            return elem;
        }
        else if (other.n % 2 == 0) {
            return pow(mul(elem, elem), div(other, FQ(2)));
        }
        else {
            FQP12 memory cpy = FQP12(elem.coefficients, elem.mod_coefficients, elem.degree);
            return mul(pow(mul(elem, elem), div(other, FQ(2))), cpy);
        }
    }

    function inv(FQP2 memory elem) internal pure returns (FQP2 memory) {
        FQ[] memory lm = new FQ[](elem.degree);
        FQ[] memory hm = new FQ[](elem.degree);
        FQ[] memory low = new FQ[](elem.degree);
        FQ[] memory high = new FQ[](elem.degree);

        lm[0] = FQ(1);
        hm[0] = FQ(0);

        for (uint i = 0; i < elem.degree; i++) {
            low[i] = elem.coefficients[i];
            high[i] = elem.mod_coefficients[i];
            lm[i] = FQ(0);
            hm[i] = FQ(0);
        }
        while (deg(low) > 0) {
            FQ[] memory r = poly_rounded_div(high, low, elem.degree);
            FQ[] memory nm = new FQ[](hm.length);
            FQ[] memory new_val = new FQ[](hm.length);

            for (uint i = 0; i < hm.length; i++) {
                nm[i] = hm[i];
                new_val[i] = high[i];
            }
            assert(lm.length == hm.length && lm.length == low.length && lm.length == high.length && lm.length == nm.length && lm.length == new_val.length && lm.length == elem.degree + 1); 
            
            for (uint i = 0; i < elem.degree + 1; i++) {
                for (uint j = 0; j < elem.degree + 1 - i; j++) {
                    nm[i + j] = sub(nm[i + j], mul(lm[i], r[j]));
                    new_val[i + j] = sub(new_val[i + j], mul(low[i], (r[j])));
                }
            }
            (lm, low, hm, high) = (nm, new_val, lm, low);
        }
        for (uint i = 0; i < elem.degree; i++) {
            elem.coefficients[i] = div(lm[i], low[0]);
        }
        return elem;
    }

    function inv(FQP12 memory elem) internal pure returns (FQP12 memory) {
        FQ[] memory lm = new FQ[](elem.degree);
        FQ[] memory hm = new FQ[](elem.degree);
        FQ[] memory low = new FQ[](elem.degree);
        FQ[] memory high = new FQ[](elem.degree);

        lm[0] = FQ(1);
        hm[0] = FQ(0);

        for (uint i = 0; i < elem.degree; i++) {
            low[i] = elem.coefficients[i];
            high[i] = elem.mod_coefficients[i];
            lm[i] = FQ(0);
            hm[i] = FQ(0);
        }
        while (deg(low) > 0) {
            FQ[] memory r = poly_rounded_div(high, low, elem.degree);
            FQ[] memory nm = new FQ[](hm.length);
            FQ[] memory new_val = new FQ[](hm.length);

            for (uint i = 0; i < hm.length; i++) {
                nm[i] = hm[i];
                new_val[i] = high[i];
            }
            assert(lm.length == hm.length && lm.length == low.length && lm.length == high.length && lm.length == nm.length && lm.length == new_val.length && lm.length == elem.degree + 1); 
            
            for (uint i = 0; i < elem.degree + 1; i++) {
                for (uint j = 0; j < elem.degree + 1 - i; j++) {
                    nm[i + j] = sub(nm[i + j], mul(lm[i], r[j]));
                    new_val[i + j] = sub(new_val[i + j], mul(low[i], (r[j])));
                }
            }
            (lm, low, hm, high) = (nm, new_val, lm, low);
        }
        for (uint i = 0; i < elem.degree; i++) {
            elem.coefficients[i] = div(lm[i], low[0]);
        }
        return elem;
    }

    function eq(FQ memory elem, FQ memory other) internal pure returns (bool) {
        return elem.n == other.n;
    }

    function eq(FQP2 memory elem, FQP2 memory other) internal pure returns (bool) {
        for (uint i = 0; i < elem.degree; i++) {
            if (elem.coefficients[i].n != other.coefficients[i].n) {
                return false;
            }
        }
        return true;
    }

    function eq(FQP12 memory elem, FQP12 memory other) internal pure returns (bool) {
        for (uint i = 0; i < elem.degree; i++) {
            if (elem.coefficients[i].n != other.coefficients[i].n) {
                return false;
            }
        }
        return true;
    }

    function neg(FQP2 memory elem) internal pure returns (FQP2 memory) {
        for (uint i = 0; i < elem.degree; i++) {
            elem.coefficients[i].n = -elem.coefficients[i].n;
        }
        return elem;
    }

    function neg(FQP12 memory elem) internal pure returns (FQP12 memory) {
        for (uint i = 0; i < elem.degree; i++) {
            elem.coefficients[i].n = -elem.coefficients[i].n;
        }
        return elem;
    }

    function inf_FQP2(FQ[2] memory mod_coeffs) internal pure returns (FQP2 memory) {
        return FQP2([FQ(0), FQ(0)], mod_coeffs, mod_coeffs.length);
    }

    function inf_FQP12(FQ[12] memory mod_coeffs) internal pure returns (FQP12 memory) {
        return FQP12([FQ(0), FQ(0), FQ(0), FQ(0), FQ(0), FQ(0), FQ(0), FQ(0), FQ(0), FQ(0), FQ(0), FQ(0)], 
            mod_coeffs, mod_coeffs.length);
    }

    function one(FQ[12] memory mod_coeffs) internal pure returns (FQP12 memory) {
        return FQP12([FQ(1), FQ(0), FQ(0), FQ(0), FQ(0), FQ(0), FQ(0), FQ(0), FQ(0), FQ(0), FQ(0), FQ(0)], 
            mod_coeffs, mod_coeffs.length);
    }
}
