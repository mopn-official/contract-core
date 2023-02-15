// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

error linkAvatarError();
error TileHasEnemy();
error PassIdOverflow();
error PassIdTilesNotOpen();

import "./IArsenal.sol";
import "./IAvatar.sol";
import "./IBomb.sol";
import "./IEnergy.sol";
import "./IGovernance.sol";
import "./IMap.sol";
import "@openzeppelin/contracts/interfaces/IERC721.sol";
