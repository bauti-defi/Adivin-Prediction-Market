// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.17;

contract Factory {

    address immutable admin;

    modifier onlyAdmin(){
        require(msg.sender == admin, "Factory: only admin");
        _;
    }

    constructor(){
        admin = msg.sender;
    }

    function createMarket() public onlyAdmin {
        // create market
        // create escrow
        // bind them together
    }

}