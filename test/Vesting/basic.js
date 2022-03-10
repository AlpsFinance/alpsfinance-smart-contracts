const Vesting = artifacts.require('./VestingBase.sol');
const BigNumber = require('bignumber.js');
const ether = require('./helpers/ether').ether;
const increaseTime = require('./helpers/increaseTime');
const duration = increaseTime.duration;
const MockToken = artifacts.require('./StandardTokenMock.sol');

require('chai')
  .use(require('chai-as-promised'))
  .use(require('chai-bignumber')(BigNumber))
  .should();

  

  contract('Vesting: Constructor', function(accounts) {
    describe('Constructor', () => {
      it('must construct properly with correct parameters.', async () => {
        const minimumVestingPeriod = duration.days(181);
        const withdrawalCap = ether("10000");//18 decimal places
        const withdrawalFrequency = 1;//Weekly
        vestingCoinMock = await MockToken.new();
        
        let vestingStartedOn;
        let earliestWithdrawalDate;

   //

        vesting = await Vesting.new(minimumVestingPeriod, withdrawalCap, vestingCoinMock.address, withdrawalFrequency );

        ///The timestamp of contract deployment.
        vestingStartedOn = (await vesting.vestingStartedOn()).toNumber();
        earliestWithdrawalDate = vestingStartedOn + minimumVestingPeriod;

        assert((await vesting.minimumVestingPeriod()).toNumber() == minimumVestingPeriod);
        assert(await vesting.vestingCoin() == vestingCoinMock.address);
    
        assert((await vesting.withdrawalFrequency()).toNumber() == duration.days(7));
        assert((await vesting.earliestWithdrawalDate()).toNumber() == earliestWithdrawalDate);
      });
    });
});