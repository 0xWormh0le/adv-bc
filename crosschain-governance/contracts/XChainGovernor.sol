// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (governance/Governor.sol)

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/governance/Governor.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@composable-finance/v2-sdk-contracts/contracts/libraries/crosslayer/CrosslayerFunctionCallsLib.sol";
import "./interfaces/IERC20Burnable.sol";


contract XChainGovernor is Governor, Ownable, ReentrancyGuard {

    using SafeERC20 for IERC20;

    enum ChainId {

    }

    address immutable public token;

    address immutable public msgSender;

    address immutable public xChainDelegator;

    mapping(ChainId => address) governorAddrs;

    mapping(address => uint256) lockAmounts;

    constructor(
        string memory name,
        address _token,
        address _msgSender,
        address _xChainDelegator
    )
        Governor(name)
        Ownable()
        ReentrancyGuard()
    {
        require(_token != address(0), "XCG: zero token address");
        require(_msgSender != address(0), "XCG: zero msg sender address");
        require(_xChainDelegator != address(0), "XCG: zero xChain delegator address");

        token = _token;
        msgSender = _msgSender;
        xChainDelegator = _xChainDelegator;
    }

    modifier onlyXChainDelegator() {
        require(msg.sender == xChainDelegator, "XCG: only xChain delegator");
        _;
    }

    function setGovernerContractAddresses(
        ChainId[] calldata _chainIds,
        address[] calldata _governorAddrs
    ) external onlyOwner {
        require(_chainIds.length == _governorAddrs.length, "XCG: length not match");

        for (uint256 i = 0; i < _chainIds.length; i++) {
            governorAddrs[_chainIds[i]] = _governorAddrs[i];
        }
    }

    function lockToken(uint256 amount) external nonReentrant {
        require(amount > 0, "XCG: zero amount");

        IERC20(token).safeTransferFrom(msg.sender, address(this), amount);

        lockAmounts[msg.sender] += amount;
    }

    function transferTokenToOtherChain(ChainId targetChainId, uint256 amount, address targetUserAddr) external nonReentrant {
        require(governorAddrs[targetChainId] != address(0), "XCG: targetChainId not registered");

        lockAmounts[msg.sender] -= amount;

        CrosslayerFunctionCallsLib.registerCrossFunctionCall(
            msgSender,
            targetChainId,
            governorAddrs[targetChainId],
            abi.encodeWithSignature("listenTokenTransferFromOtherChain(uint256)", amount)
        );
    }

    function listenTransferCallback(uint256 amount, address sourceUserAddr) external onlyXChainDelegator {
        lockAmounts[sourceUserAddr] += amount;
        IERC20(token).mint()
    }

    function listenTokenTransferFromOtherChain(uint256 amount) external onlyXChainDelegator {
        IERC020Burnable(token).burn(amount);
    }
}
