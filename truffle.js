module.exports = {
  networks: {
    development: {
      host: "127.0.0.1",
      port: 8545, // ganache-cli
      //port: 7545, // ganache ui
      network_id: "*" // Match any network id
    }
  },
  coverage: {
    host: 'localhost',
    network_id: '*',
    port: 8545,         // <-- If you change this, also set the port option in .solcover.js.
    gas:0xfffffffffff, // <-- Use this high gas value
    gasPrice: 0x01     // <-- Use this low gas price
  },
  solc: {
    optimizer: {
      enabled: true,
      runs: 200
    }
  }
};