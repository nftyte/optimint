// hardhat.config.js
require("@nomiclabs/hardhat-ethers");

/** @type import('hardhat/config').HardhatUserConfig */
module.exports = {
    // networks: {
    //     hardhat: {
    //         loggingEnabled: true,
    //     },
    // },
    solidity: {
        version: "0.8.15",
        settings: {
            viaIR: true,
            optimizer: {
                enabled: true,
                runs: 200,
            },
        },
    },
};
