const ERC20Custom = artifacts.require("ERC20Custom");
const Presale = artifacts.require("Presale");
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
    this.presale = await Presale.new({
      from: accounts[0],
    });
    // Granting Role for Airdrop contract to be a minter
    await this.erc20Custom.grantRole(
      "0x9f2df0fed2c77648de5860a4cc508cd0818c85b8b8a1ab4ceeef8d981c8956a6",
      this.airdrop.address,
      {
        from: accounts[0],
      }
    );
  });
});
