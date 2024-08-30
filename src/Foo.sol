// SPDX-License-Identifier: MIT
pragma solidity ^0.8.23;

import {Initializable} from "@openzeppelin-contracts-upgradeable-5.0.2/proxy/utils/Initializable.sol";
import {UUPSUpgradeable} from "@openzeppelin-contracts-upgradeable-5.0.2/proxy/utils/UUPSUpgradeable.sol";

contract Foo {
    function foo() public pure returns (string memory) {
        return "foo";
    }
}

contract FooU is Initializable, UUPSUpgradeable {
    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
        _disableInitializers();
    }

    function initialize() public initializer {
        __UUPSUpgradeable_init();
    }

    function foo() public pure returns (string memory) {
        return "fooU";
    }

    function _authorizeUpgrade(address) internal override {}
}

contract FooT is Initializable {
    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
        _disableInitializers();
    }

    function initialize() public initializer {}

    function foo() public pure returns (string memory) {
        return "fooT";
    }
}
