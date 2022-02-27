const Presale = artifacts.require("Presale");
const ERC20Custom = artifacts.require("ERC20Custom");

module.exports = async (deployer) => {
  // Deploy `Presale` contract
  const erc20Inst = await ERC20Custom.deployed();
  await deployer.deploy(Presale, erc20Inst.address, erc20Inst.address);

  // Grant `Presale` contract MINTER role
  const presaleInst = await Presale.deployed();
  await erc20Inst.grantRole(
    "0x9f2df0fed2c77648de5860a4cc508cd0818c85b8b8a1ab4ceeef8d981c8956a6",
    presaleInst.address
  );

  await this.presale.setPresaleRound(0, 25);

  // Transfer Ownership of `Airdrop` contract
};
