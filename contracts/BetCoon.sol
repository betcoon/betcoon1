// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract BetCoon {
    struct Bet {
        uint256 id;
        uint256 targetPrice;
        uint256 startTime;
        uint256 endTime;
        uint256 totalStake;
        uint256 winningStake;
        bool isOpen;
        bool outcome; // true if Bitcoin price is above target price
        bool isResolved;
        mapping(address => uint256) stakes;
        mapping(address => bool) betSide; // true if bet on price being above target price
    }

    uint256 public nextBetId;
    mapping(uint256 => Bet) public bets;

    // Function to create a new bet
    function createBet(uint256 targetPrice, uint256 durationInSeconds) public {
        uint256 endTime = block.timestamp + durationInSeconds;
        require(endTime > block.timestamp, "End time must be in the future");

        Bet storage bet = bets[nextBetId];
        bet.id = nextBetId;
        bet.targetPrice = targetPrice;
        bet.startTime = block.timestamp;
        bet.endTime = endTime;
        bet.isOpen = true;
        bet.isResolved = false;
        bet.totalStake = 0;
        bet.winningStake = 0;
        nextBetId++;
    }

    // Function to join an existing bet
    function joinBet(uint256 betId, bool aboveTarget) public payable {
        Bet storage bet = bets[betId];
        require(block.timestamp <= getBetCutoffTime(bet.startTime, bet.endTime), "Bet cutoff time has passed");
        require(msg.value > 0, "Must stake some amount");
        require(bet.isOpen, "Bet is not open");

        bet.stakes[msg.sender] += msg.value;
        bet.totalStake += msg.value;
        bet.betSide[msg.sender] = aboveTarget;
    }

    // Function to resolve the bet and determine the winning side
    function resolveBet(uint256 betId, uint256 actualPrice) public {
        Bet storage bet = bets[betId];
        require(block.timestamp >= bet.endTime, "Bet is still ongoing");
        require(!bet.isResolved, "Bet already resolved");

        bet.isResolved = true;
        bet.outcome = actualPrice >= bet.targetPrice;

        // Logic to calculate total winning stake
        // Iterate over stakes and sum the total staked amount for the winning side
    }

    // Function to claim winnings from a resolved bet
    function claimWinnings(uint256 betId) public {
        Bet storage bet = bets[betId];
        require(bet.isResolved, "Bet is not resolved yet");
        require(bet.stakes[msg.sender] > 0, "No stake to claim");
        require(bet.betSide[msg.sender] == bet.outcome, "Not on the winning side");

        uint256 winnerShare = (bet.stakes[msg.sender] * bet.totalStake) / bet.winningStake;
        payable(msg.sender).transfer(winnerShare);

        bet.stakes[msg.sender] = 0; // Clear the user's stake after claiming
    }

    // Utility function to get the bet cutoff time
function getBetCutoffTime(uint256 startTime, uint256 endTime) private pure returns (uint256) {
    uint256 duration = endTime - startTime;
    return startTime + (duration * 20 / 100); // 20% of the total duration
}

}
