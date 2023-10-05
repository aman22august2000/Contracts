// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

// import "erc721a/contract/ERC721A.sol";
import "https://github.com/chiru-labs/ERC721A/blob/main/contracts/ERC721A.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract MinimizeGas is ERC721A, Ownable {

    // uint256 MAX_SUPPLY =100;
    // uint256 MAX_MINTS = 10021;
    uint256 public mintRate= 0.001 ether;


    string public baseURI = "ipfs://bafybeibv6wmx2yuzl3y7wu3lmfevwrhuu37ftmaks4zzcxbofyx42fb35i/";

    constructor() ERC721A ("MinimizeGas","MGS") {}

    function mint (uint256 quantity) external payable {
        // require(quantity + _numberMinted(msg.sender) <= MAX_MINTS, "Maximum limit reached");
        // require(totalSupply() + quantity <= MAX_SUPPLY, "Not enough tokken left to mint");
        require(msg.value >= (mintRate * quantity), "Not enough ether sent");
        _safeMint(msg.sender,quantity);
    }

    function withdraw() external payable onlyOwner {
        payable(owner()).transfer(address(this).balance);
    }

    function _baseURI () internal view override returns(string memory) {
        return baseURI;
    }

    function _setMintRate(uint256 _mintRate) public onlyOwner {
        mintRate = _mintRate;
    }

}