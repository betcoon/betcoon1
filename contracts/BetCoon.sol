// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract BetCoon {
    struct Bet {
        uint256 id;
        uint256 amount;
        uint256 targetPrice;
        uint256 dueDate;
        address creator;
        bool isOpen;
    }

    uint256 public nextBetId;
    mapping(uint256 => Bet) public bets;
    mapping(address => uint256[]) public betsByUser;

    function createBet(uint256 targetPrice, uint256 dueDate) public {
        require(dueDate > block.timestamp, "Due date must be in the future");
        bets[nextBetId] = Bet(nextBetId, 0, targetPrice, dueDate, msg.sender, true);
        betsByUser[msg.sender].push(nextBetId);
        nextBetId++;
    }

    // Additional functions will go here
}