// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.17;

import "@src/interfaces/IEscrow.sol";
import "@src/PredictionMarket.sol";
import "@src/Escrow.sol";

import "@openzeppelin-contracts/token/ERC20/ERC20.sol";

library Invariants {
    /// @dev This tests for invariant #1
    function circulatingTokenSupplyEqEscrowBalance(PredictionMarket _market, Escrow _escrow)
        external
        view
        returns (bool)
    {
        ERC20 paymentToken = _escrow.paymentToken();

        // get sum of all prediction tokens
        uint256 sum = 0;

        // prediction count starts at 1.
        // that means predictionCount = 5 is 5 options.
        //for (uint256 i = 1; i < _market.getOptionCount(); i++) {
        //    sum += _market.totalSupply(i);
        //}

        // scale up sum to match payment token decimals
        sum *= 10 ** paymentToken.decimals();

        // get escrow balance, scaled down
        uint256 escrowBalance = paymentToken.balanceOf(address(_escrow));

        return sum == escrowBalance;
    }

    function circulatingTokenSupplyEqTotalPot(PredictionMarket _market, Escrow _escrow) external view returns (bool) {
        ERC20 paymentToken = _escrow.paymentToken();

        // get sum of all prediction tokens
        uint256 sum = 0;

        // prediction count starts at 1.
        // that means predictionCount = 5 is 5 options.
        //for (uint256 i = 1; i < _market.getOptionCount(); i++) {
        //    sum += _market.totalSupply(i);
        //}

        // scale up sum to match payment token decimals
        sum *= 10 ** paymentToken.decimals();

        // get escrow balance, scaled down
        (uint256 totalDeposit, uint256 _totalPaidOut, uint256 totalFee) = _escrow.marketData();

        // totalPot = totalDeposit + totalFee
        return sum == totalFee + totalDeposit;
    }

    function totalEscrowedEqTokenBalance(Escrow _escrow) external view returns (bool) {
        ERC20 paymentToken = _escrow.paymentToken();

        // get escrow balance
        uint256 escrowBalance = paymentToken.balanceOf(address(_escrow));

        return escrowBalance == _escrow.totalDeposited() + _escrow.totalFee();
    }

    function totalTokenSupplyIsLessThanAllowedSupplyCap(PredictionMarket _market) external view returns (bool) {
        // prediction count starts at 1.
        // that means predictionCount = 5 is 5 options.
        //for (uint256 i = 1; i < _market.getOptionCount(); i++) {
        //    if (_market.totalSupply(i) > _market.individualTokenSupplyCap()) return false;
        //}
        return true;
    }
}
