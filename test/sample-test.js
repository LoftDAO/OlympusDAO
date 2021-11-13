const {expect} = require("chai");
const {ethers} = require("hardhat");
const {utils} = require('ethers');
const [owner, addr1, addr2, addr3, addr4] = await ethers.getSigners();

// const PreOlympusToken = await hre.ethers.getContractFactory("PreOlympusToken");
// const PreOlympusTokenD = await PreOlympusToken.deploy({gasLimit: 20000000});
// const PreOlympusTokenDAddr = PreOlympusTokenD.address;
const PreOlympusTokenDAddr = '0xD214aF8b48E6135b81828f8D72945F6835e94212';
const PreOlympusTokenD = await ethers.getContractAt("PreOlympusToken", PreOlympusTokenDAddr);

// const OlympusERC20Token = await hre.ethers.getContractFactory("OlympusERC20Token");
// const OlympusERC20TokenD = await OlympusERC20Token.deploy({gasLimit: 20000000});
// const OlympusERC20TokenDAddr = OlympusERC20TokenD.address;
const OlympusERC20TokenDAddr = '0x91C46f43996A6196506859A07aE78598d9c57e16';
const OlympusERC20TokenD = await ethers.getContractAt("OlympusERC20Token", OlympusERC20TokenDAddr);

// const DAIAddr = '0x6B175474E89094C44Da98b954EedeAC495271d0F';  // mainnet
// const DAIAddr = '0x6A9865aDE2B6207dAAC49f8bCba9705dEB0B0e6D';  // Rinkeby
// const DAIAddr = '0x5592ec0cfb4dbc12d3ab100b257153436a1f0fea';  // Rinkeby Compound
const DAIAddr = '0xc7ad46e0b8a400bb3c915120d284aafba8fc4735';  // Rinkeby Uniswap

// const FraxAddr = 0x853d955aCEf822Db058eb8505911ED77F175b99e;

// const factoryAddr = '0x5C69bEe701ef814a2B6a3EDD4B1652CB9cc5aA6f';  // Make sure the factory is sushiswap, not uniswap factory
// const factoryD = await ethers.getContractAt("IUniswapV2Factory", factoryAddr);
// await factoryD.createPair(OlympusERC20TokenDAddr, DAIAddr, {gasLimit: 3000000});
// const OHMDAIDAddr = await factoryD.callStatic.getPair(OlympusERC20TokenDAddr, DAIAddr);
const OHMDAIPairAddr = '0x601F1dD8774c8b58007714Ec4c19993d968014aC';
const OHMDAIPairD = await ethers.getContractAt("IUniswapV2Pair", OHMDAIPairAddr);

// const OlympusTreasury = await hre.ethers.getContractFactory("OlympusTreasury");
// const OlympusTreasuryD = await OlympusTreasury.deploy(OlympusERC20TokenDAddr, DAIAddr, OHMDAIPairAddr, 10, {gasLimit: 20000000});
// const OlympusTreasuryDAddr = OlympusTreasuryD.address;
const OlympusTreasuryDAddr = '0x78d5b5fcf1BefF8c222C149e6a0D41d902317392';
const OlympusTreasuryD = await ethers.getContractAt("OlympusTreasury", OlympusTreasuryDAddr);

// const ExercisePOHM = await hre.ethers.getContractFactory("ExercisePOLY");
// const ExercisePOHMD2 = await ExercisePOLY2.deploy(PreOlympusTokenDAddr, OlympusERC20TokenDAddr, DAIAddr, VaultDAddr, {gasLimit: 20000000});
// const ExercisePOHMDAddr2 = ExercisePOHMD2.address;
const ExercisePOHMDAddr = '0x53d2A7f982291F866e1BEd7453a9B49C894440FA';
const ExercisePOHMD = await ethers.getContractAt("ExercisePOLY", ExercisePOHMDAddr);

// const OlympusBondingCalculator = await hre.ethers.getContractFactory("OlympusBondingCalculator");
// const OlympusBondingCalculatorD = await OlympusBondingCalculator.deploy(OlympusERC20TokenDAddr, {gasLimit: 20000000});
// const OlympusBondingCalculatorDAddr = OlympusBondingCalculatorD.address;
const OlympusBondingCalculatorDAddr = '0x0556ca87eBD7d52447e31b4ACfeD393A563B34a3';
const OlympusBondingCalculatorD = await ethers.getContractAt("OlympusBondingCalculator", OlympusBondingCalculatorDAddr);

const DAOAddr = '0xd96F188bDE66bC8f2F7585e59e0407291a09670a';

// const OlympusBondDepository = await hre.ethers.getContractFactory("OlympusBondDepository");
// const OlympusBondDepositoryD = await OlympusBondDepository.deploy(OlympusERC20TokenDAddr, DAIAddr, OlympusTreasuryDAddr, DAOAddr, OlympusBondingCalculatorDAddr, {gasLimit: 20000000});
// const OlympusBondDepositoryDAddr = OlympusBondDepositoryD.address;
// const OlympusBondDepositoryDAddr = '0xeb682d359Bedc0A81d05165Acaa15444b05BDec7';
// const OlympusBondDepositoryD = await ethers.getContractAt("OlympusBondDepository", OlympusBondDepositoryDAddr);

// const OlympusBondDepositoryOHMDAI = await hre.ethers.getContractFactory("OlympusBondDepository");
// const OlympusBondDepositoryOHMDAID = await OlympusBondDepositoryOHMDAI.deploy(OlympusERC20TokenDAddr, OHMDAIPairAddr, OlympusTreasuryDAddr, DAOAddr, OlympusBondingCalculatorDAddr, {gasLimit: 20000000});
// const OlympusBondDepositoryOHMDAIDAddr = OlympusBondDepositoryOHMDAID.address;
const OlympusBondDepositoryOHMDAIDAddr = '0x65cE3505c59C76805B4FB5ce9156002964Fb693b';
const OlympusBondDepositoryOHMDAID = await ethers.getContractAt("OlympusBondDepository", OlympusBondDepositoryOHMDAIDAddr);

// const RedeemHelper = await hre.ethers.getContractFactory("RedeemHelper");
// const RedeemHelperD = await RedeemHelper.deploy({gasLimit: 20000000});
// const RedeemHelperDAddr = RedeemHelperD.address;
// const RedeemHelperDAddr = '0xc5d3078e6f482AE9fD79B1B250d57aeAa7c24EBd';
// const RedeemHelperD = await ethers.getContractAt("RedeemHelper", RedeemHelperDAddr);


// const sOlympus = await hre.ethers.getContractFactory("sOlympus");
// const sOlympusD = await sOlympus.deploy({gasLimit: 20000000});
// const sOlympusDAddr = sOlympusD.address;
const sOlympusDAddr = '0x0da99Ea8bb34C7728A55f77d07130ddff20e3efC';
const sOlympusD = await ethers.getContractAt("sOlympus", sOlympusDAddr);


// const OlympusStaking = await hre.ethers.getContractFactory("OlympusStaking");
// const OlympusStakingD = await OlympusStaking.deploy(OlympusERC20TokenDAddr, sOlympusDAddr, 2200, 237, 9590000, {gasLimit: 20000000});
// const OlympusStakingDAddr = OlympusStakingD.address;
const OlympusStakingDAddr = '0x51159E3C5B1def31a25175bc73da41A6Ff6A8646';
const OlympusStakingD = await ethers.getContractAt("OlympusStaking", OlympusStakingDAddr);

// const Distributor = await hre.ethers.getContractFactory("Distributor");
// const DistributorD = await Distributor.deploy(OlympusTreasuryDAddr, OlympusERC20TokenDAddr, 2200, 9600000, {gasLimit: 20000000});
// const DistributorDAddr = DistributorD.address;
const DistributorDAddr = '0x37D0507a5e6ff6554390b8450cA600C3334877d4';
const DistributorD = await ethers.getContractAt("Distributor", DistributorDAddr);

// const StakingHelper = await hre.ethers.getContractFactory("StakingHelper");
// const StakingHelperD = await StakingHelper.deploy(OlympusStakingDAddr, OlympusERC20TokenDAddr, {gasLimit: 20000000});
// const StakingHelperDAddr = StakingHelperD.address;
const StakingHelperDAddr = '0x9398B17775145b0D81877ae69a7345138C5855a5';
const StakingHelperD = await ethers.getContractAt("StakingHelper", StakingHelperDAddr);

// const StakingWarmup = await hre.ethers.getContractFactory("StakingWarmup");
// const StakingWarmupD = await StakingWarmup.deploy(OlympusStakingDAddr, OlympusERC20TokenDAddr, {gasLimit: 20000000});
// const StakingWarmupDAddr = StakingWarmupD.address;
const StakingWarmupDAddr = '0x24417217cE4FBed51B6295398B975A71c5A9f3A9';
const StakingWarmupD = await ethers.getContractAt("StakingWarmup", StakingWarmupDAddr);

// const OlympusBondDepository = await hre.ethers.getContractFactory("OlympusBondDepository");
// const OlympusBondDepositoryD = await OlympusBondDepository.deploy({gasLimit: 20000000});
// const OlympusBondDepositoryDAddr = OlympusBondDepositoryD.address;

// const wOHM = await hre.ethers.getContractFactory("wOHM");
// const wOHMD = await wOHM.deploy(OlympusStakingDAddr, OlympusERC20TokenDAddr, sOlympusDAddr, {gasLimit: 20000000});
// const wOHMDAddr = wOHMD.address;
// const wOHMDAddr = '0x11f922F72e1cb67e568E570B7eC1b28B9F34c4D1';
// const wOHMD = await ethers.getContractAt("wOHM", wOHMDAddr);

// const Vault = await hre.ethers.getContractFactory("Vault");
// const VaultD = await Vault.deploy();
// const VaultDAddr = VaultD.address;
const VaultDAddr = '0x4aC5ceda2B10de80937010C3830251Af64D496f5';
const VaultD = await ethers.getContractAt("Vault", VaultDAddr);

// 0. Set up the vault contract
await VaultD.initialize(OlympusERC20TokenDAddr, DAIAddr, OlympusBondingCalculatorDAddr, DAOAddr);
await VaultD.setLPProfitShare(4);
await VaultD.setStakingContract(OlympusStakingDAddr);
await VaultD.setDAOWallet(DAOAddr);
await VaultD.setReserveDepositor(owner.address);
await VaultD.setReserveDepositor(addr1.address);
await VaultD.setReserveDepositor(ExercisePOHMDAddr);

// Let DAI contract approve VaultDAddr
await OlympusERC20TokenD.setVault(VaultDAddr);  // Vault must be set in OHM contract
await VaultD.depositReserves('100000000000000000000000', {gasLimit: 1000000});

// 1. Walk through the process of staking DAI to the treasury and earn sOHM
// 1.1 Deposit DAI to mint OHMs; this should go to the treasury/Vault
await OlympusERC20TokenD.totalSupply();
await PreOlympusTokenD.balanceOf(addr1.address);
await PreOlympusTokenD.approve(ExercisePOHMD.address, '100000000000000000000000000000');
// await PreOlympusTokenD.transfer(addr1.address, '100000000000000000000000');
await ExercisePOHMD.setTerms(addr1.address, '100000000000000000000000', 100);
await ExercisePOHMD.setTerms(owner.address, '100000000000000000000000', 100);
await ExercisePOHMD.getPOLYAbleToClaim(owner.address);
await ExercisePOHMD.exercisePOLY('1000000000000000000000', {gasLimit: 2000000});


await StakingHelperD.stake('100000000000000000000000', {gasLimit: 1000000});

// Add OHM-DAI liquidity pool
// 1.2 Send DAI to the treasury?


// 2. Walk through buying an asset bond and distribute rewards to stake holders

// 3. Walk through buying a lp token bond and distribute rewards to stake holders
OlympusBondDepositoryOHMDAIDAddr
await OlympusBondDepositoryOHMDAID.setBondTerms(0, 33110);
await OlympusBondDepositoryOHMDAID.initializeBondTerms(300, 33110, 1600, 50, 10000, 33000000000000, 25614114861660);
await OlympusBondDepositoryOHMDAID.setStaking(StakingHelperDAddr, 1);
// Must have pair token approve this contract
OHMDAIPairAddr
OlympusBondDepositoryOHMDAIDAddr
// lp token has to approve the treasury as well
OHMDAIPairAddr
OlympusTreasuryDAddr

await OlympusTreasuryD.queue(0, addr4.address);
await OlympusTreasuryD.queue(4, OlympusBondDepositoryOHMDAIDAddr);
await OlympusTreasuryD.queue(5, OlympusBondDepositoryOHMDAIDAddr);
await OlympusTreasuryD.toggle(4, OlympusBondDepositoryOHMDAIDAddr, OlympusBondDepositoryOHMDAIDAddr, {gasLimit: 2000000});
await OlympusTreasuryD.toggle(5, OlympusBondDepositoryOHMDAIDAddr, OlympusBondingCalculatorDAddr, {gasLimit: 2000000});

// await OlympusERC20TokenD.setVault(OlympusTreasuryD.address);  // Here vault is the treasury, but in the beginning, vault is the vault.
await OlympusBondDepositoryOHMDAID.deposit(30019581459258, 4000, owner.address, {gasLimit: 2000000});


// await OlympusTreasuryD.liquidityTokens(0);
// await OlympusTreasuryD.liquidityDepositors(0);
// await OlympusTreasuryD.isLiquidityDepositor(OlympusBondDepositoryOHMDAIDAddr);
// await OlympusTreasuryD.blocksNeededForQueue();
// await OlympusTreasuryD.LiquidityDepositorQueue(OlympusBondDepositoryOHMDAIDAddr);
// await OlympusTreasuryD.LiquidityTokenQueue(OlympusBondDepositoryOHMDAIDAddr);



await OlympusBondDepositoryOHMDAID.bondPrice();
await OlympusBondDepositoryOHMDAID.payoutFor(100);
await OlympusBondDepositoryOHMDAID.maxPayout();

await OlympusBondingCalculatorD.getTotalValue(OHMDAIPairAddr);
await OlympusBondingCalculatorD.getKValue(OHMDAIPairAddr);


// 4. Walk through the process of exercising pTokens
