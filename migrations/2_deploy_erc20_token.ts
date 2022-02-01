const ERC20Custom = artifacts.require("ERC20Custom");

module.exports = (deployer) => {
  deployer.deploy(ERC20Custom, "ALPH", "Alps Token");
};
