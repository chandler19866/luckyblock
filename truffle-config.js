const HDWalletProvider = require('@truffle/hdwallet-provider')
//const mnemonic = 
require('dotenv').config()
module.exports = {
  plugins: ['truffle-plugin-verify'],
  api_keys: {
    // etherscan: process.env.ETHERSCAN_API_KEY,
   // polygonscan: 'Y46DT32CWSCS6MES6FSES55NEDBX4BMSGB',
    bscscan: 'I32W81V3WK8Q1Y88A5RNTYF2VSGP4PGSGS'
  },
  networks: {
    development: {
      host: "localhost",
      port: 8545,
      network_id: "*", // Match any network id
      gas: 5000000
    },
    testnet: {
      provider: () => {
       return  new HDWalletProvider(process.env.MNEMONIC, `https://data-seed-prebsc-1-s1.binance.org:8545`)
      },
      network_id: 97,
      confirmations: 10,
      timeoutBlocks: 200,
      skipDryRun: false,
      gas: 0x7a1200,
    },
    bsc: {
      provider: () => new HDWalletProvider(process.env.MNEMONIC, `https://bsc-dataseed1.binance.org`),
      network_id: 56,
      confirmations: 10,
      timeoutBlocks: 200,
      skipDryRun: false,
      gas: 0x7a1400,
    },
    mumbai: {
      provider: () => {
        return new HDWalletProvider(process.env.MNEMONIC, `wss://ws-matic-mumbai.chainstacklabs.com`)
      },
      gas: 0x7a1200,
      network_id: 80001,
      skipDryRun: true
    },
    polygon: {
      provider: () => {
        return new HDWalletProvider(process.env.MNEMONIC, `wss://ws-matic-mainnet.chainstacklabs.com`)
      },
      gas: 0x7a1200,
      network_id: 137,
      skipDryRun: true
    }
  },
  compilers: {
    solc: {
      version: '0.8.0',
      settings: {
        optimizer: {
          enabled: true, // Default: false
          runs: 800      // Default: 200
        },
      }
    }
  }
};
