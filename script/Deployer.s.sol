// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.23;

import "./Migrate.s.sol";
import {Foo, FooU, FooT} from "../src/Foo.sol";

contract Deployer is BaseMigrate {
    function run() external {
        Foo foo = Foo(deployFoo());
        FooU fooU = FooU(deployFooU());
        FooT fooT = FooT(deployFooT());
        _postCheck(foo, fooU, fooT);
    }

    function deployFoo() public broadcast returns (address) {
        return deployContract("Foo.sol:Foo", abi.encode());
    }

    function deployFooU() public broadcast returns (address) {
        return
            deployUUPSProxy(
                "Foo.sol:FooU",
                abi.encodeCall(FooU.initialize, ())
            );
    }

    function deployFooT() public broadcast returns (address) {
        return
            deployTransparentProxy(
                "Foo.sol:FooT",
                abi.encodeCall(FooT.initialize, ())
            );
    }

    function _postCheck(Foo foo_, FooU foou_, FooT foot_) internal pure {
        vm.assertEq(foo_.foo(), "foo", "Post check failed");
        vm.assertEq(foou_.foo(), "fooU", "Post check failed");
        vm.assertEq(foot_.foo(), "fooT", "Post check failed");
    }
}
