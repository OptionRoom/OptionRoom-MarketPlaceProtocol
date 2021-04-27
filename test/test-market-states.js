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

var BigNumber = require('bignumber.js');
const helper = require('ganache-time-traveler');

contract('MarketMakerStates', function([, creator, oracle, investor1, trader, investor2]) {
  let conditionalTokens
  let collateralToken
  let fixedProductMarketMakerFactory
  let fixedProductMarketMaker
  let governanceMock
  let orgTimeSnapShot

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

    let snapshot = await helper.takeSnapshot();
    orgTimeSnapShot = snapshot['result'];
  })

  function addDays(theDate, days) {
    return new Date(theDate.getTime() + days*24*60*60*1000);
  }

  it('can be created by factory', async function() {
    // await fixedProductMarketMakerFactory.resetCurrentTime();

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

    fixedProductMarketMaker = await ORFPMarket.at(fixedProductMarketMakerAddress)
  })

  let orgTimeStamp;
  it('Should pass because we are in the voting period', async function() {
    orgTimeStamp = fixedProductMarketMaker.getCurrentTime();

    await fixedProductMarketMaker.castGovernanceApprovalVote(true, { from: investor1 });

    let votingResults = await fixedProductMarketMaker.getApprovingResult();
    expect(new BigNumber(votingResults[0]).isEqualTo(new BigNumber(0))).to.equal(true);
    expect(new BigNumber(votingResults[1]).isEqualTo(new BigNumber(5))).to.equal(true);
  });

  it('Should revert because the market is in pending state', async function() {
    const REVERT = "Market is not in pending state";
    let day = 1800 * 2;
    await fixedProductMarketMaker.increaseTime(day);
    try {
      await fixedProductMarketMaker.castGovernanceApprovalVote(true, { from: investor1 });
      throw null;
    }
    catch (error) {
      assert(error, "Expected an error but did not get one");
      assert(error.message.includes(REVERT), "Expected '" + REVERT + "' but got '" + error.message + "' instead");
    }
  });


  it('Should return the correct voting values if you vote yes again', async function() {
    await fixedProductMarketMaker.resetTimeIncrease();
    await helper.revertToSnapshot(orgTimeStamp);

    await fixedProductMarketMaker.castGovernanceApprovalVote(true, { from: investor1 });

    let votingResults = await fixedProductMarketMaker.getApprovingResult();
    expect(new BigNumber(votingResults[0]).isEqualTo(new BigNumber(0))).to.equal(true);
    expect(new BigNumber(votingResults[1]).isEqualTo(new BigNumber(5))).to.equal(true);
  });

  it('Should revert the yes vote and fill the no vote', async function() {
    await fixedProductMarketMaker.resetTimeIncrease();
    await helper.revertToSnapshot(orgTimeStamp);

    await fixedProductMarketMaker.castGovernanceApprovalVote(false, { from: investor1 });

    let votingResults = await fixedProductMarketMaker.getApprovingResult();

    expect(new BigNumber(votingResults[0]).isEqualTo(new BigNumber(5))).to.equal(true);
    expect(new BigNumber(votingResults[1]).isEqualTo(new BigNumber(0))).to.equal(true);
  });

  it('Should return the same results if user tries to vote no again', async function() {
    await fixedProductMarketMaker.resetTimeIncrease();
    await helper.revertToSnapshot(orgTimeStamp);

    await fixedProductMarketMaker.castGovernanceApprovalVote(false, { from: investor1 });

    let votingResults = await fixedProductMarketMaker.getApprovingResult();
    expect(new BigNumber(votingResults[0]).isEqualTo(new BigNumber(5))).to.equal(true);
    expect(new BigNumber(votingResults[1]).isEqualTo(new BigNumber(0))).to.equal(true);
  });


  it('Should allow multiple different governance should be able to vote', async function() {
    await fixedProductMarketMaker.castGovernanceApprovalVote(true, { from: investor2 });
    await fixedProductMarketMaker.castGovernanceApprovalVote(false, { from: trader });
    await fixedProductMarketMaker.castGovernanceApprovalVote(false, { from: oracle });
  });

  it('Should return the correct number of votes for the approval of the governance', async function() {
    let governanceVotes = await fixedProductMarketMaker.getApprovingResult();
    expect(new BigNumber(governanceVotes[0]).isEqualTo(new BigNumber(10))).to.equal(true);
    expect(new BigNumber(governanceVotes[1]).isEqualTo(new BigNumber(1))).to.equal(true);

    // To be able to conduct resolving we will do this
    await fixedProductMarketMaker.castGovernanceApprovalVote(true, { from: investor2 });
    await fixedProductMarketMaker.castGovernanceApprovalVote(true, { from: trader });
    await fixedProductMarketMaker.castGovernanceApprovalVote(true, { from: oracle });
  });

  it('Should return the 1-1 result', async function() {
    let outcome = await fixedProductMarketMaker.getResolvingOutcome();
    // We know the market is not in resolving yet.
    expect(new BigNumber(outcome[0]).isEqualTo(new BigNumber(1))).to.equal(true);
    expect(new BigNumber(outcome[1]).isEqualTo(new BigNumber(1))).to.equal(true);
  });


  it('Should revert because we are not in resolving period', async function() {
    const REVERT = "Market is not in resolving/ResolvingAfterDispute states";

    try {
      await fixedProductMarketMaker.castGovernanceResolvingVote(0, { from: investor1 });
      throw null;
    }
    catch (error) {
      assert(error, "Expected an error but did not get one");
      assert(error.message.includes(REVERT), "Expected '" + REVERT + "' but got '" + error.message + "' instead");
    }
  });

  let firstTimeResolve;
  it('Should be able to cast a resolving vote for gov', async function() {
    await fixedProductMarketMaker.resetTimeIncrease();
    await helper.revertToSnapshot(orgTimeStamp);

    let days = ((86400 * 3) + 10);

    await fixedProductMarketMaker.increaseTime(days);
    firstTimeResolve = await fixedProductMarketMaker.getCurrentTime();

    await fixedProductMarketMaker.castGovernanceResolvingVote(0, { from: investor1 });
  });

  it('Should return a resolved result after a vote', async function() {
    let outcome = await fixedProductMarketMaker.getResolvingOutcome();
    // We know the market is not in resolving yet.
    expect(new BigNumber(outcome[0]).isEqualTo(new BigNumber(1))).to.equal(true);
    expect(new BigNumber(outcome[1]).isEqualTo(new BigNumber(0))).to.equal(true);
  });

  it('Should allow multiple voters for the resolve', async function() {
    await fixedProductMarketMaker.resetTimeIncrease();
    await helper.revertToSnapshot(orgTimeStamp);

    let days = ((86400 * 3) + 10);

    await fixedProductMarketMaker.increaseTime(days);

    await fixedProductMarketMaker.castGovernanceResolvingVote(1, { from: investor2 });
    await fixedProductMarketMaker.castGovernanceResolvingVote(1, { from: trader });
    await fixedProductMarketMaker.castGovernanceResolvingVote(1, { from: oracle });
  });

  it('Should return not resolved after the voting', async function() {
    let outcome = await fixedProductMarketMaker.getResolvingOutcome();
    // We know the market is not in resolving yet.
    expect(new BigNumber(outcome[0]).isEqualTo(new BigNumber(0))).to.equal(true);
    expect(new BigNumber(outcome[1]).isEqualTo(new BigNumber(1))).to.equal(true);
  });

  // it('Should return the correct percentage.', async function() {
  //   let outcome = await fixedProductMarketMaker.getPercentage();
  //   let outcomeOne = new BigNumber(outcome[0]);
  //   let outcomeTwo = new BigNumber(outcome[1]);
  //   expect(outcomeOne.isEqualTo(new BigNumber(500000))).to.equal(true);
  //   expect(outcomeTwo.isEqualTo(new BigNumber(500000))).to.equal(true);
  // });
})
