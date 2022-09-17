//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.4;

import '@openzeppelin/contracts/proxy/Clones.sol';
import './interfaces/IChiselFactory.sol';
import './interfaces/IChisel.sol';

contract ChiselFactory is IChiselFactory {
    using Clones for address;

    /// @notice address of chisels
    address[] public allChisels;

    /// @notice address of chisel implementation
    address public chiselImpl;

    /// @notice address of admin
    address public admin;

    /// @notice modifier to allow only the owner to call a function
    modifier onlyAdmin() {
        require(msg.sender == admin, 'ChiselFactory: Not Admin');
        _;
    }

    constructor(address _chiselImpl, address _admin) {
        require(_chiselImpl != address(0), 'ChiselFactory: Invalid ChiselImpl');
        require(_admin != address(0), 'ChiselFactory: Invalid admin');

        chiselImpl = _chiselImpl;
        admin = _admin;
    }

    /// @dev update ChiselImpl address
    function updateChiselImpl(address _chiselImpl) external override onlyAdmin {
        require(_chiselImpl != address(0), 'ChiselFactory: Invalid ChiselImpl');
        chiselImpl = _chiselImpl;
    }

    /// @dev Create Chisel
    function createChisel(
        address _admin,
        address _vault,
        address _baseToken
    ) external override onlyAdmin returns (address newChisel) {
        bytes32 salt = keccak256(abi.encode(address(this), allChisels.length));
        newChisel = chiselImpl.cloneDeterministic(salt);
        IChisel(newChisel).initialize(_admin, _vault, _baseToken);
        allChisels.push(newChisel);

        emit NewChisel(newChisel);
    }
}
