var chai = require('chai');

//use default BigNumber
chai.use(require('chai-bignumber')());

const { expectEvent } = require('openzeppelin-test-helpers')
const { toBN } = web3.utils

const ConditionalTokens = artifacts.require('ConditionalTokens')
const WETH9 = artifacts.require('WETH9')
const PredictionMarketFactoryMock = artifacts.require('PredictionMarketFactoryMock')
const ORFPMarket = artifacts.require('ORFPMarket')
const ORGovernanceMock = artifacts.require('ORGovernanceMock')

contract('FixedProductMarketMaker', function([, creator, oracle, investor1, trader, investor2]) {
  let conditionalTokens
  let collateralToken
  let fixedProductMarketMakerFactory
  let governanceMock
  let marketMakers = [];

  let pendingMarketMakersMap = new Map()

  const questionString = "Test"
  const feeFactor = toBN(3e15) // (0.3%)

  // let positionIds
  before(async function() {
    conditionalTokens = await ConditionalTokens.deployed();
    collateralToken = await WETH9.deployed();
    fixedProductMarketMakerFactory = await PredictionMarketFactoryMock.deployed()
    governanceMock = await ORGovernanceMock.deployed()
    let deployedMarketMakerContract = await ORFPMarket.deployed();
    await fixedProductMarketMakerFactory.setTemplateAddress(deployedMarketMakerContract.address);
    await fixedProductMarketMakerFactory.assign(conditionalTokens.address);
    await fixedProductMarketMakerFactory.assignCollateralTokenAddress(collateralToken.address);
    await fixedProductMarketMakerFactory.assignGovernanceContract(governanceMock.address);

    // Setting the voting power.
    await governanceMock.setPower(5, {from: investor1});
    await governanceMock.setPower(1, {from: investor2});
    await governanceMock.setPower(2, {from: trader});
    await governanceMock.setPower(3, {from: oracle});
  })

  function addDays(theDate, days) {
    return new Date(theDate.getTime() + days*24*60*60*1000);
  }

  it('can be created by factory', async function() {
    // await fixedProductMarketMakerFactory.resetCurrentTime();
  })

  async function createNewMarket() {
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
    const fixedProductMarketMakerAddress = await fixedProductMarketMakerFactory.createMarketProposalTest.call(...createArgs)
    const createTx = await fixedProductMarketMakerFactory.createMarketProposalTest(...createArgs);
    expectEvent.inLogs(createTx.logs, 'FixedProductMarketMakerCreation', {
      creator,
      fixedProductMarketMaker: fixedProductMarketMakerAddress,
      conditionalTokens: conditionalTokens.address,
      collateralToken: collateralToken.address,
    });

    let fixedProductMarketMaker = await ORFPMarket.at(fixedProductMarketMakerAddress);
    marketMakers.push(fixedProductMarketMaker);

    // set only works because we want to delete
    pendingMarketMakersMap.set(fixedProductMarketMaker.address,fixedProductMarketMaker );
  }

  it('Should return correct active markets count', async function() {
    await createNewMarket();
    await createNewMarket();
    await createNewMarket();
    let marketsCount = await fixedProductMarketMakerFactory.getMarketsCount(ORFPMarket.MarketState.Pending);
    expect(marketsCount.toString()).to.equal("3");
  });

  it('Should check for correct markets numbers', async function() {
    let marketMaker = marketMakers[0];
    await marketMaker.castGovernanceApprovalVote(true, { from: investor1 });

    let days = 86400 * 3;
    await marketMaker.increaseTime(days);
    let activeMarketsCount = await fixedProductMarketMakerFactory.getMarketsCount(ORFPMarket.MarketState.Pending);
    expect(activeMarketsCount.toString()).to.equal("2");

    let resolvingMarketsCount = await fixedProductMarketMakerFactory.getMarketsCount(ORFPMarket.MarketState.Resolving);
    expect(resolvingMarketsCount.toString()).to.equal("1");

    // remove this market from pending states.
    pendingMarketMakersMap.delete(marketMaker.address + "");
  });

  it('Should return markets count according to the state', async function() {
    let pendingMarkets = await fixedProductMarketMakerFactory.getMarkets(ORFPMarket.MarketState.Pending, 0, 10);
    let retPendingCount = 0;

    for (let i = 0; i < pendingMarkets .length; i++) {
      if (pendingMarkets[i] !== "0x0000000000000000000000000000000000000000") {
        retPendingCount++;
      }
    }

    expect(retPendingCount).to.equal(2);

    pendingMarkets = await fixedProductMarketMakerFactory.getMarketsQuestionIDs(ORFPMarket.MarketState.Pending, 0, 5);

    let markets = pendingMarkets["markets"];
    let questionsIds = pendingMarkets["questionsIDs"];

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

})
