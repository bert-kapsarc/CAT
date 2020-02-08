pragma solidity ^0.5.12;

contract Stamper {

  attributes stamper 

  struct attributes {
    address owner;
    address parent; // parent address that created this contract (this should be the carboTag contract)
    bool active;   //Is stamper active?
    uint stamprate; //Rate of stamping speed
    uint minpmt;    //Minimum accepted payment
    uint laststamp;  //time of last stamping
    uint stamps;
    int votes;      //up votes
  }

  constructor(address target, uint stamprate, uint minpmt) public {
    stamper.owner = target;
    stamper.owner = msg.sender;
    stamper.stamprate = stamprate;
    stamper.minpmt = minpmt;
    stamper.laststamp = block.timestamp;
  }

  modifier onlyStamper () {  //added some security
    require(stamper.owner == msg.sender, "Only stamper can access this function.");
    _;
  }



  function stampEdit(uint stamprate) public onlyStamper(){
    stamper.active = false;
    stamper.stamprate = stamprate;
    //sumTokens();


    // TODO add/remove totalStampeRGold/carbon for active/non-active wallets? 
    /*
    int _carbon; //carbon to add to totalStamperCarbon
    if(wallet[target].carbon>0){  // only pass positive carbon
      _carbon = wallet[target].carbon;
    }
    if(active){ //target address is active stamper - add positive carbon and gold to totals  as receiver
      updateStamperTotals(address(0x0),target,_carbon,int(wallet[target].gold));
    }else{ //target address is not active stamper - remove positive carbon and gold from totals as sender
      updateStamperTotals(target,address(0x0),_carbon,int(wallet[target].gold));
    }*/
  }

  function stamp() public 
    onlyStamper()
  {
      // Some points to address
      // Block timestamp can be manipulated by miners within 900s
      // Make sure that this deos not distort the stamping rate within am acceptable tollerance
      // Need to set other stamp constriants (total stamps based on auditing, or other metrics)

      uint stamps = (block.timestamp-stamp.last)/stamp.rate;
      stamper.stamps += stamps; 
      CarboTag(stamper.parent).updateGold(stamps,stamper.owner)

  }

  function stampPmtAdjust(uint minpmt) public onlyStamper(){
    stamperRegistry[msg.sender].minpmt = minpmt;
  }
}

