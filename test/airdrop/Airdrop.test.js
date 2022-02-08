const ERC20Custom = artifacts.require("ERC20Custom");
const Airdrop = artifacts.require("Airdrop");
const { root } = require("../../merkle.json");
const expect = require("chai").expect;

contract("Airdrop", (accounts) => {
  const name = "Example Token";
  const symbol = "EXMP";
  const initialCap = "5000000000000000000000000000";

  beforeEach(async () => {
    this.erc20Custom = await ERC20Custom.new(name, symbol, initialCap, {
      from: accounts[0],
    });
    this.airdrop = await Airdrop.new(this.erc20Custom.address, root, {
      from: accounts[0],
    });
    // Granting Role for Airdrop contract to be a minter
    this.erc20Custom.grantRole(
      "0x9f2df0fed2c77648de5860a4cc508cd0818c85b8b8a1ab4ceeef8d981c8956a6",
      this.airdrop.address,
      {
        from: accounts[0],
      }
    );
  });

  describe("should have basic airdrop features", () => {
    it("should allow user that has claim to claim their token", async () => {});

    it("should allow user that has no claim unable to claim any token", async () => {});

    it("should disallow user that has already claimed their token", async () => {});
  });
});
