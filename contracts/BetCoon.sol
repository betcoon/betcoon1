// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract BetCoon {
    struct Bet {
        uint256 id;
        uint256 targetPrice;
        uint256 dueDate;
        address creator;
        bool isOpen;
        bool isResolved;
        mapping(address => uint256) stakes;
        uint256 totalStake;
        bool outcome; // true if target price is met or exceeded
    }

    uint256 public nextBetId;
    mapping(uint256 => Bet) public bets;

    function createBet(uint256 targetPrice, uint256 dueDate) public {
        require(dueDate > block.timestamp, "Due date must be in the future");
        Bet storage bet = bets[nextBetId];
        bet.id = nextBetId;
        bet.targetPrice = targetPrice;
        bet.dueDate = dueDate;
        bet.creator = msg.sender;
        bet.isOpen = true;
        bet.isResolved = false;
        nextBetId++;
    }

    function joinBet(uint256 betId) public payable {
        Bet storage bet = bets[betId];
        require(bet.isOpen, "Bet is not open");
        require(bet.dueDate > block.timestamp, "Bet has already ended");
        require(msg.value > 0, "Must stake some amount");

        bet.stakes[msg.sender] += msg.value;
        bet.totalStake += msg.value;
    }

    function resolveBet(uint256 betId, uint256 actualPrice) public {
        Bet storage bet = bets[betId];
        require(msg.sender == bet.creator, "Only creator can resolve the bet");
        require(bet.dueDate <= block.timestamp, "Bet has not ended yet");
        require(!bet.isResolved, "Bet is already resolved");

        bet.isResolved = true;
        bet.outcome = actualPrice >= bet.targetPrice;
    }

    function claimWinnings(uint256 betId) public {
        Bet storage bet = bets[betId];
        require(bet.isResolved, "Bet is not resolved yet");

        uint256 userStake = bet.stakes[msg.sender];
        require(userStake > 0, "No stake to claim");

        // Payout logic: winners get their stake back plus a proportion of the losing side's stake
        bool userWon = (bet.outcome && userStake >= bet.targetPrice) || (!bet.outcome && userStake < bet.targetPrice);
        if (userWon) {
            uint256 payout = userStake; // Simplified payout calculation; should be adjusted based on total stakes and odds
            payable(msg.sender).transfer(payout);
            bet.totalStake -= userStake;
        }

        bet.stakes[msg.sender] = 0;
    }

    // Additional utility functions can be added as needed
}
