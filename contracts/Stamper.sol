pragma solidity ^0.5.12;
import "./CarboTag.sol";

contract Stamper {

  attributes public stamper;

  struct attributes {
    address owner;
    address payable parent; // parent address that created this contract (this should be the carboTag contract)
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
    require(stamper.owner != msg.sender, "THe stamp can not call this fn.");
    _;
  }
  modifier onlyRegisteredWallets(){
    (bool _registered) = CarboTag(stamper.parent).registered(msg.sender);
    require(_registered == true, 'You are not a registered user of the parent accounting contract');
    _;
  }
  modifier newGovernorVote(bool _vote){
    require(governorVoteIndex[msg.sender]==0 || _vote != governorVote[governorVoteIndex[msg.sender]], '');
    _;
  }
  modifier onlyGovernor(){
    require(CarboTag(stamper.parent).governor(msg.sender), 'Only Governors can do that');
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
    if(CarboTag(stamper.parent).governor(msg.sender)){
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
      CarboTag(stamper.parent).updateGold(stamps,stamper.owner);

  }

  function stampPmtAdjust(uint minpmt) public onlyStamper(){
    stamper.minpmt = minpmt;
  }
}

