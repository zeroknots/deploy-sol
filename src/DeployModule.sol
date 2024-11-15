// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {VmSafe} from "forge-std/Vm.sol";

interface IRegistry {
    function deployModule(
        bytes32 salt,
        bytes32 resolverUID,
        bytes calldata initCode,
        bytes calldata metadata,
        bytes calldata resolverContext
    ) external payable returns (address moduleAddress);
}

/// @notice Library for deploying contracts using Safe's Singleton Factory
///         https://github.com/safe-global/safe-singleton-factory
library ModuleDeployer {
    error DeployFailed();

    IRegistry constant REGISTRY = IRegistry(address(0x000000000069E2a187AEFFb852bF3cCdC95151B2));
    bytes32 constant RESOLVER_UID = 0xdbca873b13c783c0c9c6ddfc4280e505580bf6cc3dac83f8a0f7b44acaafca4f;
    VmSafe private constant VM = VmSafe(address(uint160(uint256(keccak256("hevm cheat code")))));

    function computeAddress(bytes memory creationCode, bytes32 salt) public pure returns (address) {
        return computeAddress(creationCode, "", salt);
    }

    function computeAddress(bytes memory creationCode, bytes memory args, bytes32 salt) public pure returns (address) {
        return VM.computeCreate2Address({
            salt: salt,
            initCodeHash: _hashInitCode(creationCode, args),
            deployer: address(REGISTRY)
        });
    }

    function broadcastDeploy(bytes memory creationCode, bytes memory args, bytes32 salt) internal returns (address) {
        address expectedAddress = computeAddress(creationCode, args, salt);
        if (isContract(expectedAddress)) return expectedAddress;

        VM.broadcast();
        return _deploy(creationCode, args, salt);
    }

    function broadcastDeploy(bytes memory creationCode, bytes32 salt) internal returns (address) {
        address expectedAddress = computeAddress(creationCode, salt);
        if (isContract(expectedAddress)) return expectedAddress;
        VM.broadcast();
        return _deploy(creationCode, "", salt);
    }

    function broadcastDeploy(address deployer, bytes memory creationCode, bytes memory args, bytes32 salt)
        internal
        returns (address)
    {
        address expectedAddress = computeAddress(creationCode, args, salt);
        if (isContract(expectedAddress)) return expectedAddress;
        VM.broadcast(deployer);
        return _deploy(creationCode, args, salt);
    }

    function broadcastDeploy(address deployer, bytes memory creationCode, bytes32 salt) internal returns (address) {
        address expectedAddress = computeAddress(creationCode, salt);
        if (isContract(expectedAddress)) return expectedAddress;
        VM.broadcast(deployer);
        return _deploy(creationCode, "", salt);
    }

    function broadcastDeploy(uint256 deployerPrivateKey, bytes memory creationCode, bytes memory args, bytes32 salt)
        internal
        returns (address)
    {
        address expectedAddress = computeAddress(creationCode, salt);
        if (isContract(expectedAddress)) return expectedAddress;
        VM.broadcast(deployerPrivateKey);
        return _deploy(creationCode, args, salt);
    }

    function broadcastDeploy(uint256 deployerPrivateKey, bytes memory creationCode, bytes32 salt)
        internal
        returns (address)
    {
        address expectedAddress = computeAddress(creationCode, salt);
        if (isContract(expectedAddress)) return expectedAddress;
        VM.broadcast(deployerPrivateKey);
        return _deploy(creationCode, "", salt);
    }

    /// @dev Allows calling without Forge broadcast
    function deploy(bytes memory creationCode, bytes memory args, bytes32 salt) internal returns (address) {
        return _deploy(creationCode, args, salt);
    }

    /// @dev Allows calling without Forge broadcast
    function deploy(bytes memory creationCode, bytes32 salt) internal returns (address) {
        return _deploy(creationCode, "", salt);
    }

    function _deploy(bytes memory creationCode, bytes memory args, bytes32 salt) private returns (address module) {
        module = REGISTRY.deployModule({
            salt: salt,
            resolverUID: RESOLVER_UID,
            initCode: abi.encodePacked(creationCode, args),
            metadata: "",
            resolverContext: ""
        });
    }

    function _hashInitCode(bytes memory creationCode, bytes memory args) private pure returns (bytes32) {
        return keccak256(abi.encodePacked(creationCode, args));
    }

    function isContract(address _addr) public view returns (bool) {
        uint32 size;
        assembly {
            size := extcodesize(_addr)
        }
        return size > 0;
    }
}
