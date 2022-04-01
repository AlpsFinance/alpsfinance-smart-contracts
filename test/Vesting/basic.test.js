const Vesting = artifacts.require("./VestingBase.sol");
const BigNumber = require("bignumber.js");
const increaseTime = require("../../utils/increaseTime");
const MockToken = artifacts.require("./ERC20TokenMock.sol");

require("chai")
  .use(require("chai-as-promised"))
  .use(require("chai-bignumber")(BigNumber))
  .should();

contract("Vesting: Constructor", function (accounts) {
  describe("Constructor", () => {
    it("must construct properly with correct parameters.", async () => {
      vestingCoinMock = await MockToken.new();
      const vesting = await Vesting.new(vestingCoinMock.address);

      ///The timestamp of contract deployment.
      vestingStartedOn = (await vesting.vestingStartedOn()).toNumber();
      earliestWithdrawalDate = vestingStartedOn + minimumVestingPeriod;

      assert((await vesting.vestingCoin()) == vestingCoinMock.address);
    });
  });
});
