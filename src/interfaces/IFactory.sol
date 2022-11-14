// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.17;

/// @author bauti.eth
interface IFactory {
    struct Parameters {
        string _marketName;
        string _description;
        string _mediaUri;
        uint256 _marketExpirationDate;
        uint256 _marketResolveDate;
        uint256 _individualTokenSupplyCap;
        uint256 _individualTokenPrice;
        address _paymentToken;
        string[] _tokenNames;
        bytes6[] _tokenColors;
        uint256 _tokenCost;
        string _categories;
    }

    error NotAdmin();

    /// @notice Emitted when the factory creates a new Escrow-PredictionMarket pair.
    event PredictionMarketCreated(address indexed market, address indexed escrow, address indexed creator);

    /// @notice Creates a new prediction market that is NOT OPEN.
    /// @notice Only admin role is set on the market. Oracle and Escrow roles need to be set manually by the admin.
    function createMarket(Parameters calldata _parameters) external returns (address, address);
}
