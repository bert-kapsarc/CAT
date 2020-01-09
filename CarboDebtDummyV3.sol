pragma solidity 0.5.12;

contract CarboDebtDummy {
   address owner;
   address public newContract;
   uint public accountCount; //number of accounts
   uint public stamperCount; //number of stampers
   uint public totalDebt;   //metric for system debt
   uint public totalGold;   //metric for system gold
   uint public totalStamperDebt; //metric for stamper debt
   uint public totalStamperGold; //metric for stamper gold
   mapping (address => Attributes) public wallet;
   mapping (address => StampData) public stampRegister;
   mapping (address => Contracts) public contractRegister;
   mapping (uint => address) accountIndex;  //So we can cycle through accounts easily
   mapping (uint => address) public stamperIndex;  //So we can cycle through stampers easily
   
   modifier onlyOwner () {    //added some security
       require(msg.sender == owner, "Only contract owner can access.");
       _;
   }
      modifier onlyStamper () {  //added some security
       require(stampRegister[msg.sender].active == true, "Only stampers can access.");
       _;
   }
     modifier onlyMember () {  //added some security
       require(wallet[msg.sender].registered == true, "Only registered members can access.");
       _;
   }
     modifier notMember () {  //added some security
       require(wallet[msg.sender].registered == false, "Address already registered.");
       _;
   } 
    modifier onlyContract () {  //added some security
       require(contractRegister[msg.sender].registered == true, "Contract address not valid.");
       _;
   }
   
   constructor() public {
       owner = msg.sender;
   }
    
    struct Contracts {  //makes sure only current contracts are honored
       bool registered; //Valid account?
   }

   
   struct Attributes {  //basic wallet, minimum attributes
       bool registered; //Valid account?
       string name;   //Text Identifier
       uint debt;      //Debt held
       uint gold;      //Gold held
   }

    //Split Stamper management into a separate struct
    struct StampData {
       bool exists;   //Has registered before
       bool active;   //Is stamper active?
       uint stamprate; //Rate of stamping speed
       uint minpmt;    //Minimum accepted payment
       uint laststamp;  //time of last stamping
   } 
    
//Txhistory removed.
    
    function signUp(string memory name) public notMember(){
        accountCount++;
        accountIndex[accountCount]=msg.sender;
        wallet[msg.sender].name = name;
        wallet[msg.sender].registered = true;    
    }
    
    function stampPmtAdjust(uint minpmt) public onlyStamper(){
        stampRegister[msg.sender].minpmt = minpmt;
    }
    
    function addDebtToSelf(uint debt) public onlyMember(){
        wallet[msg.sender].debt += debt;
        sumTokens();
    }
    
    function offerTransfer(address receiver,uint debtO, uint goldO, uint goldA) public  onlyMember(){
        require(goldO<=wallet[msg.sender].gold, "Insufficient Funds");  //cant send gold unless you have it, but can ask
        wallet[msg.sender].gold -= goldO;
        newContract = address(new offerContract(msg.sender, receiver, debtO, goldO, goldA));
        contractRegister[newContract].registered = true;
        sumTokens();
    }
    
    function closeContract(bool _success, address _sender, address _receiver, uint _debtOffered, uint _goldOffered, uint _goldAsked) public onlyContract(){
    contractRegister[msg.sender].registered = false;
    if(_success && _goldAsked <= wallet[_receiver].gold){  //if contract agreed and gold asked for is still there
      if(wallet[_sender].debt<=_debtOffered){      //doesn't matter if enough debt, just make more
      wallet[_sender].debt = 0;
      }
      else{
      wallet[_sender].debt -= _debtOffered;       //pull debt
      }
      wallet[_receiver].debt += _debtOffered;     //push debt
      wallet[_receiver].gold += _goldOffered;     //pull gold from escrow, push to receiver
      wallet[_receiver].gold -= _goldAsked;       //pull gold from receiver (non escrow)
      wallet[_sender].gold += _goldAsked;         //push gold to sender
    }
    else{
        wallet[_sender].gold += _goldOffered;   //Escrow returned to sender if failed or insufficient funds from receiver
    }
    sumTokens();
    }
    
    
    function stampAdd(address target, bool active, uint stamprate, uint minpmt) public onlyOwner(){
        require(stampRegister[target].exists == false, "Stamper already registered.");
        stamperCount++;    
        stamperIndex[stamperCount]=target;
        stampRegister[target].exists = true;
        stampRegister[target].active = active;
        stampRegister[target].stamprate = stamprate;
        stampRegister[target].minpmt = minpmt;
        stampRegister[target].laststamp = block.timestamp;
        sumTokens();
    }
    function stampEdit(address target, bool active, uint stamprate) public onlyOwner(){
        require(stampRegister[target].exists == true, "Stamper not registered.");
        stampRegister[target].active = active;
        stampRegister[target].stamprate = stamprate;
        sumTokens();
    }
    function goldUpdate()public onlyStamper(){
        uint stamps = (block.timestamp-stampRegister[msg.sender].laststamp)/stampRegister[msg.sender].stamprate;
        wallet[msg.sender].gold += stamps;
        if(wallet[msg.sender].debt>=stamps){  //Keeps debt from going negative/wraparound to huge number
        wallet[msg.sender].debt -= stamps;    
        }
        else{
            wallet[msg.sender].debt =0;
        }
        sumTokens();
    }

    function sumTokens() internal{  //Generates general metrics for the system and stamper coin levels, might be pretty inefficient
        totalDebt = 0;
        totalGold = 0;
        totalStamperDebt = 0;
        totalStamperGold = 0;
        for(uint i=0;i<=accountCount;i++)
        {
        totalDebt += wallet[accountIndex[i]].debt;
        totalGold += wallet[accountIndex[i]].gold;
        }
        for(uint i=0;i<=stamperCount;i++)
        {
        if(stampRegister[stamperIndex[i]].active){
        totalStamperDebt += wallet[stamperIndex[i]].debt;
        totalStamperGold += wallet[stamperIndex[i]].gold;
        }
        }
}
}

contract offerContract {

address private maincontract;
address public party;
address public counterparty;
uint public debtOffered;
uint public goldOffered;
uint public goldAsked;

//not sure how to implement the timer, but would like to have one to revert afterwards.

mapping(address => bool) signed;

constructor(address _sender, address _receiver, uint _debtOffered, uint _goldOffered, uint _goldAsked) public {
    party = _sender;
    counterparty = _receiver;
    debtOffered = _debtOffered;
    goldOffered = _goldOffered;
    goldAsked = _goldAsked;
    maincontract = msg.sender;
}

function acceptOffer() public {
    require (msg.sender == party || msg.sender == counterparty);
    require (signed[msg.sender] == false);
    signed[msg.sender] = true;
    if(signed[party] && signed[counterparty]){
    CarboDebtDummy _home = CarboDebtDummy(maincontract);
    _home.closeContract(true,party, counterparty, debtOffered, goldOffered, goldAsked);
    selfdestruct(tx.origin);    
    }
    }
    
function rejectOffer() public {
    require (msg.sender == party || msg.sender == counterparty);
    require (signed[msg.sender] == false);
    CarboDebtDummy _home = CarboDebtDummy(maincontract);
    _home.closeContract(false, party, counterparty, debtOffered, goldOffered, goldAsked);
    selfdestruct(tx.origin);
    }
}
