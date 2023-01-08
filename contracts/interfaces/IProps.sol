// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

interface IProps {
    function useTo(
        uint256 propId,
        uint256 amount,
        uint256 x,
        uint256 y
    ) external;
}
