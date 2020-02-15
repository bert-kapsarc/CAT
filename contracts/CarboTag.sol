pragma solidity ^0.5.12;
import "./MultiSigWalletFactory.sol";
import "./Stamper.sol";

library CarboTagLib {

}

contract oldCarboTag {
  struct Attributes {  //basic wallet, minimum attributes
    //bool registered;
    string name;   //Text Identifier
    int carbon;      //Carbon held
    uint gold;      //Gold held
  }
  uint public totalCarbon;   //metric for system carbon this can be negative
  uint public totalGold;   //metric for system gold
  address public factory_addr;
  mapping (address => Attributes) public wallet;
  mapping (address => bool) public registered; //Valid account?)
  mapping (uint => address) public userIndex;  //So we can cycle through accounts easily
  uint public userCount; //number of accounts
}

contract CarboTag {
    /*
     *  Events
    */
  event EscrowFunded (address indexed sender, uint256 indexed value);

  address public owner;
  mapping (address => bool) public governor;
  address public factory_addr;
  uint public totalCarbon;   //metric for system carbon this can be negative
  uint public totalGold;   //metric for system gold
  uint public totalStamperCarbon; //metric for stamper carbon this can be non-negative
  uint public totalStamperGold; //metric for stamper gold
  
  struct Attributes {  //basic wallet, minimum attributes
    string name;   //Text Identifier
    int carbon;      //Carbon held
    uint gold;      //Gold held
  }
  mapping (address => Attributes) public wallet;
  mapping (address => bool) public registered; //Valid account?)
  //mapping a given wallet address pair to escrow address
  mapping(address => mapping(address => address payable)) internal EscrowAddr;
  mapping (address => address[]) public escrowList; // mapping user address to array of active escrows
  function getEscrowList(address _address)
      public
      view
      returns (address[] memory) 
  {
      return escrowList[_address];
  }
  //escrow addresses associated with each wallet
    // Note this is additional data stored on the network
    // To help users keep track of the escrow accounts associated with their wallet
    // and check for exisitng transactions in each escrow
    // to minimze data storage we could store this data externally...

  // TO-DO only store escrow tx data into the correspoinding multisig wallet 
  // within the encodeWithSignature data. Requires developing decoding routine 
  // that will read fn/parameters stored in the external multisig wallet (true escrow)
  // This will make the carbon contract lighter
  // For now laziliy store escrow tx data within the carbon contract
  // rather than decoding the parameters using assembly (complex)... 
  struct EscrowTxAttr {
    
    uint multisig_tx_id; //transactionId from multisig wallet
    bool exists;
    // Below attributes are stored as encoded bytes data in the external multisig wallet
    address issuer;
    //address receiver;
    int carbon; // signed integer carbon transfer, (+) for send carbon to receiver, (-) to request carbon transfer to sender
    int gold; // signed integer gold transfer, (+) for send gold to receiver, (-) to request gold transfer to sender
  }

  // mapping escrow address and transaction ID to escrow transaction attributes
  mapping(address => mapping(uint => EscrowTxAttr)) public escrowTx;
  mapping(address => uint) public escrowTxCount;

  // This maps the account holders address to their stamper contract address
  mapping (address => address) public stamperRegistry;

  // directory of all registered wallets. This will increae the weight of the contract
  mapping (uint => address) public userIndex;  //So we can cycle through accounts easily
  mapping (uint => address) public stamperIndex;  //So we can cycle through stampers easily
  uint public userCount; //number of accounts
  uint public stamperCount; //number of stampers

  modifier onlyOwner () {  //added some security
    require(msg.sender == owner, 'ONly the contract owner can do that');
    _;
  }
  modifier onlyGovernor () {    //added some governance
    require(governor[msg.sender] == true);
    _;
  }
  modifier onlyMember () {  //added some security
    require(registered[msg.sender] == true, "You are not registered");
    _;
  }
  modifier onlyEscrow(address _sender, address _receiver) {  //added some security
    require(findEscrowAddr(_sender, _receiver) == msg.sender, "Can only call from Escrow contract");
    _;
  }
  modifier onlyStamperContract(address _stamper) {  //added some security
    require(stamperRegistry[_stamper] == msg.sender, "Can only call from Stamper Contract");
    _;
  }
  modifier escrowExists(address _sender, address _receiver){
    require(findEscrowAddr(_sender, _receiver)!=address(0x0), "No escrow wallet");
    _;  
  }
  modifier escrowTxExists(address _sender, address _receiver, uint _txID){
    require(findEscrowAddr(_sender, _receiver)!=address(0x0)
      && escrowTx[findEscrowAddr(_sender, _receiver)][_txID].exists, 
      "Escro TX does not exist");
    _;  
  }
  modifier escrowDoesNotExist(address _sender, address _receiver){
    require(findEscrowAddr(_sender, _receiver)==address(0x0), "Escrow already created");
    _;  
  }
  modifier stamperDoesNotExsit(address _target){
    require(stamperRegistry[_target]==address(0x0), "Stamper already registered.");
    _;
  }
  // out boolean if sender transfering gold out (+), or sender request to receive gold (-) 
  modifier sufficientGold(address _sender, address _receiver, int _gold){
    require(
      (_gold>0 && uint(_gold)<=wallet[_sender].gold) //cant send gold unless you have it,
      || (_gold<=0)// && uint(_gold)<=wallet[_receiver].gold) // but can ask
      // The second condition prevents asking for gold that exceeds balance from 
      // requester (_receivers) wallet. We do not really need this?
      , "Insufficient gold for this transfer");  
    _;
  }


  constructor(address factory, address payable oldAddr) public {
    owner = msg.sender;
    governor[msg.sender]=true;
    factory_addr = factory;
    oldCarboTag oldContract = oldCarboTag(oldAddr);
    userCount = oldContract.userCount();
    //userCount = accounts.length;
    totalCarbon = oldContract.totalCarbon();  //old name for carbon...
    totalGold = oldContract.totalGold();
    // reset stamper accounts in the new contract
    // stamperCount = oldContract.stamperCount;
    // totalStamperCarbon; //metric for stamper carbon this can be non-negative
    // totalStamperGold; //metric for stamper gold
    address _address;
    //for (uint i=0; i<accounts.length; i++) {
    //  _address = accounts[i];
    for(uint i=0;i<userCount;i++) {
      _address = oldContract.userIndex(i);
      userIndex[i]=_address;
      (string memory _name, int _carbon, uint _gold) = oldContract.wallet(_address);
      
      wallet[_address].name = _name; 
      wallet[_address].carbon = _carbon;
      wallet[_address].gold = _gold; 
      registered[_address] = oldContract.registered(_address);
      /*
      TODO Carry over escrow from old contract addrr?
      this is tricky because the MultiSigWallet escrrow include the old contract address 
      as an owner to allow CarboTag to trigger the escrow
      This will be easier when the escrow is not linked to this contract
      such that createTransaction() fn is not longer user to create escrow txs
      Instead txs will be created by directly calling MultiSigWallet (TODO)

      address _escrowList = getEscrowList(_address) ;
      for(uint j=0;j<_escrowList.length;j++) {
        
        (address[] _owners)=MultiSigWallet(_escrowList[j]).getOwners();
        for(uint k=0;k<_owners.length;k++) {
          if((_owners[k] != oldAddr || _owners[k]!=_address) && findEscrowAddr(_address, _escrowList[j])!=address(0x0))
          {
            EscrowAddr[_address][_owners[k]] = _escrowList[j];
          }
        }
      } 
      */  
    }
  }

  function() 
    external payable 
  {

  }
    
  function addGovernor(address _target)  
    public 
    onlyOwner()
  {
    governor[_target]=true;
  }

  function signUp(string memory name) public{
    require(registered[msg.sender]!= true, "ALREADY REGISTERED");
    userIndex[userCount++]=msg.sender;
    wallet[msg.sender].name = name;
    registered[msg.sender] = true;
  }

  function findEscrowAddr(address _sender, address _receiver)  
    view
    public
    returns (address payable _escrow)
  {
    if(EscrowAddr[_sender ][_receiver]!=address(0x0)){
      _escrow = EscrowAddr[_sender][_receiver];
    }else{
      _escrow = EscrowAddr[_receiver][_sender];
    }
  }

  function createEscrow(address _receiver)//, uint _value) 
    public
    onlyMember()
    escrowDoesNotExist(msg.sender,_receiver)
    returns(address payable _escrowAddr){
    // Escrow has 3 participants and all must sign
    // include this contract as onwer of ESCROW
    // confirms that this cpnytract is party in the escrow (can submit TXs)
    uint _required = 3;
    address[] memory _owners = new address[](3);
    _owners[0]= msg.sender;
    _owners[1]=_receiver;
    _owners[2]= address(this);

    _escrowAddr = address(MultiSigWalletFactory(factory_addr).create(_owners, _required));
    EscrowAddr[msg.sender][_receiver] = _escrowAddr;
    escrowList[msg.sender].push(_escrowAddr);
    escrowList[_receiver].push(_escrowAddr);
  }



  function addCarbon(uint carbon) public onlyMember(){
    require(carbon>0, 'Can only add positive carbon');
    wallet[msg.sender].carbon += int(carbon);
    totalCarbon += carbon;
    if(stamperRegistry[msg.sender]!=address(0x0)){
      totalStamperCarbon += carbon;
    }
  }
  // receiver: counterparty to the offer
  // carbon: signed integer carbon transfer, (+) for send gold to receiver, (-) to request gold transfer to sender
  // gold: signed integer gold transfer, (+) for send gold to receiver, (-) to request gold transfer to sender
  function createTransaction(address _receiver,int _carbon, int _gold)
    public 
    payable
    onlyMember()
    escrowExists(msg.sender, _receiver)
    sufficientGold(msg.sender,_receiver, _gold) // must have sufficient gold to submit transfer
  {
    if(_gold>0){
      wallet[msg.sender].gold -= uint(_gold); //remove (+) gold transfer from sender wallet
    }
    if(_carbon==0 && _gold>0){
      // send the gold now if it is not combined with a debt transfer request 
      wallet[_receiver].gold += uint(_gold);
    }else{  
      // Store transaction in Escrow
      address payable _escrowAddr = findEscrowAddr(msg.sender, _receiver);
      uint _txID;
      for (uint i=0; i<=escrowTxCount[_escrowAddr]; i++){
        if(!escrowTx[_escrowAddr][i].exists){
          //if escrow tx does not exist set index as txID
          _txID = i;
          break;
        }
      }
      if (_txID == escrowTxCount[_escrowAddr]){
        // increment the TX count if necessary
        escrowTxCount[_escrowAddr]++;
      } 
      
      EscrowTxAttr storage _tx=escrowTx[_escrowAddr][_txID];
      _tx.exists = true;
      _tx.issuer = msg.sender;
      //_tx.receiver = _receiver;
      _tx.gold = _gold; // store gold transfer for reference before approval by receiver
      _tx.carbon = _carbon; // store carbon transfer for reference before approval by receiver
      // encoded function for offerAccept to be triggered by multisig escrow wallet
      bytes memory _data = abi.encodeWithSignature("acceptTransaction(address,address,uint256,int256,int256)",msg.sender,_receiver,_txID,_carbon,_gold); 
      //address(this).call(_data);
      uint _value = msg.value;
      _tx.multisig_tx_id = MultiSigWallet(_escrowAddr).submitTransaction(address(this),_value, _data);
    }
  }


  //TO-DO add
  function acceptTransaction(address _sender, address _receiver, uint _txID, int _carbon, int _gold) 
    external 
    payable
    onlyEscrow(_sender,_receiver)
    escrowTxExists(_sender,_receiver,_txID)
  {
    address _escrowAddr = findEscrowAddr(_sender,_receiver);
    EscrowTxAttr storage _tx = escrowTx[_escrowAddr][_txID];
    // secruity cehck
    //function call should match vlalues stored in Escrow Transaction
    //if we store all data in encodedFuncitonCall we dont need this
    require(_tx.exists == true, 'This transaction has been rejected');
    require(_carbon == _tx.carbon, 'The carbon transfer values do not match');
    require(_gold == _tx.gold, 'The gold transfer values do not match');
    require(_gold>=0 || (_gold<0 && uint(_gold)<=wallet[_receiver].gold), "Not enough gold to fullfill sender's ask");

    wallet[_sender].carbon -= _carbon;
    wallet[_receiver].carbon += _carbon;
    
    if(_tx.gold>0){// if sender has added gold to escrow
      wallet[_receiver].gold += uint(_gold); //pull gold from escrow, push to receiver
    }else if(_tx.gold<0){ // if sender is requesting gold transfer
      wallet[_sender].gold += uint(_gold); //push gold to sender
      wallet[_receiver].gold -= uint(_gold); //push gold to sender
    }
    // What to do if a payment is sent to this funciton
    //send funds to _sender ??
    //_sender.call.value(msg.value)("");

    updateStamperTotals(_sender,_receiver,_gold,_carbon);

    // Delete the escrow?
    delete escrowTx[_escrowAddr][_txID];
    for (uint i=escrowTxCount[_escrowAddr]; i>0; i--)
      //update TxCount if necessary
      if(escrowTx[_escrowAddr][i].exists){
        break;
      }else{
        escrowTxCount[_escrowAddr]=i-1;
      }
  }

  function rejectTransaction(address _counterparty, uint _txID) 
    public
    onlyMember()
    escrowTxExists(msg.sender,_counterparty,_txID)
  {
    address payable _escrowAddr = findEscrowAddr(msg.sender, _counterparty);
    MultiSigWallet(_escrowAddr).revokeConfirmation(_txID);
    EscrowTxAttr storage _tx = escrowTx[_escrowAddr][_txID];
    if(_tx.gold>0){// if sender has added gold to escrow
      wallet[_tx.issuer].gold += uint(_tx.gold); //return gold in escrow to issuers
    }
    delete escrowTx[_escrowAddr][_txID];
  }
  

  function addStamper(address target, uint stamprate, uint minpmt) 
    public 
    // only contract governors can nominate stampers
    onlyGovernor()
    stamperDoesNotExsit(target)

  {
    Stamper stamper = new Stamper(target,msg.sender,stamprate,minpmt);

    stamperRegistry[target] = address(stamper);
    stamperIndex[stamperCount++]=target;
    //sumTokens();
    uint _carbon; //carbon to add to totalStamperCarbon
    if(wallet[target].carbon>0){
      _carbon = uint(wallet[target].carbon); // only pass positive carbon 
    }
    totalStamperCarbon += uint(_carbon);
    totalStamperGold += wallet[target].gold;
  }

  function updateGold(uint stamps, address stamper)
    public 
    onlyStamperContract(stamper)
  {
    // Some points to address
    // Block timestamp can be manipulated by miners within 900s
    // Make sure that this deos not distort the stamping rate within am acceptable tollerance
    // Need to set other stamp constriants (total stamps based on auditing, or other metrics)
    uint carbon;// new carbon generated by stamper if stamps exceed carbons)
    wallet[stamper].gold += stamps;
    if(wallet[stamper].carbon>int(stamps)){
      wallet[stamper].carbon -= int(stamps);
    }else{
      // Keeps stamper carbon from going negative
      // Stamper wallet can not have negative debt after stamping ...(?)
      wallet[stamper].carbon = 0;
      totalCarbon += stamps;
      // stamper creates new _carbon if it stamps more than it has carbon
      carbon = stamps - uint(wallet[stamper].carbon);
    } 

    totalGold += stamps;
    totalCarbon += carbon - stamps;
    totalStamperGold += stamps;
    totalStamperCarbon += carbon - stamps;
  }

  function updateStamperTotals(address _sender, address _receiver, int _carbon, int _gold) internal{
    //why do we need to update/store these???
    int8 _sign; // defines direction of carbon/gold movements
    bool _stamper=false;
    if(stamperRegistry[_sender]!= address(0x0)){
      _stamper = true;
      _sign = 1; // if stamper is sender values are sent out ( substract )
    }if(stamperRegistry[_receiver]!= address(0x0)){
      _stamper = !_stamper; //if both sender and receiver are stampers do nothing (no change in total gold/carbon balance)
      _sign = -1; // if stamper is receiver values are coming in (add)
    }
    // note when carbon/gold are negative these are asks by the sender and direction if flipped
    if(_stamper){
      totalStamperCarbon -= uint(_sign*_carbon);
      totalStamperGold -= uint(_sign*_gold);
    }
  }

  // Fn to get the external multisig transaciton ID for an escrow transaction 
  // created in this contract 
  function transactionData(address _escrowAddr, uint _txID)
    public
    view
    returns(uint)
  {
    return(escrowTx[_escrowAddr][_txID].multisig_tx_id);
  }
  // Function to return all existing escrow txs.
  function getTransactionIds(address _escrowAddr, uint from, uint to)
      public
      view
      returns (uint[] memory _transactionIds)
  {
      uint[] memory transactionIdsTemp = new uint[](escrowTxCount[_escrowAddr]);
      uint count = 0;
      uint i;
      
      for (i=0; i<escrowTxCount[_escrowAddr]; i++)
          if ( escrowTx[_escrowAddr][i].exists )
          {
              transactionIdsTemp[count] = i;
              count += 1;
          }
      _transactionIds = new uint[](to - from);
      for (i=from; i<to; i++)
          _transactionIds[i - from] = transactionIdsTemp[i];
  }
  
/*
  function sumTokens() external view returns(uint, uint, uint, uint) {  //Generates general metrics for the system and stamper coin levels, might be pretty inefficient
    // Commented this out as it would cost too much gas (now just a view function)
    // instead wee update totalCarbon totalGold, etc... every time a relevant transaciton is sumitted/confirmed
    uint totalCarbonx = 0;
    uint totalGoldx = 0;
    uint totalStamperCarbonx = 0;
    uint totalStamperGoldx = 0;
    for(uint i=0;i<=userCount;i++)
      {
      totalCarbonx += uint(wallet[userIndex[i]].carbon);
      totalGoldx += wallet[userIndex[i]].gold;
      }
    for(uint i=0;i<=stamperCount;i++)
      {
      totalStamperCarbonx += uint(wallet[stamperIndex[i]].carbon);
      totalStamperGoldx += wallet[stamperIndex[i]].gold;
      }
    return (totalCarbonx,totalGoldx,totalStamperCarbonx,totalStamperGoldx);
  }
*/
  function changeOwner(address _newOwner)
    onlyOwner()
    public
  {
    owner = _newOwner;
  }
  function killContract()
    onlyOwner()
    public
  {
    selfdestruct(tx.origin);
  }
}
