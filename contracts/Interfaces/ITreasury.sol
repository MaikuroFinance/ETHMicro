// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev Interface of the Treasury Contract
 */
interface ITreasury {
    function deposit() payable external;

    function withdraw(uint amount) payable external;
}