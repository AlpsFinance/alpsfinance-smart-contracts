const Presale = artifacts.require("Presale");
const address = require("../constant/address.json");

module.exports = async (_, network) => {
  if (address[network]) {
    const { multisig } = address[network];

    const presaleInst = await Presale.deployed();

    // Transfer Ownership of `Presale` contract
    await presaleInst.transferOwnership(multisig);
  }
};
