const Vesting = artifacts.require('./VestingBase.sol');
const MockToken = artifacts.require('./ERC20TokenMock.sol');
const EVMRevert = require('../../utils/EVMRevert').EVMRevert;
const ether = require('../../utils/ether').ether;  
const { increaseTimeTo, duration} = require('../../utils/increaseTime');
const BigNumber = require('bignumber.js');
const keccak256 = require("keccak256");
const { ethers } = require("ethers");
const { decimals, airdrop } = require("../../config.json");
const { MerkleTree } = require("merkletreejs");
const truffleAssert = require("truffle-assertions");



require('chai')
  .use(require('chai-as-promised'))
  .use(require('chai-bignumber')(BigNumber))
  .should();

  contract('Vesting: Withdrawal', function(accounts) {
    const merkleTree = new MerkleTree(
        // Generate leafs
        Object.entries(airdrop).map(([address, tokens]) =>
          Buffer.from(
            // Hash in appropriate Merkle format
            ethers.utils
              .solidityKeccak256(
                ["address", "uint256"],
                [
                  ethers.utils.getAddress(address),
                  ethers.utils.parseUnits(tokens.toString(), decimals).toString(),
                ]
              )
              .slice(2),
            "hex"
          )
        ),
        keccak256,
        { sortPairs: true }
      );

      let vesting; 

    


    describe('Ruleset for Vesting Allocations',async () => {

        let vestingCoinMock;

        beforeEach(async () => {

            const minimumVestingPeriod = duration.days(181);
            const withdrawalCap = ether("10000");//18 decimal places
            const withdrawalFrequency = 0;//Daily

            vestingCoinMock = await MockToken.new();
            this.vesting = await Vesting.new(minimumVestingPeriod,
                withdrawalCap, vestingCoinMock.address, 
                withdrawalFrequency,
                   {
               from: accounts[0],
             });  

             
             await vestingCoinMock.approve(this.vesting.address, ether("50000000"));
             await this.vesting.fund();
                            
        });
       
      


        accounts.forEach((account) => {
            const amount = airdrop[account];
            // Check if an account has claim, then test the withdrwal function
            // Otherwise, check whether any revert exists.
            it(
              amount
                ? `should allow ${account} has claim to withdraw vesting`
                : `should disallow ${account} has no claim to withdraw vesting`,
              async () => {
                const formattedAddress = ethers.utils.getAddress(account);
                // Get tokens for address
                const numTokens = ethers.utils
                  .parseUnits((amount ?? 100).toString(), decimals)
                  .toString();
      
                // Generate hashed leaf from address
                const leaf = Buffer.from(
                  // Hash in appropriate Merkle format
                  ethers.utils
                    .solidityKeccak256(
                      ["address", "uint256"],
                      [formattedAddress, numTokens]
                    )
                    .slice(2),
                  "hex"
                );
                // Generate airdrop proof
                const proof = merkleTree.getHexProof(leaf);
              


            let earliestWithdrawalDate = (await this.vesting.earliestWithdrawalDate()).toNumber();
            let releaseOn = earliestWithdrawalDate + duration.minutes(1);
            let totalVested = numTokens;
            let round = parseInt('1')


            await this.vesting.createAllocation(account, 'John Doe 1',numTokens, releaseOn);
            expect(parseInt(await this.vesting.totalVested())).to.equal(parseInt(totalVested));      
            await increaseTimeTo(releaseOn + duration.minutes(1));

            await this.vesting.setMerkleRoot( merkleTree.getHexRoot());
             //Check if the beneficiary can withdraw amount more than actually allocated.
             await this.vesting.withdraw(ether("20000000"), proof, round, {from: account}).should.be.rejectedWith(EVMRevert);

                if (amount) {
                  await this.vesting.withdraw(numTokens, proof, round, { from: account });
                 
                } else {
                 
                  await  this.vesting.withdraw(numTokens, proof, round, { from: account }).should.be.rejectedWith(EVMRevert);
                   
              
                }
              }
            );
          });


    it("should disallow user that has already claimed their vesting", async () => {
      const amount = airdrop[accounts[0]];
      const formattedAddress = ethers.utils.getAddress(accounts[0]);
      // Get tokens for address
      const numTokens = ethers.utils
        .parseUnits(amount.toString(), decimals)
        .toString();

      // Generate hashed leaf from address
      const leaf = Buffer.from(
        // Hash in appropriate Merkle format
        ethers.utils
          .solidityKeccak256(
            ["address", "uint256"],
            [formattedAddress, numTokens]
          )
          .slice(2),
        "hex"
      );
      // Generate airdrop proof
      const proof = merkleTree.getHexProof(leaf);
      let earliestWithdrawalDate = (await this.vesting.earliestWithdrawalDate()).toNumber();
      let releaseOn = earliestWithdrawalDate + duration.minutes(1);
      let round = parseInt('1')

     

      await this.vesting.createAllocation(accounts[0], 'John Doe 1',numTokens, releaseOn); 
      await this.vesting.setMerkleRoot( merkleTree.getHexRoot());
      await increaseTimeTo(releaseOn + duration.minutes(1));
     
      // #1 Successful Claim
      await this.vesting.withdraw(numTokens, proof, round, { from: accounts[0] });
       // #2 Failed Claim
        await this.vesting.withdraw(numTokens, proof, round, { from: accounts[0]}).should.be.rejectedWith(EVMRevert);
       
   

     
    });
      

    

      
    });
}); 