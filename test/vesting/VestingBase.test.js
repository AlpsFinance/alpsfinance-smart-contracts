const Vesting = artifacts.require("./VestingBase.sol");
const MockToken = artifacts.require("./ERC20TokenMock.sol");
const EVMRevert = require("../../utils/EVMRevert").EVMRevert;
const ether = require("../../utils/ether").ether;
const BigNumber = require("bignumber.js");
const keccak256 = require("keccak256");
const { ethers } = require("ethers");
const { decimals, airdrop } = require("../../config.json");
const { MerkleTree } = require("merkletreejs");
const truffleAssert = require("truffle-assertions");

require("chai")
  .use(require("chai-as-promised"))
  .use(require("chai-bignumber")(BigNumber))
  .should();

contract("VestingBase", function (accounts) {
  let vestingCoinMock;
  let vesting;
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

  beforeEach(async () => {
    vestingCoinMock = await MockToken.new();
    vesting = await Vesting.new(vestingCoinMock.address);
    await vestingCoinMock.transfer(vesting.address, ether("50000000"));
  });

  describe("Constructor", () => {
    it("must construct properly with correct parameters.", async () => {
      assert((await vesting.vestingCoin()) == vestingCoinMock.address);
    });
  });

  describe("Ruleset for Funding and Withdrawing Funds", () => {
    it("must not allow non admins to remove funds from the vesting.", async () => {
      await vesting
        .removeFunds(ether("20000000"), { from: accounts[1] })
        .should.be.rejectedWith(EVMRevert);
    });

    it("must allow admins to remove funds from the vesting.", async () => {
      const withdrawnAmount = ether("20000000");
      await vesting.removeFunds(withdrawnAmount, { from: accounts[0] });
    });
  });

  describe("Ruleset for Vesting Allocations", async () => {
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

          let round = parseInt("1");

          await vesting.setMerkleRoot(merkleTree.getHexRoot(), round);
          //Check if the beneficiary can withdraw amount more than actually allocated.
          await vesting
            .withdraw(ether("20000000"), proof, round, { from: account })
            .should.be.rejectedWith(EVMRevert);

          if (amount) {
            await vesting.withdraw(numTokens, proof, round, {
              from: account,
            });
          } else {
            await truffleAssert.reverts(
              vesting.withdraw(numTokens, proof, round, { from: account }),
              "VestingBase: Address has no Vesting allocation!"
            );
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
      // Generate  proof
      const proof = merkleTree.getHexProof(leaf);

      let round = parseInt("1");

      await vesting.setMerkleRoot(merkleTree.getHexRoot(), round);

      // #1 Successful Withdraw
      await vesting.withdraw(numTokens, proof, round, {
        from: accounts[0],
      });
      // #2 Failed Withdraw
      await truffleAssert.reverts(
        vesting.withdraw(numTokens, proof, round, {
          from: accounts[0],
        }),
        "VestingBase: Vesting has been claimed!"
      );
    });
  });
});
