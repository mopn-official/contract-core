// SPDX-License-Identifier: GPL-3.0-only
pragma solidity ^0.8.21;

library Errors {
    error ReentrantCall();
    error ReentrantCallView();
    error NotDiamond();
}
