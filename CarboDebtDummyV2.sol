pragma solidity 0.5.12;

contract CarboDebtDummy {
   address owner;
   uint public accountCount; //number of accounts
   uint public stamperCount; //number of stampers
   uint public totalDebt;   //metric for system debt
   uint public totalGold;   //metric for system gold
   uint public totalStamperDebt; //metric for stamper debt
   uint public totalStamperGold; //metric for stamper gold
   mapping (address => Attributes) public wallet;
   mapping (address => EscrowWallet) public escrow;
   mapping (address => StampData) public stampRegister;
   mapping (uint => address) accountIndex;  //So we can cycle through accounts easily
   mapping (uint => address) stamperIndex;  //So we can cycle through stampers easily
   
   modifier onlyOwner () {    //added some security
       require(msg.sender == owner);
       _;
   }
      modifier onlyStamper () {  //added some security
       require(stampRegister[msg.sender].isstamper == true);
       _;
   }
     modifier onlyMember () {  //added some security
       require(wallet[msg.sender].registered == true);
       _;
   }
   constructor() public {
       owner = msg.sender;
   }
   
   struct Attributes {  //basic wallet, minimum attributes
       bool registered; //Valid account?
       string name;   //Text Identifier
       uint debt;      //Debt held
       uint gold;      //Gold held
   }
    //split escrow into separate struct, so we can cut it out later easily
    struct EscrowWallet {
       address senderEscrow;//Source of transfer
       string nameEscrow;   //Source name
       uint debtEscrow;      //Debt offered
       uint goldEscrow;      //Gold offered (can be positive or negative)
   }
    //Split Stamper management into a separate struct
    struct StampData {
       bool isstamper;   //Is stamper active?
       uint stamprate; //Rate of stamping speed
       uint minpmt;    //Minimum accepted payment
       uint laststamp;  //time of last stamping
   } 
    
//Txhistory removed.
    
    function signUp(string memory name) public{
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
    // TO-DO create external multisig debt escrow that accepts/rejects debt rebalancing in the CarboDebt wallet
    // 1. Avoid storing escrow data in the core wallet to avoid overloading wallet (tx fees)
    // 2. Create separate escrow TX for each debt transfer in a separate contract. Reference only escrow contract addresses in wallet.
    // Why? there is a security issue
    // Imagine a wallet has received a send debt request, and they want to accept
    // A troll sends new offerTransfer to wallet in an earlier or the same block where the wallet owner sends thwe offerAccept msg
    // The previous escrow is overwritten, but wallet owner does not realize
    // Transmission of the offerAccept results in the trolls unwanted debt being accepted, 
    // Proposal
    // Each escrow agreement should be organized in a separate multisig contract agreement
    // Consider desigining a multisig contract that can be pre-signed by both parties off-chain, and submitted once on-chain by one party
    // No need to record accpet/request in different blocks (this increases tx cost/latency)
    function offerTransfer(address receiver,uint debt, uint gold) public  onlyMember(){
        if((debt<=wallet[msg.sender].debt)&&(gold<=wallet[msg.sender].gold)){  //cant send what you dont have
        escrow[receiver].senderEscrow = msg.sender;
        escrow[receiver].nameEscrow = wallet[msg.sender].name;
        escrow[receiver].debtEscrow = debt;
        escrow[receiver].goldEscrow = gold;
        }
    }
    function offerAccept() public onlyMember(){
        wallet[msg.sender].debt += escrow[msg.sender].debtEscrow;
        wallet[escrow[msg.sender].senderEscrow].debt -= escrow[msg.sender].debtEscrow;
        escrow[msg.sender].debtEscrow = 0;
        wallet[msg.sender].gold += escrow[msg.sender].goldEscrow;
        wallet[escrow[msg.sender].senderEscrow].gold -= escrow[msg.sender].goldEscrow;
        escrow[msg.sender].goldEscrow = 0;
        escrow[msg.sender].senderEscrow = msg.sender;
        escrow[msg.sender].nameEscrow = "";
    }
    function offerReject() public onlyMember(){
        escrow[msg.sender].debtEscrow = 0;
        escrow[msg.sender].goldEscrow = 0;
        escrow[msg.sender].senderEscrow = msg.sender;
        escrow[msg.sender].nameEscrow = "";
    }
    
    function stampManager(address target, bool isstamper, uint stamprate, uint minpmt) public onlyOwner(){
        stamperCount++;
        stamperIndex[stamperCount]=target;
        stampRegister[target].isstamper = isstamper;
        stampRegister[target].stamprate = stamprate;
        stampRegister[target].minpmt = minpmt;
        stampRegister[target].laststamp = block.timestamp;
        sumTokens();
    }
    function goldUpdate()public onlyStamper(){
        uint stamps = (block.timestamp-stampRegister[msg.sender].laststamp)/stampRegister[msg.sender].stamprate;
        wallet[msg.sender].gold += stamps;
        if(wallet[msg.sender].debt>=stamps){  Keeps debt from going negative/wraparound to huge number
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
        totalStamperDebt += wallet[stamperIndex[i]].debt;
        totalStamperGold += wallet[stamperIndex[i]].gold;
        }
}
}
