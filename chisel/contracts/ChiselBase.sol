//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.4;

import '@openzeppelin/contracts/proxy/utils/Initializable.sol';
import '@openzeppelin/contracts/security/ReentrancyGuard.sol';

import './interfaces/IChisel.sol';
import './interfaces/IWarpVault.sol';
import './interfaces/IWarpLendingPair.sol';
import './external/token/ERC20.sol';

abstract contract ChiselBase is IChisel, ERC20, Initializable, ReentrancyGuard {
    /// @notice vault contract address
    IWarpVault public vault;

    /// @notice base token address
    IERC20 public baseToken;

    /// @notice vaultShares of Chisel funds deposited into lendingPair
    mapping(IWarpLendingPair => uint256) pairVaultShares;

    /// @notice admin address
    address public admin;

    /// @notice incentive that will be rewared to the caller
    uint256 public callIncentive;

    /// @notice users' deposited funds that are not deposited into lendingPair yet
    uint256 public bufferVaultShares;

    modifier onlyAdmin() {
        require(admin == msg.sender, 'Not Admin');
        _;
    }

    modifier matchingPair(IWarpLendingPair _pair) {
        require(baseToken == _pair.asset(), 'Incorrect Pair');
        _;
    }

    constructor() ReentrancyGuard() {}

    /// @notice Initialize contract
    /// @param _admin admin address
    /// @param _vault Vault contract address
    /// @param _baseToken Base token (ERC20) address
    function initialize(
        address _admin,
        address _vault,
        address _baseToken
    ) external override initializer {
        require(_admin != address(0), 'initialize: admin');
        require(_vault != address(0), 'initialize: vault');
        require(_baseToken != address(0), 'initialize: baseToken');

        admin = _admin;
        vault = IWarpVault(_vault);
        baseToken = IERC20(_baseToken);

        // initialize receipt token
        string memory tokenName = string(
            abi.encodePacked('Chisel Reciept ', ERC20(_baseToken).name(), ' Token')
        );
        string memory tokenSymbol = string(abi.encodePacked('CR-', ERC20(_baseToken).symbol()));
        initializeERC20(tokenName, tokenSymbol, 18);

        callIncentive = 500;
        emit Initialized(admin, address(vault), address(baseToken));
    }

    function _addLiquidityToPair(IWarpLendingPair _to, uint256 _vaultShares) internal {
        if (!vault.userApprovedContracts(address(this), address(_to))) {
            vault.approveContract(address(this), address(_to), true, 0, 0, 0);
        }

        _to.depositBorrowAsset(address(this), _vaultShares);
    }
}
