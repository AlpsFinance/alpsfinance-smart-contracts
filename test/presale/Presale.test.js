/**
 * @fileoverview this testing will use the mock version instead of the
 * production version as it uses Chainlink Oracles, which for testing purpose
 * can't be used.
 */
const ERC20Custom = artifacts.require("ERC20Custom");
const Presale = artifacts.require("MockPresale");
const PresaleDetails = require("../../constant/presale.json");
const timeTravel = require("../../utils/timeTravel");
const expect = require("chai").expect;
const truffleAssert = require("truffle-assertions");

contract("Presale", (accounts) => {
  const name = "Example Token";
  const symbol = "EXMP";
  const initialCap = "5000000000000000000000000000";
  const currentTime = Date.now();
  const startingTime = (currentTime - 100000).toString();
  const { usdPrice, minimumUSDPurchase, maximumPresaleAmount } = PresaleDetails[0];

  beforeEach(async () => {
    this.erc20Custom = await ERC20Custom.new(name, symbol, initialCap, {
      from: accounts[0],
    });
    this.presale = await Presale.new(
      this.erc20Custom.address,
      accounts[5],
      (currentTime * 2).toString(),
      {
        from: accounts[0],
      }
    );
    // Granting Role for Presale contract to be a minter
    await this.erc20Custom.grantRole(
      "0x9f2df0fed2c77648de5860a4cc508cd0818c85b8b8a1ab4ceeef8d981c8956a6",
      this.presale.address,
      {
        from: accounts[0],
      }
    );

    // Set A Sample Presale Round
    await this.presale.setPresaleRound(
      "0",
      // make the starting time in the past for easy testing
      startingTime,
      web3.utils.toWei(usdPrice.toString()),
      web3.utils.toWei(minimumUSDPurchase.toString()),
      web3.utils.toWei(maximumPresaleAmount.toString()),
      { from: accounts[0] }
    );
  });

  /**
   * Testing getter methods:
   * - Should be able to fetch current presale round (with only one round)
   * - Should be able to fetch current presale round (with multiple rounds)
   * - should be able to fetch current presale details
   * - should be able to fetch the correct total number of presale rounds
   */
  describe("should have the properly working getter methods", () => {
    it("should be able to fetch current presale round (with only one round)", async () => {
      expect(parseInt((await this.presale.getCurrentPresaleRound()).toString())).to.equal(0);
    });

    it("should be able to fetch current presale round (with multiple rounds)", async () => {
      // Setting up a second round
      await this.presale.setPresaleRound(
        "1",
        // make the starting time in the past for easy testing
        (currentTime - 100).toString(),
        web3.utils.toWei(usdPrice.toString()),
        web3.utils.toWei(minimumUSDPurchase.toString()),
        web3.utils.toWei(maximumPresaleAmount.toString()),
        { from: accounts[0] }
      );

      await timeTravel(currentTime);

      expect(parseInt((await this.presale.getCurrentPresaleRound()).toString())).to.equal(1);
    });

    it("should be able to fetch current presale details", async () => {
      const currentPresaleDetails = await this.presale.getCurrentPresaleDetails();

      expect(currentPresaleDetails[0].toString()).to.equal(startingTime);
      expect(parseInt(currentPresaleDetails[1].toString()) / 10 ** 18).to.equal(usdPrice);
      expect(parseInt(currentPresaleDetails[2].toString()) / 10 ** 18).to.equal(minimumUSDPurchase);
      expect(parseInt(currentPresaleDetails[3].toString()) / 10 ** 18).to.equal(
        maximumPresaleAmount
      );
    });

    it("should be able to fetch the correct total number of presale rounds", async () => {
      // Setting up a second round
      await this.presale.setPresaleRound(
        "1",
        // make the starting time in the past for easy testing
        (currentTime - 100).toString(),
        web3.utils.toWei(usdPrice.toString()),
        web3.utils.toWei(minimumUSDPurchase.toString()),
        web3.utils.toWei(maximumPresaleAmount.toString()),
        { from: accounts[0] }
      );

      expect(parseInt((await this.presale.getTotalPresaleRound()).toString())).to.equal(2);
    });
  });

  /**
   * Testing presale features:
   * - Should enable user to purchase ALPS token with native token
   * - Should enable user to purchase ALPS token with ERC20 token
   * - Should disable user from purchasing ALPS after ending time is reached
   */
  describe("should have basic presale features", () => {
    it("should enable user to purchase ALPS token with native token", async () => {
      const nativeTokenAmount = web3.utils.toWei((1).toString());
      // Make the token available to be used to purchase ALPS token
      await this.presale.setPresalePaymentToken(
        "0x0000000000000000000000000000000000000000",
        true,
        this.erc20Custom.address, // for mock value testing
        {
          from: accounts[0],
        }
      );

      await this.presale.presaleTokens(
        "0x0000000000000000000000000000000000000000",
        nativeTokenAmount,
        {
          from: accounts[0],
          value: nativeTokenAmount,
        }
      );
      const currentPresaleRound = (await this.presale.getCurrentPresaleRound()).toString();

      expect(
        parseInt(web3.utils.fromWei((await this.erc20Custom.balanceOf(accounts[0])).toString()))
      ).to.equal(1200); // This is just a mock calculation 1/0.000125
      expect(
        parseInt((await this.presale.getPresaleAmountByRound(currentPresaleRound)).toString())
      ).to.equal(1.2e21);
    });

    it("should enable user to purchase ALPS token with ERC20 token", async () => {
      const erc20TokenAmount = web3.utils.toWei((100).toString());
      // Create a new ERC20 token to purchase ALPS token
      this.erc20Custom2 = await ERC20Custom.new(name, symbol, initialCap, {
        from: accounts[0],
      });

      // Mint 100 new ERC20 token
      await this.erc20Custom2.mint(accounts[0], erc20TokenAmount, {
        from: accounts[0],
      });

      // Approve `Presale` contract to purchase the ALPS token
      await this.erc20Custom2.approve(this.presale.address, erc20TokenAmount, {
        from: accounts[0],
      });

      // Make the token available to be used to purchase ALPS token
      "0x0000000000000000000000000000000000000000",
        await this.presale.setPresalePaymentToken(
          this.erc20Custom2.address,
          true,
          this.erc20Custom.address, // for mock value testing

          {
            from: accounts[0],
          }
        );

      // await timeTravel(currentTime);

      await this.presale.presaleTokens(this.erc20Custom2.address, erc20TokenAmount, {
        from: accounts[0],
      });

      const currentPresaleRound = (await this.presale.getCurrentPresaleRound()).toString();

      expect(
        parseInt(web3.utils.fromWei((await this.erc20Custom.balanceOf(accounts[0])).toString()))
      ).to.equal(1200); // This is just a mock calculation 100/0.000125
      expect(
        parseInt((await this.presale.getPresaleAmountByRound(currentPresaleRound)).toString())
      ).to.equal(1.2e21);
    });

    it("should disable user from purchasing ALPS after ending time is reached", async () => {
      const nativeTokenAmount = web3.utils.toWei((1).toString());
      // Make the token available to be used to purchase ALPS token
      await this.presale.setPresalePaymentToken(
        "0x0000000000000000000000000000000000000000",
        true,
        this.erc20Custom.address, // for mock value testing
        {
          from: accounts[0],
        }
      );

      await timeTravel(currentTime * 3);

      await truffleAssert.reverts(
        this.presale.presaleTokens(
          "0x0000000000000000000000000000000000000000",
          nativeTokenAmount,
          {
            from: accounts[0],
            value: nativeTokenAmount,
          }
        )
      );
    });
  });

  describe("should be able to manage access control correctly", () => {
    it("should be able to set ending time by owners", async () => {
      const newEndingTime = currentTime * 10;
      await this.presale.setEndingTime(newEndingTime, { from: accounts[0] });

      expect(parseInt((await this.presale.endingTime()).toString())).to.equal(newEndingTime);
    });

    it("should disable access to set ending time by non-owners", async () => {
      const newEndingTime = currentTime * 10;
      await truffleAssert.reverts(this.presale.setEndingTime(newEndingTime, { from: accounts[1] }));
    });
  });
});
