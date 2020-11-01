# FlightSurety

FlightSurety is an application project for Udacity's Blockchain course.

## Install

This repository contains Smart Contract code in Solidity (using Truffle), tests (also using Truffle), dApp scaffolding (using HTML, CSS and JS) and server app scaffolding.

To install, download or clone the repo, then:

`npm install`
`truffle compile`

#### Launch Ganache with following settings.
- Number of accounts: `50`
- Ether per account: `200`

#### Migrate contract to ganache.

`truffle migrate --reset`

## Develop Client

To run truffle tests:

- `truffle test ./test/flightSurety.js`
- `truffle test ./test/oracles.js`
- `truffle test ./test/flightSuretyApp_airline.js`
- `truffle test ./test/flightSuretyApp_passenger.js`

![Passing flightSurety test](./screenshots/pass flightSurety test.png)
![Passing oracles test](./screenshots/pass oracle test.png)
![Passing airline test](./screenshots/pass pass airline test.png)
![Passing passenger test](./screenshots/pass passenger test.png)

To use the dapp:

## Launching blockchain

- start Ganache 
- run `truffle migrate --reset`

## Develop Server
- `npm run server`
    - Register oracels, airlines, and flight
    - Listen to fetch flight status request and respond by passing on a randomly generated status code for a flight

## Start dapp server:

`npm run dapp`

To view dapp:

`http://localhost:8000`

## Dapp image

![alt_text](./screenshots/dapp UI.png "UI")

## Deploy

To build dapp for prod:
`npm run dapp:prod`

Deploy the contents of the ./dapp folder


## Resources

* [How does Ethereum work anyway?](https://medium.com/@preethikasireddy/how-does-ethereum-work-anyway-22d1df506369)
* [BIP39 Mnemonic Generator](https://iancoleman.io/bip39/)
* [Truffle Framework](http://truffleframework.com/)
* [Ganache Local Blockchain](http://truffleframework.com/ganache/)
* [Remix Solidity IDE](https://remix.ethereum.org/)
* [Solidity Language Reference](http://solidity.readthedocs.io/en/v0.4.24/)
* [Ethereum Blockchain Explorer](https://etherscan.io/)
* [Web3Js Reference](https://github.com/ethereum/wiki/wiki/JavaScript-API)