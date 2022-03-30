const ERC20Custom = artifacts.require("ERC20Custom");
const address = require("../constant/address.json");

module.exports = async (deployer, network) => {
  await deployer.deploy(
    ERC20Custom,
    "ALPS Token",
    "ALPS",
    web3.utils.toWei((5 * 10 ** 9).toString())
  );
  const erc20Inst = await ERC20Custom.deployed();

  if (address[network]) {
    const { multisig } = address[network];

    // Pre-mint Tokens to Multisig wallet
    await erc20Inst.mint(multisig, "2500000000000000000000000000");

    // Grant `DEFAULT ADMIN` role
    await erc20Inst.grantRole(
      "0x0000000000000000000000000000000000000000000000000000000000000000",
      multisig
    );

    // Grant `PAUSER` role
    await erc20Inst.grantRole(
      "0x65d7a28e3265b37a6474929f336521b332c1681b933f6cb9f3376673440d862a",
      multisig
    );

    // Grant `MINTER` role
    await erc20Inst.grantRole(
      "0x9f2df0fed2c77648de5860a4cc508cd0818c85b8b8a1ab4ceeef8d981c8956a6",
      multisig
    );
  }
};
