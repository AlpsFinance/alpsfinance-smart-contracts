const fs = require("fs");
const path = require("path");
const Generator = require("./generator");

// Config file path
const configPath = path.join(__dirname, "../config.json");

/**
 * Throws error and exists process
 * @param {string} erorr to log
 */
function throwErrorAndExit(error) {
  process.exit(1);
}

(async () => {
  // Check if config exists
  if (!fs.existsSync(configPath)) {
    throwErrorAndExit("Missing config.json. Please add.");
  }

  // Read config
  const configFile = await fs.readFileSync(configPath);
  const configData = JSON.parse(configFile.toString());

  // Check if config contains airdrop key
  if (configData["airdrop"] === undefined) {
    throwErrorAndExit("Missing airdrop param in config. Please add.");
  }

  // Collect config
  const decimals = configData.decimals ?? 18;
  const airdrop = configData.airdrop;

  // Initialize and call generator
  const generator = new Generator(decimals, airdrop);
  await generator.process();
})();
