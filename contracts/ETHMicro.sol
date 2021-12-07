// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./Interfaces/IETHMicro.sol";
import "./Interfaces/IRegistry.sol";
import "./Interfaces/IETHKey.sol";
import "./Dependencies/DSMath.sol";
import "./Interfaces/ITreasury.sol";
import "./Dependencies/Context.sol";
import "./Dependencies/Base.sol";

pragma solidity ^0.8.0;

contract ETHMicro is IETHMicro, Context, DSMath {
    mapping(address => uint256) private _balances;
    mapping(address => uint256) private _reflectedBalances;
    mapping(address => uint256) private _rates;

    mapping(address => mapping(address => uint256)) private _allowances;

    uint256 private _totalSupply;
    uint256 private globalRate;

    uint256 private initializationCount;

    IETHKey public ethKey;
    ITreasury public treasury;
    IRegistry public registry;

    string private _name = "ETH Micro";
    string private _symbol = "ETHMI";

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
        initializationCount = 0;
        globalRate = 1 ether;
    }

    function initializeContract(address ethKeyAddress, address treasuryAddress) external {
        require(
            initializationCount == 0,
            "Contract can only be initialized once"
        );
        ethKey = IETHKey(ethKeyAddress);
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
        if (account != address(ethKey) && account != address(this)) {
            return (globalRate - _rates[account]);
        } else {
            return 1 ether;
        }

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
        if (account == address(this) || account == address(ethKey)) {
            return _reflectedBalances[account];
        }
        return wmul(_balances[account], globalRate - _rates[account]);
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

    function transferRewards(address recipient, uint256 amount)
        public
        virtual
        override
        onlyETHKey
        returns (bool)
    {
        _transferRewards(address(ethKey), recipient, amount);
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
        require(
            _reflectedBalances[sender] >= amount,
            "ERC20: transfer amount exceeds balance"
        );

        uint256 senderRate = _rates[sender];
        uint256 recipientRate = _rates[recipient];
        if (recipientRate == 0 && _reflectedBalances[recipient] == 0) {
            recipientRate = globalRate - 1 ether;
        }

        uint256 contractBalance = _reflectedBalances[address(this)];
        uint256 ethKeyContractBalance = _reflectedBalances[address(ethKey)];

        uint256 txFee = amount / 160;
        uint256 microShare = (txFee / 100) * 60;
        uint256 keyShare = (txFee / 100) * 40;

        contractBalance += microShare;
        ethKeyContractBalance += keyShare;


        uint256 recipientBalance = _balances[recipient];
        uint256 senderBalance = _balances[sender];
        recipientBalance += (wdiv(( amount - txFee),(globalRate - recipientRate)));
        senderBalance -= wdiv(amount, (globalRate - senderRate));

        uint256 effectiveSupply = _totalSupply -
        contractBalance -
        ethKeyContractBalance - recipientBalance;

        if (senderBalance < effectiveSupply) {
            effectiveSupply -= senderBalance;
            globalRate +=  wdiv(microShare, effectiveSupply);
            recipientRate +=  wdiv(microShare, effectiveSupply);
            senderRate +=  wdiv(microShare, effectiveSupply);
        }


        ethKey.setRate(keyShare);
        _rates[sender] = senderRate;
        _rates[recipient] = recipientRate;


        _reflectedBalances[sender] -= amount;
        _balances[sender] = senderBalance;
        _balances[recipient] = recipientBalance;
        _reflectedBalances[recipient] += ((amount - txFee));
        _reflectedBalances[address(this)] = contractBalance;
        _reflectedBalances[address(ethKey)] = ethKeyContractBalance;

        emit Transfer(sender, recipient, amount);
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
    function _transferRewards(
        address sender,
        address recipient,
        uint256 amount
    ) internal virtual {
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");

        uint256 effectiveRate = globalRate - _rates[recipient];
        _balances[recipient] += wdiv(amount,effectiveRate);
        _reflectedBalances[recipient] += (amount);
        _reflectedBalances[sender] -= amount;
        
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
        require(account != address(0), "ERC20: cannot mint to the zero address");
        require(amount != 0, "Cannot mint 0 tokens");

        uint256 userAmount = amount - mintFee;
        
        if (_rates[account] == 0 && _reflectedBalances[account] == 0) {
            _rates[account] = globalRate - 1 ether;
        }

        uint256 effectiveRate = globalRate - _rates[account];
        _balances[account] += wdiv(userAmount,effectiveRate);
            
        _reflectedBalances[account] += userAmount;

        _reflectedBalances[address(ethKey)] += mintFee;

        _totalSupply += amount;

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
            _reflectedBalances[account] >= amount,
            "ERC20: burn amount exceeds balance"
        );

        uint256 baseAmount;
        uint256 tempRate = _rates[account];
        uint256 tempGlobalRate = globalRate;

        if (tempRate <= (tempGlobalRate - 1 ether)) {
            baseAmount = wdiv(amount, (tempGlobalRate - tempRate));
        } else {
            baseAmount = amount;
            tempRate = tempGlobalRate - 1 ether;
        }

        _reflectedBalances[account] -= amount;
        _balances[account] -= baseAmount;

        _reflectedBalances[address(this)] -= (amount - baseAmount);
        _totalSupply -= amount;

        if (_balances[account] == 0) {
            _rates[account] = globalRate - 1 ether;
        } else {
            _rates[account] = tempRate;
        }

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
     * @dev Ensure that msg.sender === ETHKey contract address.
     */
    modifier onlyETHKey() {
        require(msg.sender == address(ethKey), "Access Denied");
        _;
    }
}
