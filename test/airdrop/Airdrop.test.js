const ERC20Custom = artifacts.require("ERC20Custom");
const Airdrop = artifacts.require("Airdrop");
const { root } = require("../../merkle.json");
const expect = require("chai").expect;

contract("Airdrop", (accounts) => {
  const name = "Example Token";
  const symbol = "EXMP";

  beforeEach(async () => {
    this.erc20Custom = await ERC20Custom.new(name, symbol, {
      from: accounts[0],
    });
    this.airdrop = await Airdrop.new(this.erc20Custom.address, root, {
      from: accounts[0],
    });
    await this.erc20Custom.mint(this.airdrop.address, "1000000000000000000", {
      from: accounts[0],
    });
  });

  describe("should have basic airdrop features", () => {
    it("should have the right name and symbol", async () => {});
  });
});
