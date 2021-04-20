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
    await fixedProductMarketMakerFactory.resetCurrentTime();

    let now = new Date();
    let endTime = Math.floor(addDays(now,3).getTime() / 1000);
    const createArgs = [
      questionString,
      endTime,
      2,
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

    fixedProductMarketMaker = await ORFPMarket.at(fixedProductMarketMakerAddress)
  })

  it('Should pass because we are in the voting period', async function() {
    let now = new Date();
    let day = 86400 / 2;
    let endDate = new Date(now.getTime() + day);

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

  it('Multiple different users should be able to vote', async function() {
    let now = new Date();
    let day = 86400 / 2;
    let endDate = new Date(now.getTime() + day);

    await fixedProductMarketMaker.resetCurrentTime();
    await fixedProductMarketMaker.castGovernanceApprovalVote(true, { from: investor2 });
    await fixedProductMarketMaker.castGovernanceApprovalVote(false, { from: trader });
    await fixedProductMarketMaker.castGovernanceApprovalVote(false, { from: oracle });
  });

  it('Should return the correct number of governance after multiple votes', async function() {
    let governanceVotes = await fixedProductMarketMaker.getGovernanceVotingResults();
    expect(governanceVotes[0].toString()).to.equal("6");
    expect(governanceVotes[1].toString()).to.equal("5");
  });


  it('Should return the 1-1 result', async function() {
    let outcome = await fixedProductMarketMaker.getResolvingOutcome();
    // We know the market is not in resolving yet.
    expect(outcome[0].toString()).to.equal("1");
    expect(outcome[1].toString()).to.equal("1");
  });


  it('Should revert because we are not in resolving period', async function() {
    const REVERT = "market is not in resolving period";

    await fixedProductMarketMaker.resetCurrentTime();
    try {
      await fixedProductMarketMaker.castGovernanceResolvingVote(0, { from: investor1 });
      throw null;
    }
    catch (error) {
      assert(error, "Expected an error but did not get one");
      assert(error.message.includes(REVERT), "Expected '" + REVERT + "' but got '" + error.message + "' instead");
    }
  });

  it('Should be able to cast a resolving vote for gov', async function() {
    let days = 86400 * 4;
    await fixedProductMarketMaker.resetCurrentTime();
    await fixedProductMarketMaker.increaseTime(days);
    await fixedProductMarketMaker.castGovernanceResolvingVote(0, { from: investor1 });
    await fixedProductMarketMaker.resetCurrentTime();
  });
})
