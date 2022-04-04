const Vesting = artifacts.require("./VestingBase.sol");
const MockToken = artifacts.require("./ERC20TokenMock.sol");
const EVMRevert = require("../../utils/EVMRevert").EVMRevert;
const ether = require("../../utils/ether").ether;
const increaseTime = require("../../utils/increaseTime");
const duration = increaseTime.duration;
const BigNumber = require("bignumber.js");

require("chai").use(require("chai-as-promised")).should();

contract("Vesting: Funding", function (accounts) {
  describe("Ruleset for Funding and Withdrawing Funds", () => {
    let vestingCoinMock;
    let vesting;

    beforeEach(async () => {
      vestingCoinMock = await MockToken.new();

      vesting = await Vesting.new(vestingCoinMock.address);
    });

    it("must not allow non admins to fund the vesting.", async () => {
      ///Transfer some tokens to a non admin.
      vestingCoinMock.transfer(accounts[1], ether("100000000"));

      await vestingCoinMock.approve(vesting.address, ether("50000000"), {
        from: accounts[1],
      });
      await vesting
        .fund({ from: accounts[1] })
        .should.be.rejectedWith(EVMRevert);
    });

    it("must allow administrators to fund the vesting with correct parameters.", async () => {
      const amount = web3.utils.toBN(ether("50000000"));
      const amount1 = web3.utils.toBN(ether("100000000"));

      await vestingCoinMock.approve(vesting.address, ether("50000000"));
      await vesting.fund();

      await vestingCoinMock.approve(vesting.address, ether("50000000"));

      await vesting.fund({ from: accounts[0] });
    });

    it("must not allow non admins to remove funds from the vesting.", async () => {
      await vestingCoinMock.approve(vesting.address, ether("50000000"));
      await vesting.fund();

      await vesting
        .removeFunds(ether("20000000"), { from: accounts[1] })
        .should.be.rejectedWith(EVMRevert);
    });

    it("must allow admins to remove funds from the vesting.", async () => {
      await vestingCoinMock.approve(vesting.address, ether("50000000"));
      await vesting.fund({ from: accounts[0] });

      const withdrawnAmount = ether("20000000");

      await vesting.removeFunds(withdrawnAmount, { from: accounts[0] });
    });
  });
});
