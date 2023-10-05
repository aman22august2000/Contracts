// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";

contract Blacklisting is Ownable {

    mapping (address => bool) isBlacklisted;

    function addBlacklist(address user) public onlyOwner returns (bool) {
        require(isBlacklisted[user]!=true,"User is already blacklisted");
        isBlacklisted[user]=true;
        return true;
    }

    function removeBlacklist(address user) public onlyOwner returns (bool) {
        require(isBlacklisted[user]!=false,"User is not blacklisted");
        isBlacklisted[user]=false;
        return true;
    }

    function checkIsBlacklisted(address user) public view returns (bool) {
        return isBlacklisted[user];
    }
}