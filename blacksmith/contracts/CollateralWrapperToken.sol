// SPDX-License-Identifier: MIT
pragma solidity 0.8.1;

import "./WrapperToken.sol";
import "./interfaces/IBSLendingPair.sol";

////////////////////////////////////////////////////////////////////////////////////////////
/// @title CollateralWrapperToken
/// @author @samparsky
////////////////////////////////////////////////////////////////////////////////////////////

contract CollateralWrapperToken is WrapperToken {
    function transfer(address _recipient, uint256 _amount) external override returns (bool) {
        uint256 maxWithdrawAllowed = IBSLendingPair(this.owner()).getMaxWithdrawAllowed(msg.sender);
        require(_amount <= maxWithdrawAllowed, "EXCEEDS_ALLOWED");
        _transfer(msg.sender, _recipient, _amount);
        return true;
    }
}
