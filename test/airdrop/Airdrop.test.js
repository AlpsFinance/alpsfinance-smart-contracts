const ERC20Custom = artifacts.require("ERC20Custom");
const Airdrop = artifacts.require("Airdrop");
const truffleAssert = require("truffle-assertions");
const { decimals, airdrop } = require("../../config.json");
const { ethers } = require("ethers");
const keccak256 = require("keccak256");
const { MerkleTree } = require("merkletreejs");
const expect = require("chai").expect;

contract("Airdrop", (accounts) => {
  const name = "Example Token";
  const symbol = "EXMP";
  const initialCap = "5000000000000000000000000000";
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
    this.erc20Custom = await ERC20Custom.new(name, symbol, initialCap, {
      from: accounts[0],
    });
    this.airdrop = await Airdrop.new(
      this.erc20Custom.address,
      merkleTree.getHexRoot(),
      {
        from: accounts[0],
      }
    );
    // Granting Role for Airdrop contract to be a minter
    await this.erc20Custom.grantRole(
      "0x9f2df0fed2c77648de5860a4cc508cd0818c85b8b8a1ab4ceeef8d981c8956a6",
      this.airdrop.address,
      {
        from: accounts[0],
      }
    );
  });

  describe("should have basic airdrop features", () => {
    accounts.forEach((account) => {
      const amount = airdrop[account];
      // Check if an account has claim, then test the claim function
      // Otherwise, check whether any revert exists.
      it(
        amount
          ? `should allow ${account} that has claim to claim token`
          : `should disallow ${account} that has no claim to claim any token`,
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

          if (amount) {
            await this.airdrop.claim(numTokens, proof, { from: account });
            // Still get error here
            expect(
              parseInt(await this.erc20Custom.balanceOf(account)).toString()
            ).to.equal(numTokens);
          } else {
            await truffleAssert.reverts(
              this.airdrop.claim(numTokens, proof, { from: account }),
              "Airdrop: Address has no Airdrop claim!"
            );
          }
        }
      );
    });

    it("should disallow user that has already claimed their token", async () => {
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

      // #1 Successful Claim
      await this.airdrop.claim(numTokens, proof, { from: accounts[0] });

      // #2 Failed Claim
      await truffleAssert.reverts(
        this.airdrop.claim(numTokens, proof, { from: accounts[0] }),
        "Airdrop: Airdrop has been claimed!"
      );
    });

    it("should disallow user from claiming 0 tokens", async () => {
      const amount = 0;
      const formattedAddress = ethers.utils.getAddress(accounts[2]);
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

      await truffleAssert.reverts(
        this.airdrop.claim(numTokens, proof, { from: accounts[2] }),
        "Airdrop: Amount cannot be 0!"
      );
    });
  });

  describe("should have admin access to implement changes", () => {
    it("should allow changes to new merkle root", async () => {
      const newMerkleRoot =
        "0x9f2df0fed2c77648de5860a4cc508cd0818c85b8b8a1ab4ceeef8d981c8956a6";
      await this.airdrop.setMerkleRoot(newMerkleRoot, { from: accounts[0] });

      expect(await this.airdrop.getMerkleRoot({ from: accounts[0] })).to.equal(
        newMerkleRoot
      );
    });

    it("should disallow changes for 0 value merkle root", async () => {
      // await truffleAssert.reverts(
      //   this.airdrop.setMerkleRoot(
      //     "0x0000000000000000000000000000000000000000000000000000000000000000",
      //     { from: accounts[0] }
      //   ),
      //   "Airdrop: Invalid new merkle root value!"
      // );
    });

    it("should disallow changes for the same existing merkle root", async () => {
      // await truffleAssert.reverts(
      //   this.airdrop.setMerkleRoot(merkleTree.getHexRoot(), {
      //     from: accounts[0],
      //   }),
      //   "Airdrop: Invalid new merkle root value!"
      // );
    });

    it("should disallow changes on merkle root for non-admin", async () => {});
  });
});
