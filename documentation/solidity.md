pragma solidity ^0.4.11;
contract Example {
    
}

function (<parameter types>) <visibility> [constant] [payable] [returns (<return types>)]
           
visibility: internal, external
type:
    constant: does not change contract state (read operation)
    payable: accept ether as payment to fund contract
    return: function returns an output

Constructor
function with same name as contract is optional constructor (max one, without overloading). executed once when the contract is created

e.g. function Example() {}


Fallback
function with no name, no parameters and no returns, is optional fallback, executed when: 
    (1) a contract is called, but no function signature matches (or none was supplied);
    (2) a contract receives ether without accompanying data. Take care: a fallback function has very little gas available. 
    If there is no fallback function and (1) or (2) happens, an exception is thrown.

e.g. function() {}


State variables
permanently stored in contract storage and are global

Structs
complex custom types, that can form a group of other types

Enums
simple custom types with a finite, non-zero set of values

Address 
a 20-byte value, corresponding to an Ethereum address, has comparison operators and has few members:

    balance and transfer, to access the balance of an address or to send ether, this means that you can use it like this: address a = 0x123; a.transfer(42);
    send, similar as transfer, but in case of failure does not throw an exception and simply returns false
    call, callcode and delegatecall are ways to interact with other contracts:
        call ... executing the code of the other contract
        callcode ... deprecated in favor of delegatecall
        delegatecall ... execute the code of the other contract, but in the context of the current contract’s storage (msg.sender and msg.value are preserved) – take care with it, consider security aspects
Mappings
map keys to their values
    mapping(address => uint) balances;

Conversions
    implicit conversions are possible, when they make sense (like uint8 to uint32, also uint160 can be converted to address, but not int8 to uint32, as negative numbers would be lost
    explicit conversions are sometimes possible, but take great care when doing so and test thoroughly.

contract Example {
    uint num; //state variable
    uint constant x = sha256(42); //constant state variable

    struct DummyStruct { //struct
        uint num2;
        bool isNew; 
    }

    DummyStruct ds;
    enum States { Created, Active, Inactive, Killed } //enum States state;
    States state;
    
    function setState(States newState) { 
        state = newState;
        ds.isNew = true;
    }
}
