// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./Interfaces/IETHKey.sol";
import "./Interfaces/ITreasury.sol";
import "./Interfaces/IRegistry.sol";
import "./Interfaces/IETHMicro.sol";
import "./Dependencies/Context.sol";
import "./Dependencies/DSMath.sol";
import "./Dependencies/Base.sol";

pragma solidity ^0.8.0;

contract ETHKey is IETHKey, Context, DSMath {
    mapping(address => uint256) private _balances;
    mapping(address => uint256) private _rates;

    mapping(address => mapping(address => uint256)) private _allowances;

    uint256 private _totalSupply;
    string private _name = "ETH Key";
    string private _symbol = "ETHKEY";

    uint256 private globalRate;
    int256 private initializationCount;

    IETHMicro public ethmi;
    IRegistry public registry;
    ITreasury public treasury;

    /**
     * @dev Sets the values for {name} and {symbol}.
     *
     * The default value of {decimals} is 18. To select a different value for
     * {decimals} you should overload it.
     *
     * All two of these values are immutable: they can only be set once during
     * construction.
     */
    constructor() {
        globalRate = 0;
        initializationCount = 0;
    }

    function initializeContract(address ethmiAddress, address treasuryAddress) external {
        require(
            initializationCount == 0,
            "Contract can only be initialized once"
        );
        ethmi = IETHMicro(ethmiAddress);
        treasury = ITreasury(treasuryAddress);
        initializationCount += 1;
    }

    function mint(
        address account,
        uint256 amount,
        uint256 mintFee
    ) external override onlyTreasury {
        assert(account != address(0));

        _mint(account, amount, mintFee);
        emit Transfer(address(0), account, amount);
    }

    function burn(address account, uint256 amount)
        external
        override
        onlyTreasury
    {
        assert(account != address(0));
        _burn(account, amount);
        emit Transfer(account, address(0), amount);
    }

    /**
     * @dev Returns the name of the token.
     */
    function name() public view virtual returns (string memory) {
        return _name;
    }

    /**
     * @dev Returns the symbol of the token, usually a shorter version of the
     * name.
     */
    function symbol() public view virtual returns (string memory) {
        return _symbol;
    }

    /**
     * @dev Returns the number of decimals used to get its user representation.
     * For example, if `decimals` equals `2`, a balance of `505` tokens should
     * be displayed to a user as `5.05` (`505 / 10 ** 2`).
     *
     * Tokens usually opt for a value of 18, imitating the relationship between
     * Ether and Wei. This is the value {ERC20} uses, unless this function is
     * overridden;
     *
     * NOTE: This information is only used for _display_ purposes: it in
     * no way affects any of the arithmetic of the contract, including
     * {IERC20-balanceOf} and {IERC20-transfer}.
     */
    function decimals() public view virtual returns (uint8) {
        return 18;
    }

    /**
     * @dev See {IERC20-totalSupply}.
     */
    function totalSupply() public view virtual override returns (uint256) {
        return _totalSupply;
    }

    function getRate(address account) public view returns (uint256) {
        return (globalRate - _rates[account]);
    }

    function setRate(uint256 amount) public override onlyETHMI {
        _setRate(amount);
    }

    function getRewardsBalance(address account) public view returns (uint256) {
        return wmul(_balances[account], (globalRate - _rates[account]));
    }

    function getGlobalRate() public view returns (uint256) {
        return globalRate;
    }

    /**
     * @dev See {IERC20-balanceOf}.
     */
    function balanceOf(address account)
        public
        view
        virtual
        override
        returns (uint256)
    {
        return _balances[account];
    }

    /**
     * @dev See {IERC20-transfer}.
     *
     * Requirements:
     *
     * - `recipient` cannot be the zero address.
     * - the caller must have a balance of at least `amount`.
     */
    function transfer(address recipient, uint256 amount)
        public
        virtual
        override
        returns (bool)
    {
        _transfer(_msgSender(), recipient, amount);
        return true;
    }

    /**
     * @dev See {IERC20-allowance}.
     */
    function allowance(address owner, address spender)
        public
        view
        virtual
        override
        returns (uint256)
    {
        return _allowances[owner][spender];
    }

    /**
     * @dev See {IERC20-approve}.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function approve(address spender, uint256 amount)
        public
        virtual
        override
        returns (bool)
    {
        _approve(_msgSender(), spender, amount);
        return true;
    }

    /**
     * @dev See {IERC20-transferFrom}.
     *
     * Emits an {Approval} event indicating the updated allowance. This is not
     * required by the EIP. See the note at the beginning of {ERC20}.
     *
     * Requirements:
     *
     * - `sender` and `recipient` cannot be the zero address.
     * - `sender` must have a balance of at least `amount`.
     * - the caller must have allowance for ``sender``'s tokens of at least
     * `amount`.
     */
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) public virtual override returns (bool) {
        _transfer(sender, recipient, amount);

        uint256 currentAllowance = _allowances[sender][_msgSender()];
        require(
            currentAllowance >= amount,
            "ERC20: transfer amount exceeds allowance"
        );
        unchecked {
            _approve(sender, _msgSender(), currentAllowance - amount);
        }

        return true;
    }

    /**
     * @dev Atomically increases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to {approve} that can be used as a mitigation for
     * problems described in {IERC20-approve}.
     *
     * Emits an {Approval} event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function increaseAllowance(address spender, uint256 addedValue)
        public
        virtual
        returns (bool)
    {
        _approve(
            _msgSender(),
            spender,
            _allowances[_msgSender()][spender] + addedValue
        );
        return true;
    }

    /**
     * @dev Atomically decreases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to {approve} that can be used as a mitigation for
     * problems described in {IERC20-approve}.
     *
     * Emits an {Approval} event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     * - `spender` must have allowance for the caller of at least
     * `subtractedValue`.
     */
    function decreaseAllowance(address spender, uint256 subtractedValue)
        public
        virtual
        returns (bool)
    {
        uint256 currentAllowance = _allowances[_msgSender()][spender];
        require(
            currentAllowance >= subtractedValue,
            "ERC20: decreased allowance below zero"
        );
        unchecked {
            _approve(_msgSender(), spender, currentAllowance - subtractedValue);
        }

        return true;
    }

    /**
     * @dev sets new globalRate with `amount`.
     *
     * This internal function is used to set the global rate
     *
     *
     * Requirements:
     *
     * - `amount` must be positive.
     */
    function _setRate(uint256 amount) internal virtual {
        (globalRate += wdiv(amount, _totalSupply));
    }

    /**
     * @dev Moves `amount` of tokens from `sender` to `recipient`.
     *
     * This internal function is equivalent to {transfer}, and can be used to
     * e.g. implement automatic token fees, slashing mechanisms, etc.
     *
     * Emits a {Transfer} event.
     *
     * Requirements:
     *
     * - `sender` cannot be the zero address.
     * - `recipient` cannot be the zero address.
     * - `sender` must have a balance of at least `amount`.
     */
    function _transfer(
        address sender,
        address recipient,
        uint256 amount
    ) internal virtual {
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != sender, "ERC20: recipient cannot be the same as sender");
        require(recipient != address(0), "ERC20: transfer to the zero address");

        uint256 senderBalance = _balances[sender];
        require(
            senderBalance >= amount,
            "ERC20: transfer amount exceeds balance"
        );


        if (_rates[recipient] == 0 && _balances[recipient] == 0) {
            _rates[recipient] = globalRate;
        }

        uint256 senderEffectiveRate = (globalRate - _rates[sender]);
        uint256 recipientBalance = _balances[recipient];
        uint256 senderRewards = wmul(senderEffectiveRate, amount);

        uint256 effectiveSupply;
        uint256 senderReceiverBalances = senderBalance + recipientBalance;
        uint256 capitalAdjustment;

        //If the receiver and sender are the only holders of ETHKey
        //Then we dont move any rates and just burn the rewards
        if (senderReceiverBalances >= _totalSupply) {
            effectiveSupply = 0;
            capitalAdjustment = 0;
        } else {
            effectiveSupply = _totalSupply - senderReceiverBalances;
            capitalAdjustment = wdiv(senderRewards, effectiveSupply);
        }

        _balances[recipient] += amount;
        _balances[sender] -= amount;

        globalRate += capitalAdjustment;
        _rates[recipient] += capitalAdjustment;

        if (_balances[sender] != 0) {
            _rates[sender] += capitalAdjustment;
        } else {
            _rates[sender] = globalRate;
        }

        emit Transfer(sender, recipient, amount);
    }

    /** @dev Creates `amount` tokens and assigns them to `account`, increasing
     * the total supply.
     *
     * Emits a {Transfer} event with `from` set to the zero address.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     */
    function _mint(
        address account,
        uint256 amount,
        uint256 mintFee
    ) internal virtual {
        require(account != address(0), "ERC20: mint to the zero address");
        require(amount != 0, "You cannot mint 0 tokens");

        uint256 accountBalance = _balances[account];
        if (_rates[account] == 0 && accountBalance == 0) {
            _rates[account] = globalRate;
        }

        uint256 capitalAdjustment;
        uint256 tempGlobalRate = globalRate;



        uint256 effectiveRate = tempGlobalRate - _rates[account];
        uint256 effectiveSupply = _totalSupply - accountBalance;
        uint256 rewards = wmul(accountBalance, effectiveRate);

        if (effectiveSupply != 0) {
            capitalAdjustment = wdiv((mintFee), effectiveSupply);
        } else {
            if (_totalSupply == 0) {
                capitalAdjustment = wdiv((mintFee), amount);
            } else {
                capitalAdjustment= wdiv((mintFee), _totalSupply);
            }
        }
        
        tempGlobalRate += capitalAdjustment;
        accountBalance += amount;

        if (rewards != 0) {
            _rates[account] = tempGlobalRate - wdiv(rewards, accountBalance);
        } else {
            _rates[account] = tempGlobalRate;
        }

        _totalSupply += (amount);
        _balances[account] = (accountBalance);
        globalRate = tempGlobalRate;

        emit Transfer(address(0), account, amount);
    }

    /**
     * @dev Destroys `amount` tokens from `account`, reducing the
     * total supply.
     *
     * Emits a {Transfer} event with `to` set to the zero address.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     * - `account` must have at least `amount` tokens.
     */
    function _burn(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: burn from the zero address");

        require(
            _balances[account] >= amount,
            "ERC20: burn amount exceeds balance"
        );

        //Temporary variables for rates and rewards amounts
        uint256 tempGlobalRate = globalRate;
        uint256 tempRate = _rates[account];
        uint256 effectiveRate = tempGlobalRate - tempRate;
        uint256 effectiveRewardsAmount = wmul(amount, effectiveRate);

        //Update balances
        _balances[account] -= amount;
        _totalSupply -= amount;

        //figure redemption fee, get effective supply and figure capital adjustment
        uint256 redemptionFee = (effectiveRewardsAmount / 10);
        uint256 effectiveSupply = (_totalSupply - _balances[account]);
        uint256 capitalAdjustment;
        if (effectiveSupply != 0) {
            capitalAdjustment = wdiv(redemptionFee, effectiveSupply);
        } else {
            capitalAdjustment = 0;
        }

        //Update global rate by capital adjustment to distribute rewards
        tempGlobalRate += capitalAdjustment;


        //If the account balance is over 0 then update their rate accordingly to keep their same effective rate
        //If it is 0 then reset their effective rate to 0
        if (_balances[account] != 0) {
            _rates[account] += capitalAdjustment;
        } else {
            _rates[account] = tempGlobalRate;
        }

        globalRate = tempGlobalRate;
        //Finally transfer out the rewards
        ethmi.transferRewards(account, (effectiveRewardsAmount - redemptionFee));

        emit Transfer(account, address(0), amount);
    }

    /**
     * @dev Sets `amount` as the allowance of `spender` over the `owner` s tokens.
     *
     * This internal function is equivalent to `approve`, and can be used to
     * e.g. set automatic allowances for certain subsystems, etc.
     *
     * Emits an {Approval} event.
     *
     * Requirements:
     *
     * - `owner` cannot be the zero address.
     * - `spender` cannot be the zero address.
     */
    function _approve(
        address owner,
        address spender,
        uint256 amount
    ) internal virtual {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    /**
     * @dev Ensure that msg.sender === Treasury contract address.
     */
    modifier onlyTreasury() {
        require(msg.sender == address(treasury), "Access Denied");
        _;
    }

    /**
     * @dev Ensure that msg.sender === ETHMI contract address.
     */
    modifier onlyETHMI() {
        require(msg.sender == address(ethmi), "Access Denied");
        _;
    }
}
