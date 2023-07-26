// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "./erc6551/interfaces/IERC6551Account.sol";
import "./interfaces/IMOPNGovernance.sol";
import "./interfaces/IMOPN.sol";
import "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";
import "@openzeppelin/contracts/utils/Multicall.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract MOPNBomb is ERC1155, Multicall, Ownable {
    string public name;
    string public symbol;

    IMOPNGovernance governance;

    mapping(uint256 => string) private _uris;

    constructor(address governance_) ERC1155("") {
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

    function mint(
        address to,
        uint256 id,
        uint256 amount
    ) public onlyGovernance {
        _mint(to, id, amount, "");
    }

    function burn(
        address from,
        uint256 id,
        uint256 amount
    ) public onlyGovernance {
        _burn(from, id, amount);
    }

    function _beforeTokenTransfer(
        address,
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory
    ) internal virtual override {
        IMOPN mopn = IMOPN(governance.mopnContract());
        for (uint256 i = 0; i < ids.length; i++) {
            if (ids[i] == 2) {
                if (mopn.getAccountCoordinate(from) > 0) {
                    mopn.subMOPNPoint(
                        from,
                        getAccountCollection(from),
                        amounts[i]
                    );
                }
                if (mopn.getAccountCoordinate(to) > 0) {
                    mopn.addMOPNPoint(to, getAccountCollection(to), amounts[i]);
                }
            }
        }
    }

    function getAccountCollection(
        address account
    ) public view returns (address collectionAddress) {
        (, collectionAddress, ) = IERC6551Account(payable(account)).token();
    }

    modifier onlyGovernance() {
        require(msg.sender == address(governance), "not allowed");
        _;
    }
}
