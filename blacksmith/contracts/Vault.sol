// SPDX-License-Identifier: MIT
pragma solidity 0.8.1;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "./interfaces/IERC3156FlashBorrower.sol";
import "./interfaces/IBSLendingPair.sol";
import "./VaultBase.sol";

////////////////////////////////////////////////////////////////////////////////////////////
///
/// @title Vault
/// @author @samparsky
/// @notice Vault contract stores assets deposited into the Lending pairs.
/// It enables deposit, withdrawal, flashloans and transfer of tokens.
/// It represents the deposited token amount in form of shares
/// This contract implements the EIP3156 IERC3156FlashBorrower for flashloans.
///
////////////////////////////////////////////////////////////////////////////////////////////

contract Vault is VaultBase {
    using SafeERC20 for IERC20;

    /// @notice modifier to allow only blacksmith team to call a function
    modifier onlyOwner {
        require(msg.sender == owner, "ONLY_OWNER");
        _;
    }

    modifier allowed(address _from) {
        require(
            msg.sender == _from || userApprovedContracts[_from][msg.sender] == true,
            "ONLY_ALLOWED"
        );
        _;
    }

    /// @dev setup a vault
    constructor() VaultBase() {}

    ////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
    // UUPSProxiable
    ////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

    function initialize(uint256 _flashLoanRate, address _owner) external override initializer {
        require(_owner != address(0), "INVALID_OWNER");
        require(flashLoanRate < MAX_FLASHLOAN_RATE, "INVALID_RATE");

        flashLoanRate = _flashLoanRate;
        owner = _owner;
    }

    function proxiableUUID() public pure override returns (bytes32) {
        return keccak256("org.warp.contracts.warpvault.implementation");
    }

    function updateCode(address newAddress) external override onlyOwner {
        _updateCodeAddress(newAddress);
    }

    ////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
    // Vault Actions
    ////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

    /// @notice approve a contract to enable the contract to withdraw
    function approveContract(
        address _user,
        address _contract,
        bool _status,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external override {
        require(_contract != address(0), "INVALID_CONTRACT");

        bytes32 digest =
            keccak256(
                abi.encodePacked(
                    "\x19\x01",
                    _domainSeparatorV4(),
                    keccak256(
                        abi.encode(
                            _VAULT_APPROVAL_SIGNATURE_TYPE_HASH,
                            _status
                                // solhint-disable-next-line
                                ? keccak256("Grant full access to funds in Warp Vault? Read more here https://warp.finance/permission")
                                : keccak256(
                                    "Revoke access to Warp Vault? Read more here https://warp.finance/revoke"
                                ),
                            _user,
                            _contract,
                            _status,
                            userApprovalNonce[_user]++
                        )
                    )
                )
            );

        address recoveredAddress = ecrecover(digest, v, r, s);
        require(recoveredAddress == _user, "INVALID_SIGNATURE");

        userApprovedContracts[_user][_contract] = _status;

        emit Approval(_user, _contract, _status);
    }

    /// @notice pause vault actions
    function pause() external onlyOwner {
        _pause();
    }

    /// @notice unpause vault actions
    function unpause() external onlyOwner {
        _unpause();
    }

    /// @notice Deposit an amount of `token`
    /// @param _token The ERC-20 token to deposit.
    /// @param _from which account to pull the tokens.
    /// @param _to which account to push the tokens.
    /// @param _amount Token amount in native representation to deposit.
    /// @return amountOut The deposit amount in vault shares
    function deposit(
        IERC20 _token,
        address _from,
        address _to,
        uint256 _amount
    ) external override whenNotPaused allowed(_from) returns (uint256 amountOut) {
        // Checks
        require(_to != address(0), "INVALID_TO_ADDRESS");

        amountOut = toShare(_token, _amount, false);
        // transfer appropriate amount of underlying from _from to vault
        _token.safeTransferFrom(_from, address(this), _amount);

        // calculate shares
        balanceOf[_token][_to] = balanceOf[_token][_to] + amountOut;
        totals[_token] = totals[_token] + amountOut;

        emit Deposit(_token, _from, _to, _amount, amountOut);
    }

    /// @notice Withdraw the underlying share of `token` from a user account.
    /// @param _token The ERC-20 token to withdraw.
    /// @param _from which user to pull the tokens.
    /// @param _to which user to push the tokens.
    /// @param _shares of shares to withdraw
    /// @return amountOut The amount of underlying transferred
    function withdraw(
        IERC20 _token,
        address _from,
        address _to,
        uint256 _shares
    ) external override whenNotPaused allowed(_from) returns (uint256 amountOut) {
        // Checks
        require(_to != address(0), "INVALID_TO_ADDRESS");

        amountOut = toUnderlying(_token, _shares);
        balanceOf[_token][_from] = balanceOf[_token][_from] - _shares;
        totals[_token] = totals[_token] - _shares;

        _token.safeTransfer(_to, amountOut);

        emit Withdraw(_token, _from, _to, _shares, amountOut);
    }

    /// @notice Transfer share of `token` to another account
    /// @param _token The ERC-20 token to transfer.
    /// @param _from which user to pull the tokens.
    /// @param _to which user to push the tokens.
    /// @param _shares of shares to transfer
    function transfer(
        IERC20 _token,
        address _from,
        address _to,
        uint256 _shares
    ) external override whenNotPaused allowed(_from) {
        _transfer(_token, _from, _to, _shares);
    }

    /// @notice accept transfer of control
    function acceptOwnership() external {
        require(msg.sender == newOwner, "invalid owner");
        owner = newOwner;
        newOwner = address(0);
        emit OwnershipAccepted(newOwner, block.timestamp);
    }

    /// @notice Transfer control from current owner address to another
    /// @param _newOwner The new team
    function transferToNewOwner(address _newOwner) external onlyOwner {
        require(_newOwner != address(0), "INVALID_NEW_OWNER");
        newOwner = _newOwner;
        emit TransferControl(_newOwner, block.timestamp);
    }

    function _transfer(
        IERC20 _token,
        address _from,
        address _to,
        uint256 _shares
    ) internal {
        require(_to != address(0), "INVALID_TO_ADDRESS");
        // Effects
        balanceOf[_token][_from] = balanceOf[_token][_from] - _shares;
        balanceOf[_token][_to] = balanceOf[_token][_to] + _shares;
        emit Transfer(_token, _from, _to, _shares);
    }

    /// @notice The amount of currency available to be lent.
    /// @param _token The loan currency.
    /// @return The amount of `token` that can be borrowed.
    function maxFlashLoan(address _token) external view override returns (uint256) {
        return totals[IERC20(_token)];
    }

    /// @notice The fee to be charged for a given loan.
    /// @param // _token The loan currency.
    /// @param _amount The amount of tokens lent.
    /// @return The amount of `token` to be charged for the loan, on top of the returned principal.
    function flashFee(address, uint256 _amount) public view override returns (uint256) {
        return (_amount * flashLoanRate) / 1e18;
    }

    /// @notice Initiate a flash loan.
    /// @param _receiver The receiver of the tokens in the loan, and the receiver of the callback.
    /// @param _token The loan currency.
    /// @param _amount The amount of tokens lent.
    /// @param _data Arbitrary data structure, intended to contain user-defined parameters.
    function flashLoan(
        IERC3156FlashBorrower _receiver,
        address _token,
        uint256 _amount,
        bytes calldata _data
    ) external override returns (bool) {
        require(totals[IERC20(_token)] >= _amount, "Not enough balance");

        IERC20 token = IERC20(_token);

        uint256 tokenBalBefore = token.balanceOf(address(this));
        token.safeTransfer(address(_receiver), _amount);

        uint256 fee = flashFee(_token, _amount);
        require(
            _receiver.onFlashLoan(msg.sender, _token, _amount, fee, _data) ==
                FLASHLOAN_CALLBACK_SUCCESS,
            "IERC3156: Callback failed"
        );

        // receive loans and fees
        token.safeTransferFrom(address(_receiver), address(this), _amount + fee);

        uint256 receivedFees = token.balanceOf(address(this)) - tokenBalBefore;
        require(receivedFees >= fee, "not enough fees");

        emit FlashLoan(msg.sender, token, _amount, fee, address(_receiver));

        return true;
    }

    /// @dev Update the flashloan rate charged, only blacksmith team can call
    /// @param _newRate The ERC-20 token.
    function updateFlashloanRate(uint256 _newRate) external onlyOwner {
        require(_newRate < MAX_FLASHLOAN_RATE, "invalid rate");
        flashLoanRate = _newRate;
        emit UpdateFlashLoanRate(_newRate);
    }

    /// @dev Helper function to represent an `amount` of `token` in shares.
    /// @param _token The ERC-20 token.
    /// @param _amount The `token` amount.
    /// @param _ceil If to ceil the amount or not
    /// @return share The token amount represented in shares.
    function toShare(
        IERC20 _token,
        uint256 _amount,
        bool _ceil
    ) public view override returns (uint256 share) {
        uint256 currentTotal = totals[_token];
        if (currentTotal > 0) {
            uint256 currentUnderlyingBalance = _token.balanceOf(address(this));
            share = (_amount * currentTotal) / currentUnderlyingBalance;

            if (_ceil && ((share * currentUnderlyingBalance) / currentTotal) < _amount) {
                share = share + 1;
            }
        } else {
            share = _amount;
        }
    }

    /// @notice Helper function represent shares back into the `token` amount.
    /// @param _token The ERC-20 token.
    /// @param _share The amount of shares.
    /// @return amount The share amount back into native representation.
    function toUnderlying(IERC20 _token, uint256 _share)
        public
        view
        override
        returns (uint256 amount)
    {
        amount = (_share * _token.balanceOf(address(this))) / totals[_token];
    }
}
