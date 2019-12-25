pragma solidity 0.5.12;

contract CarboDebtDummy {
   address owner;
   uint public txcount=0;
   
   mapping (address => Attributes) public wallet;
   mapping (uint => History) public txhistory;
   
   modifier onlyOwner () {
       require(msg.sender == owner);
       _;
   }
      modifier onlyStamper () {
       require(wallet[msg.sender].isstamper = true);
       _;
   }
   constructor() public {
       owner = msg.sender;
   }
   
   struct Attributes {
       string name;   //Text Identifier
       uint debt;      //Debt held
       uint gold;      //Gold held
       bool isstamper;   //Is stamper active?
       uint stamprate; //Rate of stamping speed
       uint minpmt;    //Minimum accepted payment
       uint laststamp;  //time of last stamping
       address senderEscrow;//Source of transfer
       string nameEscrow;   //Source name
       uint debtEscrow;      //Debt offered
       uint goldEscrow;      //Gold offered (can be positive or negative)
   }
    
    struct History {
        address txsender;
        address txreceiver;
        uint txdebt;
        uint txgold;
    }
    
    function incrementtx()internal{
        txcount += 1;
    }
    
    function addtx()internal{
        incrementtx();
        txhistory[txcount].txsender = wallet[msg.sender].senderEscrow;
        txhistory[txcount].txreceiver = msg.sender;
        txhistory[txcount].txdebt = wallet[msg.sender].debtEscrow;
        txhistory[txcount].txgold = wallet[msg.sender].goldEscrow;
    }
    
    function signUp(string memory name) public{
        wallet[msg.sender].name = name;
    }
    function stampPmtAdjust(uint minpmt) public{
        wallet[msg.sender].minpmt = minpmt;
    }
    function addDebtToSelf(uint debt) public{
        wallet[msg.sender].debt += debt;
    }
    function offerTransfer(address receiver,uint debt, uint gold) public{
        wallet[receiver].senderEscrow = msg.sender;
        wallet[receiver].nameEscrow = wallet[msg.sender].name;
        wallet[receiver].debtEscrow = debt;
        wallet[receiver].goldEscrow = gold;
    }
    function offerAccept() public{
        addtx();
        wallet[msg.sender].debt += wallet[msg.sender].debtEscrow;
        wallet[wallet[msg.sender].senderEscrow].debt -= wallet[msg.sender].debtEscrow;
        wallet[msg.sender].debtEscrow = 0;
        wallet[msg.sender].gold += wallet[msg.sender].goldEscrow;
        wallet[wallet[msg.sender].senderEscrow].gold -= wallet[msg.sender].goldEscrow;
        wallet[msg.sender].goldEscrow = 0;
        wallet[msg.sender].senderEscrow = msg.sender;
        wallet[msg.sender].nameEscrow = "";
    }
    function offerReject() public{
        wallet[msg.sender].debtEscrow = 0;
        wallet[msg.sender].goldEscrow = 0;
        wallet[msg.sender].senderEscrow = msg.sender;
        wallet[msg.sender].nameEscrow = "";
    }
    
    function stampManager(address target, bool isstamper, uint stamprate, uint minpmt) public onlyOwner(){
        wallet[target].isstamper = isstamper;
        wallet[target].stamprate = stamprate;
        wallet[target].minpmt = minpmt;
        wallet[target].laststamp = block.timestamp;
    }
    function goldUpdate()public onlyStamper(){
        uint stamps = (block.timestamp-wallet[msg.sender].laststamp)/wallet[msg.sender].stamprate;
        wallet[msg.sender].gold += stamps;
        wallet[msg.sender].debt -= stamps;
    }
}
