pragma solidity ^0.4.25;

// It's important to avoid vulnerabilities due to numeric overflow bugs
// OpenZeppelin's SafeMath library, when used correctly, protects agains such bugs
// More info: https://www.nccgroup.trust/us/about-us/newsroom-and-events/blog/2018/november/smart-contract-insecurity-bad-arithmetic/

import "../node_modules/openzeppelin-solidity/contracts/math/SafeMath.sol";

/************************************************** */
/* FlightSurety Smart Contract                      */
/************************************************** */
contract FlightSuretyApp {
    using SafeMath for uint256; // Allow SafeMath functions to be called for all uint256 types (similar to "prototype" in Javascript)

    /********************************************************************************************/
    /*                                       DATA VARIABLES                                     */
    /********************************************************************************************/

    // Flight status codes
    uint8 private constant STATUS_CODE_UNKNOWN = 0;
    uint8 private constant STATUS_CODE_ON_TIME = 10;
    uint8 private constant STATUS_CODE_LATE_AIRLINE = 20;
    uint8 private constant STATUS_CODE_LATE_WEATHER = 30;
    uint8 private constant STATUS_CODE_LATE_TECHNICAL = 40;
    uint8 private constant STATUS_CODE_LATE_OTHER = 50;

    address private contractOwner;          // Account used to deploy contract
    uint8 threshold = 4;                    // Ryan added: threshold for MultiCalls 
    FlightSuretyData flightSuretyData;      // Ryan added: Instance of Data Contract


    struct Flight {
        bool isRegistered;
        uint8 statusCode;
        uint256 updatedTimestamp;        
        address airline;
    }

    mapping(bytes32 => Flight) private flights;
    mapping(address => bool) private voted;                            // bool indicator on whether airline registration is being voted on



    /********************************************************************************************/
    /*                                       EVENT DEFINITIONS                                  */
    /********************************************************************************************/

    event RegisterAirline(address account);
    event voteAirlineRegistrationRequest(address account);

    event airlineSubmitFunding(address account, uint amount);
    

 
    /********************************************************************************************/
    /*                                       FUNCTION MODIFIERS                                 */
    /********************************************************************************************/

    // Modifiers help avoid duplication of code. They are typically used to validate something
    // before a function is allowed to be executed.

    /**
    * @dev Modifier that requires the "operational" boolean variable to be "true"
    *      This is used on all state changing functions to pause the contract in 
    *      the event there is an issue that needs to be fixed
    */
    modifier requireIsOperational() 
    {
         // Modify to call data contract's status
        require(flightSuretyData.isOperational(), "Contract is currently not operational");  
        _;  // All modifiers require an "_" which indicates where the function body will be added
    }

    /**
    * @dev Modifier that requires the "ContractOwner" account to be the function caller
    */
    modifier requireContractOwner()
    {
        require(msg.sender == contractOwner, "Caller is not contract owner");
        _;
    }

    /********************************************************************************************/
    /*                                       CONSTRUCTOR                                        */
    /********************************************************************************************/

    /**
    * @dev Contract constructor
    *
    */
    constructor(address dataContract)   // Ryan added:
        public 
    {
        contractOwner = msg.sender;
        
        // Ryan added: initialize data contract and first airline
        flightSuretyData = FlightSuretyData(dataContract);
        // flightSuretyData.registerAirline(contractOwner, false);
        // emit RegisterAirline(contractOwner);
    }

    /********************************************************************************************/
    /*                                       UTILITY FUNCTIONS                                  */
    /********************************************************************************************/

    function isOperational() public view returns(bool) 
    {
        // return true;  // Modify to call data contract's status

        // Ryan added: 
        return flightSuretyData.isOperational();
    }

    function IsAirlineRegistered(address account) public view returns(bool) 
    {
        return flightSuretyData.getAirlineRegistrationStatus(account);
    }

    function IsAirlineOperational(address account) public view returns(bool) 
    {
        return flightSuretyData.getAirlineOperatingStatus(account);
    }



    /********************************************************************************************/
    /*                                     SMART CONTRACT FUNCTIONS                             */
    /********************************************************************************************/

  
   /**
    * @dev Add an airline to the registration queue
    *
    */   
    function registerAirline(address airline) external
        requireIsOperational
        returns(bool success, uint256 votes)
    {
        require(airline != address(0), "'account' must be a valid address.");
        require(flightSuretyData.getAirlineOperatingStatus(msg.sender), "Caller airline is not operational - Need to submit 10ETH");
        require(!flightSuretyData.getAirlineRegistrationStatus(airline), "Airline is already registered");

        uint MultiCallAccounts = flightSuretyData.multiCallsLength();

        if (MultiCallAccounts < threshold){
            // Register airline directly in this case
            flightSuretyData.registerAirline(airline, false);
            emit RegisterAirline(airline);
        } else {
            if(voted[airline]){
                uint voteCount = flightSuretyData.getVoteCounter(airline);

                if(voteCount >= MultiCallAccounts.div(2)){
                    // Airline has been voted in
                    flightSuretyData.registerAirline(airline, false);

                    flightSuretyData.resetVoteCounter(airline);

                    return (success, voteCount);

                    emit RegisterAirline(airline);
                } else {
                    // Airline has been voted out
                    flightSuretyData.resetVoteCounter(airline);
                    delete voted[airline];                      // delete voted just in case the airline would be re-registered and up for a vote
                    return (!success, voteCount);
                }
            }
            else{
                return (!success, 0);
                emit voteAirlineRegistrationRequest(airline);
            }
        }
    }

    /**
    * @dev Approve registration of fifth and subsequent airlines
    *
    */

    function voteAirlineRegistration(address airline, bool airline_vote) public 
        requireIsOperational 
    {
        
        require(!flightSuretyData.getAirlineRegistrationStatus(airline),"Airline is already registered");
        require(flightSuretyData.getAirlineOperatingStatus(msg.sender),"Airline voter is not operational - Need to submit 10ETH");
        
        // Check and avoid duplicate vote for the same airline
        bool isDuplicate = false;
        // isDuplicate = flightSuretyData.getVoterStatus(msg.sender);
        uint numberOfExistingVoters = flightSuretyData.getVoterLength(airline);

        if (numberOfExistingVoters == 0){
            isDuplicate = false;
        } else {
            address[] memory ExistingVoters = flightSuretyData.getVoter(airline);

            for(uint c =0; c < numberOfExistingVoters; c++){
                if(ExistingVoters[c] == msg.sender){
                    isDuplicate = true;
                    break;
                }
            }
        }

        // Check to avoid same registered airline voting multiple times
        require(!isDuplicate, "Caller has already voted.");
        flightSuretyData.addVoters(msg.sender, airline_vote);

        if(airline_vote == true){
            flightSuretyData.addVoterCounter(airline, 1);
        }
        
        voted[airline] = true;
    }


    // Ryan added: Airline submit 10ETH fund
    function submitFunding() payable public
        requireIsOperational
    {

        // verify fund is 10 Ether
        require(msg.value >= 10 ether, "Funding should be 10ETH");

        // Make sure airline has not yet been funded
        require(!flightSuretyData.getAirlineOperatingStatus(msg.sender), "Airline is already funded");

        // Make sure airline is registered
        require(flightSuretyData.getAirlineRegistrationStatus(msg.sender),"Airline is not yet registered");

        // pass ETH to data contract
        flightSuretyData.fund.value(msg.value)(msg.sender);

        emit airlineSubmitFunding(msg.sender, msg.value);

    }





   /**
    * @dev Register a future flight for insuring.
    *
    */  
    function registerFlight()
                                external
                                pure
    {

    }
    
   /**
    * @dev Called after oracle has updated flight status
    *
    */  
    function processFlightStatus
                                (
                                    address airline,
                                    string memory flight,
                                    uint256 timestamp,
                                    uint8 statusCode
                                )
                                internal
                                pure
    {
    }


    // Generate a request for oracles to fetch flight information
    function fetchFlightStatus
                        (
                            address airline,
                            string flight,
                            uint256 timestamp                            
                        )
                        external
    {
        uint8 index = getRandomIndex(msg.sender);

        // Generate a unique key for storing the request
        bytes32 key = keccak256(abi.encodePacked(index, airline, flight, timestamp));
        oracleResponses[key] = ResponseInfo({
                                                requester: msg.sender,
                                                isOpen: true
                                            });

        emit OracleRequest(index, airline, flight, timestamp);
    } 


// region ORACLE MANAGEMENT

    // Incremented to add pseudo-randomness at various points
    uint8 private nonce = 0;    

    // Fee to be paid when registering oracle
    uint256 public constant REGISTRATION_FEE = 1 ether;

    // Number of oracles that must respond for valid status
    uint256 private constant MIN_RESPONSES = 3;


    struct Oracle {
        bool isRegistered;
        uint8[3] indexes;        
    }

    // Track all registered oracles
    mapping(address => Oracle) private oracles;

    // Model for responses from oracles
    struct ResponseInfo {
        address requester;                              // Account that requested status
        bool isOpen;                                    // If open, oracle responses are accepted
        mapping(uint8 => address[]) responses;          // Mapping key is the status code reported
                                                        // This lets us group responses and identify
                                                        // the response that majority of the oracles
    }

    // Track all oracle responses
    // Key = hash(index, flight, timestamp)
    mapping(bytes32 => ResponseInfo) private oracleResponses;

    // Event fired each time an oracle submits a response
    event FlightStatusInfo(address airline, string flight, uint256 timestamp, uint8 status);

    event OracleReport(address airline, string flight, uint256 timestamp, uint8 status);

    // Event fired when flight status request is submitted
    // Oracles track this and if they have a matching index
    // they fetch data and submit a response
    event OracleRequest(uint8 index, address airline, string flight, uint256 timestamp);


    // Register an oracle with the contract
    function registerOracle
                            (
                            )
                            external
                            payable
    {
        // Require registration fee
        require(msg.value >= REGISTRATION_FEE, "Registration fee is required");

        uint8[3] memory indexes = generateIndexes(msg.sender);

        oracles[msg.sender] = Oracle({
                                        isRegistered: true,
                                        indexes: indexes
                                    });
    }

    function getMyIndexes
                            (
                            )
                            view
                            external
                            returns(uint8[3])
    {
        require(oracles[msg.sender].isRegistered, "Not registered as an oracle");

        return oracles[msg.sender].indexes;
    }




    // Called by oracle when a response is available to an outstanding request
    // For the response to be accepted, there must be a pending request that is open
    // and matches one of the three Indexes randomly assigned to the oracle at the
    // time of registration (i.e. uninvited oracles are not welcome)
    function submitOracleResponse
                        (
                            uint8 index,
                            address airline,
                            string flight,
                            uint256 timestamp,
                            uint8 statusCode
                        )
                        external
    {
        require((oracles[msg.sender].indexes[0] == index) || (oracles[msg.sender].indexes[1] == index) || (oracles[msg.sender].indexes[2] == index), "Index does not match oracle request");


        bytes32 key = keccak256(abi.encodePacked(index, airline, flight, timestamp)); 
        require(oracleResponses[key].isOpen, "Flight or timestamp do not match oracle request");

        oracleResponses[key].responses[statusCode].push(msg.sender);

        // Information isn't considered verified until at least MIN_RESPONSES
        // oracles respond with the *** same *** information
        emit OracleReport(airline, flight, timestamp, statusCode);
        if (oracleResponses[key].responses[statusCode].length >= MIN_RESPONSES) {

            emit FlightStatusInfo(airline, flight, timestamp, statusCode);

            // Handle flight status as appropriate
            processFlightStatus(airline, flight, timestamp, statusCode);
        }
    }


    function getFlightKey
                        (
                            address airline,
                            string flight,
                            uint256 timestamp
                        )
                        pure
                        internal
                        returns(bytes32) 
    {
        return keccak256(abi.encodePacked(airline, flight, timestamp));
    }

    // Returns array of three non-duplicating integers from 0-9
    function generateIndexes
                            (                       
                                address account         
                            )
                            internal
                            returns(uint8[3])
    {
        uint8[3] memory indexes;
        indexes[0] = getRandomIndex(account);
        
        indexes[1] = indexes[0];
        while(indexes[1] == indexes[0]) {
            indexes[1] = getRandomIndex(account);
        }

        indexes[2] = indexes[1];
        while((indexes[2] == indexes[0]) || (indexes[2] == indexes[1])) {
            indexes[2] = getRandomIndex(account);
        }

        return indexes;
    }

    // Returns array of three non-duplicating integers from 0-9
    function getRandomIndex
                            (
                                address account
                            )
                            internal
                            returns (uint8)
    {
        uint8 maxValue = 10;

        // Pseudo random number...the incrementing nonce adds variation
        uint8 random = uint8(uint256(keccak256(abi.encodePacked(blockhash(block.number - nonce++), account))) % maxValue);

        if (nonce > 250) {
            nonce = 0;  // Can only fetch blockhashes for last 256 blocks so we adapt
        }

        return random;
    }

// endregion

}

// Ryan added: Creat interfaces
contract FlightSuretyData {
    function isOperational() public view returns(bool);

    // Airlines
    function registerAirline(address account, bool funded) external;
    function getAirlineOperatingStatus(address account) external returns(bool);
    // function setAirlineOperatingStatus(address account, bool status) external;
    function getAirlineRegistrationStatus(address account) external returns(bool);

    // fund
    function fund(address account) public payable;

    // MultiCall
    function multiCallsLength() external returns(uint);
    function addVoterCounter(address airline, uint count) external;
    function getVoteCounter(address account) external  returns(uint);
    function setVoteCounter(address account, uint vote) external;
    function resetVoteCounter(address account) external;
    function addVoters(address voter, bool vote) external;
    function getVoter(address account) external returns(address[]);
    function getVoterLength(address account) external returns(uint);

}
