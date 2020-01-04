pragma solidity ^0.5.12;
import "./MultiSigWalletFactory.sol";
contract CarboDebtDummy {
  address owner;
  address public factory_addr;
  uint public accountCount; //number of accounts
  uint public stamperCount; //number of stampers
  uint public totalDebt;   //metric for system debt this can be negative
  uint public totalStamperDebt; //metric for stamper debt this can be non-negative
  uint public totalGold;   //metric for system gold
  uint public totalStamperGold; //metric for stamper gold
  mapping (address => Attributes) public wallet;
   

  //mapping (address => EscrowWallet) public escrow;
  // mapping wallet addresses to external escrow contract (MultiSigWallet)
  mapping(address => mapping(address => address payable)) public escrow;

  mapping (address => StampData) public stampRegister;
  mapping (uint => address) accountIndex;  //So we can cycle through accounts easily
  mapping (uint => address) stamperIndex;  //So we can cycle through stampers easily
  
  modifier onlyOwner () {    //added some security
      require(msg.sender == owner);
      _;
  }
     modifier onlyStamper () {  //added some security
      require(stampRegister[msg.sender].isstamper == true, "Address not approved as stamper");
      _;
  }
    modifier onlyMember () {  //added some security
      require(wallet[msg.sender].registered == true, "You are not registered");
      _;
  }
    modifier onlyEscrow(address _sender, address _receiver) {  //added some security
      require(escroWallet(_sender, _receiver) == msg.sender, "Can only call from Escrow contract");
      _;
  }
  modifier escrowExists(address _sender, address _receiver){
    require(escroWallet(_sender, _receiver)!=address(0), "No esrow wallet");
    _;  
  }
  constructor(address factory) public {
     owner = msg.sender;
     factory_addr = factory;
     totalGold = 0;
     totalDebt = 0;
     totalStamperGold = 0;
     totalStamperDebt = 0;
  }
  
  
  struct Attributes {  //basic wallet, minimum attributes
      bool registered; //Valid account?
      string name;   //Text Identifier
      int debt;      //Debt held
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
    
  function signUp(string memory name) public{
      accountCount++;
      accountIndex[accountCount]=msg.sender;
      wallet[msg.sender].name = name;
      wallet[msg.sender].registered = true;

  }

  function escroWallet(address _sender, address _receiver) 
    public 
    view
    //onlyMember() 
    returns (address payable _escrow){
      if(escrow[_sender ][_receiver]!=address(0)){
        _escrow = escrow[_sender][_receiver];
      }else{
        _escrow = escrow[_receiver][_sender];
      }
  }

  function createEscrow(address _receiver) 
    public
    returns(address payable _escrow){
    uint _required = 2;
    address[] memory _owners = new address[](2);
    _owners[0]= msg.sender;
    _owners[1]=_receiver;
    if(escrow[msg.sender][_receiver]==address(0)){
      if(escrow[_receiver][msg.sender]==address(0)){
        _escrow = MultiSigWalletFactory(factory_addr).create(_owners, _required);
        escrow[msg.sender][_receiver] = _escrow;
      }
    }
  }

  function stampPmtAdjust(uint minpmt) public onlyStamper(){
      stampRegister[msg.sender].minpmt = minpmt;
  }
  function addDebtToSelf(uint debt) public onlyMember(){
    require(debt>0);
    wallet[msg.sender].debt += int(debt);
    totalDebt += debt;
    if(stampRegister[msg.sender].isstamper == true){
      totalStamperDebt += debt;
    }
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
  
  function offerTransferDebt(address _receiver, uint _debt) 
    public
    view 
    onlyMember()
    escrowExists(msg.sender,_receiver)
    returns(bytes memory _data){ 
    _data = abi.encodeWithSignature("offerAcceptDebt(address,address,uint)", msg.sender, _receiver, _debt);
  }

  function offerAcceptDebt(address _sender, address _receiver, uint debt) 
    external 
    onlyEscrow(_sender,_receiver)
    {
      wallet[_sender].debt += int(debt);
      wallet[_receiver].debt -= int(debt);

      //do we need to update/store these???
      if(stampRegister[_sender].isstamper == true){
        totalStamperDebt -= debt;
      }else if(stampRegister[_receiver].isstamper == true){
        totalStamperDebt += debt;
      }

      /*escrow[msg.sender].debtEscrow = 0;
      wallet[msg.sender].gold += escrow[msg.sender].goldEscrow;
      wallet[escrow[msg.sender].senderEscrow].gold -= escrow[msg.sender].goldEscrow;
      escrow[msg.sender].goldEscrow = 0;
      escrow[msg.sender].senderEscrow = msg.sender;
      escrow[msg.sender].nameEscrow = "";*/
  }
  /*
   dont need this for debt transfer
  function offerReject() public onlyMember(){
      escrow[msg.sender].debtEscrow = 0;
      escrow[msg.sender].goldEscrow = 0;
      escrow[msg.sender].senderEscrow = msg.sender;
      escrow[msg.sender].nameEscrow = "";
  }
  */
  
  function stampManager(address target, bool isstamper, uint stamprate, uint minpmt) public onlyOwner(){
    stamperCount++;
    stamperIndex[stamperCount]=target;
    stampRegister[target].isstamper = isstamper;
    stampRegister[target].stamprate = stamprate;
    stampRegister[target].minpmt = minpmt;
    stampRegister[target].laststamp = block.timestamp;
  }
  function goldUpdate() public onlyStamper(){
    uint stamps = (block.timestamp-stampRegister[msg.sender].laststamp)/stampRegister[msg.sender].stamprate;
    wallet[msg.sender].debt -= int(stamps); 
    wallet[msg.sender].gold += stamps; 
    // do we need to store these values these
    // or only read them?
    totalGold += stamps;
    totalStamperGold += stamps;
  }

  function sumTokens() external view returns(uint, uint, uint, uint) {  //Generates general metrics for the system and stamper coin levels, might be pretty inefficient
    // this is too cumbersome, just update totalDeb totalGold, etc... every time a relevant transaciton is sumitted/confirmed
    // or use this just to view current state 
    // do we need to store these values as part of execturale (not view/pure) contract logic
    uint totalDebtx = 0;
    uint totalGoldx = 0;
    uint totalStamperDebtx = 0;
    uint totalStamperGoldx = 0;
    for(uint i=0;i<=accountCount;i++)
      {
      totalDebtx += uint(wallet[accountIndex[i]].debt);
      totalGoldx += wallet[accountIndex[i]].gold;
      }
    for(uint i=0;i<=stamperCount;i++)
      {
      totalStamperDebtx += uint(wallet[stamperIndex[i]].debt);
      totalStamperGoldx += wallet[stamperIndex[i]].gold;
      }
    return (totalDebtx,totalGoldx,totalStamperDebtx,totalStamperGoldx);
  }
}
