const ERC20Custom = artifacts.require("ERC20Custom");
const expect = require("chai").expect;
const truffleAssert = require("truffle-assertions");

contract("ERC20Custom", (accounts) => {
  const name = "Example Token";
  const symbol = "EXMP";
  const initialCap = "5000000000000000000000000000";

  beforeEach(async () => {
    this.erc20Custom = await ERC20Custom.new(name, symbol, initialCap, {
      from: accounts[0],
    });
  });

  /**
   * Testing basic token features:
   * - should have the right name and symbol
   * - should have the right initial cap
   * - should be minting new tokens
   */
  describe("should have basic ERC20 features", () => {
    it("should have the right name and symbol", async () => {
      expect(await this.erc20Custom.name()).to.equal(name);
      expect(await this.erc20Custom.symbol()).to.equal(symbol);
    });

    it("should have the right initial cap", async () => {
      expect(parseInt(await this.erc20Custom.cap())).to.equal(5e27);
    });

    it("should be minting new tokens", async () => {
      const amount = web3.utils.toBN("1");

      // Expect in the beginning to have balance 0
      expect(
        (await this.erc20Custom.balanceOf(accounts[1])).toString()
      ).to.equal("0");
      await this.erc20Custom.mint(accounts[1], amount);
      // Expect to have 1 token after mint
      expect(
        (await this.erc20Custom.balanceOf(accounts[1])).toString()
      ).to.equal(amount.toString());
    });
  });

  /**
   * Testing token cap supply:
   * - Should enable set new cap supply by the admin
   * - Should disable set new cap supply by non-admins
   * - Should disable set new cap supply with 0 value
   * - Should enable increase cap supply by the admin
   * - Should disable increase cap supply by non-admins
   * - Should disable increase cap supply with 0 value
   * - Should enable decrease cap supply by the admin
   * - Should disable decrease cap supply by non-admins
   * - Should disable decrease cap supply with 0 value
   * - Should disable decrease cap supply more than the difference between cap supply and minted supply
   */
  describe("Should have token cap supply features", () => {
    it("Should enable set new cap supply by the admin", async () => {
      // Set new cap supply to 200 billion
      await this.erc20Custom.setCap(
        web3.utils.toBN("200000000000000000000000000000"),
        { from: accounts[0] }
      );

      expect(parseInt(await this.erc20Custom.cap())).to.equal(2e29);
    });

    it("Should disable set new cap supply by non-admins", async () => {
      await truffleAssert.reverts(
        // Set new supply to 200 billion
        this.erc20Custom.setCap(
          web3.utils.toBN("200000000000000000000000000000"),
          {
            from: accounts[1],
          }
        ),
        `AccessControl: account ${accounts[1].toLowerCase()} is missing role 0x0000000000000000000000000000000000000000000000000000000000000000`
      );
    });

    it("Should disable set new cap supply with 0 value", async () => {
      truffleAssert.reverts(
        // Set new supply to 200 billion
        this.erc20Custom.setCap(0, {
          from: accounts[0],
        }),
        "ERC20Custom: New cap set to be lower than or equal to total supply!"
      );
    });

    it("Should enable increase cap supply by the admin", async () => {
      // increase the cap supply by 20 billion
      await this.erc20Custom.increaseCap(
        web3.utils.toBN("5000000000000000000000000000"),
        {
          from: accounts[0],
        }
      );

      expect(parseInt(await this.erc20Custom.cap())).to.equal(1e28);
    });

    it("Should disable increase cap supply by non-admins", async () => {
      // increase the cap supply by 20 billion
      truffleAssert.reverts(
        this.erc20Custom.increaseCap(
          web3.utils.toBN("20000000000000000000000000000"),
          {
            from: accounts[1],
          }
        ),
        `AccessControl: account ${accounts[1].toLowerCase()} is missing role 0x0000000000000000000000000000000000000000000000000000000000000000`
      );
    });

    it("Should disable increase cap supply with 0 value", async () => {
      truffleAssert.reverts(
        this.erc20Custom.increaseCap(0, {
          from: accounts[0],
        }),
        "ERC20Custom: Increase Cap value has non-valid 0 value!"
      );
    });

    it("Should enable decrease cap supply by the admin", async () => {
      // increase the cap supply by 10 billion
      // this is required because 20 billion has been minted and the cap supply is 20 billion
      // if not, revert error will appear
      await this.erc20Custom.increaseCap(
        web3.utils.toBN("10000000000000000000000000000"),
        {
          from: accounts[0],
        }
      );

      // decrease the cap supply by 10 billion
      await this.erc20Custom.decreaseCap(
        web3.utils.toBN("10000000000000000000000000000"),
        {
          from: accounts[0],
        }
      );

      expect(parseInt(await this.erc20Custom.cap())).to.equal(5e27);
    });

    it("Should disable decrease cap supply by non-admin", async () => {
      // increase the cap supply by 10 billion
      // this is required because 20 billion has been minted and the cap supply is 20 billion
      // if not, revert error will appear
      await this.erc20Custom.increaseCap(
        web3.utils.toBN("10000000000000000000000000000"),
        {
          from: accounts[0],
        }
      );

      // decrease the cap supply by 10 billion
      truffleAssert.reverts(
        this.erc20Custom.decreaseCap(
          web3.utils.toBN("10000000000000000000000000000"),
          {
            from: accounts[1],
          }
        ),
        `AccessControl: account ${accounts[1].toLowerCase()} is missing role 0x0000000000000000000000000000000000000000000000000000000000000000`
      );
    });

    it("Should disable decrease cap supply with 0 value", async () => {
      // increase the cap supply by 10 billion
      // this is required because 20 billion has been minted and the cap supply is 20 billion
      // if not, revert error will appear
      await this.erc20Custom.increaseCap(
        web3.utils.toBN("10000000000000000000000000000"),
        {
          from: accounts[0],
        }
      );

      truffleAssert.reverts(
        this.erc20Custom.decreaseCap(0, {
          from: accounts[0],
        }),
        "ERC20Custom: Decrease Cap value has non-valid value!"
      );
    });

    it("Should disable decrease cap supply more than the difference between cap supply and minted supply", async () => {
      // Since 20 billion has been minted and the cap supply is 20 billion, the difference between them is 0
      // Therefore, it shall revert as the cap supply can't be decreased (without deviating from the total minted supply)
      truffleAssert.reverts(
        this.erc20Custom.decreaseCap(
          web3.utils.toBN("10000000000000000000000000000"),
          {
            from: accounts[0],
          }
        ),
        "ERC20Custom: Decrease Cap value has non-valid value!"
      );
    });
  });

  /**
   * Testing Access Control features:
   * - should be able to grant roles to new address
   * - should be able to revoke roles from existing member
   */
  describe("should be able to manage access control correctly", () => {
    it("should be able to grant roles to new address", async () => {
      const mintAmount = "1000000000000000000";

      // Grant the address MINTER role
      await this.erc20Custom.grantRole(
        "0x9f2df0fed2c77648de5860a4cc508cd0818c85b8b8a1ab4ceeef8d981c8956a6",
        accounts[1],
        { from: accounts[0] }
      );

      await this.erc20Custom.mint(accounts[2], mintAmount, {
        from: accounts[1],
      });

      expect(
        parseInt(await this.erc20Custom.balanceOf(accounts[2])).toString()
      ).to.equal(mintAmount);
    });

    it("should be able to revoke roles from existing member", async () => {
      const mintAmount = "1000000000000000000";

      // Revoke the address MINTER role
      await this.erc20Custom.revokeRole(
        "0x9f2df0fed2c77648de5860a4cc508cd0818c85b8b8a1ab4ceeef8d981c8956a6",
        accounts[0],
        { from: accounts[0] }
      );

      await truffleAssert.reverts(
        this.erc20Custom.mint(accounts[1], mintAmount, {
          from: accounts[0],
        }),
        `AccessControl: account ${accounts[0].toLowerCase()} is missing role 0x9f2df0fed2c77648de5860a4cc508cd0818c85b8b8a1ab4ceeef8d981c8956a6`
      );
    });
  });
});
