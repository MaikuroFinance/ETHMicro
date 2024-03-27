# ETH Micro


## System Overview
The ETH Micro ecosystem is compromised of two ERC20 tokens, a 100% collateralized ETH Micro token and ETH Key token. This provides a mechanism for arbitrage against ETH and a low-risk opportunity to earn yield in times of volatility. The goal of this project is to provide a completely decentralized way for ETH holders to benefit from volatility while providing arbitragers a unique trade opportunity between ETH, ETHMI, and ETHKEY

Documentation: https://docs.ethmicro.com

### Contracts
ETHMI - https://etherscan.io/address/0x9f35d0d0a2c46293adad9d16fd847445b100efb8  
ETHKEY - https://etherscan.io/address/0x43f07f1d52eb52ccca4601bac8b9d034465a3899  
Treasury - https://etherscan.io/address/0xc927768424cf6425df7f58fd31895d4d0f6eb9af  



## Main System Utilities
### Minting
Deposit ETH to mint 1000 to 1 ETHMI and 1000 to 1 ETHkey. Example 1 ETH = 1000 ETHMI and 1000 ETHkey. There is no minimum and no maximum amount that can be minted.

### Unlocking ETH
You must send equal amounts of ETHMI and ETHkey to unlock and redeem ETH from the treasury smart contract. Example: Sendong 1000 ETHMI and 1000 ETHkey will burn the tokens and send you back 1 ETH, plus any ETHMI locked in the ETHkey.

### ETHMI Total Supply
The total supply of ETHMI is 1000 times the ETH deposited in the contract. This ensures that ETH Micro is always collateralized and redeemable for ETH. It also prevents the bank-run issues that leveraged platforms must contend with.

### ETHkey Total Supply
The initial total supply of ETHkey is 100,000,000. This initial excess supply is intended to provide an early-adopter incentive with increased payouts and ensure there is adequate ETHKey liquidity for redemptions. In addition, the additional ETHKey supply will be 1000x the ETH deposited.

### ETHMI Transfer Fee
Every transaction of ETHMI has a fee of %0.625 which is deducted from the amount sent so sending 100 ETHMI would result in 99.375 ETHMI being delivered. 60% of this fee is sent to all ETHMI holders at an equal rate per ETHMI. 40% of the this fee is sent to all ETHKey holders at an equal rate per ETHKEY.

### Minting Fee
There is a 2% fee to create ETHkey when minting ETHMI. This 2% fee is distributed to all ETHKEY holders rewards balances at an equal rate per ETHKey.
Example: Send 1 ETH to mint 1000 ETHMI and 1000 ETHkey. Sending address receives 980 ETHMI (1000 - 2%( 20 ETHmi) = 980 ETHmi) and 1000 ETkey.

### ETHMI Balance Growth
The balance of an address holding ETHMI automatically grows from receiving a portion of the transaction fees in the network. 60% of the 0.625% transfer fee gets reflectively distributed to all address balances based on the percentage of total supply the address represents.

### ETHkey Pool Rewards
40% of the 0.625% ETHMI transfer fee is sent to the ETHkey reward pool. Each held ETHkey accumulates a redeemable portion of new ETHMI in the ETHkey rewards pool. The amount assigned to each ETHkey is based on the percentage of total supply each ETHkey represents at the time in the network. An address holding ETHkey can check the underlying balance of ETHMI by connecting to the ETHMI app. ETHMI that is assigned to ETHkey can be redeemed by unlocking ETH from the ETHMI smart contract.

### ETHKEY Transfer Impact on Rewards
Transferring ETHKEY will cause the rewards associated with the transferred tokens to be distributed among all other ETHKEY holders at the time. This is to reward holders of ETHKEY and ensure liquidity pools do not accumulate significant ETHKEY rewards.
