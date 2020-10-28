import FlightSuretyApp from '../../build/contracts/FlightSuretyApp.json';
import FlightSuretyData from '../../build/contracts/FlightSuretyData.json';
import Config from './config.json';
import Web3 from 'web3';

export default class Contract {
    constructor(network, callback) {

        let config = Config[network];
        this.web3 = new Web3(new Web3.providers.HttpProvider(config.url));

        this.flightSuretyApp = new this.web3.eth.Contract(FlightSuretyApp.abi, config.appAddress);
        this.flightSuretyData = new this.web3.eth.Contract(FlightSuretyData.abi, config.dataAddress);

        this.initialize(callback);
        this.owner = null;
        this.airlines = [];
        this.passengers = [];
    }

    initialize(callback) {

        this.web3.eth.getAccounts((error, accts) => {
           
            this.owner = accts[0];
            // Ryan added: 
            // this.flightSuretyData.methods.authorizeCaller(this.flightSuretyApp._address).send({from: this.owner});
            //

            let counter = 0;
            
            while(this.airlines.length < 4) {
                this.airlines.push(accts[counter++]);
            }

            while(this.passengers.length < 5) {
                this.passengers.push(accts[counter++]);
            }

            callback();
        });


    }

    isOperational(callback) {
       let self = this;
       self.flightSuretyApp.methods
            .isOperational()
            .call({ from: self.owner}, callback);
    }


// Ryan added:

    listRegistredAirline(callback) {
        let self = this;
        self.flightSuretyApp.methods
             .ListRegistredAirline()
             .call({ from: self.owner}, callback);        
    }

    credit(callback){
        this.flightSuretyApp.methods.getAccountCredit(this.passengers[0])
                .call({ from: this.passengers[0]}, (error, result) => {
                    callback(error,  this.web3.utils.fromWei(result,'ether'));           
                });
    }

// Need to modify to listen on insuranceAmount input
    buyTicket(airline, flightNumber, timestamp, insuranceAmount, passenger, callback) {
        let self = this;
        let payload = {
            airline: airline,
            flight: flightNumber,
            timestamp: timestamp,
            // price: self.web3.utils.toWei((flight.price).toString())
            //price: self.web3.utils.toWei((Math.floor(Math.random()*10+1)/10).toString(),"ether")
            price: self.web3.utils.toWei(insuranceAmount.toString(),"ether")
        } 
      
        self.flightSuretyApp.methods
            .submitPurchase(payload.airline, payload.flight, payload.timestamp)
            .send({ from: passenger, value:payload.price}, (error, result) => {
                callback(error, payload);
                
            });
    }


    fetchFlightStatus(flight, callback) {
        let self = this;
        let payload = {
            airline: self.airlines[0],
            flight: flight,
            timestamp: Math.floor(flight.timestamp / 1000)
        } 
        self.flightSuretyApp.methods
            .fetchFlightStatus(payload.airline, payload.flight, payload.timestamp)
            .send({ from: self.owner}, (error, result) => {
                callback(error, payload);
            });
    }

    redeemCredit(passenger,callback){
        let self = this;
        self.flightSuretyApp.methods.submitWithdrawal()
                .send({ from: passenger}, (error, result) => {
                    callback(error,result);
                });
    }


}