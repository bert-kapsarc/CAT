pragma solidity ^0.5.12;

/// @title Contract to certify the carbon .
/// @author Bertrand Williams-Rioux / Shetty
/// @notice Contract to certify the carbon.

contract Certification {
    // Contract creator
    address public owner;

    // List of auditors
    // TODO : This could be an array but it adds complexity in retreival and duplicate checks.for simplicity it now a map
    mapping(address => bool) public auditors;

    // Request Id counter for the variable "certRequests" (see below)
    uint256 internal requestIdCounter = 0;

    // List of certificate request
    mapping(address => mapping(uint256 => CertificationAttrs))
        public certRequests;

    // All information needed to get certified.
    struct CertificationAttrs {
        // Array of TX #s (i.e. address[]) for direct emissions (e.g fuels consumed, leaked, flared)
        // directly by the address requesting certificate. Validate: requester address as the receiver.
        address[] scope1;
        // Scope 2 inputs: array of TX #s for other forms of energy consumed (electricity steam).
        // requester address as the receiver. Validate: requester address as the receiver
        address[] scope2;
        // Fuels received for process (Fp) : array of TX #s (different from above) that represent fuels received by requester
        // for processing. e.g. raw crude for refining. Validate: requester address as the receiver
        address[] processFuel;
        // Scope 3 downstream (i.e. fuels sent out by requester address). Should be one of the following:
        // - Raw fuels extracted by the company.  : array of TX #'s representing all primary fuels sent out by the company. Validate: requester address as the sender
        // - Fuels post processing:
        // - Fuels sent out by company after processing (e.g. refined crude products). Validate: requester address as the sender
        // - Waste discarded from fuel processing: array of TX #s. Validate: requester address as the sender
        address[] fpp_fuel;
        address[] fpp_waste;
        address[] rawfuels;
        // Total energy content of scope 3
        uint256 scope3Energy;
        //Not: Fp - Fpp - Waste = other scope 1 emissions (e.g. refinery flaring)
        uint256 other_scope1_emissions;

        address requestor;
    }

    function nextRequestId(address requestor)
        internal
        returns (uint256 requestid) {
        return ++requestIdCounter;
    }

    function validateReceiver(address[] txns) returns (bool isReceiver) {
        
    }

    function requestCertificate(address[] txns) returns (bool isReceiver) {

    }

    function requestAudit(address auditor , address test , uint256 id) {

    }

}
