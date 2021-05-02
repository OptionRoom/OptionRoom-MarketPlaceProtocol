var chai = require('chai');

//use default BigNumber
chai.use(require('chai-bignumber')());

const { expectEvent } = require('openzeppelin-test-helpers')
const { toBN } = web3.utils

let ConditionalTokensContract = artifacts.require("../../contracts/OR/ORConditionalTokens.sol");

const WETH9 = artifacts.require('WETH9')
const PredictionMarketFactoryMock = artifacts.require('PredictionMarketFactoryMock')
const ORFPMarket = artifacts.require('ORFPMarket')
const ORMarketController = artifacts.require('ORMarketController')
const CentralTimeForTesting = artifacts.require('CentralTimeForTesting')

var BigNumber = require('bignumber.js');
const helper = require('ganache-time-traveler');

const ORMarketLib = artifacts.require('ORMarketLib')

contract('MarketMakerStates: test dispute market', function([, creator, oracle, investor1, trader, investor2]) {
  let conditionalTokens
  let collateralToken
  let fixedProductMarketMakerFactory
  let fixedProductMarketMaker
  let governanceMock
  let orgTimeSnapShot

  let marketPendingPeriod = 1800;
  let marketResolvingPeriod = 1800;
  let marketDisputePeriod = 4 * 1800;
  let marketReCastResolvingPeriod = 4 * 1800;

  let disputeThreshold = toBN(100e18);

  let centralTime;

  const questionString = "Test"
  const feeFactor = toBN(3e15) // (0.3%)

  let positionIds
  async  function createConditionalTokensContract(theDate, days) {
    conditionalTokens = await ConditionalTokensContract.new();
  }

  before(async function() {
    await createConditionalTokensContract();
    collateralToken = await WETH9.deployed();
    fixedProductMarketMakerFactory = await PredictionMarketFactoryMock.deployed()
    governanceMock = await ORMarketController.deployed()
    centralTime = await CentralTimeForTesting.deployed();

    // Assign the timer to the governance.
    await fixedProductMarketMakerFactory.setCentralTimeForTesting(centralTime.address);
    await governanceMock.setCentralTimeForTesting(centralTime.address);

    let deployedMarketMakerContract = await ORFPMarket.deployed();

    await fixedProductMarketMakerFactory.setTemplateAddress(deployedMarketMakerContract.address);
    await fixedProductMarketMakerFactory.assign(conditionalTokens.address);
    await fixedProductMarketMakerFactory.assignCollateralTokenAddress(collateralToken.address);
    await fixedProductMarketMakerFactory.assignGovernanceContract(governanceMock.address);

    // Setting the voting power.
    await governanceMock.setPower(investor1, 5);
    await governanceMock.setPower(investor2, 1);
    await governanceMock.setPower(trader, 2);
    await governanceMock.setPower(oracle, 3);

    let snapshot = await helper.takeSnapshot();
    orgTimeSnapShot = snapshot['result'];
  })

  function addDays(theDate, days) {
    return new Date(theDate.getTime() + days*24*60*60*1000);
  }

  it('can be created by factory', async function() {
    let now = new Date();
    let resolvingEndDate = addDays(now, 5);
    let endTime = Math.floor(addDays(now,3).getTime() / 1000);
    let resolvingEndTime = Math.floor(resolvingEndDate.getTime() / 1000);

    const createArgs = [
      questionString,
      endTime,
      resolvingEndTime,
      feeFactor,
      { from: creator }
    ]

    await centralTime.initializeTime();
    const fixedProductMarketMakerAddress = await fixedProductMarketMakerFactory.createMarketProposalTest.call(...createArgs)
    const createTx = await fixedProductMarketMakerFactory.createMarketProposalTest(...createArgs);
    expectEvent.inLogs(createTx.logs, 'FixedProductMarketMakerCreation', {
      creator,
      fixedProductMarketMaker: fixedProductMarketMakerAddress,
      conditionalTokens: conditionalTokens.address,
      collateralToken: collateralToken.address,
    });

    fixedProductMarketMaker = await ORFPMarket.at(fixedProductMarketMakerAddress)
  })

  let orgTimeStamp;

  it('Should check on the state change when voting from governance', async function() {
    await centralTime.resetTimeIncrease();
    await centralTime.increaseTime(marketPendingPeriod);

    // Start should be shown as rejected.
    let state = await governanceMock.getMarketState(fixedProductMarketMaker.address);
    expect(new BigNumber(state).isEqualTo(new BigNumber(2))).to.equal(true);

    await centralTime.resetTimeIncrease();

    // approve it.
    await governanceMock.castGovernanceValidatingVote(fixedProductMarketMaker.address,true,  { from: investor2 });
    await governanceMock.castGovernanceValidatingVote(fixedProductMarketMaker.address, true, { from: trader });
    await governanceMock.castGovernanceValidatingVote(fixedProductMarketMaker.address,true,  { from: oracle });

    await centralTime.increaseTime(marketPendingPeriod);
    state = await governanceMock.getMarketState(fixedProductMarketMaker.address);
    expect(new BigNumber(state).isEqualTo(new BigNumber(3))).to.equal(true);
  });

  const addedFunds1 = toBN(1e18)
  it('can buy tokens from it', async function() {
    const investmentAmount = toBN(1e18)
    const buyOutcomeIndex = 1;

    await collateralToken.deposit({ value: addedFunds1, from: investor1 });
    await collateralToken.approve(fixedProductMarketMaker.address, addedFunds1, { from: investor1 });
    await fixedProductMarketMaker.addLiquidity(addedFunds1, { from: investor1 });

    // we already have 2 yeses and 2 nos
    await collateralToken.deposit({ value: investmentAmount, from: trader });
    await collateralToken.approve(fixedProductMarketMaker.address, investmentAmount, { from: trader });
    const outcomeTokensToBuy = await fixedProductMarketMaker.calcBuyAmount(investmentAmount, buyOutcomeIndex);
    await fixedProductMarketMaker.buy(investmentAmount, buyOutcomeIndex, outcomeTokensToBuy, { from: trader });
  })

  let firstTimeResolve;
  it('Should be able to cast a resolving vote for gov', async function() {
    await centralTime.resetTimeIncrease();
    await centralTime.increaseTime(marketPendingPeriod);

    let days = ((86400 * 3) + 10);

    await centralTime.increaseTime(days);
    await governanceMock.castGovernanceResolvingVote(fixedProductMarketMaker.address, 1, { from: investor1 });
    await governanceMock.castGovernanceResolvingVote(fixedProductMarketMaker.address, 1, { from: investor2 });
    await governanceMock.castGovernanceResolvingVote(fixedProductMarketMaker.address, 1, { from: trader });
    await governanceMock.castGovernanceResolvingVote(fixedProductMarketMaker.address, 1, { from: oracle });
  });

  it('Should revert because we are not in dispute period', async function() {
    const REVERT = "Market is not in dispute state";

    try {
      await governanceMock.disputeMarket(fixedProductMarketMaker.address, "I dont want to play", { from: trader });
      throw null;
    }
    catch (error) {
      assert(error, "Expected an error but did not get one");
      assert(error.message.includes(REVERT), "Expected '" + REVERT + "' but got '" + error.message + "' instead");
    }
  });

  it('Should be able to cast a dispute for a market', async function() {
    // Initially here we are the resolving state !
    let state = await governanceMock.getMarketState(fixedProductMarketMaker.address);
    expect(new BigNumber(state).isEqualTo(new BigNumber(5))).to.equal(true);
    let days = ((86400 * 5) + 1000);
    await centralTime.resetTimeIncrease();
    await centralTime.increaseTime(days);
    const createTx = await governanceMock.disputeMarket(fixedProductMarketMaker.address, "Might just pass", { from: trader });
    expectEvent.inLogs(createTx.logs, 'DisputeSubmittedEvent', {
      disputer: trader,
      market: fixedProductMarketMaker.address,
    });

    state = await governanceMock.getMarketState(fixedProductMarketMaker.address);
    expect(new BigNumber(state).isEqualTo(new BigNumber(ORMarketLib.MarketState.DisputePeriod))).to.equal(true);
  });


  it('Should revert because address already submitted', async function() {
    const REVERT = "User already dispute";

    try {
      await governanceMock.disputeMarket(fixedProductMarketMaker.address, "I will try again", { from: trader });
      throw null;
    }
    catch (error) {
      assert(error, "Expected an error but did not get one");
      assert(error.message.includes(REVERT), "Expected '" + REVERT + "' but got '" + error.message + "' instead");
    }
  });
})
