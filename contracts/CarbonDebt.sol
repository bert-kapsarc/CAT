pragma solidity ^0.5.12;
contract CarbonDebt {

    enum PlayerClass { Producer, Consumer, Manager}

    struct Player {
        PlayerClass class;
        address[] backers;
        uint debt; //integer value of carbon debt in kg.
    }

    address public contract_owner;

    mapping(address => Player) public players;

    constructor() public {
        contract_owner = msg.sender;
    }  

    function createNewPlayer(PlayerClass player_class, uint carbon) public {
        // only create player if its class has not yet been set
        require(uint(players[msg.sender].class)==0);
        players[msg.sender].class = player_class;
        assignDebt(carbon);
    }

    function assignDebt(uint carbon) public {
        require(uint(players[msg.sender].class)>0);
        players[msg.sender].debt += carbon;
    }

    function receiveDebt(address source, uint carbon) external {
        require(players[source].debt>carbon);
        players[source].debt -= carbon;
        players[msg.sender].debt += carbon;
    }

    function playerDebt(address _player) public view returns (uint){
        return players[_player].debt;
    }

    function playerType(address _player) public view returns (uint){
        return uint(players[_player].class);
    }

}