// SPDX-License-Identifier: MIT
pragma solidity 0.8.1;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import { Initializable } from "@openzeppelin/contracts/proxy/utils/Initializable.sol";
import { UUPSProxiable } from "./upgradability/UUPSProxiable.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "./interfaces/IBSVault.sol";

abstract contract VaultStorageV1 is UUPSProxiable, Pausable, IBSVault {
    /// @notice the flashloan rate to charge for flash loans
    uint256 public flashLoanRate;

    /// @notice the address that access to perform `admin` functions
    address public owner;

    /// @dev the address that access to perform `admin` functions
    address public newOwner;

    /// @notice mapping of token asset to user address and balance
    mapping(IERC20 => mapping(address => uint256)) public override balanceOf;

    /// @notice mapping of token asset to total deposit
    mapping(IERC20 => uint256) public totals;

    /// @notice mapping of user to contract to approval status
    mapping(address => mapping(address => bool)) public userApprovedContracts;

    /// @notice mapping of user to approval nonce
    mapping(address => uint256) public userApprovalNonce;
}

abstract contract VaultBase is VaultStorageV1  {
    /// @notice vault name
    string public constant name = "WarpVault v1";

    /// @notice vault version
    string public constant version = "1";

    /// @dev vault approval message digest
    bytes32 internal constant _VAULT_APPROVAL_SIGNATURE_TYPE_HASH =
        keccak256(
            "VaultAccessApproval(bytes32 warning,address user,address contract,bool approved,uint256 nonce)"
        );

    /// @dev EIP712 type hash
    bytes32 private constant _EIP712_TYPE_HASH =
        keccak256(
            "EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)"
        );
    
    /// @dev ERC3156 constant for flashloan callback success
    bytes32 internal constant FLASHLOAN_CALLBACK_SUCCESS =
        keccak256("ERC3156FlashBorrower.onFlashLoan");
    
    /// @notice max flashlaon rate 10%
    uint256 public constant MAX_FLASHLOAN_RATE = 1e17;

    bytes32 internal immutable _HASHED_NAME;
    bytes32 internal immutable _HASHED_VERSION;
    bytes32 private immutable _CACHED_DOMAIN_SEPARATOR;
    uint256 private immutable _CACHED_CHAIN_ID;

    constructor() {
        bytes32 hashedVersion = keccak256(bytes(version));
        bytes32 hashedName = keccak256(bytes(name));

        _HASHED_NAME = hashedName;
        _HASHED_VERSION = hashedVersion;
        _CACHED_DOMAIN_SEPARATOR = _buildDomainSeparator(
            _EIP712_TYPE_HASH,
            hashedName,
            hashedVersion
        );
        _CACHED_CHAIN_ID = _getChainId();
    }

    function _buildDomainSeparator(
        bytes32 _typeHash,
        bytes32 _name,
        bytes32 _version
    ) internal view returns (bytes32) {
        return keccak256(abi.encode(_typeHash, _name, _version, _getChainId(), address(this)));
    }

    function _domainSeparatorV4() internal view returns (bytes32) {
        if (_getChainId() == _CACHED_CHAIN_ID) {
            return _CACHED_DOMAIN_SEPARATOR;
        } else {
            return _buildDomainSeparator(_EIP712_TYPE_HASH, _HASHED_NAME, _HASHED_VERSION);
        }
    }

    function _getChainId() private view returns (uint256 chainId) {
        // solhint-disable-next-line
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        // solhint-disable-next-line no-inline-assembly
        assembly {
            chainId := chainid()
        }
    }
}
