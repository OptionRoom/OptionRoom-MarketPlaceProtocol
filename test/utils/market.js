var chai = require('chai');

//use default BigNumber
chai.use(require('chai-bignumber')());

const { expectEvent } = require('openzeppelin-test-helpers')
const { toBN } = web3.utils

const ConditionalTokensContract = artifacts.require("../../../contracts/OR/ORConditionalTokens.sol");
const MarketLibContract = artifacts.require("../../../contracts/OR/ORFPMarket.sol");
const CollatContract = artifacts.require("canonical-weth/contracts/WETH9.sol");
const CollateralToken2Contract = artifacts.require("../../../contracts/mocks/ERC20DemoToken.sol");

const PredictionMarketFactoryMock = artifacts.require('PredictionMarketFactoryMock')
const ORFPMarket = artifacts.require('ORFPMarket')
const RoomsGovernor = artifacts.require('ORGovernanceMock')
const CentralTimeForTestingContract = artifacts.require('CentralTimeForTesting')
const RewardProgram = artifacts.require('RewardProgramMock')
const RewardCenterMockController = artifacts.require("../../../contracts/mock/RewardCenterMock.sol");
const CourtStakeMock = artifacts.require("../../../contracts/mock/CourtStakeMock.sol");

const ORMarketLib = artifacts.require('ORMarketLib')
var BigNumber = require('bignumber.js');


let conditionalTokens
let collateralToken
var fixedProductMarketMakerFactory
let fixedProductMarketMaker
let governanceMock
let orgTimeSnapShot

let centralTime
let marketLibrary;

let rewardProgram;
// let permissionsController;

const {
  marketValidationPeriod,
  marketResolvingPeriod,
  marketDisputePeriod,
  marketReCastResolvingPeriod,
  oneDay,
} = require('./constants')

const disputeThreshold = toBN(100e18)
const minHoldingToDispute = toBN(10e18)

const questionString = 'Test'
const feeFactor = toBN(3e15) // (0.3%)

let positionIds
let deployer;
let rewardCenter;

function setDeployer(deployerAccount) {
  deployer = deployerAccount;
}

async function prepareContracts(creator, oracle, investor1, trader, investor2) {
  conditionalTokens = await ConditionalTokensContract.new();
  marketLibrary = await MarketLibContract.new();
  centralTime = await CentralTimeForTestingContract.new();
  
  collateralToken = await CollatContract.new() ;//await WETH9.deployed();

  fixedProductMarketMakerFactory = await PredictionMarketFactoryMock.deployed()
  governanceMock = await RoomsGovernor.deployed()
  
  let courtStakeContract = await CourtStakeMock.new();

  await centralTime.initializeTime();

  // Assign the timer to the governance.
  await fixedProductMarketMakerFactory.setCentralTimeForTesting(centralTime.address);
  rewardProgram = await RewardProgram.deployed();
  await rewardProgram.setCentralTimeForTesting(centralTime.address);
  await rewardProgram.doInitialization();
  
  rewardCenter = await RewardCenterMockController.new();
  await rewardCenter.setCentralTimeForTesting(centralTime.address);
  
  // setting the time for the governance as well.
  await governanceMock.setCentralTimeForTesting(centralTime.address);
  await governanceMock.setMarketsControllarAddress(fixedProductMarketMakerFactory.address);

  await rewardProgram.setMarketControllerAddress(fixedProductMarketMakerFactory.address);
  // Two very important calls...
  await rewardProgram.setRewardCenter(rewardCenter.address);
  await rewardCenter.setRewardProgram(rewardProgram.address);

  // Setting the reward program here.
  await fixedProductMarketMakerFactory.setRewardProgram(rewardProgram.address);
  await fixedProductMarketMakerFactory.setRewardCenter(rewardCenter.address);
  
  let deployedMarketMakerContract = await ORFPMarket.deployed();
  await fixedProductMarketMakerFactory.setTemplateAddress(deployedMarketMakerContract.address);
  await fixedProductMarketMakerFactory.assign(conditionalTokens.address);
  await fixedProductMarketMakerFactory.assignCollateralTokenAddress(collateralToken.address);
  await fixedProductMarketMakerFactory.assignGovernanceContract(governanceMock.address);

  // Setting the voting power.
  // setting the court stake.
  await governanceMock.setCourtStake(courtStakeContract.address);
  await courtStakeContract.setCentralTimeForTesting(centralTime.address);

  // add suspend permission for this controller.
  await courtStakeContract.suspendPermission(governanceMock.address, true);
  
  await governanceMock.setPower(investor1, 5);
  await governanceMock.setPower(investor2, 1);
  await governanceMock.setPower(trader, 2);
  await governanceMock.setPower(oracle, 3);
  
  return [fixedProductMarketMakerFactory,rewardProgram,rewardCenter, conditionalTokens, governanceMock];
}

async function createNewMarket(creator) {
  let now = new Date()
  let resolvingEndDate = addDays(now, 5)
  let endTime = Math.floor(addDays(now, 3).getTime() / 1000)
  let resolvingEndTime = Math.floor(resolvingEndDate.getTime() / 1000)

  const createArgs = [
    questionString,
    endTime,
    resolvingEndTime,
    feeFactor,
    { from: creator },
  ]

  await centralTime.initializeTime();
  await fixedProductMarketMakerFactory.setCollateralAllowed(collateralToken.address, true);

  const createTx = await fixedProductMarketMakerFactory.createMarketProposalTest(...createArgs)
  expectEvent.inLogs(createTx.logs, 'FixedProductMarketMakerCreation', {
    creator,
    conditionalTokens: conditionalTokens.address,
    collateralToken: collateralToken.address,
  })

  const { fixedProductMarketMaker } = createTx.logs.find(
    ({ event }) => event === 'FixedProductMarketMakerCreation'
  ).args;
  
  const marketToReturn = await ORFPMarket.at(fixedProductMarketMaker)
  positionIds = await marketToReturn.getPositionIds();
  return [marketToReturn, collateralToken, positionIds];
}

async function createNewMarketWithCollateral(creator, isERC20, addedFunds, question) {
  let now = new Date()
  let resolvingEndDate = addDays(now, 5)
  let endTime = Math.floor(addDays(now, 3).getTime() / 1000)
  let resolvingEndTime = Math.floor(resolvingEndDate.getTime() / 1000)

  let col;
  if (isERC20) {
    col = await CollateralToken2Contract.new();
    await fixedProductMarketMakerFactory.setCollateralAllowed(col.address, true);
    await fixedProductMarketMakerFactory.assignCollateralTokenAddress(col.address);

    await col.mint(addedFunds, { from: creator })
    await col.transfer(creator, addedFunds, { from: creator })
  }  else {
    col =await CollatContract.new() ;
    await fixedProductMarketMakerFactory.setCollateralAllowed(col.address, true);
    await fixedProductMarketMakerFactory.assignCollateralTokenAddress(col.address);
    await col.deposit({ value: addedFunds, from: creator })
  }

  const createArgs = [
    question,
    endTime,
    resolvingEndTime,
    col.address,
    addedFunds,
    { from: creator }
  ]

  await centralTime.initializeTime();

  await col.approve(fixedProductMarketMakerFactory.address, addedFunds, { from: creator })
  
  const createTx = await fixedProductMarketMakerFactory.createMarketProposal(...createArgs)
  expectEvent.inLogs(createTx.logs, 'FixedProductMarketMakerCreation', {
    creator,
    conditionalTokens: conditionalTokens.address,
    collateralToken: col.address,
  })

  const { fixedProductMarketMaker } = createTx.logs.find(
    ({ event }) => event === 'FixedProductMarketMakerCreation'
  ).args;

  // Return those attributes to the creation, so that we can check on them.
  const marketToReturn = await ORFPMarket.at(fixedProductMarketMaker)
  positionIds = await marketToReturn.getPositionIds();
  return [marketToReturn, col, positionIds];
}

function addDays(theDate, days) {
  return new Date(theDate.getTime() + days * 24 * 60 * 60 * 1000)
}

async function invokeFactoryMethod(func,...args) {
  fixedProductMarketMakerFactory[func](...args);
}

async function callViewFactoryMethod(func,args) {
  return fixedProductMarketMakerFactory[func](...args);
}

async function callControllerMethod(func, args) {
    return fixedProductMarketMakerFactory[func].call(...args);
}

async function executeControllerMethod(func,args) {
  fixedProductMarketMakerFactory[func]( ...args);
}


async function conditionalApproveForAll(market,account) {
   conditionalTokens.setApprovalForAll(market.address, true, { from: account });
}

async function conditionalApproveFor(market,amount, account) {
  conditionalTokens.approve(market.address,amount, true, { from: account });
}

async function conditionalBalanceOf(account, positionId) {
  return conditionalTokens.balanceOf(account, positionId);
}

async function executeMarketMethod(market, func,args) {
  return market[func](...args);
}

async function moveToActive() {
  centralTime.increaseTime(marketValidationPeriod + 10);
}

async function moveToResolving() {
  centralTime.increaseTime(marketResolvingPeriod + 10);
}

async function moveToResolved() {
  centralTime.increaseTime((oneDay * 5) + 10);
}

async function moveToResolved11() {
  return centralTime.getTimeIncrease();
}

async function increaseTime(time) {
  centralTime.increaseTime(time);
}


async function resetTimeIncrease() {
  centralTime.resetTimeIncrease();
}

async function getCollateralBalance(account) {
  return collateralToken.balanceOf(account);
}

async function moveOneDay() {
  centralTime.increaseTime(oneDay + 100);
}

async function forwardMarketToResolving(fixedProductMarketMaker, investor1, trader, investor2) {
  await fixedProductMarketMakerFactory.castGovernanceValidatingVote(fixedProductMarketMaker.address,true, 
    { from: investor2 });
  
  await moveToActive();
}

module.exports = {
  setDeployer,
  moveToResolved11,
  prepareContracts,
  createNewMarket,
  createNewMarketWithCollateral,
  addDays,
  invokeFactoryMethod,
  callViewFactoryMethod,
  callControllerMethod,
  increaseTime,
  moveToActive,
  moveToResolving,
  moveToResolved,
  moveOneDay,
  executeControllerMethod,
  resetTimeIncrease,
  conditionalApproveForAll,
  conditionalBalanceOf,
  conditionalApproveFor,
  forwardMarketToResolving,
  getCollateralBalance,
}
