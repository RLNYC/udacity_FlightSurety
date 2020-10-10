pragma solidity ^0.4.25;

import "../node_modules/openzeppelin-solidity/contracts/math/SafeMath.sol";

contract FlightSuretyData {
    using SafeMath for uint256;

    /********************************************************************************************/
    /*                                       DATA VARIABLES                                     */
    /********************************************************************************************/

    address private contractOwner;                                      // Account used to deploy contract
    bool private operational = true;                                    // Blocks all state changes throughout the contract if false

    /************************ Ryan Added:*********************************************************/ 

    //data variables for airlines and MultiCalls
    address[] multiCalls = new address[](0);
    
    struct Airlines{
        bool isRegistered;
        bool isOperational;
    }

    struct Voters{
        address[] airlineVoter;
        mapping(address => bool) voteResults;
    }

    mapping(address => Airlines) airlines;
    mapping(address => Voters) voters;
    mapping(address => uint) private voteCount;
    mapping(address => uint256) private funding;

    // operational control
    mapping(address => uint256) private authorizedCaller;



    /********************************************************************************************/
    /*                                       EVENT DEFINITIONS                                  */
    /********************************************************************************************/

    event AuthorizedContract(address authContract);
    event DeAuthorizedContract(address authContract);

    /**
    * @dev Constructor
    *      The deploying account becomes contractOwner
    */
    constructor() public 
    {
        contractOwner = msg.sender;
        
        // Ryan added: initialize first airline
        airlines[msg.sender] = Airlines({
            isRegistered: true,
            isOperational: false
        }); 


    }

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
        require(operational, "Contract is currently not operational");
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

    modifier isCallerAuthorized()
    {
        require(authorizedCaller[msg.sender] == 1, "Caller is not authorized");
        _;
    }


    /********************************************************************************************/
    /*                                       UTILITY FUNCTIONS                                  */
    /********************************************************************************************/

    /**
    * @dev Get operating status of contract
    *
    * @return A bool that is the current operating status
    */      
    function isOperational() public view returns(bool) 
    {
        return operational;
    }


    /**
    * @dev Sets contract operations on/off
    *
    * When operational mode is disabled, all write transactions except for this one will fail
    */    
    function setOperatingStatus(bool mode) external
        requireContractOwner 
    {
        operational = mode;
    }

    // Ryan Added: Operational control granted to authorized App contract

    function authorizeCaller(address contractAddress) external
        requireContractOwner
    {
        authorizedCaller[contractAddress] = 1;
        emit AuthorizedContract(contractAddress);
    }

    function deauthorizeContract(address contractAddress) external
        requireContractOwner
    {
        delete authorizedCaller[contractAddress];
        emit DeAuthorizedContract(contractAddress);
    } 

    /********************************************************************************************/
    /*                                     SMART CONTRACT FUNCTIONS                             */
    /********************************************************************************************/


    // Ryan added: Functions for multiCalls

    function multiCallsLength() external 
        requireIsOperational
        isCallerAuthorized 
        returns(uint)
    {
        return multiCalls.length;
    }

    function addVoterCounter(address airline, uint count) external
        requireIsOperational
        isCallerAuthorized
    {
        voteCount[airline].add(count); 
    }

    function getVoteCounter(address account) external 
        requireIsOperational 
        isCallerAuthorized
        returns(uint)
    {
        return voteCount[account];
    }

    function resetVoteCounter(address account) external 
        requireIsOperational
        isCallerAuthorized
    {
        delete voteCount[account];
    }

    function addVoters(address account, bool vote) external
        requireIsOperational
        isCallerAuthorized
    {
        voters[account].airlineVoter.push(msg.sender);
        voters[account].voteResults[msg.sender] = vote;
    }

    function getVoter(address account) external 
        requireIsOperational
        isCallerAuthorized
        returns(address[])
    {
        address[] memory v = voters[account].airlineVoter;
        return v;
    }

    function getVoterLength(address account) external 
        requireIsOperational
        isCallerAuthorized
        returns(uint)
    {
        return voters[account].airlineVoter.length;
    }

    //Ryan added: Set and Get function for Airlines

    function getAirlineRegistrationStatus(address account) external 
        requireIsOperational
        isCallerAuthorized
        returns(bool)
    {
        return airlines[account].isRegistered;
    }

    function setAirlineOperatingStatus(address account, bool status) private
        requireIsOperational
    {
        airlines[account].isOperational = status;
    }

    function getAirlineOperatingStatus(address account) external
        requireIsOperational
        isCallerAuthorized
        returns(bool)
    {
        return airlines[account].isOperational;
    }


   /**
    * @dev Add an airline to the registration queue
    *      Can only be called from FlightSuretyApp contract
    *
    */   
    function registerAirline(address account, bool funded) external
        requireIsOperational
        isCallerAuthorized
    {
        airlines[account] = Airlines({
            isRegistered: true,           // isRegistered is always true for a registered airline
            isOperational: funded  // isOperational is only true when airline has submited 10 Ether 
        });

        multiCalls.push(account);

    }


   /**
    * @dev Buy insurance for a flight
    *
    */   
    function buy() external payable
    {

    }

    /**
     *  @dev Credits payouts to insurees
    */
    function creditInsurees() external pure
    {

    }
    

    /**
     *  @dev Transfers eligible payout funds to insuree
     *
    */
    function pay() external pure
    {

    }

   /**
    * @dev Initial funding for the insurance. Unless there are too many delayed flights
    *      resulting in insurance payouts, the contract should be self-sustaining
    *
    */   
    function fund(address account) payable public
        requireIsOperational
        isCallerAuthorized
    {
        funding[account] = msg.value;
        setAirlineOperatingStatus(account, true);
    }

    function getFundingRecord(address account) public
        requireIsOperational
        returns(uint256)
    {
        uint256 record = funding[account];
        return record;
    }




    function getFlightKey(
        address airline,
        string memory flight,
        uint256 timestamp
    )
        pure
        internal
        returns(bytes32) 
    {
        return keccak256(abi.encodePacked(airline, flight, timestamp));
    }

    /**
    * @dev Fallback function for funding smart contract.
    *
    */
    function() external payable 
    {
        fund(msg.sender);
    }


}

