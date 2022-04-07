const VestingBase = artifacts.require("VestingBase");

module.exports = async (deployer) => {
  const erc20Inst = await ERC20Custom.deployed();
  await deployer.deploy(VestingBase, erc20Inst.address);
};
