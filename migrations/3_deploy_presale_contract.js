const Presale = artifacts.require("Presale");
const ERC20Custom = artifacts.require("ERC20Custom");
const PresaleDetails = require("../constant/presale.json");
const address = require("../constant/address.json");

module.exports = async (deployer, network) => {
  // Deploy `Presale` contract
  const erc20Inst = await ERC20Custom.deployed();
  await deployer.deploy(Presale, erc20Inst.address, erc20Inst.address);

  // Grant `Presale` contract MINTER role
  const presaleInst = await Presale.deployed();
  await erc20Inst.grantRole(
    "0x9f2df0fed2c77648de5860a4cc508cd0818c85b8b8a1ab4ceeef8d981c8956a6",
    presaleInst.address
  );

  /**
   * Pre-sale price Round 1 — 28th Feb. 12 noon EST — 0.000125
   * Pre-sale price Round 2 — 7th March — 12 noon EST — 0.000250
   * Pre-sale price Round 3 — 14th March — 12 noon EST — 0.00050
   */
  PresaleDetails.forEach(async (presale, index) => {
    const { startingTime, usdPrice, minimumUSDPurchase, maximumPresaleAmount } =
      presale;

    await presaleInst.setPresaleRound(
      index.toString(),
      // only deploy with real time schedule in FTM mainnet
      network === "fantom_mainnet" ? startingTime.toString() : Date.now(),
      web3.utils.toWei(usdPrice.toString()),
      web3.utils.toWei(minimumUSDPurchase.toString()),
      web3.utils.toWei(maximumPresaleAmount.toString())
    );
  });

  if (address[network]) {
    const { multisig } = address[network];

    // Transfer Ownership of `Presale` contract
    await presaleInst.transferOwnership(multisig);
  }
};
