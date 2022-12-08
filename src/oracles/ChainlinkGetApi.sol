// // SPDX-License-Identifier: MIT
// pragma solidity ^0.8.7;

// import "@chainlink/ChainlinkClient.sol";
// import "@chainlink/ConfirmedOwner.sol";
// import "@src/PredictionMarket.sol";

// contract APIConsumer is ChainlinkClient, ConfirmedOwner {
//     using Chainlink for Chainlink.Request;

//     uint256 public winner;
//     PredictionMarket public market;
//     bytes32 private jobId;
//     uint256 private fee;

//     event RequestWinner(bytes32 indexed requestId, uint256 winner);

//     constructor() ConfirmedOwner(msg.sender) {
//         setChainlinkToken(0x01BE23585060835E02B77ef475b0Cc51aA1e0709);
//         setChainlinkOracle(0xf3FBB7f3391F62C8fe53f89B41dFC8159EE9653f);
//         jobId = ""; //TODO - add JobId
//         fee = (1 * LINK_DIVISIBILITY) / 10; // 0,1 * 10**18 (Varies by network and job)
//     }

//     // function setMarket(address _market) external onlyAdmin {
//     //     market = _market;
//     // }

//     /**
//      * Create a Chainlink request to retrieve API response, find the target
//      * data, then multiply by 1000000000000000000 (to remove decimal places from data).
//      */
//     function requestVolumeData() public returns (bytes32 requestId) {
//         Chainlink.Request memory req = buildChainlinkRequest(jobId, address(this), this.fulfill.selector);

//         // Set the URL to perform the GET request on
//         req.add("get", "https://adivin.io/get/worldcupwinner");

//         req.add("path", "RESULT,WINNER"); // Chainlink nodes 1.0.0 and later support this format

//         int256 timesAmount = 10 ** 18;
//         req.addInt("times", timesAmount);

//         // Sends the request
//         return sendChainlinkRequest(req, fee);
//     }

//     /**
//      * Receive the response in the form of uint256
//      */
//     function fulfill(bytes32 _requestId, uint256 _winner) public recordChainlinkFulfillment(_requestId) {
//         emit RequestWinner(_requestId, _volume);
//         winner = _winner;
//         market.submitResult(winner);
//     }

//     /**
//      * Allow withdraw of Link tokens from the contract
//      */
//     function withdrawLink() public onlyOwner {
//         LinkTokenInterface link = LinkTokenInterface(chainlinkTokenAddress());
//         require(link.transfer(msg.sender, link.balanceOf(address(this))), "Unable to transfer");
//     }
// }
