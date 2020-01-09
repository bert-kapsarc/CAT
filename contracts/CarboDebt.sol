pragma solidity ^0.5.12;
import "./MultiSigWalletFactory.sol";
contract CarboDebt {
    /*
     *  Events
    */
  event EscrowFunded (address indexed sender, uint256 indexed value);


  address owner;
  address public factory_addr;
  uint public accountCount; //number of accounts
  uint public stamperCount; //number of stampers
  uint public totalDebt;   //metric for system debt this can be negative
  uint public totalStamperDebt; //metric for stamper debt this can be non-negative
  uint public totalGold;   //metric for system gold
  uint public totalStamperGold; //metric for stamper gold
  
  struct Attributes {  //basic wallet, minimum attributes
    bool registered; //Valid account?
    string name;   //Text Identifier
    int debt;      //Debt held
    uint gold;      //Gold held
  }
  mapping (address => Attributes) public wallet;

  // TO-DO only store escrow tx data into the correspoinding multisig wallet 
  // within the encodeWithSignature data. Requires developing decoding routine 
  // that will read fn/parameters stored in the external multisig wallet (true escrow)
  // This will make the debt contract lighter
  // For now laziliy store escrow tx data within the debt contract
  // rather than decoding the parameters using assembly (complex)... 
  struct EscrowTx {
    // this struct should be stored as encoded bytes data in a multisig wallet
    uint multisig_tx_id; //transactionId from multisig wallet
    bool exists;
    address sender;
    address receiver;
    int debt; // signed integer debt transfer, (+) for send debt to receiver, (-) to request debt transfer to sender
    int gold; // signed integer gold transfer, (+) for send gold to receiver, (-) to request gold transfer to sender
  }
  struct EscrowAttr {
    uint last_tx_id; // last_tx_id
    mapping(uint => EscrowTx) transactions;
  }

  mapping(address => mapping(address => address payable)) public findEscrowAddr;

  mapping(address => EscrowAttr) escrow;

    //Split Stamper management into a separate struct
  struct StampData {
    bool exists;   //Has registered before
    bool active;   //Is stamper active?
    uint stamprate; //Rate of stamping speed
    uint minpmt;    //Minimum accepted payment
    uint laststamp;  //time of last stamping
  }
  mapping (address => StampData) public stampRegister;
  mapping (uint => address) accountIndex;  //So we can cycle through accounts easily
  mapping (uint => address) stamperIndex;  //So we can cycle through stampers easily
  
  modifier onlyOwner () {    //added some security
      require(msg.sender == owner);
      _;
  }
  modifier onlyStamper () {  //added some security
    require(stampRegister[msg.sender].active == true, "Only stampers can access.");
    _;
  }
  
  modifier onlyMember () {  //added some security
    require(wallet[msg.sender].registered == true, "You are not registered");
    _;
  }
  modifier onlyEscrow(address _sender, address _receiver) {  //added some security
    require(escrowAddr(_sender, _receiver) == msg.sender, "Can only call from Escrow contract");
    _;
  }
  modifier escrowExists(address _sender, address _receiver){
    require(escrowAddr(_sender, _receiver)!=address(0x0), "No esrow wallet");
    _;  
  }
  modifier escrowTxExists(address _sender, address _receiver, uint _txID){
    require(escrowAddr(_sender, _receiver)!=address(0x0)
      && escrow[escrowAddr(_sender, _receiver)].transactions[_txID].exists, 
      "Escro TX does not exist");
    _;  
  }
  modifier escrowDoesNotExist(address _sender, address _receiver){
    require(escrowAddr(_sender, _receiver)==address(0x0), "Escrow already created");
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
  constructor(address factory) public {
     owner = msg.sender;
     factory_addr = factory;
  }

  function() external payable {}
    
  function signUp(string memory name) public{
      accountCount++;
      accountIndex[accountCount]=msg.sender;
      wallet[msg.sender].name = name;
      wallet[msg.sender].registered = true;

  }

  function escrowAddr(address _sender, address _receiver) 
    public 
    view
    returns (address payable _escrow){
      if(findEscrowAddr[_sender ][_receiver]!=address(0x0)){
        _escrow = findEscrowAddr[_sender][_receiver];
      }else{
        _escrow = findEscrowAddr[_receiver][_sender];
      }
  }

  function createEscrow(address _receiver)//, uint _value) 
    public
    onlyMember()
    escrowDoesNotExist(msg.sender,_receiver)
    returns(address payable _escrowAddr){
    uint _required = 2;
    address[] memory _owners = new address[](3);
    _owners[0]= msg.sender;
    _owners[1]=_receiver;
    _owners[2]= address(this);
    //uint256 _value = 2e18;
    // if escrowAdrr is blank create
    if(escrowAddr(msg.sender,_receiver)==address(0x0)){
      _escrowAddr = MultiSigWalletFactory(factory_addr).create(_owners, _required);
      // send some ether to this account
      // TODO check if there is sufficient funds
      // How to create escrow wallet with signed deposit from sender (i.e. uint _value)?
      //(bool success, ) = _escrow.call.value(_value)("");
      //if(success){emit EscrowFunded(_escrow, _value);}
      findEscrowAddr[msg.sender][_receiver] = address(_escrowAddr);
    }
  }

  function stampPmtAdjust(uint minpmt) public onlyStamper(){
      stampRegister[msg.sender].minpmt = minpmt;
  }

  function addDebtToSelf(uint debt) public onlyMember(){
    require(debt>0, 'Can only add positive debt');
    wallet[msg.sender].debt += int(debt);
    totalDebt += debt;
    if(stampRegister[msg.sender].exists == true){
      totalStamperDebt += debt;
    }
  }
  // receiver: counterparty to the offer
  // debt: signed integer debt transfer, (+) for send gold to receiver, (-) to request gold transfer to sender
  // gold: signed integer gold transfer, (+) for send gold to receiver, (-) to request gold transfer to sender
  function createTransaction(address _receiver,int _debt, int _gold)
    public 
    payable
    onlyMember()
    escrowExists(msg.sender, _receiver)
    sufficientGold(msg.sender,_receiver, _gold) // must have sufficient gold to submit transfer
  {
    bytes memory _data; // encoded function for offerAccept to be triggered by multisig escrow wallet
    address payable multisigAddr;
    // if escrow address does not exist for the msg.sender and _receiver pair create one
    //if(escrowAddr(msg.sender, _receiver)==address(0x0)){
    //  multisigAddr = address(createEscrow(_receiver));
    //}else{
    // load existing escrow attributes
      multisigAddr = escrowAddr(msg.sender, _receiver);
    //}
    EscrowAttr storage _escrow=escrow[multisigAddr];
    
    uint _txID = _escrow.last_tx_id++; //initialize next tx id

    EscrowTx storage _tx = _escrow.transactions[_txID];
    _tx.exists = true;
    _tx.sender = msg.sender;
    _tx.receiver = _receiver;
    _tx.gold = _gold; // store gold transfer for reference before approval by receiver
    _tx.debt = _debt; // store debt transfer for reference before approval by receiver
    if(_gold>0){
      wallet[msg.sender].gold -= uint(_gold); //remove (+) gold transfer from sender wallet
    }     
    //Encoded fn call used to trigger the offerAccept function
    _data = abi.encodeWithSignature("acceptTransaction(address,address,uint256,int256,int256)", msg.sender,_receiver,_txID, _debt, _gold); 
    //address(this).call(_data);

    // store transaction ID from multisig wallet for user reference (signing)
    MultiSigWallet(multisigAddr);
    uint _value = msg.value;
    _tx.multisig_tx_id = MultiSigWallet(multisigAddr).submitTransaction(address(this),_value, _data);
  }


  //TO-DO add
  function acceptTransaction(address _sender, address _receiver, uint _txID, int _debt, int _gold) 
    external 
    payable
    onlyEscrow(_sender,_receiver)
    escrowTxExists(_sender,_receiver,_txID)
  {
    EscrowAttr storage _escrow = escrow[escrowAddr(_sender,_receiver)];
    EscrowTx storage _tx = _escrow.transactions[_txID];
    // secruity cehck
    //function call should match vlalues stored in Escrow Transaction
    //if we store all data in encodedFuncitonCall we dont need this
    require(_debt == _tx.debt );
    require(_gold == _tx.gold );
    require(_gold>=0 || (_gold<0 && uint(_gold)<=wallet[_receiver].gold), "Not enough gold to fullfill sender's ask");

    wallet[_sender].debt -= _debt;
    wallet[_receiver].debt += _debt;
    
    if(_tx.gold>0){// if sender has added gold to escrow
      wallet[_receiver].gold += uint(_gold); //pull gold from escrow, push to receiver
    }else if(_tx.gold<0){ // if sender is requesting gold transfer
      wallet[_sender].gold += uint(_gold); //push gold to sender
      wallet[_receiver].gold -= uint(_gold); //push gold to sender
    }
    // What to do if a payment is sent to this funciton
    //send funds to _sender ??
    //_sender.call.value(msg.value)("");

    updateStamperTotals(_sender,_receiver,_gold,_debt);

    // Delete the escrow?
    delete _escrow.transactions[_txID];
  }

  function rejectTransaction(address _counterparty, uint _txID) 
    public
    onlyMember()
    escrowTxExists(msg.sender,_counterparty,_txID)
  {
    EscrowAttr storage _escrow = escrow[escrowAddr(msg.sender,_counterparty)];
    EscrowTx storage _tx = _escrow.transactions[_txID];
    if(_tx.gold>0){// if sender has added gold to escrow
      wallet[_tx.sender].gold += uint(_tx.gold); //return gold in escrow to sender
    }
    delete _escrow.transactions[_txID];
  }
  

  function stampAdd(address target, bool active, uint stamprate, uint minpmt) 
    public 
    onlyOwner()

  {
    require(wallet[target].registered == true, "Target does not exist");
    require(stampRegister[target].exists == false, "Stamper already registered.");
    stamperCount++;    
    stamperIndex[stamperCount]=target;
    stampRegister[target].exists = true;
    stampRegister[target].active = active;
    stampRegister[target].stamprate = stamprate;
    stampRegister[target].minpmt = minpmt;
    stampRegister[target].laststamp = block.timestamp;
    //sumTokens();
    uint _debt; //debt to add to totalStamperDebt
    if(wallet[target].debt>0){
      _debt = uint(wallet[target].debt); // only pass positive debt 
    }
    totalStamperDebt += uint(_debt);
    totalStamperGold += wallet[target].gold;
  }

  function stampEdit(address target, bool active, uint stamprate) public onlyOwner(){
      require(stampRegister[target].exists == true, "Stamper not registered.");
      stampRegister[target].active = active;
      stampRegister[target].stamprate = stamprate;
      //sumTokens();


      // TODO add/remove totalStampeRGold/debt for active/non-active wallets? 
      /*
      int _debt; //debt to add to totalStamperDebt
      if(wallet[target].debt>0){  // only pass positive debt
        _debt = wallet[target].debt;
      }
      if(active){ //target address is active stamper - add positive debt and gold to totals  as receiver
        updateStamperTotals(address(0x0),target,_debt,int(wallet[target].gold));
      }else{ //target address is not active stamper - remove positive debt and gold from totals as sender
        updateStamperTotals(target,address(0x0),_debt,int(wallet[target].gold));
      }*/
  }
  function goldUpdate()public onlyStamper(){
      uint stamps = (block.timestamp-stampRegister[msg.sender].laststamp)/stampRegister[msg.sender].stamprate;
      wallet[msg.sender].gold += stamps;
      wallet[msg.sender].debt -= int(stamps); // debt can be negative

      /*if(wallet[msg.sender].debt>=stamps){  //Keeps debt from going negative/wraparound to huge number
        wallet[msg.sender].debt -= stamps;    
      }
      else{
          wallet[msg.sender].debt =0;
      }*/
      totalGold += stamps;
      totalStamperGold += stamps;
      totalStamperDebt -= stamps;
  }

  function updateStamperTotals(address _sender, address _receiver, int _debt, int _gold) internal{
    //why do we need to update/store these???
    int8 _sign; // defines direction of debt/gold movements
    bool _stamper=false;
    if(stampRegister[_sender].exists == true){
      _stamper = true;
      _sign = 1; // if stamper is sender values are sent out ( substract )
    }if(stampRegister[_receiver].exists == true){
      _stamper = !_stamper; //if both sender and receiver are stampers do nothing (no change in total gold/debt balance)
      _sign = -1; // if stamper is receiver values are coming in (add)
    }
    // note when debt/gold are negative these are asks by the sender and direction if flipped
    if(_stamper){
      totalStamperDebt -= uint(_sign*_debt);
      totalStamperGold -= uint(_sign*_gold);
    }
  }

  function sumTokens() external view returns(uint, uint, uint, uint) {  //Generates general metrics for the system and stamper coin levels, might be pretty inefficient
    // this iwill end up costing too much gass
    // instead just update totalDebt totalGold, etc... every time a relevant transaciton is sumitted/confirmed
    // or use this just to view current state 
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

  function killContract()
    onlyOwner()
    public
  {
    selfdestruct(tx.origin);
  }
}
