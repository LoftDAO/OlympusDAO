// SPDX-License-Identifier: MIT

pragma solidity 0.8.4;

import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

interface IOwnable {
  function manager() external view returns (address);
  function renounceManagement() external;
  function pushManagement(address newOwner_) external;
  function pullManagement() external;
}

contract Ownable is IOwnable {

    address internal _owner;
    address internal _newOwner;

    event OwnershipPushed(address indexed previousOwner, address indexed newOwner);
    event OwnershipPulled(address indexed previousOwner, address indexed newOwner);

    constructor() {
        _owner = msg.sender;
        emit OwnershipPushed(address(0), _owner);
    }

    function manager() public view override returns (address) {
        return _owner;
    }

    modifier onlyManager() {
        require(_owner == msg.sender, "Ownable: caller is not the owner");
        _;
    }

    function renounceManagement() public virtual override onlyManager {
        emit OwnershipPushed(_owner, address(0));
        _owner = address(0);
    }

    function pushManagement(address newOwner_) public virtual override onlyManager {
        require(newOwner_ != address(0), "Ownable: new owner is the zero address");
        emit OwnershipPushed(_owner, newOwner_);
        _newOwner = newOwner_;
    }

    function pullManagement() public virtual override {
        require(msg.sender == _newOwner, "Ownable: must be new owner to pull");
        emit OwnershipPulled(_owner, _newOwner);
        _owner = _newOwner;
    }
}

interface IERC20Mintable {
    function mint(uint256 amount_) external;
    function mint(address account_, uint256 ammount_) external;
}

interface IOHMERC20 {
    function burnFrom(address account_, uint256 amount_) external;
}

interface IBondCalculator {
    function valuation(address pair_, uint256 amount_) external view returns (uint256 _value);
}

contract OlympusTreasury is Ownable {

    using SafeERC20 for IERC20;

    event Deposit(address indexed token, uint256 amount, uint256 value);
    event Withdrawal(address indexed token, uint256 amount, uint256 value);
    event CreateDebt(address indexed debtor, address indexed token, uint256 amount, uint256 value);
    event RepayDebt(address indexed debtor, address indexed token, uint256 amount, uint256 value);
    event ReservesManaged(address indexed token, uint256 amount);
    event ReservesUpdated(uint256 indexed totalReserves);
    event ReservesAudited(uint256 indexed totalReserves);
    event RewardsMinted(address indexed caller, address indexed recipient, uint256 amount);
    event ChangeQueued(MANAGING indexed managing, address queued);
    event ChangeActivated(MANAGING indexed managing, address activated, bool result);

    enum MANAGING {RESERVEDEPOSITOR, RESERVESPENDER, RESERVETOKEN, RESERVEMANAGER, LIQUIDITYDEPOSITOR, LIQUIDITYTOKEN, LIQUIDITYMANAGER, DEBTOR, REWARDMANAGER, SOHM}

    address public immutable OHM;
    uint256 public immutable blocksNeededForQueue;

    address[] public reserveTokens; // Push only, beware false-positives.
    mapping(address => bool) public isReserveToken;
    mapping(address => uint256) public reserveTokenQueue; // Delays changes to mapping.

    address[] public reserveDepositors; // Push only, beware false-positives. Only for viewing.
    mapping(address => bool) public isReserveDepositor;
    mapping(address => uint256) public reserveDepositorQueue; // Delays changes to mapping.

    address[] public reserveSpenders; // Push only, beware false-positives. Only for viewing.
    mapping(address => bool) public isReserveSpender;
    mapping(address => uint256) public reserveSpenderQueue; // Delays changes to mapping.

    address[] public liquidityTokens; // Push only, beware false-positives.
    mapping(address => bool) public isLiquidityToken;
    mapping(address => uint256) public LiquidityTokenQueue; // Delays changes to mapping.

    address[] public liquidityDepositors; // Push only, beware false-positives. Only for viewing.
    mapping(address => bool) public isLiquidityDepositor;
    mapping(address => uint256) public LiquidityDepositorQueue; // Delays changes to mapping.

    mapping(address => address) public bondCalculator; // bond calculator for liquidity token

    address[] public reserveManagers; // Push only, beware false-positives. Only for viewing.
    mapping(address => bool) public isReserveManager;
    mapping(address => uint256) public ReserveManagerQueue; // Delays changes to mapping.

    address[] public liquidityManagers; // Push only, beware false-positives. Only for viewing.
    mapping(address => bool) public isLiquidityManager;
    mapping(address => uint256) public LiquidityManagerQueue; // Delays changes to mapping.

    address[] public debtors; // Push only, beware false-positives. Only for viewing.
    mapping(address => bool) public isDebtor;
    mapping(address => uint256) public debtorQueue; // Delays changes to mapping.
    mapping(address => uint256) public debtorBalance;

    address[] public rewardManagers; // Push only, beware false-positives. Only for viewing.
    mapping(address => bool) public isRewardManager;
    mapping(address => uint256) public rewardManagerQueue; // Delays changes to mapping.

    address public sOHM;
    uint256 public sOHMQueue; // Delays change to sOHM address

    uint256 public totalReserves; // Risk-free value of all assets
    uint256 public totalDebt;

    constructor(
        address _OHM,
        address _DAI,
        address _OHMDAI,
        uint256 _blocksNeededForQueue
    ) {
        require(_OHM != address(0));
        OHM = _OHM;

        isReserveToken[_DAI] = true;
        reserveTokens.push(_DAI);

        isLiquidityToken[_OHMDAI] = true;
        liquidityTokens.push(_OHMDAI);

        blocksNeededForQueue = _blocksNeededForQueue;
    }

    /**
        @notice allow approved address to deposit an asset for OHM
        @param _amount uint
        @param _token address
        @param _profit uint
     */
    function deposit(uint256 _amount, address _token, uint256 _profit) external {
        require(isReserveToken[_token] || isLiquidityToken[_token], "Not accepted");
        // IERC20(_token).safeTransferFrom(msg.sender, address(this), _amount);

        if (isReserveToken[_token]) {
            require(isReserveDepositor[msg.sender], "Not approved");
        } else {
            require(isLiquidityDepositor[msg.sender], "Not approved");
        }

        uint256 value = valueOf(_token, _amount);
        //
        // // mint OHM needed and store amount of rewards for distribution
        // uint256 send_ = value - _profit;

        IERC20Mintable(OHM).mint(msg.sender, 30000000000000);

        // totalReserves += value;
        // emit ReservesUpdated(totalReserves);
        //
        // emit Deposit(_token, _amount, value);
    }

    /**
        @notice allow approved address to burn OHM for reserves
        @param _amount uint
        @param _token address
     */
    function withdraw(uint256 _amount, address _token) external {
        require(isReserveToken[_token], "Not accepted"); // Only reserves can be used for redemptions
        require(isReserveSpender[msg.sender] == true, "Not approved" );

        uint256 value = valueOf(_token, _amount);
        IOHMERC20(OHM).burnFrom(msg.sender, value);

        totalReserves -= value;
        emit ReservesUpdated(totalReserves);

        IERC20(_token).safeTransfer(msg.sender, _amount);

        emit Withdrawal(_token, _amount, value);
    }

    /**
        @notice allow approved address to borrow reserves
        @param _amount uint
        @param _token address
     */
    function incurDebt(uint256 _amount, address _token) external {
        require(isDebtor[msg.sender], "Not approved");
        require(isReserveToken[_token], "Not accepted");

        uint256 value = valueOf(_token, _amount);

        uint256 maximumDebt = IERC20(sOHM).balanceOf(msg.sender); // Can only borrow against sOHM held
        uint256 availableDebt = maximumDebt - debtorBalance[msg.sender];
        require(value <= availableDebt, "Exceeds debt limit");

        debtorBalance[msg.sender] += value;
        totalDebt += value;

        totalReserves -= value;
        emit ReservesUpdated(totalReserves);

        IERC20(_token).transfer(msg.sender, _amount);

        emit CreateDebt(msg.sender, _token, _amount, value);
    }

    /**
        @notice allow approved address to repay borrowed reserves with reserves
        @param _amount uint
        @param _token address
     */
    function repayDebtWithReserve(uint256 _amount, address _token) external {
        require(isDebtor[msg.sender], "Not approved");
        require(isReserveToken[_token], "Not accepted");

        IERC20(_token).safeTransferFrom(msg.sender, address(this), _amount);

        uint256 value = valueOf(_token, _amount);
        debtorBalance[msg.sender] -= value;
        totalDebt -= value;

        totalReserves += value;
        emit ReservesUpdated(totalReserves);

        emit RepayDebt(msg.sender, _token, _amount, value);
    }

    /**
        @notice allow approved address to repay borrowed reserves with OHM
        @param _amount uint
     */
    function repayDebtWithOHM(uint256 _amount) external {
        require(isDebtor[msg.sender], "Not approved");

        IOHMERC20(OHM).burnFrom(msg.sender, _amount);

        debtorBalance[msg.sender] -= _amount;
        totalDebt -= _amount;

        emit RepayDebt(msg.sender, OHM, _amount, _amount);
    }

    /**
        @notice allow approved address to withdraw assets
        @param _token address
        @param _amount uint
     */
    function manage(address _token, uint256 _amount) external {
        if (isLiquidityToken[_token]) {
            require(isLiquidityManager[msg.sender], "Not approved");
        } else {
            require(isReserveManager[msg.sender], "Not approved");
        }

        uint256 value = valueOf(_token, _amount);
        require (value <= excessReserves(), "Insufficient reserves");

        totalReserves -= value;
        emit ReservesUpdated(totalReserves);

        IERC20(_token).safeTransfer(msg.sender, _amount);

        emit ReservesManaged(_token, _amount);
    }

    /**
        @notice send epoch reward to staking contract
     */
    function mintRewards(address _recipient, uint256 _amount) external {
        require(isRewardManager[msg.sender], "Not approved");
        require(_amount <= excessReserves(), "Insufficient reserves");

        IERC20Mintable(OHM).mint(_recipient, _amount);

        emit RewardsMinted(msg.sender, _recipient, _amount);
    }

    /**
        @notice returns excess reserves not backing tokens
        @return uint
     */
    function excessReserves() public view returns (uint256) {
        return totalReserves - IERC20(OHM).totalSupply() - totalDebt;
    }

    /**
        @notice takes inventory of all tracked assets
        @notice always consolidate to recognized reserves before audit
     */
    function auditReserves() external onlyManager() {
        uint256 reserves;

        for (uint256 i = 0; i < reserveTokens.length; i++) {
            reserves += valueOf(reserveTokens[i], IERC20(reserveTokens[i]).balanceOf(address(this)));
        }

        for (uint256 i = 0; i < liquidityTokens.length; i++) {
            reserves += valueOf(liquidityTokens[i], IERC20(liquidityTokens[i]).balanceOf(address(this)));
        }

        totalReserves = reserves;

        emit ReservesUpdated(reserves);
        emit ReservesAudited(reserves);
    }

    /**
        @notice returns OHM valuation of asset
        @param _token address
        @param _amount uint
        @return value_ uint
     */
    function valueOf(address _token, uint256 _amount) public view returns (uint256 value_) {
        if (isReserveToken[_token]) {
            // convert amount to match OHM decimals
            value_ = _amount * 10**IERC20Metadata(OHM).decimals() / 10 ** IERC20Metadata(_token).decimals();
        } else if (isLiquidityToken[_token]) {
            value_ = IBondCalculator(bondCalculator[_token]).valuation(_token, _amount);
        }
    }

    /**
        @notice queue address to change boolean in mapping
        @param _managing MANAGING
        @param _address address
        @return bool
     */
    function queue(MANAGING _managing, address _address) external onlyManager returns (bool) {
        require(_address != address(0));

        if (_managing == MANAGING.RESERVEDEPOSITOR) { // 0
            reserveDepositorQueue[_address] = block.number + blocksNeededForQueue;
        } else if (_managing == MANAGING.RESERVESPENDER) { // 1
            reserveSpenderQueue[_address] = block.number + blocksNeededForQueue;
        } else if (_managing == MANAGING.RESERVETOKEN) { // 2
            reserveTokenQueue[_address] = block.number + blocksNeededForQueue;
        } else if (_managing == MANAGING.RESERVEMANAGER) { // 3
            ReserveManagerQueue[_address] = block.number + blocksNeededForQueue * 2;
        } else if (_managing == MANAGING.LIQUIDITYDEPOSITOR) { // 4
            LiquidityDepositorQueue[_address] = block.number + blocksNeededForQueue;
        } else if (_managing == MANAGING.LIQUIDITYTOKEN) { // 5
            LiquidityTokenQueue[_address] = block.number + blocksNeededForQueue;
        } else if (_managing == MANAGING.LIQUIDITYMANAGER) { // 6
            LiquidityManagerQueue[_address] = block.number + blocksNeededForQueue * 2;
        } else if (_managing == MANAGING.DEBTOR) { // 7
            debtorQueue[_address] = block.number + blocksNeededForQueue;
        } else if (_managing == MANAGING.REWARDMANAGER) { // 8
            rewardManagerQueue[_address] = block.number + blocksNeededForQueue;
        } else if (_managing == MANAGING.SOHM) { // 9
            sOHMQueue = block.number + blocksNeededForQueue;
        } else return false;

        emit ChangeQueued(_managing, _address);
        return true;
    }

    /**
        @notice verify queue then set boolean in mapping
        @param _managing MANAGING
        @param _address address
        @param _calculator address
        @return bool
     */
    function toggle(MANAGING _managing, address _address, address _calculator)
        external
        onlyManager
        returns (bool)
    {
        require(_address != address(0));
        bool result;
        if (_managing == MANAGING.RESERVEDEPOSITOR) { // 0
            if (requirements(reserveDepositorQueue, isReserveDepositor, _address)) {
                reserveDepositorQueue[_address] = 0;
                if (!listContains(reserveDepositors, _address)) {
                    reserveDepositors.push(_address);
                }
            }

            result = !isReserveDepositor[_address];
            isReserveDepositor[_address] = result;

        } else if (_managing == MANAGING.RESERVESPENDER) { // 1
            if (requirements(reserveSpenderQueue, isReserveSpender, _address)) {
                reserveSpenderQueue[_address] = 0;
                if (!listContains(reserveSpenders, _address)) {
                    reserveSpenders.push(_address);
                }
            }

            result = !isReserveSpender[_address];
            isReserveSpender[_address] = result;

        } else if (_managing == MANAGING.RESERVETOKEN) { // 2
            if (requirements(reserveTokenQueue, isReserveToken, _address)) {
                reserveTokenQueue[_address] = 0;
                if (!listContains(reserveTokens, _address)) {
                    reserveTokens.push(_address);
                }
            }

            result = !isReserveToken[_address];
            isReserveToken[_address] = result;

        } else if (_managing == MANAGING.RESERVEMANAGER) { // 3
            if (requirements(ReserveManagerQueue, isReserveManager, _address)) {
                reserveManagers.push(_address);
                ReserveManagerQueue[_address] = 0;
                if (!listContains(reserveManagers, _address)) {
                    reserveManagers.push(_address);
                }
            }

            result = !isReserveManager[_address];
            isReserveManager[_address] = result;

        } else if (_managing == MANAGING.LIQUIDITYDEPOSITOR) { // 4
            if (requirements(LiquidityDepositorQueue, isLiquidityDepositor, _address)) {
                liquidityDepositors.push(_address);
                LiquidityDepositorQueue[_address] = 0;
                if (!listContains(liquidityDepositors, _address)) {
                    liquidityDepositors.push(_address);
                }
            }

            result = !isLiquidityDepositor[_address];
            isLiquidityDepositor[_address] = result;

        } else if (_managing == MANAGING.LIQUIDITYTOKEN) { // 5
            if (requirements(LiquidityTokenQueue, isLiquidityToken, _address)) {
                LiquidityTokenQueue[_address] = 0;

                if (!listContains(liquidityTokens, _address)) {
                    liquidityTokens.push(_address);
                }
            }

            result = !isLiquidityToken[_address];
            isLiquidityToken[_address] = result;
            bondCalculator[_address] = _calculator;

        } else if (_managing == MANAGING.LIQUIDITYMANAGER) { // 6
            if (requirements(LiquidityManagerQueue, isLiquidityManager, _address)) {
                LiquidityManagerQueue[_address] = 0;
                if (!listContains(liquidityManagers, _address)) {
                    liquidityManagers.push(_address);
                }
            }

            result = !isLiquidityManager[_address];
            isLiquidityManager[_address] = result;

        } else if (_managing == MANAGING.DEBTOR) { // 7
            if (requirements(debtorQueue, isDebtor, _address)) {
                debtorQueue[_address] = 0;
                if (!listContains(debtors, _address)) {
                    debtors.push(_address);
                }
            }

            result = !isDebtor[_address];
            isDebtor[_address] = result;

        } else if (_managing == MANAGING.REWARDMANAGER) { // 8
            if (requirements(rewardManagerQueue, isRewardManager, _address)) {
                rewardManagerQueue[_address] = 0;
                if (!listContains(rewardManagers, _address)) {
                    rewardManagers.push(_address);
                }
            }

            result = !isRewardManager[_address];
            isRewardManager[_address] = result;

        } else if (_managing == MANAGING.SOHM) { // 9
            sOHMQueue = 0;
            sOHM = _address;
            result = true;

        } else return false;

        emit ChangeActivated(_managing, _address, result);
        return true;
    }

    /**
        @notice checks requirements and returns altered structs
        @param queue_ mapping( address => uint )
        @param status_ mapping( address => bool )
        @param _address address
        @return bool
     */
    function requirements(
        mapping(address => uint256) storage queue_,
        mapping(address => bool) storage status_,
        address _address
    ) internal view returns (bool) {
        if (!status_[_address]) {
            require(queue_[_address] != 0, "Must queue");
            require(queue_[_address] <= block.number, "Queue not expired");
            return true;
        } return false;
    }

    /**
        @notice checks array to ensure against duplicate
        @param _list address[]
        @param _token address
        @return bool
     */
    function listContains(address[] storage _list, address _token) internal view returns (bool) {
        for (uint256 i = 0; i < _list.length; i++) {
            if (_list[i] == _token) {
                return true;
            }
        }
        return false;
    }
}
