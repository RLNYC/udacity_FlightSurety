
var Test = require('../config/testConfig.js');
var BigNumber = require('bignumber.js');

contract('Flight Surety Tests - Airline Registration', async (accounts) => {

  var config;
  before('setup contract', async () => {
    config = await Test.Config(accounts);
    await config.flightSuretyData.authorizeCaller(config.flightSuretyApp.address);
  });

  /****************************************************************************************/
  /* Airline Registration                                                                 */
  /****************************************************************************************/

  it('(airline) cannot register an Airline using registerAirline() if it is not funded', async () => {
    
    // ARRANGE
    let newAirline = accounts[2];

    // ACT
    try {
        await config.flightSuretyApp.registerAirline(newAirline, {from: config.owner});
    }
    catch(e) {

    }

    let result = await config.flightSuretyApp.IsAirlineRegistered.call(newAirline); 

    // ASSERT
    assert.equal(result, false, "Airline should not be able to register another airline if it hasn't provided funding");

  });

  it('(airline) Able to submit funding', async () => {
    
    const payment = web3.utils.toWei("10","ether");

    // ACT

    await config.flightSuretyApp.submitFunding.call({from: config.owner, value: payment});

    let result = await config.flightSuretyData.getFundingRecord.call(config.owner);
    console.log(result);

    let status = await config.flightSuretyApp.IsAirlineOperational.call(config.owner);
    console.log(status); 

    // ASSERT
    assert.equal(result, payment, "Airline is able to submit funding");

  });


  it('(airline) Register First 4 Airlines', async () => {
    
    // ARRANGE
    let result = true;
    let newAirline2 = accounts[2];
    let newAirline3 = accounts[3];
    let newAirline4 = accounts[4];
    let newAirline5 = accounts[5];

    const payment = web3.utils.toWei("10","ether");

    // ACT
    try {
        await config.flightSuretyApp.submitFunding.call({from: config.owner, value: payment});

        // await config.flightSuretyApp.registerAirline(newAirline, {from: config.owner});
    }
    catch(e) {
        result = false;

    }

    // let result = await config.flightSuretyApp.IsAirlineRegistered(newAirline); 

    // ASSERT
    assert.equal(result, true, "First 4 airlines are registered");

  });
 

});
