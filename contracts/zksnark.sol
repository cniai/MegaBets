//SPDX-License-Identifier: Apache License 2.0

// Solidity files have to start with this pragma.
// It will be used by the Solidity compiler to validate its version.
pragma solidity ^0.8.0;

import "./bn128_pairing.sol";

contract zksnark is bn128_pairing {

    constructor() bn128_pairing() {

    }
}