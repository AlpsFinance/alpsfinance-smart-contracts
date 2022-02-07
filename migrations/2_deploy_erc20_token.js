const ERC20Custom = artifacts.require("ERC20Custom");

module.exports = async (deployer) => {
  await deployer.deploy(ERC20Custom, "ALPS Token", "ALPS");
};
