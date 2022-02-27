/**
 * @description This function is used for testing time-dependent smart contracts
 *
 * @param {number} seconds - Number of seconds we would like to time travel
 * @returns
 */
const timeTravel = async (seconds) => {
  return new Promise((resolve) => {
    web3.currentProvider.send(
      {
        jsonrpc: "2.0",
        method: "evm_increaseTime",
        params: [seconds],
        id: new Date().getTime(),
      },
      () => {
        // second call within the callback
        web3.currentProvider.send(
          {
            jsonrpc: "2.0",
            method: "evm_mine",
            params: [],
            id: new Date().getTime(),
          },
          () => {
            // need to resolve the Promise in the second callback
            resolve();
          }
        );
      }
    );
  });
};

module.exports = timeTravel;
