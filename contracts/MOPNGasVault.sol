// SPDX-License-Identifier: MIT
pragma solidity ^0.8.21;
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";

// an erc721 collection that has 1000 NFTs
// it has a receive function to collect eth
// each NFT share 1/1000 of the collected eth of the collection vault
// vault has a function to let token owner claim eth
// for safety, key functions should has reentrancy guard
contract MOPNGasVault is ERC721, Ownable {
    using Address for address;
    using SafeMath for uint256;

    mapping(uint256 => uint256) private _claimed;

    uint256 public totalShares;

    uint256 public constant MAX_SUPPLY = 1000;
    uint256 private _currentTokenId = 0;

    constructor(address initialOwner) ERC721("MOPN Gas Share", "MGS") Ownable(initialOwner){}

    function mint(address to) public onlyOwner {
        require(_currentTokenId < MAX_SUPPLY, "Max supply reached");
        _mint(to, _currentTokenId);
        _currentTokenId++;
    }

    receive() external payable  {
        uint256 shares = msg.value / 1000;
        totalShares = totalShares.add(shares);
    }

    function claim(uint256 tokenId) public nonReentrant {
        require(msg.sender == ownerOf(tokenId), "Not token owner");
        uint256 payment = totalShares - _claimed[tokenId];
        require(payment != 0, "No funds to claim");
        _claimed[tokenId] = totalShares;
        payable(msg.sender).transfer(payment);
    }

    function claimableBalanceOf(uint256) public view returns (uint256) {
        require(ownerOf(tokenId) != address(0), "Token does not exist");
        return totalShares - _claimed[tokenId];
    }
}