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

    // Fee structure variables
    uint256 public constant FEE_CUTOFF_PERCENTAGE = 20; // Cutoff time as a percentage of total bet duration
    uint256 public constant INITIAL_FEE_PERCENTAGE = 5; // Initial fee percentage
    uint256 public constant FINAL_FEE_PERCENTAGE = 15; // Final fee percentage

    event BetCreated(uint256 indexed betId, uint256 targetPrice, uint256 startTime, uint256 endTime);
    event BetJoined(uint256 indexed betId, address indexed participant, uint256 amount, bool aboveTarget);
    event BetResolved(uint256 indexed betId, bool outcome);
    event WinningsClaimed(uint256 indexed betId, address indexed claimant, uint256 amount);

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

        emit BetCreated(nextBetId, targetPrice, block.timestamp, endTime);

        nextBetId++;
    }

    // Function to join an existing bet
    function joinBet(uint256 betId, bool aboveTarget) public payable {
        Bet storage bet = bets[betId];
        require(block.timestamp <= getBetCutoffTime(bet.startTime, bet.endTime), "Bet cutoff time has passed");
        require(msg.value > 0, "Must stake some amount");
        require(bet.isOpen, "Bet is not open");

        uint256 fee = calculateFee(bet.startTime, bet.endTime, msg.value);
        uint256 stakedAmount = msg.value - fee;

        bet.stakes[msg.sender] += stakedAmount;
        bet.totalStake += stakedAmount;
        bet.betSide[msg.sender] = aboveTarget;

        emit BetJoined(betId, msg.sender, stakedAmount, aboveTarget);
    }

    // Function to resolve the bet and determine the winning side
    function resolveBet(uint256 betId, uint256 actualPrice) public {
        Bet storage bet = bets[betId];
        require(block.timestamp >= bet.endTime, "Bet is still ongoing");
        require(!bet.isResolved, "Bet already resolved");

        bet.isResolved = true;
        bet.outcome = actualPrice >= bet.targetPrice;

        // Calculate total winning stake
        calculateWinningStake(betId);

        emit BetResolved(betId, bet.outcome);
    }

    // Function to claim winnings from a resolved bet
    function claimWinnings(uint256 betId) public {
        Bet storage bet = bets[betId];
        require(bet.isResolved, "Bet is not resolved yet");
        require(bet.stakes[msg.sender] > 0, "No stake to claim");
        require(bet.betSide[msg.sender] == bet.outcome, "Not on the winning side");

        uint256 winnerShare = (bet.stakes[msg.sender] * bet.totalStake) / bet.winningStake;
        payable(msg.sender).transfer(winnerShare);

        emit WinningsClaimed(betId, msg.sender, winnerShare);

        bet.stakes[msg.sender] = 0; // Clear the user's stake after claiming
    }

    // Utility function to get the bet cutoff time
    function getBetCutoffTime(uint256 startTime, uint256 endTime) private pure returns (uint256) {
        uint256 duration = endTime - startTime;
        return startTime + (duration * FEE_CUTOFF_PERCENTAGE / 100);
    }

    // Function to calculate fee based on participation time
    function calculateFee(uint256 startTime, uint256 endTime, uint256 amount) private view returns (uint256) {
        uint256 duration = endTime - startTime;
        uint256 elapsedTime = block.timestamp - startTime;
        uint256 feePercentage = INITIAL_FEE_PERCENTAGE + (FINAL_FEE_PERCENTAGE - INITIAL_FEE_PERCENTAGE) * elapsedTime / duration;
        return amount * feePercentage / 100;
    }

    // Function to calculate the total winning stake
    function calculateWinningStake(uint256 betId) private {
        Bet storage bet = bets[betId];
        uint256 totalWinningStake = 0;
        // Iterate through all participants and sum the stakes of those on the winning side
        // Add logic to iterate through stakes mapping
        bet.winningStake = totalWinningStake;
    }
}
