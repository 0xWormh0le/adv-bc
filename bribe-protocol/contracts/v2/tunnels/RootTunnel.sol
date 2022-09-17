// SPDX-License-Identifier: MIT
pragma solidity 0.8.4;

import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";
import "./BaseRootTunnel.sol";
import "./Create2.sol";

contract RootTunnel is BaseRootTunnel, Create2 {
    using SafeERC20 for IERC20;

    // maybe DEPOSIT and MAP_TOKEN can be reduced to bytes4
    bytes32 public constant DEPOSIT = keccak256("DEPOSIT");

    bytes32 public constant MAP_TOKEN = keccak256("MAP_TOKEN");

    event TokenMappedERC20(address indexed rootToken, address indexed childToken);

    event FxDepositERC20(
        address indexed rootToken,
        address indexed depositor,
        address indexed userAddress,
        uint256 amount
    );

    mapping(address => address) public rootToChildTokens;

    bytes32 public immutable childTokenTemplateCodeHash;

    constructor(address _fxRoot, address _fxERC20Token) BaseRootTunnel(_fxRoot) {
        // compute child token template code hash
        childTokenTemplateCodeHash = keccak256(minimalProxyCreationCode(_fxERC20Token));
    }

    /**
     * @notice Map a token to enable its movement via the PoS Portal, callable only by mappers
     * @param rootToken address of token on root chain
     */
    function _mapToken(address rootToken) internal {
        // check if token is already mapped
        require(rootToChildTokens[rootToken] == address(0x0), "FxERC20RootTunnel: ALREADY_MAPPED");

        // name, symbol and decimals
        IERC20Metadata rootTokenContract = IERC20Metadata(rootToken);
        string memory name = rootTokenContract.name();
        string memory symbol = rootTokenContract.symbol();
        uint8 decimals = rootTokenContract.decimals();

        // MAP_TOKEN, encode(rootToken, name, symbol, decimals)
        bytes memory message = abi.encode(MAP_TOKEN, abi.encode(rootToken, name, symbol, decimals));
        _sendMessageToChild(message);

        // compute child token address before deployment using create2
        bytes32 salt = keccak256(abi.encodePacked(rootToken));
        address childToken = computedCreate2Address(
            salt,
            childTokenTemplateCodeHash,
            fxChildTunnel
        );

        // add into mapped tokens
        rootToChildTokens[rootToken] = childToken;
        emit TokenMappedERC20(rootToken, childToken);
    }

    function deposit(
        address rootToken,
        address user,
        uint256 amount,
        bytes calldata data
    ) external {
        require(msg.sender == pool, "FxERC20RootTunnel: FROM_POOL");

        // map token if not mapped
        if (rootToChildTokens[rootToken] == address(0x0)) {
            _mapToken(rootToken);
        }

        // transfer from depositor to this contract
        IERC20(rootToken).safeTransferFrom(
            msg.sender, // depositor
            address(this), // manager contract
            amount
        );

        // DEPOSIT, encode(rootToken, depositor, user, amount, extra data)
        bytes memory message = abi.encode(
            DEPOSIT,
            abi.encode(rootToken, msg.sender, user, amount, data)
        );
        _sendMessageToChild(message);

        emit FxDepositERC20(rootToken, msg.sender, user, amount);
    }
}
