var HDWalletProvider = require("truffle-hdwallet-provider");
var mnemonic = "put person oblige identify october artist also acquire all mail hold address";

module.exports = {
  // networks: {
  //   development: {
  //     provider: function() {
  //       return new HDWalletProvider(mnemonic, "http://127.0.0.1:7545/", 0, 50);
  //     },
  //     network_id: '*',
  //     gas: 9999999
  //   }
  // },
  networks: {
    development: {
      host: "127.0.0.1",     // Localhost
      port: 7545,            // Standard Ganache UI port
      network_id: "*", 
      gas: 9999999
    }
  },
  compilers: {
    solc: {
      version: "^0.4.24"
    }
  }
};