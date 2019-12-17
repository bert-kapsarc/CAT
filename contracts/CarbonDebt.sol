pragma solidity ^0.5.12;

library Participant{
    enum Class { Default, Producer, Consumer, Sinker}
}

contract Directory{
    address public owner; //owner of the directory contract
    address[] public contracts; //list of all contract addresses in the directory
    constructor() public {
        owner = msg.sender;
    }

    event newDebtContract(
        address contractAddress
    );

    function createContract(Participant.Class participant_class, uint debt) external payable returns(address newContract) {
        // this function creates new debt contract
        // uses the default debt contract logic developed for this project
        // the registerContrsact can be used to register external contracts with different logic
        debtContract c = (new debtContract).value(msg.value)(address(msg.sender), participant_class, debt);
        contracts.push(address(c));
        emit newDebtContract(address(c));
        return address(c);
    }

    function registerContract(address c) external returns(address newContract){
        // this function is used to register an existing external debt contract. 
        // This way participants can publish new contracts external to the default hard coded into createContract
        // TODO add some validation checks inorder for the external contract to be accepted into the directory
        //  i.  
        //  ii. 
        contracts.push(c);
        emit newDebtContract(c);
        return c;
    }
}

contract debtContract{
    struct Member {
        Participant.Class class;
        address[] backers;
        uint debt; //integer value of carbon debt in kg.
        bool exists;
    }

    address public owner;

    mapping(address => Member) public participants;

    constructor(address owner_address, Participant.Class owner_class, uint carbon) public payable {
        owner = owner_address;
        participants[owner_address].class = owner_class;
        participants[owner_address].debt += carbon;
    }  

    function createNewParticipant(Participant.Class participant_class, uint carbon) public {
        // only create participant if has not yet been set
        require(participants[msg.sender].exists);
        participants[msg.sender].class = participant_class;
        assignDebt(carbon);
    }

    function assignDebt(uint carbon) public {
        // only the contract owner can assign debt to their own Participant mapping
        require(
            msg.sender==owner,
            "Only the contract owner can assign debt to himself"
        );
        //require(uint(participants[msg.sender].class)>0);
        participants[msg.sender].debt += carbon;
    }

    function receiveDebt(address source, uint carbon) external {
        // any address can request owner to send them debt

        // TO-DO - add mutisig functionality to prevent debt trolling
        // Propose using the MultiSigWallet from https://github.com/gnosis/MultiSigWallet/releases
        // Code cloned into git submodule MultiSigWallet
        
        // The multisig wallet can be funded to send ether
        // however, we may only want the wallet to send confirmtion that releases the debt
        // This requires both parties in the debt transfer to approve it (2of2 multisig)
        // Can use the Transaction.data stored in the multisig wallet to trigger debt transfer when the multisig is confirmed 
        // and executed via the wallets external_call function

        // Note: The multisig allows us to assocaite multiple public/private keys 
        // to a given debt transfer transaction request
        // and enable NofM multisig to confirm a transaciotn 

        // Example contract confirmation protocol
        // Receiver opens a receiveDebt tx request by sending a commitment to pay for energy/product, 
        // Note the receiver could fund the MultisigWallet 
        // Embeds confirmation of payment within contract logic
        // Opon receipt of payment bebt owner signs tx request to releases debt 
        // and the contract reflects the commitment to sell.


        require(
            participants[source].debt>carbon,
            'Debt transfer exceeds debt balance'
        );
        participants[source].debt -= carbon;
        participants[msg.sender].debt += carbon;
    }

    function sendDebt(address source, uint carbon) external {
        // Used by debt owners to sned debt to another account
        // Again this requires using the multisig wallet.
    }

    function participantDebt(address _participant) public view returns (uint){
        return participants[_participant].debt;
    }

    function participantType(address _participant) public view returns (uint){
        return uint(participants[_participant].class);
    }

}