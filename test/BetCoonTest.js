const { expect } = require("chai");
const { ethers } = require("hardhat");
const { parseEther } = require('ethers/lib/utils'); // Direct import of parseEther

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

    describe("Creating a Bet", function () {
        it("Should allow users to create a bet", async function () {
            const targetPrice = 50000;
            const duration = 3600;
            await betCoon.createBet(targetPrice, duration);

            const bet = await betCoon.bets(0);
            expect(bet.targetPrice).to.equal(targetPrice);
            expect(bet.isOpen).to.equal(true);
        });
    });

    describe("Joining a Bet", function () {
        it("Should allow users to join an existing bet", async function () {
            const betAmount = parseEther("1.0");
            await betCoon.createBet(50000, 3600);
            await betCoon.connect(addr1).joinBet(0, true, { value: betAmount });

            const bet = await betCoon.bets(0);
            expect(bet.totalStake).to.equal(betAmount);
        });
    });

    describe("Joining a Bet After Cutoff Time", function () {
        it("Should not allow joining a bet after the cutoff time", async function () {
            await betCoon.createBet(50000, 3600);
            // Simulate time passage beyond the cutoff time
            // This may require specific hardhat functionalities or test environment setup

            // Attempt to join the bet and expect it to fail
            await expect(
                betCoon.connect(addr1).joinBet(0, true, { value: parseEther("1.0") })
            ).to.be.revertedWith("Bet cutoff time has passed");
        });
    });

    describe("Resolving a Bet", function () {
        it("Should resolve a bet correctly", async function () {
            await betCoon.createBet(50000, 3600);
            await betCoon.connect(addr1).joinBet(0, true, { value: parseEther("1.0") });
            
            // Simulate time passage and resolve the bet
            // This requires manipulating the blockchain's time

            // Add logic to resolve the bet and check if it's resolved correctly
        });
    });

    describe("Claiming Winnings", function () {
        it("Should allow winners to claim winnings", async function () {
            // Logic to create, join, resolve a bet, and then claim winnings
            // Ensure that winnings are correctly distributed
        });
    });
});
