const Airdrop = artifacts.require("Airdrop");
const ERC20Custom = artifacts.require("ERC20Custom");
const { root } = require("../merkle.json");

module.exports = async (deployer) => {
  const erc20Inst = await ERC20Custom.deployed();
  await deployer.deploy(Airdrop, erc20Inst.address, root);
};
