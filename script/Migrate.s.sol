// SPDX-License-Identifier: MIT
pragma solidity ^0.8.23;

import {ERC1967Proxy} from "@openzeppelin-contracts-5.0.2/proxy/ERC1967/ERC1967Proxy.sol";
import {console2 as console, StdStyle, BaseDeploy} from "@foundry-kit-1.0.0/src/BaseDeploy.s.sol";
import {TransparentUpgradeableProxy} from "@openzeppelin-contracts-5.0.2/proxy/transparent/TransparentUpgradeableProxy.sol";

interface IProxy {
    function upgradeToAndCall(
        address implementation,
        bytes memory data
    ) external;
}

abstract contract BaseMigrate is BaseDeploy {
    using StdStyle for *;

    function deployContract(
        string memory fileDest,
        bytes memory args
    )
        public
        log(string.concat(unicode"Deploying 🚀 ", fileDest))
        returns (address contractAddress)
    {
        contractAddress = deploy(fileDest, args);
        console.log(
            unicode"Logic 🧩: ".green(),
            string.concat(_explorerUrl(), "address/", vm.toString(contractAddress))
        );
    }

    function deployUUPSProxy(
        string memory fileDest,
        bytes memory args
    )
        public
        log(string.concat(unicode"Deploying 🚀 🆙 ", fileDest))
        returns (address proxy)
    {
        address logic = deploy(fileDest, EMPTY_ARGS);
        proxy = deploy(
            "ERC1967Proxy.sol:ERC1967Proxy",
            abi.encode(logic, args)
        );
        console.log(
            unicode"Logic 🧩: ".green(),
            string.concat(_explorerUrl(), "address/", vm.toString(logic))
        );
        console.log(
            unicode"Proxy ⚙️ : ".green(),
            string.concat(_explorerUrl(), "address/", vm.toString(proxy))
        );
    }

    function deployTransparentProxy(
        string memory fileDest,
        bytes memory args
    )
        public
        log(string.concat(unicode"Deploying 🚀 🇹🇷 ", fileDest))
        returns (address proxy)
    {
        address logic = deploy(fileDest, EMPTY_ARGS);
        proxy = deploy(
            "TransparentUpgradeableProxy.sol:TransparentUpgradeableProxy",
            abi.encode(logic, msg.sender, args)
        );
        console.log(
            unicode"Logic 🧩: ".green(),
            string.concat(_explorerUrl(), "address/", vm.toString(logic))
        );
        console.log(
            unicode"Proxy ⚙️ : ".green(),
            string.concat(_explorerUrl(), "address/", vm.toString(proxy))
        );
    }

    function upgradeProxy(
        string memory fileDest,
        address proxy,
        bytes memory args
    ) public log(string.concat(unicode"Upgrading 🛠️ ", fileDest)) {
        address logic = deploy(fileDest, EMPTY_ARGS);
        IProxy(proxy).upgradeToAndCall(logic, args);
        console.log(
            unicode"Logic 🧩: ".green(),
            string.concat(_explorerUrl(), "address/", vm.toString(logic))
        );
        console.log(
            unicode"Proxy ⚙️ : ".green(),
            string.concat(_explorerUrl(), "address/", vm.toString(proxy))
        );
    }
}
