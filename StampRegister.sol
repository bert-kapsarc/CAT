pragma solidity 0.5.1;

contract StampRegister {
   uint256 public stamperCount = 0;
   mapping (uint => Stamper) public stampers;
   
   address owner;
   
   modifier onlyOwner () {
       require(msg.sender == owner);
       _;
   }
   
   constructor() public {
       owner = msg.sender;
   }
   
   struct Stamper {
       uint256 _id;  //Stamper ID
       string _name; //Text Identifier
       bool _active; //Is stamper active?
       uint _rate;   //Rate of stamping speed
       uint _minPmt;   //Minimum accepted payment
       address _wallet; //address of stamper
   }
    
    function addStamper(string memory _name, bool _active, uint _rate, uint _minPmt, address _wallet) public onlyOwner(){
        incrementStamper();
        stampers[stamperCount] = Stamper(stamperCount, _name,_active,_rate,_minPmt,_wallet);
    }
    
    function editStamper(uint256 _id, string memory _name, bool _active, uint _rate, uint _minPmt, address _wallet) public onlyOwner(){
        stampers[_id] = Stamper(_id, _name,_active,_rate,_minPmt,_wallet);
    }

    function incrementStamper() internal {
        stamperCount += 1;
    }
}
