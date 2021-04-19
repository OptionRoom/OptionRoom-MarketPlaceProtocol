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
  let fixedProductMarketMaker
  let governanceMock

  const questionString = "Test"
  const feeFactor = toBN(3e15) // (0.3%)

  // let positionIds
  before(async function() {
    conditionalTokens = await ConditionalTokens.deployed();
    collateralToken = await WETH9.deployed();
    fixedProductMarketMakerFactory = await PredictionMarketFactoryMock.deployed()
    governanceMock = await ORGovernanceMock.deployed()
    await fixedProductMarketMakerFactory.assign(conditionalTokens.address);
    await fixedProductMarketMakerFactory.assignCollateralTokenAddress(collateralToken.address);
    await fixedProductMarketMakerFactory.assignGovernanceContract(governanceMock.address);
  })

  it('can be created by factory', async function() {
    let now = new Date();
    const createArgs = [
      questionString,
      12,
      now.getTime(),
      feeFactor,
      { from: creator }
    ]
    await fixedProductMarketMakerFactory.resetCurrentTime();

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

  it('Should pass because we are in the voting period', async function() {
    let now = new Date();
    let day = 86400 / 2;
    let endDate = new Date(now.getTime() + day);

    // Setting the voting power.
    await governanceMock.setPower(5, {from: investor1});

    await fixedProductMarketMaker.resetCurrentTime();
    await fixedProductMarketMaker.castGovernanceApprovalVote(true, { from: investor1 });
  });

  it('Should revert because the market is in pending state', async function() {
    const REVERT = "Market is not in pending state";
    let day = 60 * 60 * 24 * 1000;

    await fixedProductMarketMaker.resetCurrentTime();
    await fixedProductMarketMaker.increaseTime(day);
    try {
      await fixedProductMarketMaker.castGovernanceApprovalVote(true, { from: investor1 });
      throw null;
    }
    catch (error) {
      assert(error, "Expected an error but did not get one");
      assert(error.message.includes(REVERT), "Expected '" + REVERT + "' but got '" + error.message + "' instead");
    }

    await fixedProductMarketMaker.resetCurrentTime();
  });


  it('Should revert because already voted', async function() {
    const REVERT = "user already voted";

    await fixedProductMarketMaker.resetCurrentTime();
    try {
      await fixedProductMarketMaker.castGovernanceApprovalVote(true, { from: investor1 });
      throw null;
    }
    catch (error) {
      assert(error, "Expected an error but did not get one");
      assert(error.message.includes(REVERT), "Expected '" + REVERT + "' but got '" + error.message + "' instead");
    }
  });

  it('Should return the correct number of governance votes', async function() {
    let governanceVotes = await fixedProductMarketMaker.getGovernanceVotingResults();
    expect(governanceVotes[0].toString()).to.equal("5");
    expect(governanceVotes[1].toString()).to.equal("0");
  });
})
