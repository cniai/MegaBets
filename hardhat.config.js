require("@nomicfoundation/hardhat-toolbox");

/** @type import('hardhat/config').HardhatUserConfig */
module.exports = {
  defaultNetwork: "hardhat",
  networks: {
    hardhat: {

    },
    sepolia: {
      url: "https://sepolia.infura.io/v3/2585dd5ab3464f879cb1878710739ada",
      accounts: ['e5be2f3457306c6ff3ca25cd7a01d5fd3fe6857e4e74fa529dbdeb83ebe4f71a']
    }
  },
  solidity: {
    version: "0.8.19",
    settings: {
      optimizer: {
        enabled: true,
        runs: 200
      }
    }
  },
  paths: {
    sources: "./contracts",
    tests: "./test",
    cache: "./cache",
    artifacts: "./artifacts"
  },
  mocha: {
    timeout: 40000
  }
}