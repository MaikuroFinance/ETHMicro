// SPDX-License-Identifier: MIT

import "./Dependencies/Context.sol";
import "./Dependencies/DSMath.sol";
import "./Interfaces/IETHKey.sol";
import "./Interfaces/IETHMicro.sol";
import "./Interfaces/IRegistry.sol";

pragma solidity ^0.8.0;

contract Treasury is Context, DSMath {
    uint256 private initializationCount;
    uint256 private excessETHKeySupply;

    IETHMicro public ethmi;
    IETHKey public ethKey;
    IRegistry public registry;

    constructor(uint256 excess) {
        initializationCount = 0;
        excessETHKeySupply = excess;
    }

    event Deposit(address indexed _from, uint256 _ethmi, uint256 _ethKey);

    event Withdrawl(address indexed _to, uint256 _ether);

    //Initialize initial addresses and then lock it forever
    function initializeContract(address ethmiAddress, address ethKeyAddress) external {
        require(
            initializationCount == 0,
            "Contract can only be initialized once"
        );

        //initialize ethmi contract
        ethmi = IETHMicro(ethmiAddress);

        //initialize ethKey contract
        ethKey = IETHKey(ethKeyAddress);

        initializationCount += 1;
    }

    function getExcessETHKey() external view returns (uint256){
        return excessETHKeySupply;
    }

    function deposit() external payable {
        uint256 tokenCount = (msg.value * 1000);

        uint256 depositTxFee = (tokenCount * 2) / 100;

        ethmi.mint(msg.sender, tokenCount, depositTxFee);

        if (excessETHKeySupply > 0) {
            uint256 tier1 = 85000000 ether;
            uint256 tier3 = 4;
            uint256 tier4 = 3;
            uint256 tier5 = 2;
            if (
                excessETHKeySupply <= 100000000 ether &&
                excessETHKeySupply > 15000000 ether
            ) {
                ethKey.mint(msg.sender, tokenCount + tier1, depositTxFee);
                excessETHKeySupply -= tier1;
            } else if (
                excessETHKeySupply <= 15000000 ether &&
                excessETHKeySupply > 10000000 ether
            ) {
                ethKey.mint(msg.sender, tokenCount * tier3, depositTxFee);
                excessETHKeySupply -= ((tokenCount * tier3) - tokenCount);
            } else if (
                excessETHKeySupply <= 10000000 ether &&
                excessETHKeySupply > 5000000 ether
            ) {
                ethKey.mint(msg.sender, tokenCount * tier4, depositTxFee);
                excessETHKeySupply -= ((tokenCount * tier4) - tokenCount);
            }
            else if (
                excessETHKeySupply <= 5000000 ether &&
                excessETHKeySupply > 0 ether
            ) {
                if (excessETHKeySupply >= ((tokenCount * tier5) - tokenCount)) {
                    ethKey.mint(msg.sender, tokenCount * tier5, depositTxFee);
                    excessETHKeySupply -= ((tokenCount * tier5) - tokenCount);
                } else {
                    ethKey.mint(msg.sender, tokenCount + excessETHKeySupply, depositTxFee);
                    excessETHKeySupply = 0;
                }
            }
        } else {
            ethKey.mint(msg.sender, tokenCount, depositTxFee);
        }

        emit Deposit(msg.sender, (tokenCount - depositTxFee), tokenCount);
    }

    function withdraw(uint256 amount) external {
        address payable sender = payable(msg.sender);

        require(
            ethmi.balanceOf(sender) >= amount,
            "Insufficient ETH Micro balance"
        );
        require(
            ethKey.balanceOf(sender) >= amount,
            "Insufficient ETH Key Balance"
        );

        ethmi.burn(sender, amount);
        ethKey.burn(sender, amount);

        sender.transfer(amount / 1000);

        emit Withdrawl(sender, (amount / 1000));
    }
}
