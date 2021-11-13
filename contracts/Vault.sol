// SPDX-License-Identifier: MIT

pragma solidity 0.8.4;

import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";

interface IOwnable {
    function owner() external view returns (address);
    function renounceOwnership() external;
    function transferOwnership(address newOwner_) external;
}

interface IBondingCalculator {
    function calcDebtRatio(uint pendingDebtDue_, uint managedTokenTotalSupply_) external pure returns (uint debtRatio_);
    function calcBondPremium(uint debtRatio_, uint bondScalingFactor) external pure returns (uint premium_);
    function calcPrincipleValuation(uint k_, uint amountDeposited_, uint totalSupplyOfTokenDeposited_) external pure returns (uint principleValuation_);
    function principleValuation(address principleTokenAddress_, uint amountDeposited_) external view returns (uint principleValuation_);
    function calculateBondInterest(address treasury_, address principleTokenAddress_, uint amountDeposited_, uint bondScalingFactor) external returns (uint interestDue_);
}

/**
interface IPrincipleDepository {

  function getCurrentBondTerm() external returns ( uint, uint );

  function treasury() external returns ( address );

  function getBondCalculator() external returns ( address );

  function isPrincipleToken( address ) external returns ( bool );

  function getDepositorInfoForDepositor( address ) external returns ( uint, uint, uint );

  function addPrincipleToken( address newPrincipleToken_ ) external returns ( bool );

  function setTreasury( address newTreasury_ ) external returns ( bool );

  function addBondTerm( address bondPrincipleToken_, uint256 bondScalingFactor_, uint256 bondingPeriodInBlocks_ ) external returns ( bool );

  function getDepositorInfo( address depositorAddress_) external view returns ( uint principleAmount_, uint interestDue_, uint bondMaturationBlock_);

  function depositBondPrinciple( address bondPrincipleTokenToDeposit_, uint256 amountToDeposit_ ) external returns ( bool );

  function depositBondPrincipleWithPermit( address bondPrincipleTokenToDeposit_, uint256 amountToDeposit_, uint256 deadline, uint8 v, bytes32 r, bytes32 s ) external returns ( bool );

  function withdrawPrincipleAndForfeitInterest( address bondPrincipleToWithdraw_ ) external returns ( bool );

  function redeemBond(address bondPrincipleToRedeem_ ) external returns ( bool );
}
*/

interface ITreasury {
  function getBondingCalculator() external returns (address);
  // function payDebt( address depositor_ ) external returns ( bool );
  function getTimelockEndBlock() external returns (uint);
  function getManagedToken() external returns (address);
  // function getDebtAmountDue() external returns ( uint );
  // function incurDebt( uint principieTokenAmountDeposited_, uint bondScalingValue_ ) external returns ( bool );
}

contract Ownable is IOwnable {

    address internal _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    constructor () {
        _owner = msg.sender;
        emit OwnershipTransferred(address(0), _owner);
    }

    function owner() public view override returns (address) {
        return _owner;
    }

    modifier onlyOwner {
        require(_owner == msg.sender, "Ownable: caller is not the owner");
        _;
    }

    function renounceOwnership() public override onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    function transferOwnership(address newOwner_) public override onlyOwner {
        require(newOwner_ != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner_);
        _owner = newOwner_;
    }
}

interface IERC20Mintable {
    function mint(uint256 amount_) external;
    function mint(address account_, uint256 ammount_) external;
}

contract Vault is ITreasury, Ownable {

    using SafeERC20 for IERC20;

    event TimelockStarted(uint timelockEndBlock);

    bool public isInitialized;

    uint public timelockDurationInBlocks;
    bool public isTimelockSet;
    uint public override getTimelockEndBlock;

    address public daoWallet;
    address public LPRewardsContract;
    address public stakingContract;

    uint public LPProfitShare;

    uint public getPrincipleTokenBalance;

    address public override getManagedToken;
    address public getReserveToken;
    address public getPrincipleToken;

    address public override getBondingCalculator;

    mapping(address => bool) public isReserveToken;

    mapping(address => bool) public isPrincipleToken;

    mapping(address => bool) public isPrincipleDepositor;

    mapping(address => bool) public isReserveDepositor;

    modifier notInitialized {
        require(!isInitialized);
        _;
    }

    modifier onlyReserveToken(address reserveTokenChallenge_) {
        require(isReserveToken[reserveTokenChallenge_] == true, "Vault: reserveTokenChallenge_ is not a reserve Token.");
        _;
    }

    modifier onlyPrincipleToken(address PrincipleTokenChallenge_) {
        require(isPrincipleToken[PrincipleTokenChallenge_] == true, "Vault: PrincipleTokenChallenge_ is not a Principle token.");
        _;
    }

    modifier notTimelockSet {
        require(!isTimelockSet);
        _;
    }

    modifier isTimelockExpired {
        require(getTimelockEndBlock != 0);
        require(isTimelockSet);
        require(block.number >= getTimelockEndBlock);
        _;
    }

    modifier isTimelockStarted() {
        if (getTimelockEndBlock != 0) {
            emit TimelockStarted(getTimelockEndBlock);
        }
        _;
    }

    function setDAOWallet(address newDAOWallet_) external onlyOwner returns (bool) {
        daoWallet = newDAOWallet_;
        return true;
    }

    function setStakingContract(address newStakingContract_) external onlyOwner returns (bool) {
        stakingContract = newStakingContract_;
        return true;
    }

    function setLPRewardsContract(address newLPRewardsContract_) external onlyOwner returns (bool) {
        LPRewardsContract = newLPRewardsContract_;
        return true;
    }

    function setLPProfitShare(uint newDAOProfitShare_) external onlyOwner returns (bool) {
        LPProfitShare = newDAOProfitShare_;
        return true;
    }

    function initialize(
        address newManagedToken_,
        address newReserveToken_,
        address newBondingCalculator_,
        address newLPRewardsContract_
    )
        external
        onlyOwner
        notInitialized
        returns (bool)
    {
        getManagedToken = newManagedToken_;
        getReserveToken = newReserveToken_;
        isReserveToken[newReserveToken_] = true;
        getBondingCalculator = newBondingCalculator_;
        LPRewardsContract = newLPRewardsContract_;
        isInitialized = true;
        return true;
    }

    function setPrincipleToken(address newPrincipleToken_)
        external
        onlyOwner
        returns (bool)
    {
        getPrincipleToken = newPrincipleToken_;
        isPrincipleToken[newPrincipleToken_] = true;
        return true;
    }

    function setPrincipleDepositor(address newDepositor_)
        external
        onlyOwner
        returns (bool)
    {
        isPrincipleDepositor[newDepositor_] = true;
        return true;
    }

    function setReserveDepositor(address newDepositor_)
        external
        onlyOwner
        returns (bool)
    {
        isReserveDepositor[newDepositor_] = true;
        return true;
    }

    function removePrincipleDepositor(address depositor_)
        external
        onlyOwner
        returns (bool)
    {
        isPrincipleDepositor[depositor_] = false;
        return true;
    }

    function removeReserveDepositor(address depositor_)
        external
        onlyOwner
        returns (bool)
    {
        isReserveDepositor[depositor_] = false;
        return true;
    }

    function rewardsDepositPrinciple( uint depositAmount_ ) external returns ( bool ) {
        require(isReserveDepositor[msg.sender], "Not allowed to deposit");
        address principleToken = getPrincipleToken;
        IERC20(principleToken).safeTransferFrom(msg.sender, address(this), depositAmount_);
        uint value = IBondingCalculator(getBondingCalculator).principleValuation(principleToken, depositAmount_) / 1e9;
        uint forLP = value / LPProfitShare;
        IERC20Mintable(getManagedToken).mint(stakingContract, value - forLP);
        IERC20Mintable(getManagedToken).mint(LPRewardsContract, forLP);
        return true;
    }

    function depositReserves(uint amount_) external returns ( bool ) {
        require(isReserveDepositor[msg.sender] == true, "Not allowed to deposit");
        IERC20(getReserveToken).safeTransferFrom( msg.sender, address(this), amount_);
        address managedToken_ = getManagedToken;
        IERC20Mintable(managedToken_).mint(msg.sender, amount_ / 10**IERC20Metadata(managedToken_).decimals());
        return true;
    }

    function depositPrinciple(uint depositAmount_) external returns (bool) {
        require(isPrincipleDepositor[msg.sender], "Not allowed to deposit");
        address principleToken = getPrincipleToken;
        IERC20(principleToken).safeTransferFrom(msg.sender, address(this), depositAmount_);
        uint value = IBondingCalculator(getBondingCalculator).principleValuation(principleToken, depositAmount_) / 1e9;
        IERC20Mintable(getManagedToken).mint(msg.sender, value);
        return true;
    }

    function migrateReserveAndPrinciple()
        external
        onlyOwner
        isTimelockExpired
        returns (bool saveGas_)
    {
        IERC20(getReserveToken).safeTransfer(daoWallet, IERC20(getReserveToken).balanceOf(address(this)));
        IERC20(getPrincipleToken).safeTransfer(daoWallet, IERC20(getPrincipleToken).balanceOf(address(this)));
        return true;
    }

    function setTimelock(uint newTimelockDurationInBlocks_)
        external
        onlyOwner
        notTimelockSet
        returns (bool)
    {
        timelockDurationInBlocks = newTimelockDurationInBlocks_;
        return true;
    }

    function startTimelock()
        external
        onlyOwner
        returns (bool)
    {
        getTimelockEndBlock = block.number + timelockDurationInBlocks;
        isTimelockSet = true;
        emit TimelockStarted(getTimelockEndBlock);
        return true;
    }
}
