const ERC20Custom = artifacts.require("ERC20Custom");
const expect = require("chai").expect;

contract("ERC20Custom", (accounts) => {
  const name = "Example Token";
  const symbol = "EXMP";

  beforeEach(async () => {
    this.erc20Custom = await ERC20Custom.new(name, symbol, {
      from: accounts[0],
    });
  });

  it("should have the right name and symbol", async () => {
    expect(await this.erc20Custom.name()).to.equal(name);
    expect(await this.erc20Custom.symbol()).to.equal(symbol);
  });

  it("should be minting new tokens", async () => {
    const amount = web3.utils.toBN("1");

    // Expect in the beginning to have balance 0
    expect((await this.erc20Custom.balanceOf(accounts[1])).toString()).to.equal(
      "0"
    );
    await this.erc20Custom.mint(accounts[1], amount);
    // Expect to have 1 token after mint
    expect((await this.erc20Custom.balanceOf(accounts[1])).toString()).to.equal(
      amount.toString()
    );
  });
});
