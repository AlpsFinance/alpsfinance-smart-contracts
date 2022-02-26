/**
 * @fileoverview this testing will use the mock version instead of the
 * production version as it uses Chainlink Oracles, which for testing purpose
 * can't be used.
 */
const ERC20Custom = artifacts.require("ERC20Custom");
const Presale = artifacts.require("MockPresale");
// const truffleAssert = require("truffle-assertions");
// const expect = require("chai").expect;

contract("Presale", (accounts) => {
  const name = "Example Token";
  const symbol = "EXMP";
  const initialCap = "5000000000000000000000000000";

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
  });

  describe("should have basic presale features", () => {
    it("should", async () => {});
  });
});
