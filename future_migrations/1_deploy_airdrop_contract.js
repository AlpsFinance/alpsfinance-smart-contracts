const Airdrop = artifacts.require("Airdrop");
const ERC20Custom = artifacts.require("ERC20Custom");
const { root } = require("../merkle.json");
const address = require("../constant/address.json");

module.exports = async (deployer, network) => {
  // Deploy `Airdrop` contract
  const erc20Inst = await ERC20Custom.deployed();
  await deployer.deploy(Airdrop, erc20Inst.address, root);
  const airdropInst = await Airdrop.deployed();

  // Grant `Airdrop` contract MINTER role
  await erc20Inst.grantRole(
    "0x9f2df0fed2c77648de5860a4cc508cd0818c85b8b8a1ab4ceeef8d981c8956a6",
    airdropInst.address
  );

  if (address[network]) {
    const { multisig } = address[network];

    // Transfer Ownership of `Airdrop` contract
    await airdropInst.transferOwnership(multisig);
  }
};
