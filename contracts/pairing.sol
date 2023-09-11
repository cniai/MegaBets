//SPDX-License-Identifier: Apache License 2.0

// Solidity files have to start with this pragma.
// It will be used by the Solidity compiler to validate its version.
pragma solidity ^0.8.0;

import "hardhat/console.sol";

library pairing {
    uint constant field_mod = 21888242871839275222246405745257275088696311157297823662689037894645226208583;
    
    function inv(uint a) internal pure returns (FQ memory) {
        if (a == 0) {
            return FQ(0);
        }
        uint lm = 1;
        uint hm = 0;
        uint low = a % field_mod;
        uint high = field_mod;

        while (low > 1) {
            uint r = high / low;
            uint nm = hm - r * lm;
            uint new_val = high - r * low;
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
            elem.n = (elem.n * elem.n) ** (other.n / 2);
            return elem;
        }
        else {
            elem.n = ((elem.n * elem.n) ** (other.n / 2)) * elem.n;
            return elem;
        }
    }

    function add(FQP memory elem, FQP memory other) internal pure returns (FQP memory) {
        for (uint i = 0; i < elem.coefficients.length; i++) {
            elem.coefficients[i] = add(elem.coefficients[i], other.coefficients[i]);
        }
        return elem;
    }

    function sub(FQP memory elem, FQP memory other) internal returns (FQP memory) {
        for (uint i = 0; i < elem.coefficients.length; i++) {
            elem.coefficients[i] = sub(elem.coefficients[i], other.coefficients[i]);
        }
        return elem;
    }

    function mul_constant(FQP memory elem, FQ memory other) internal pure returns (FQP memory) {
        for (uint i = 0; i < elem.coefficients.length; i++) {
            elem.coefficients[i] = mul(elem.coefficients[i], other);
        }
        return elem;
    }

    function mul(FQP memory elem, FQP memory other) internal returns (FQP memory) {
        FQP memory b;
        b.coefficients = new FQ[](elem.degree * 2 - 1);

        for (uint i = 0; i < elem.degree * 2 - 1; i++) {
            b.coefficients[i] = FQ(0);
        }
        for (uint i = 0; i < elem.degree; i++) {
            for (uint j = 0; j < elem.degree; j++) {
                b.coefficients[i + j] = add(b.coefficients[i + j], 
                    mul(elem.coefficients[i], other.coefficients[j]));
            }
        }
        while (deg(b.coefficients) > elem.degree) {
            uint exp = deg(b.coefficients) - elem.degree - 1;
            FQ memory top = b.coefficients[b.coefficients.length - 1];
            delete b.coefficients[b.coefficients.length - 1];

            for (uint i = 0; i < elem.degree; i++) {
                b.coefficients[exp + i] = sub(b.coefficients[exp + i], mul(top, elem.mod_coefficients[i]));
            }
        }
        return b;
    }

    function div(FQP memory elem, FQ memory other) internal returns (FQP memory) {
        for (uint i = 0; i < elem.coefficients.length; i++) {
            elem.coefficients[i] = div(elem.coefficients[i], other);
        }
        return elem;
    }

    function div(FQP memory elem, FQP memory other) internal returns (FQP memory) {
        elem = mul(elem, inv(other));
        return elem;
    }

    function pow(FQP memory elem, FQ memory other) internal returns (FQP memory) {
        if (other.n == 0) {
            FQ[] memory coeffs = new FQ[](elem.degree);
            coeffs[0] = FQ(1);
            
            for (uint i = 0; i < elem.degree - 1; i++) {
                coeffs[i] = FQ(0);
            }
            return FQP(coeffs, elem.mod_coefficients, elem.degree);
        }
        else if (other.n == 1) {
            return elem;
        }
        else if (other.n % 2 == 0) {
            return pow(mul(elem, elem), div(other, FQ(2)));
        }
        else {
            FQP memory cpy = FQP(elem.coefficients, elem.mod_coefficients, elem.degree);
            return mul(pow(mul(elem, elem), div(other, FQ(2))), cpy);
        }
    }

    function inv(FQP memory elem) internal returns (FQP memory) {
        FQ[] memory lm = new FQ[](elem.degree);
        FQ[] memory hm = new FQ[](elem.degree);
        FQ[] memory low = elem.coefficients;
        FQ[] memory high = elem.mod_coefficients;
        FQ[] memory new_coeffs = new FQ[](elem.degree);
        uint degree = elem.degree;

        lm[0] = FQ(1);
        hm[0] = FQ(0);

        for (uint i = 0; i < elem.degree; i++) {
            lm[i] = FQ(0);
            hm[0] = FQ(0);
        }
        while (deg(low) > 0) {
            FQ[] memory r = poly_rounded_div(high, low, degree);
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
            new_coeffs[i] = div(lm[i], low[0]);
        }
        return FQP(new_coeffs, elem.mod_coefficients, elem.degree);
    }
}

struct FQ {
    uint n;
}

struct FQP {
    FQ[] coefficients;
    FQ[] mod_coefficients;
    uint degree;
}
