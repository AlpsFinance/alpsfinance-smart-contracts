/**
 * @fileoverview this testing will use the mock version instead of the
 * production version as it uses Chainlink Oracles, which for testing purpose
 * can't be used.
 */
const ERC20Custom = artifacts.require("ERC20Custom");
const Presale = artifacts.require("MockPresale");
const PresaleDetails = require("../../constant/presale.json");
const truffleAssert = require("truffle-assertions");
const expect = require("chai").expect;

contract("Presale", (accounts) => {
  const name = "Example Token";
  const symbol = "EXMP";
  const initialCap = "5000000000000000000000000000";
  const startingTime = (Date.now() - 100000).toString();
  const { usdPrice, minimumUSDPurchase, maximumPresaleAmount } =
    PresaleDetails[0];

  beforeEach(async () => {
    this.erc20Custom = await ERC20Custom.new(name, symbol, initialCap, {
      from: accounts[0],
    });
    this.presale = await Presale.new(this.erc20Custom.address, accounts[5], {
      from: accounts[0],
    });
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

  describe("should have the properly working getter methods", () => {
    it("should be able to fetch current presale round", async () => {
      expect(
        parseInt((await this.presale.getCurrentPresaleRound()).toString())
      ).to.equal(0);
    });

    it("should be able to fetch current presale details", async () => {
      const currentPresaleDetails =
        await this.presale.getCurrentPresaleDetails();

      expect(currentPresaleDetails[0].toString()).to.equal(startingTime);
      expect(parseInt(currentPresaleDetails[1].toString()) / 10 ** 18).to.equal(
        usdPrice
      );
      expect(parseInt(currentPresaleDetails[2].toString()) / 10 ** 18).to.equal(
        minimumUSDPurchase
      );
      expect(parseInt(currentPresaleDetails[3].toString()) / 10 ** 18).to.equal(
        maximumPresaleAmount
      );
    });
  });

  describe("should have basic presale features", () => {
    it("should enable user to purchase ALPS token with native token", async () => {
      const nativeTokenAmount = web3.utils.toWei((100).toString());
      await this.presale.presaleTokens(
        "0x0000000000000000000000000000000000000000",
        nativeTokenAmount,
        {
          from: accounts[0],
          value: nativeTokenAmount,
        }
      );

      expect(
        (await this.erc20Custom.balanceOf(accounts[0])).toString()
      ).to.equal(web3.utils.toWei("240000").toString()); // This is just a mock calculation 100/0.000125
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

      await this.presale.presaleTokens(
        this.erc20Custom2.address,
        erc20TokenAmount,
        {
          from: accounts[0],
        }
      );

      expect(
        (await this.erc20Custom.balanceOf(accounts[0])).toString()
      ).to.equal(web3.utils.toWei("240000").toString()); // This is just a mock calculation 100/0.000125
    });
  });
});
