const { expect } = require("chai");
const { ethers } = require("hardhat");

describe("BetCoon Contract", function () {
    let BetCoon;
    let betCoon;
    let owner;
    let addr1;
    let addr2;
    let addrs;

    beforeEach(async function () {
        [owner, addr1, addr2, ...addrs] = await ethers.getSigners();
        BetCoon = await ethers.getContractFactory("BetCoon");
        betCoon = await BetCoon.deploy();
    });

    describe("Bet Creation", function () {
        it("Should allow users to create a bet", async function () {
            const targetPrice = 50000;
            const duration = 3600; // 1 hour
            await betCoon.createBet(targetPrice, duration);

            const bet = await betCoon.bets(0);
            expect(bet.targetPrice).to.equal(targetPrice);
            expect(bet.isOpen).to.equal(true);
        });
    });

    describe("Joining a Bet", function () {
        it("Should allow users to join an existing bet", async function () {
            const betAmount = ethers.utils.parseEther("1.0");
            await betCoon.createBet(50000, 3600);
            await betCoon.connect(addr1).joinBet(0, true, { value: betAmount });

            const bet = await betCoon.bets(0);
            expect(await betCoon.totalStake(0)).to.equal(betAmount);
        });
    });

    describe("Joining a Bet After Cutoff Time", function () {
        it("Should not allow joining a bet after the cutoff time", async function () {
            await betCoon.createBet(50000, 3600); // 1 hour duration
            // Fast-forward time to simulate passing the cutoff time
            // This requires manipulating the blockchain's time in the test environment

            // Attempt to join the bet after the cutoff time
            await expect(
                betCoon.connect(addr1).joinBet(0, true, { value: ethers.utils.parseEther("1.0") })
            ).to.be.revertedWith("Bet cutoff time has passed");
        });
    });

    describe("Bet Resolution", function () {
        it("Should resolve a bet correctly based on actual price", async function () {
            await betCoon.createBet(50000, 3600); // 1 hour duration
            await betCoon.connect(addr1).joinBet(0, true, { value: ethers.utils.parseEther("1.0") });

            // Fast-forward time to simulate bet end
            // This requires manipulating the blockchain's time in the test environment

            // Simulate actual price and resolve the bet
            const actualPrice = 51000; // Price above target
            await betCoon.resolveBet(0, actualPrice);

            const bet = await betCoon.bets(0);
            expect(bet.isResolved).to.equal(true);
            expect(bet.outcome).to.equal(true); // Outcome should be true since actual price is above target
        });
    });

    describe("Claiming Winnings", function () {
        it("Should allow winners to claim winnings", async function () {
            // Setup the bet
            await betCoon.createBet(50000, 3600); // 1 hour duration
            await betCoon.connect(addr1).joinBet(0, true, { value: ethers.utils.parseEther("1.0") });

            // Simulate the bet resolution
            const actualPrice = 51000; // Price above target
            await betCoon.resolveBet(0, actualPrice);

            // Claim winnings
            await expect(betCoon.connect(addr1).claimWinnings(0))
                .to.emit(betCoon, 'WinningsClaimed')
                .withArgs(0, addr1.address, ethers.utils.parseEther("1.0"));

            // Check if the stake is cleared
            const bet = await betCoon.bets(0);
            expect(bet.stakes[addr1.address]).to.equal(0);
        });

        it("Should not allow losers to claim winnings", async function () {
            // Create a bet and join from losing side
            const targetPrice = 50000;
            const betAmount = ethers.utils.parseEther("1.0");
            await betCoon.createBet(targetPrice, 3600);
            await betCoon.connect(addr2).joinBet(0, false, { value: betAmount });

            // Simulate the bet resolution
            const actualPrice = 51000; // Price above target
            await betCoon.resolveBet(0, actualPrice);

            // Attempt to claim winnings from losing side
            await expect(betCoon.connect(addr2).claimWinnings(0))
                .to.be.revertedWith("Not on the winning side");
        });

        it("Should not allow claiming winnings if the bet is not resolved", async function () {
            // Create a bet and join
            const targetPrice = 50000;
            const betAmount = ethers.utils.parseEther("1.0");
            await betCoon.createBet(targetPrice, 3600);
            await betCoon.connect(addr1).joinBet(0, true, { value: betAmount });

            // Attempt to claim winnings before the bet is resolved
            await expect(betCoon.connect(addr1).claimWinnings(0))
                .to.be.revertedWith("Bet is not resolved yet");
        });
    });
});
