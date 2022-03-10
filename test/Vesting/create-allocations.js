const Vesting = artifacts.require('./VestingBase.sol');
const EVMRevert = require('./helpers/EVMRevert').EVMRevert;
const ether = require('./helpers/ether').ether;
const increaseTime = require('./helpers/increaseTime');
const duration = increaseTime.duration;
const MockToken = artifacts.require('./StandardTokenMock.sol');
const expect = require("chai").expect;

require('chai')
  .use(require('chai-as-promised'))
  
  .should();

  contract('Vesting: Create Vesting', function(accounts) {
    describe('Ruleset for Creating Vesting Allocations', () => {
        let vestingCoinMock;
        let vestingSchedule;

        beforeEach(async () => {
            const minimumVestingPeriod = duration.days(181);
            const withdrawalCap = ether("10000");//18 decimal places
            const withdrawalFrequency = 1;//Weekly

            vestingCoinMock = await MockToken.new();
                    
            vesting = await Vesting.new(minimumVestingPeriod, withdrawalCap, vestingCoinMock.address, withdrawalFrequency );

            await vestingCoinMock.approve(vesting.address, ether("50000000"));
            await vesting.fund();
        });

        it('must allow admins to create vesting allocations.', async () => {
            let earliestWithdrawalDate = (await vesting.earliestWithdrawalDate()).toNumber();
            let releaseOn = earliestWithdrawalDate + duration.minutes(1);
            let totalVested = parseInt("4999995");

            await vesting.createAllocation(accounts[1], 'John Doe 1', web3.utils.toBN("111111"), releaseOn);
            await vesting.createAllocation(accounts[2], 'John Doe 2', web3.utils.toBN("222222"), releaseOn);
            await vesting.createAllocation(accounts[3], 'John Doe 3',  web3.utils.toBN("333333"), releaseOn);
            await vesting.createAllocation(accounts[4], 'John Doe 4',  web3.utils.toBN("444444"), releaseOn);
            await vesting.createAllocation(accounts[5], 'John Doe 5',  web3.utils.toBN("555555"), releaseOn);
            await vesting.createAllocation(accounts[6], 'John Doe 6', web3.utils.toBN("666666"), releaseOn);
            await vesting.createAllocation(accounts[7], 'John Doe 7', web3.utils.toBN("777777"), releaseOn);
            await vesting.createAllocation(accounts[8], 'John Doe 8', web3.utils.toBN("888888"), releaseOn);
            await vesting.createAllocation(accounts[9], 'John Doe 9',  web3.utils.toBN("999999"), releaseOn);
            
            expect(parseInt(await vesting.totalVested())).to.equal(totalVested);
        });

        it('must correctly create vesting allocations.', async () => {
            let earliestWithdrawalDate = (await vesting.earliestWithdrawalDate()).toNumber();
            let releaseOn = earliestWithdrawalDate + duration.minutes(1);

            await vesting.createAllocation(accounts[1], 'John Doe', parseInt("111111"), releaseOn);
            
            
            expect(parseInt(await vesting.totalVested())).to.equal(parseInt("111111"));

            let allocation = await vesting.getAllocation(accounts[1]);
            
            assert(allocation[1].toString() == "John Doe");
            assert(allocation[2].toNumber() == releaseOn);
            expect(allocation[3].toString()).to.equal(("111111").toString());//allocation
            expect(allocation[4].toString()).to.equal(("111111").toString());//closing balance
            expect(allocation[5].toString()).to.equal(("0").toString());//withdrawn
            assert(allocation[6].toNumber() == 0);//last withdrawn on
            assert(allocation[7] == false);//deleted
        });

        it('must not allow non admins to create vesting allocation.', async () => {
            let earliestWithdrawalDate = (await vesting.earliestWithdrawalDate()).toNumber();
            let releaseOn = earliestWithdrawalDate + duration.minutes(1);

            await vesting.createAllocation(accounts[3], 'John Doe', ether("250000"), releaseOn, {from: accounts[2]}).should.be.rejectedWith(EVMRevert);
        });

        it('must not allow overwrite of existing vesting allocation.', async () => {
            let earliestWithdrawalDate = (await vesting.earliestWithdrawalDate()).toNumber();
            let releaseOn = earliestWithdrawalDate + duration.minutes(1);

            await vesting.createAllocation(accounts[3], 'John Doe', ether("250000"), releaseOn);
            await vesting.createAllocation(accounts[3], 'John Doe', ether("250000"), releaseOn).should.be.rejectedWith(EVMRevert);
        });

        it('must not allow creating vesting allocation which can be released before the earliest withdrawal date.', async () => {
            let earliestWithdrawalDate = (await vesting.earliestWithdrawalDate()).toNumber();
            let releaseOn = earliestWithdrawalDate - duration.minutes(1);

            await vesting.createAllocation(accounts[3], 'John Doe', ether("250000"), releaseOn).should.be.rejectedWith(EVMRevert);
        });

        it('must not allow creating vesting allocation which exceeds the maximum cap (token balance of the contract).', async () => {
            let earliestWithdrawalDate = (await vesting.earliestWithdrawalDate()).toNumber();
            let releaseOn = earliestWithdrawalDate + duration.minutes(1);

            await vesting.createAllocation(accounts[3], 'John Doe', ether("50000001"), releaseOn).should.be.rejectedWith(EVMRevert);

            await vesting.createAllocation(accounts[3], 'John Doe', ether("20000000"), releaseOn);
            await vesting.createAllocation(accounts[4], 'John Doe', ether("30000000"), releaseOn);
            await vesting.createAllocation(accounts[5], 'John Doe', ether("1"), releaseOn).should.be.rejectedWith(EVMRevert);

            await vestingCoinMock.approve(vesting.address, ether("50000000"));
            await vesting.fund();

            await vesting.createAllocation(accounts[6], 'John Doe', ether("30000000"), releaseOn);
            await vesting.createAllocation(accounts[7], 'John Doe', ether("20000001"), releaseOn).should.be.rejectedWith(EVMRevert);
        });
    });
});