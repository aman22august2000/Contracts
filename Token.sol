// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Burnable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "./Blacklisting.sol";

contract MyToken is ERC20, ERC20Burnable, Ownable, Blacklisting {
    uint256 public costOfToken; // Cost of one fungible token 

    constructor(string memory name, string memory symbol) ERC20(name, symbol){
       costOfToken = 10;
    }

    function mint(uint256 amount) public onlyOwner {
        _mint(_msgSender(), amount);
    }

    function buyToken(uint numberOfToken) public payable {
        require(owner() != _msgSender(), "You are the owner of token");
        require(isBlacklisted[_msgSender()] != true, "You does not buy token because you are blacklisted");
        require(msg.value >= numberOfToken*costOfToken, "Amount is less to buy token");
        payable(_msgSender()).transfer(msg.value - numberOfToken*costOfToken);
        _transfer(owner(), _msgSender(), numberOfToken);
    }

    function transfer(address to, uint256 amount) public override returns (bool) {
        address user = _msgSender();
        require(to != user, "You transfer token to the same address");
        require(isBlacklisted[user] != true, "You does not transfer token because you are blacklisted");
        require(isBlacklisted[to] != true, "You does not transfer token to a blacklisted address");
        _transfer(user, to, amount);
        return true;
    }

    function approve(address spender, uint256 amount) public override returns (bool) {
        require(isBlacklisted[spender] != true, "You does not approve token to a blacklisted address");
        address user = _msgSender();
        require(spender != user, "You don't need to approve yourself");
        _approve(user, spender, amount);
        return true;
    }

    function transferFrom(address from, address to, uint256 amount) public override returns (bool) {
        address spender = _msgSender();
        require(isBlacklisted[spender] != true, "You does not transfer token because you are blacklisted");
        require(isBlacklisted[to] != true, "You does not transfer token to a blacklisted address");
        _spendAllowance(from, spender, amount);
        _transfer(from, to, amount);
        return true;
    }

    // Withdraw Ether from the contract (only callable by the owner)
    function withdrawEther() public onlyOwner {
        require(address(this).balance > 0, "No balance to withdraw");
        payable(owner()).transfer(address(this).balance);
    }

    function balanceOfContract() public view returns(uint256) {
        return address(this).balance;
    }

}