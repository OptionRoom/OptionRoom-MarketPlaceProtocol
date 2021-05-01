var chai = require('chai');

//use default BigNumber
chai.use(require('chai-bignumber')());

const { expectEvent } = require('openzeppelin-test-helpers')
const { toBN } = web3.utils

let ConditionalTokensContract = artifacts.require("../../contracts/OR/ORConditionalTokens.sol");
let MarketLibContract = artifacts.require("../../contracts/OR/ORFPMarket.sol");

const WETH9 = artifacts.require('WETH9')
const PredictionMarketFactoryMock = artifacts.require('PredictionMarketFactoryMock')
const ORFPMarket = artifacts.require('ORFPMarket')
const ORMarketController = artifacts.require('ORMarketController')
const CentralTimeForTesting = artifacts.require('CentralTimeForTesting')

const ORMarketLib = artifacts.require('ORMarketLib')
var BigNumber = require('bignumber.js');
contract('FixedProductMarketMaker: create multiple markets test', function([, creator, oracle, investor1, trader, investor2]) {
  let conditionalTokens
  let collateralToken
  let fixedProductMarketMakerFactory
  let governanceMock
  let marketMakers = [];
  let centralTime
  let marketLibrary;

  let pendingMarketMakersMap = new Map()

  const questionString = "Test"
  const feeFactor = toBN(3e15) // (0.3%)

  let marketMinShareLiq = 100e18;
  let marketValidatingPeriod = 1800;
  let marketDisputePeriod = 4 * 1800;
  let marketReCastResolvingPeriod = 4 * 1800;
  let disputeThreshold = 100e18;

  async  function createConditionalTokensContract(theDate, days) {
    conditionalTokens = await ConditionalTokensContract.new();
    marketLibrary = await MarketLibContract.new();
  }

  // let positionIds
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
  })

  function addDays(theDate, days) {
    return new Date(theDate.getTime() + days*24*60*60*1000);
  }


  async function createNewMarket(creatorAddress) {
    let now = new Date();
    let resolvingEndDate = addDays(now, 5);
    let endTime = Math.floor(addDays(now,3).getTime() / 1000);
    let resolvingEndTime = Math.floor(resolvingEndDate.getTime() / 1000);
    const createArgs = [
      questionString,
      endTime,
      resolvingEndTime,
      feeFactor,
      { from: creatorAddress }
    ]

    await centralTime.initializeTime();

    const fixedProductMarketMakerAddress = await fixedProductMarketMakerFactory.createMarketProposalTest.call(...createArgs)
    const createTx = await fixedProductMarketMakerFactory.createMarketProposalTest(...createArgs);
    expectEvent.inLogs(createTx.logs, 'FixedProductMarketMakerCreation', {
      creator: creatorAddress,
      fixedProductMarketMaker: fixedProductMarketMakerAddress,
      conditionalTokens: conditionalTokens.address,
      collateralToken: collateralToken.address,
    });

    let fixedProductMarketMaker = await ORFPMarket.at(fixedProductMarketMakerAddress);
    marketMakers.push(fixedProductMarketMaker);

    // set only works because we want to delete
    pendingMarketMakersMap.set(fixedProductMarketMaker.address,fixedProductMarketMaker );
  }

  it('Should create and return correct validating markets count', async function() {
    await createNewMarket(creator);
    await createNewMarket(creator);
    await createNewMarket(creator);
    let marketsCount = await fixedProductMarketMakerFactory.getMarketsCount(ORMarketLib.MarketState.Validating);
    expect(marketsCount.toString()).to.equal("3");
  });

  it('Should check for correct markets numbers', async function() {
    let marketMaker = marketMakers[0];
    await governanceMock.castGovernanceValidatingVote(marketMaker.address, true, { from: investor1 });

    await centralTime.increaseTime(marketValidatingPeriod + 100);

    let invalidMarketsCount = await fixedProductMarketMakerFactory.getMarketsCount(ORMarketLib.MarketState.Invalid);
    let activeMarketsCount = await fixedProductMarketMakerFactory.getMarketsCount(ORMarketLib.MarketState.Active);
    let rejectedMarketsCount = await fixedProductMarketMakerFactory.getMarketsCount(ORMarketLib.MarketState.Rejected);
    let validatingMarketsCount = await fixedProductMarketMakerFactory.getMarketsCount(ORMarketLib.MarketState.Validating);
    let resolvingMarketsCount = await fixedProductMarketMakerFactory.getMarketsCount(ORMarketLib.MarketState.Resolving);

    expect(invalidMarketsCount.toString()).to.equal("0");
    expect(activeMarketsCount.toString()).to.equal("1");
    expect(rejectedMarketsCount.toString()).to.equal("2");
    expect(validatingMarketsCount.toString()).to.equal("0");
    expect(resolvingMarketsCount.toString()).to.equal("0");

    // remove this market from pending states.
    pendingMarketMakersMap.delete(marketMaker.address + "");
  });

  it('Should return paginated markets according to the state', async function() {
    let rejectedMarketsCount = await fixedProductMarketMakerFactory.getMarkets(ORMarketLib.MarketState.Rejected, 0, 10);
    let retPendingCount = 0;

    for (let i = 0; i < rejectedMarketsCount .length; i++) {
      if (rejectedMarketsCount[i] !== "0x0000000000000000000000000000000000000000") {
        retPendingCount++;
      }
    }

    expect(retPendingCount).to.equal(2);

    rejectedMarketsCount = await fixedProductMarketMakerFactory.getMarketsQuestionIDs(ORMarketLib.MarketState.Rejected, 0, 5);

    let markets = rejectedMarketsCount["markets"];
    let questionsIds = rejectedMarketsCount["questionsIDs"];

    let firstFoundMarket;
    for (let j = 0; j < markets .length; j++) {
      if (markets[j] !== "0x0000000000000000000000000000000000000000") {
        firstFoundMarket = markets[j];
        break;
      }
    }

    let firstAddressInMap = pendingMarketMakersMap.keys().next().value

    expect(firstFoundMarket).to.equal(firstAddressInMap);
  });


  it('Should return markets for the proposer', async function() {
    await centralTime.resetTimeIncrease();

    // Create another three markets for another account
    await createNewMarket(investor1);
    await createNewMarket(investor1);
    await createNewMarket(investor1);

    await centralTime.increaseTime(marketValidatingPeriod + 100);

    let creatorMarketsCount = await fixedProductMarketMakerFactory.getMarketCountByProposer(creator);
    let creatorRejectedMarketsCount = await fixedProductMarketMakerFactory.getMarketCountByProposerNState(creator, ORMarketLib.MarketState.Rejected);
    let creatorResolvingMarketsCount = await fixedProductMarketMakerFactory.getMarketCountByProposerNState(creator, ORMarketLib.MarketState.Active);

    let investor1MarketsCount = await fixedProductMarketMakerFactory.getMarketCountByProposer(investor1);
    let investor1RejectedMarketsCount = await fixedProductMarketMakerFactory.getMarketCountByProposerNState(investor1, ORMarketLib.MarketState.Rejected);

    expect(new BigNumber(creatorMarketsCount).isEqualTo(3)).to.equal(true);
    expect(new BigNumber(investor1MarketsCount).isEqualTo(3)).to.equal(true);
    expect(new BigNumber(investor1RejectedMarketsCount).isEqualTo(3)).to.equal(true);


    expect(new BigNumber(creatorRejectedMarketsCount).isEqualTo(2)).to.equal(true);
    expect(new BigNumber(creatorResolvingMarketsCount).isEqualTo(1)).to.equal(true);

  });

})
