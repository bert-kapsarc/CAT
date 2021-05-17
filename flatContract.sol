
// File: contracts/Factory.sol

pragma solidity ^0.5.12;

contract Factory {

    /*
     *  Events
     */
    event ContractInstantiation(address sender, address instantiation);

    /*
     *  Storage
     */
    mapping(address => bool) public isInstantiation;
    mapping(address => address[]) public instantiations;

    /*
     * Public functions
     */
    /// @dev Returns number of instantiations by creator.
    /// @param creator Contract creator.
    /// @return Returns number of instantiations by creator.
    function getInstantiationCount(address creator)
        public
        view
        returns (uint)
    {
        return instantiations[creator].length;
    }

    /*
     * Internal functions
     */
    /// @dev Registers contract in factory registry.
    /// @param instantiation Address of contract instantiation.
    function register(address instantiation)
        internal
    {
        isInstantiation[instantiation] = true;
        instantiations[msg.sender].push(instantiation);
        emit ContractInstantiation(msg.sender, instantiation);
    }
}

// File: contracts/MultiSigWallet.sol

pragma solidity ^0.5.12;


/// @title Multisignature wallet - Allows multiple parties to agree on transactions before execution.
/// @author Stefan George - <stefan.george@consensys.net>
contract MultiSigWallet {

    /*
     *  Events
     */
    event Confirmation(address indexed sender, uint indexed transactionId);
    event Revocation(address indexed sender, uint indexed transactionId);
    event Submission(uint indexed transactionId);
    event Execution(uint indexed transactionId);
    event ExecutionFailure(uint indexed transactionId);
    event Deposit(address indexed sender, uint value);
    event OwnerAddition(address indexed owner);
    event OwnerRemoval(address indexed owner);
    event RequirementChange(uint required);

    /*
     *  Constants
     */
    uint constant public MAX_OWNER_COUNT = 50;

    /*
     *  Storage
     */
    mapping (uint => Transaction) public transactions;
    mapping (uint => mapping (address => bool)) public confirmations;
    mapping (address => bool) public isOwner;
    address[] public owners;
    uint public required;
    uint public transactionCount;

    struct Transaction {
        address destination;
        uint value;
        bytes data;
        bool executed;
    }

    /*
     *  Modifiers
     */
    modifier onlyWallet() {
        require(msg.sender == address(this), 'Chnages can only be made by wallet address');
        _;
    }

    modifier ownerDoesNotExist(address owner) {
        require(!isOwner[owner], 'Owner already assigned');
        _;
    }

    modifier ownerExists(address owner) {
        require(isOwner[owner], 'This address is not an owner of this wallet');
        _;
    }

    modifier transactionExists(uint transactionId) {
        require(transactions[transactionId].destination != address(0x0), 'Transaction does not exist');
        _;
    }

    modifier confirmed(uint transactionId, address owner) {
        require(confirmations[transactionId][owner], 'Transaction not confirmed');
        _;
    }

    modifier notConfirmed(uint transactionId, address owner) {
        require(!confirmations[transactionId][owner], 'Transaction is already confirmed');
        _;
    }

    modifier notExecuted(uint transactionId) {
        require(!transactions[transactionId].executed, 'Transaction alreay executed');
        _;
    }

    modifier notNull(address _address) {
        require(_address != address(0x0), 'Address is null');
        _;
    }

    modifier validRequirement(uint ownerCount, uint _required) {
        require(ownerCount <= MAX_OWNER_COUNT
            && _required <= ownerCount
            && _required != 0
            && ownerCount != 0, 'Wallet is not valid');
        _;
    }

    /// @dev Fallback function allows to deposit ether.
    function()
        payable
        external
    {
        if (msg.value > 0)
          emit  Deposit(msg.sender, msg.value);
    }

    /*
     * Public functions
     */
    /// @dev Contract constructor sets initial owners and required number of confirmations.
    /// @param _owners List of initial owners.
    /// @param _required Number of required confirmations.
    constructor(address[] memory _owners, uint _required)
        public
        validRequirement(_owners.length, _required)
    {
        for (uint i=0; i<_owners.length; i++) {
            require(!isOwner[_owners[i]] && _owners[i] != address(0));
            isOwner[_owners[i]] = true;
        }
        owners = _owners;
        required = _required;
    }

    /// @dev Allows to add a new owner. Transaction has to be sent by wallet.
    /// @param owner Address of new owner.
    function addOwner(address owner)
        public
        onlyWallet
        ownerDoesNotExist(owner)
        notNull(owner)
        validRequirement(owners.length + 1, required)
    {
        isOwner[owner] = true;
        owners.push(owner);
        emit OwnerAddition(owner);
    }

    /// @dev Allows to remove an owner. Transaction has to be sent by wallet.
    /// @param owner Address of owner.
    function removeOwner(address owner)
        public
        onlyWallet
        ownerExists(owner)
    {
        isOwner[owner] = false;
        for (uint i=0; i<owners.length - 1; i++)
            if (owners[i] == owner) {
                owners[i] = owners[owners.length - 1];
                break;
            }
        owners.length -= 1;
        if (required > owners.length)
            changeRequirement(owners.length);
        emit OwnerRemoval(owner);
    }

    /// @dev Allows to replace an owner with a new owner. Transaction has to be sent by wallet.
    /// @param owner Address of owner to be replaced.
    /// @param newOwner Address of new owner.
    function replaceOwner(address owner, address newOwner)
        public
        onlyWallet
        ownerExists(owner)
        ownerDoesNotExist(newOwner)
    {
        for (uint i=0; i<owners.length; i++)
            if (owners[i] == owner) {
                owners[i] = newOwner;
                break;
            }
        isOwner[owner] = false;
        isOwner[newOwner] = true;
        emit OwnerRemoval(owner);
        emit OwnerAddition(newOwner);
    }

    /// @dev Allows to change the number of required confirmations. Transaction has to be sent by wallet.
    /// @param _required Number of required confirmations.
    function changeRequirement(uint _required)
        public
        onlyWallet
        validRequirement(owners.length, _required)
    {
        required = _required;
        emit RequirementChange(_required);
    }

    /// @dev Allows an owner to submit and confirm a transaction.
    /// @param destination Transaction target address.
    /// @param value Transaction ether value.
    /// @param data Transaction data payload.
    /// @return Returns transaction ID.
    function submitTransaction(address destination, uint256 value, bytes memory data)
        public
        returns (uint transactionId)
    {
        //(bool result, ) = destination.call(data); 
        //require(result, "transaction failed");
        transactionId = addTransaction(destination, value, data);
        confirmTransaction(transactionId);
    }

    /// @dev Allows an owner to confirm a transaction.
    /// @param transactionId Transaction ID.
    function confirmTransaction(uint transactionId)
        public
        ownerExists(msg.sender)
        transactionExists(transactionId)
        notConfirmed(transactionId, msg.sender)
    {
        confirmations[transactionId][msg.sender] = true;
        emit Confirmation(msg.sender, transactionId);
        executeTransaction(transactionId);
    }

    /// @dev Allows an owner to revoke a confirmation for a transaction.
    /// @param transactionId Transaction ID.
    function revokeConfirmation(uint transactionId)
        public
        ownerExists(msg.sender)
        confirmed(transactionId, msg.sender)
        notExecuted(transactionId)
    {
        confirmations[transactionId][msg.sender] = false;
        emit Revocation(msg.sender, transactionId);
    }

    /// @dev Allows anyone to execute a confirmed transaction.
    /// @param transactionId Transaction ID.
    function executeTransaction(uint transactionId)
        public
        ownerExists(msg.sender)
        confirmed(transactionId, msg.sender)
        notExecuted(transactionId)
    {
        if (isConfirmed(transactionId)) {
            Transaction storage txn = transactions[transactionId];
            txn.executed = true;
            if (external_call(txn.destination, txn.value, txn.data.length, txn.data))
                emit Execution(transactionId);
                //selfdestruct(tx.origin); 
                //In what situations do we we want to destruct the escrow?
                //Escrow is designed to be one time use only
                //Escrow has no other pending tx

            else {
                emit ExecutionFailure(transactionId);
                txn.executed = false;
            }
        }
    }

    // call has been separated into its own function in order to take advantage
    // of the Solidity's code generator to produce a loop that copies tx.data into memory.
    function external_call(address destination, uint value, uint dataLength, bytes memory data) 
      internal returns (bool) {
        bool result;
        assembly {
            let x := mload(0x40)   // "Allocate" memory for output (0x40 is where "free memory" pointer is stored by convention)
            let d := add(data, 32) // First 32 bytes are the padded length of data, so exclude that
            result := call(
                sub(gas, gaslimit),   // 34710 is the value that solidity is currently emitting
                                   // It includes callGas (700) + callVeryLow (3, to pay for SUB) + callValueTransferGas (9000) +
                                   // callNewAccountGas (25000, in case the destination address does not exist and needs creating)
                destination,
                value,
                d,
                dataLength,        // Size of the input (in bytes) - this is what fixes the padding problem
                x,
                0                  // Output is ignored, therefore the output size is zero
            )
        }
        
        return result;
    }

    /// @dev Returns the confirmation status of a transaction.
    /// @param transactionId Transaction ID.
    /// @return Confirmation status.
    function isConfirmed(uint transactionId)
        public
        view
        returns (bool)
    {
        uint count = 0;
        for (uint i=0; i<owners.length; i++) {
            if (confirmations[transactionId][owners[i]])
                count += 1;
            if (count == required)
                return true;
        }
    }

    /*
     * Internal functions
     */
    /// @dev Adds a new transaction to the transaction mapping, if transaction does not exist yet.
    /// @param destination Transaction target address.
    /// @param value Transaction ether value.
    /// @param data Transaction data payload.
    /// @return Returns transaction ID.
    function addTransaction(address destination, uint value, bytes memory data)
        internal
        notNull(destination)
        returns (uint transactionId)
    {
        transactionId = transactionCount;
        transactions[transactionId] = Transaction({
            destination: destination,
            value: value,
            data: data,
            executed: false
        });
        transactionCount += 1;
        emit Submission(transactionId);
    }

    /*
     * Web3 call functions
     */
    /// @dev Returns number of confirmations of a transaction.
    /// @param transactionId Transaction ID.
    /// @return Number of confirmations.
    function getConfirmationCount(uint transactionId)
        public
        view
        returns (uint count)
    {
        for (uint i=0; i<owners.length; i++)
            if (confirmations[transactionId][owners[i]])
                count += 1;
    }

    /// @dev Returns total number of transactions after filers are applied.
    /// @param pending Include pending transactions.
    /// @param executed Include executed transactions.
    /// @return Total number of transactions after filters are applied.
    function getTransactionCount(bool pending, bool executed)
        public
        view
        returns (uint count)
    {
        for (uint i=0; i<transactionCount; i++)
            if (   pending && !transactions[i].executed
                || executed && transactions[i].executed)
                count += 1;
    }

    /// @dev Returns list of owners.
    /// @return List of owner addresses.
    function getOwners()
        public
        view
        returns (address[] memory) 
    {
        return owners;
    }

    /// @dev Returns array with owner addresses, which confirmed transaction.
    /// @param transactionId Transaction ID.
    /// @return Returns array of owner addresses.
    function getConfirmations(uint transactionId)
        public
        view
        returns (address[] memory _confirmations)
    {
        address[] memory confirmationsTemp = new address[](owners.length);
        uint count = 0;
        uint i;
        for (i=0; i<owners.length; i++)
            if (confirmations[transactionId][owners[i]]) {
                confirmationsTemp[count] = owners[i];
                count += 1;
            }
        _confirmations = new address[](count);
        for (i=0; i<count; i++)
            _confirmations[i] = confirmationsTemp[i];
    }

    /// @dev Returns list of transaction IDs in defined range.
    /// @param from Index start position of transaction array.
    /// @param to Index end position of transaction array.
    /// @param pending Include pending transactions.
    /// @param executed Include executed transactions.
    /// @return Returns array of transaction IDs.
    function getTransactionIds(uint from, uint to, bool pending, bool executed)
        public
        view
        returns (uint[] memory _transactionIds)
    {
        uint[] memory transactionIdsTemp = new uint[](transactionCount);
        uint count = 0;
        uint i;
        for (i=0; i<transactionCount; i++)
            if (   pending && !transactions[i].executed
                || executed && transactions[i].executed)
            {
                transactionIdsTemp[count] = i;
                count += 1;
            }
        _transactionIds = new uint[](to - from);
        for (i=from; i<to; i++)
            _transactionIds[i - from] = transactionIdsTemp[i];
    }
}

// File: contracts/MultiSigWalletFactory.sol

pragma solidity ^0.5.12;




/// @title Multisignature wallet factory - Allows creation of multisig wallet.
/// @author Stefan George - <stefan.george@consensys.net>
contract MultiSigWalletFactory is Factory {

    /*
     * Public functions
     */
    /// @dev Allows verified creation of multisignature wallet.
    /// @param _owners List of initial owners.
    /// @param _required Number of required confirmations.
    /// @return Returns wallet address.
    function create(address[] memory _owners, uint _required)
        public
        returns (address payable multisig_wallet)
    {
        MultiSigWallet escrow = new MultiSigWallet(_owners, _required);
        multisig_wallet = address(escrow);
        register(multisig_wallet);
    }
}

// File: contracts/Stamper.sol

pragma solidity ^0.5.12;
//import "./CAT.sol";

/// @title Stamper Registry
/// @author Bertrand Williams-Rioux
/// @notice Use this to Generate new stamper contracts (offset credit generators).
/// @dev <docment-me>
contract Stamper {

  attributes public stamper;

  struct attributes {
    address owner;
    address payable parent; // parent address that created this contract (this should be the CAT contract)
    address nominator;
    bool active;   //Is stamper active?
    uint rate; //Rate of stamping speed
    uint minpmt;    //Minimum accepted payment
    uint last;  //time of last stamping
    uint stamps;
    uint yayCount; //number of yes votes
    uint nayCount; //number of no votes
  }
  // currently we do not track public vote addresses
  int public publicVoteCount;  //public up/down votes
  
  mapping(uint => bool) public governorVote;     //governor votes
  mapping(address => uint) public governorVoteIndex;
  uint public governorVoteCount;

  //Proposal Vote maps propsal index to proposalVoteIndex to vote state
  mapping(uint => mapping(uint => bool)) public proposalVote;
  //Proposal Vote maps propsal index to voter address to proposalVote Index
  mapping(uint => mapping(address => uint)) public proposalVoteIndex;
  uint public proposalCount;
  mapping(uint => uint) public proposalVoteCount;
  mapping(uint => proposalAttr) public proposal;

  struct proposalAttr {
    uint rate;
    address origin; // who created this proposal;
    uint timeApproved;
    uint yayCount; //number of yes votes
    uint nayCount; //number of no votes
  }
  constructor(address target, address nominator, uint rate, uint minpmt) public {
    stamper.owner = target;
    stamper.parent = msg.sender;
    stamper.nominator = nominator;
    stamper.rate = rate;
    stamper.minpmt = minpmt;
    stamper.last = block.timestamp;
    incrementProposal(nominator,rate);

  }

  modifier onlyStamper () {  //added some security
    require(stamper.owner == msg.sender, "Only the stamper can access this function.");
    _;
  }
  modifier notStamper () {  //added some security
    require(stamper.owner != msg.sender, "The stamper can not call this fn.");
    _;
  }
  modifier onlyRegisteredWallets(){
    (bool _registered) = CAT(stamper.parent).registered(msg.sender);
    require(_registered == true, 'You are not a registered user of the parent accounting contract');
    _;
  }
  modifier newGovernorVote(bool _vote){
    require(governorVoteIndex[msg.sender]==0 || _vote != governorVote[governorVoteIndex[msg.sender]], '');
    _;
  }
  modifier onlyGovernor(){
    require(CAT(stamper.parent).governor(msg.sender), 'Only Governors can do that');
    _;
  }
  modifier notApproved(uint _proposal){
    require(proposal[_proposal].timeApproved == 0, 'Proposal has already been approved');
    _;
  }


  function vote(bool _vote)
    public
    notStamper()
    onlyRegisteredWallets()
    newGovernorVote(_vote)
  {
    // governor voting
    if(CAT(stamper.parent).governor(msg.sender)){
      if(governorVoteIndex[msg.sender] == 0){
        //start tracking votes from index 1. 
        //index 0 is default value for governors that have not yet voted only
        governorVoteIndex[msg.sender] = ++governorVoteCount;
      }
      governorVote[governorVoteIndex[msg.sender]] = _vote;
      (uint yay,uint nay) = countGovernorVotes();
      // if yay greater than nay and yay is at least 7 activate stamper
      if(yay>nay && yay>6){
          stamper.active = true;
      }else{
        stamper.active = false;
      }
    }else{
      //increment public votes
      //note that currently public can vote as many times as they see fit
      // however public votes hold a very minor weight in the final activation process
      if(_vote){
        publicVoteCount++;
      }else{
        publicVoteCount--;
      }
    }
  }

  function countGovernorVotes()
    view
    public
    returns(uint yay,uint nay)
  {
    for(uint i=1;i<=governorVoteCount;i++)
      if(governorVote[i]){
        yay ++;
      }else{
        nay ++;
      }
  }
  //TODO recounting the total number of votes is computationally expensive (looping)
  // instead we should store the total number of votes (yay/nay)
  // and update them conditionally when a new/revised vote is submitted 
  function countProposalVotes(uint _proposal)
    view
    public
    returns(uint yay,uint nay)
  {
    for(uint i=1;i<=proposalVoteCount[_proposal];i++)
      if(proposalVote[_proposal][i]){
        yay ++;
      }else{
        nay ++;
      }
  }

  // TODO who controls stamper rate revisions
  // should these vchanges be subject to vote approval
  // shoul dcuurent stamper rate have an expiration and require voting renewal
  // This needs to be developed ...
  function proposeStamperRate(uint _rate) public onlyGovernor(){
    incrementProposal(msg.sender,_rate);
  }

  function incrementProposal(address _voter, uint _rate) internal {
    uint _index = ++proposalVoteIndex[proposalCount][msg.sender];
    proposalVote[proposalCount][_index] = true;
    proposal[proposalCount].rate = _rate;
    proposal[proposalCount].origin = _voter;
    setProposalVote(proposalCount++,_voter,true);
  }

  function voteForProposal(uint _proposal, bool _vote) 
    public 
    onlyGovernor()
    notApproved(_proposal)
  {
    setProposalVote(_proposal,msg.sender,_vote);
    (uint yay,uint nay) = countProposalVotes(_proposal);
    // if yay greater than nay and yay is at least 7 activate stamper
    if(yay>nay && yay>6){
      proposal[_proposal].timeApproved = block.timestamp;
      stamper.rate = proposal[_proposal].rate;
    }
  }

  function setProposalVote(uint _proposal,address _voter,bool _vote) internal
  {
    if(proposalVoteIndex[_proposal][_voter] == 0){
      //start tracking votes from index 1. 
      //index 0 is default value vote index
      proposalVoteIndex[_proposal][_voter] = ++proposalVoteCount[_proposal];
    }
    proposalVote[_proposal][proposalVoteIndex[_proposal][_voter]] = _vote;
  }

  function stamp() public 
    onlyStamper()
  {
      // Some points to address
      // Block timestamp can be manipulated by miners within 900s
      // Make sure that this deos not distort the stamping rate within am acceptable tollerance
      // Need to set other stamp constriants (total stamps based on auditing, or other metrics)

      uint stamps = (block.timestamp-stamper.last)/stamper.rate;
      stamper.stamps += stamps; 
      CAT(stamper.parent).updateGold(stamps,stamper.owner);

  }

  function stampPmtAdjust(uint minpmt) public onlyStamper(){
    stamper.minpmt = minpmt;
  }
}

// File: contracts/CAT.sol

pragma solidity ^0.5.12;



/// @title Contract which executes trade between 2 entities via escrow.
/// @author Bertrand Rioux
/// @notice You can use this contract for transacting carbon inventories and carbon offset credits (tokens) derived from them.
/// @dev <docment-me>
contract CAT {
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
    uint offsets;  //Carbon Gold used as offset
  }
  mapping (address => Attributes) public wallet;
  mapping (address => bool) public registered; //Valid account?)
  //mapping a given wallet address pair to escrow address
  mapping(address => mapping(address => address payable)) internal EscrowAddr;
  mapping (address => address[]) public escrowList; // mapping user address to array of active escrows
  function getEscrowList(address _address)
    public view
    returns (address[] memory) {
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
      || (_gold<=0 && uint(_gold)<=wallet[_receiver].gold) // but can ask
      // The second condition prevents asking for gold that exceeds balance from 
      // requester (_receivers) wallet. We do not really need this?
      , "Insufficient gold for this transfer");  
    _;
  }

  /// @dev Constructor set deployer as owner and as a governor
  /// @param mswfactory MultisigWalletFactory address used by this contract to setup escrow wallets
  constructor(address mswfactory) public {
    owner = msg.sender;
    governor[msg.sender]=true;
    factory_addr = mswfactory;
  }

  function() external payable {}
    
  /// @dev Register target address as governor
  /// @param _target the wallet name
  function addGovernor(address _target)  
    public 
    onlyOwner()
    {
      governor[_target]=true;
    }

  /// @dev Register wallet with the CAT network
  /// @param name the wallet name
  function signUp(string memory name) public
    {
      require(registered[msg.sender]!= true, "ALREADY REGISTERED");
      userIndex[userCount++]=msg.sender;
      wallet[msg.sender].name = name;
      registered[msg.sender] = true;
    }


  /// @dev find escrow account with you and the receiver. 
  /// @param _receiver The receiver account
  /// @return Escrow Address
  /// @notice Will be dropped in future deployments. This data is to be stored/managed by the client
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

  /// @dev Create an escrow account with you and the receiver
  /// @param _receiver The receiver account
  /// @return Escrow Address
  function createEscrow(address _receiver)//, uint _value) 
    public
    onlyMember()
    escrowDoesNotExist(msg.sender,_receiver)
    returns(address payable _escrowAddr)
    {
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

  /// @dev Add carbon to your account
  /// @param carbon The amount of carbon in KG CO2e
  function addCarbon(uint carbon) public onlyMember()
    {
      require(carbon>0, 'Can only add positive carbon');
      wallet[msg.sender].carbon += int(carbon);
      totalCarbon += carbon;
      if(stamperRegistry[msg.sender]!=address(0x0)){
        totalStamperCarbon += carbon;
      }
    }

  /// @dev Create a transaction request to transfer carbon and gold using escrow.
  /// @param _receiver Counterparty to the offer
  /// @param _carbon Signed integer carbon transfer, (+) for send gold to receiver, (-) to request gold transfer to sender.
  /// @param _gold Signed integer gold transfer, (+) for send gold to receiver, (-) to request gold transfer to sender.
  /// @notice In future will include escrow address as this willnot be stored in the contract
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

  /** @dev Accept a pending transaction in escrow.
  * @param _sender sender
  * @param _receiver receiver
  * @param _txID Transaction ID 
  * @param _carbon signed integer carbon transfer, (+) for send gold to receiver, (-) to request gold transfer to sender.
  * @param _gold signed integer gold transfer, (+) for send gold to receiver, (-) to request gold transfer to sender.
  */
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

  /** @dev Reject a transaction.
  * @param _counterparty The counterparty
  * @param _txID Transaction ID 
  */
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

  function updateStamperTotals(address _sender, address _receiver, int _carbon, int _gold) 
    internal{
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

  /** @dev Get the external multisig transaciton data for an escrow transaction 
  * @param _escrowAddr The escrow address
  * @param _txID The escrow transaction ID 
  */
  function transactionData(address _escrowAddr, uint _txID)
    public
    view
    returns(uint)
    {
      return(escrowTx[_escrowAddr][_txID].multisig_tx_id);
    }

  /** @dev Function to return all existing escrow transactions between 2 entities.
  * @param _escrowAddr The counterparty
  * @param from Initiator 
  * @param to Receiver 
  */
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


  /** @dev Function to burn stamped carbon (gold) to register it as a locked offset.
  * @param _gold Stamped carbon to burn
  */
  function lockOffset(uint _gold) 
    public
    onlyMember() {
    require(_gold<=wallet[msg.sender].gold, "Insufficient carbon credits to offset");
    wallet[msg.sender].gold -= _gold;
    wallet[msg.sender].offsets += _gold;
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
    { owner = _newOwner;}
  function killContract()
    onlyOwner()
    public
    { selfdestruct(tx.origin);}
}
