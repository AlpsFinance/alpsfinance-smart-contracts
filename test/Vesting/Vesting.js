   
const Vesting = artifacts.require('./VestingBase.sol');
const BigNumber = require('bignumber.js');
const EVMRevert = require('./helpers/EVMRevert').EVMRevert;
const ether = require('./helpers/ether').ether;
const increaseTime = require('./helpers/increaseTime');
const duration = increaseTime.duration;
const MockToken = artifacts.require('./StandardTokenMock.sol');
const expect = require("chai").expect;

require('chai')
  .use(require('chai-as-promised'))
  .should();

  contract('Vesting: Funding', function(accounts) {
    describe('Ruleset for Funding and Withdrawing Funds', () => {
        let vestingCoinMock;
        let vesting;

        beforeEach(async () => {
            const minimumVestingPeriod = duration.days(181);
            const withdrawalCap = ether("10000");//18 decimal places
            const withdrawalFrequency = 1;//Weekly

           vestingCoinMock = await MockToken.new();
                    
            vesting = await Vesting.new(minimumVestingPeriod, withdrawalCap, vestingCoinMock.address, withdrawalFrequency );
        });

        it('must not allow non admins to fund the vesting.', async () => {
            ///Transfer some tokens to a non admin.
            vestingCoinMock.transfer(accounts[1], ether("100000000"));

            await vestingCoinMock.approve(vesting.address, ether("50000000"), { from: accounts[1] });
            await vesting.fund({from: accounts[1]}).should.be.rejectedWith(EVMRevert);
        });

        it('must allow administrators to fund the vesting with correct parameters.', async () => {

            const amount = web3.utils.toBN(ether("50000000"));
            const amount1 = web3.utils.toBN(ether("100000000"));
            
            await vestingCoinMock.approve(vesting.address, ether("50000000"));
            await vesting.fund();

            await vestingCoinMock.approve(vesting.address, ether("50000000"));
            
            await vesting.fund({from: accounts[0]});
        });

        it('must not allow non admins to remove funds from the vesting.', async () => {
            await vestingCoinMock.approve(vesting.address, ether("50000000"));
            await vesting.fund();

            await vesting.removeFunds(ether("20000000"), {from: accounts[1]}).should.be.rejectedWith(EVMRevert);
        });

        it('must allow admins to remove funds from the vesting schedule.', async () => {
            await vestingCoinMock.approve(vesting.address, ether("50000000"));
            await vesting.fund({from: accounts[0]});

            
            const withdrawnAmount = ether("20000000");

           

            await vesting.removeFunds(withdrawnAmount,{from: accounts[0]} );
        
        });
    });
});