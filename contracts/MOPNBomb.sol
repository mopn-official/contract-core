// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract MOPNBomb is ERC1155, Ownable {
    constructor() ERC1155("") {}

    function setURI(string memory newuri) public onlyOwner {
        _setURI(newuri);
    }

<<<<<<< Updated upstream
    function mint(address to, uint256 id, uint256 amount) public onlyOwner {
=======
    constructor(
        address governance_,
        address initialOwner
    ) ERC1155("") Ownable(initialOwner) {
        name = "MOPN Bomb";
        symbol = "MOPNBOMB";
        governance = IMOPNGovernance(governance_);
    }

    /**
     * @notice setURI is used to set the URI corresponding to the tokenId
     * @param tokenId_ token id
     * @param uri_ metadata uri corresponding to the token
     */
    function setURI(uint256 tokenId_, string calldata uri_) external onlyOwner {
        _uris[tokenId_] = uri_;
        emit URI(uri_, tokenId_);
    }

    /**
     * @notice uri is used to get the URI corresponding to the tokenId
     * @param tokenId_ token id
     * @return metadata uri corresponding to the token
     */
    function uri(
        uint256 tokenId_
    ) public view virtual override returns (string memory) {
        return _uris[tokenId_];
    }

    function mint(address to, uint256 id, uint256 amount) public onlyMOPN {
>>>>>>> Stashed changes
        _mint(to, id, amount, "");
    }

    function burn(address from, uint256 id, uint256 amount) public onlyOwner {
        _burn(from, id, amount);
    }
}
