// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

contract kyc {

    // address public owner;

    // constructor() {
    //     owner = msg.sender;
    // }

    // modifier onlyOwner() {
    //     require(msg.sender==owner,"Only owner can call this function");
    //     _;
    // }

    struct details {
        string name;
        uint256 contactNumber;
        string personAddress;
        uint256 aadharNumber;
        bool status;
    }

    mapping (address=>details) kycDetail;


    function doingKYC (string memory _name,uint256 _contactNumber, string memory _personAddress, 
                        uint256 _aadharNumber) public returns (bool) {
        require(!kycDetail[msg.sender].status, "KYC is already done");
        address user = msg.sender;
        kycDetail[user].name=_name;
        kycDetail[user].contactNumber=_contactNumber;
        kycDetail[user].personAddress=_personAddress;
        kycDetail[user].aadharNumber=_aadharNumber;
        kycDetail[user].status=true;
        return true;
    }

    function viewDetails(address add) public view returns (details memory) {
        return kycDetail[add];
    }
    
}