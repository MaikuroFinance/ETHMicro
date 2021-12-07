// SPDX-License-Identifier: MIT

import "./IERC20.sol";

pragma solidity ^0.8.0;

interface IETHMicro is IERC20 {
    // --- Events ---

    // --- Functions ---

    function mint(
        address _account,
        uint256 _amount,
        uint256 _mintFee
    ) external;

    function burn(address _account, uint256 _amount) external;

    function transferRewards(address recipient, uint256 amount)
        external
        returns (bool);
}
