const Vesting = artifacts.require('./VestingBase.sol');
const BigNumber = require('bignumber.js');
const { expect } = require('chai');
const EVMRevert = require('./helpers/EVMRevert').EVMRevert;
const ether = require('./helpers/ether').ether;
const { increaseTimeTo, duration} = require('./helpers/increaseTime');
const MockToken = artifacts.require('./StandardTokenMock.sol');

require('chai')
  .use(require('chai-as-promised'))
  .use(require('chai-bignumber')(BigNumber))
  .should();

  contract('Vesting: Withdrawal', function(accounts) {
    describe('Ruleset for Vesting Allocations', () => {
        let vestingCoinMock;

        beforeEach(async () => {
            vestingCoinMock = await MockToken.new();                  
        });

        it('must correctly calculate daily allocations.', async () => {
            const minimumVestingPeriod = duration.days(181);
            const withdrawalCap = ether("10000");//18 decimal places
            const withdrawalFrequency = 0;//Daily

          const  vesting = await Vesting.new(minimumVestingPeriod, withdrawalCap, vestingCoinMock.address, withdrawalFrequency );

            await vestingCoinMock.approve(vesting.address, ether("50000000"));
            await vesting.fund();

            let earliestWithdrawalDate = (await vesting.earliestWithdrawalDate()).toNumber();
            let releaseOn = earliestWithdrawalDate + duration.minutes(1);
            let totalVested = ether("111111");

            await vesting.createAllocation(accounts[1], 'John Doe 1', ether("111111"), releaseOn);
            
         
            expect(parseInt(await vesting.totalVested())).to.equal(parseInt(totalVested));      

            await increaseTimeTo(releaseOn + duration.minutes(1));

            expect(parseInt(await vesting.getDrawingPower(accounts[1]))).to.be.equal(parseInt(ether("10000")));

            //Check if the beneficiary can withdraw amount more than actually allocated.
            await vesting.withdraw(ether("20000000"), {from: accounts[1]}).should.be.rejectedWith(EVMRevert);

            await vesting.withdraw(ether("5000"), {from: accounts[1]});

            await increaseTimeTo(releaseOn + duration.days(1) + duration.minutes(1));

        expect(parseInt(await vesting.getDrawingPower(accounts[1]))).to.equal(parseInt(ether("15000")));

            await increaseTimeTo(releaseOn + duration.days(8) + duration.minutes(1));

        expect(parseInt(await vesting.getDrawingPower(accounts[1]))).to.equal(parseInt(ether("85000")));

            await increaseTimeTo(releaseOn + duration.days(10) + duration.minutes(1));

            await vesting.withdraw(ether("25000"), {from: accounts[1]});

            expect(parseInt(await vesting.getDrawingPower(accounts[1]))).to.equal(parseInt(ether("80000")));

            await increaseTimeTo(releaseOn + duration.days(11) + duration.minutes(1));

            await vesting.withdraw(ether("55000"), {from: accounts[1]});

            expect(parseInt(await vesting.getDrawingPower(accounts[1]))).to.equal(parseInt(ether("26111")));

            await vesting.withdraw(ether("55000"), {from: accounts[1]}).should.be.rejectedWith(EVMRevert);

            await increaseTimeTo(releaseOn + duration.days(12) + duration.minutes(1));

            await vesting.withdraw(ether("26112"), {from: accounts[1]}).should.be.rejectedWith(EVMRevert);
            await vesting.withdraw(ether("26111"), {from: accounts[1]});

           expect(parseInt(await vesting.getDrawingPower(accounts[1]))).to.equal(parseInt(ether("0")));
        });

    });
});