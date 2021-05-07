const ORMarketLib = artifacts.require('ORMarketLib')

const {
  prepareContracts, createNewMarket,
  executeControllerMethod, moveToActive, conditionalApproveForAll, callControllerMethod,
  conditionalBalanceOf, moveToResolving,resetTimeIncrease,increaseTime,moveToResolved
} = require('./utils/market.js')
const { toBN } = web3.utils
var BigNumber = require('bignumber.js')


// TODO: Tareq, please add the withdraw of the votes for the resolving, and check the power reset.
contract('Option room: test proposal states', function([, creator, oracle, investor1, trader, investor2]) {
  let collateralToken
  let fixedProductMarketMaker
  let governanceMock

  let marketPendingPeriod = 1800;
  
  before(async function() {
    governanceMock = await prepareContracts(creator, oracle, investor1, trader, investor2)
  })

  it('can be created by factory', async function() {
    let retValues = await createNewMarket(creator)
    fixedProductMarketMaker = retValues[0]
    collateralToken = retValues[1]
  })
  
  let orgTimeStamp;
  it('Should pass because we are in the voting period', async function() {
    orgTimeStamp = governanceMock.getCurrentTime();

    await governanceMock.castGovernanceValidatingVote(fixedProductMarketMaker.address, true, { from: investor1 });

    let marketInformation = await governanceMock.getMarketInfo(fixedProductMarketMaker.address);
    let validatingVotesCount = marketInformation['validatingVotesCount'];

    expect(new BigNumber(validatingVotesCount[0]).isEqualTo(new BigNumber(0))).to.equal(true);
    expect(new BigNumber(validatingVotesCount[1]).isEqualTo(new BigNumber(5))).to.equal(true);
  });

  it('Should revert because the market is in pending state', async function() {
    const REVERT = "Market is not in validation state";
    let day = 1800 * 2;
    await increaseTime(day);
    try {
      await governanceMock.castGovernanceValidatingVote(fixedProductMarketMaker.address, true, { from: investor1 });
      throw null;
    }
    catch (error) {
      assert(error, "Expected an error but did not get one");
      assert(error.message.includes(REVERT), "Expected '" + REVERT + "' but got '" + error.message + "' instead");
    }
  });


  it('Should revert because address alread voted', async function() {
    await resetTimeIncrease();
    const REVERT = "user already voted";

    try {
      await governanceMock.castGovernanceValidatingVote(fixedProductMarketMaker.address, true, { from: investor1 });
      throw null;
    }
    catch (error) {
      assert(error, "Expected an error but did not get one");
      assert(error.message.includes(REVERT), "Expected '" + REVERT + "' but got '" + error.message + "' instead");
    }
  });

  it('Should be to unvote', async function() {
    await resetTimeIncrease();

    await governanceMock.withdrawGovernanceValidatingVote(fixedProductMarketMaker.address, { from: investor1 });
    // await governanceMock.withdrawGovernanceResolvingVote(fixedProductMarketMaker.address, { from: investor1 });

    let marketInformation = await governanceMock.getMarketInfo(fixedProductMarketMaker.address);
    let validatingVotesCount = marketInformation['validatingVotesCount'];

    expect(new BigNumber(validatingVotesCount[0]).isEqualTo(new BigNumber(0))).to.equal(true);
    expect(new BigNumber(validatingVotesCount[1]).isEqualTo(new BigNumber(0))).to.equal(true);
  });

  it('Should roll back because address already voted', async function() {
    await resetTimeIncrease();

    const REVERT = "user did not vote";

    try {
      await governanceMock.withdrawGovernanceValidatingVote(fixedProductMarketMaker.address, { from: investor1 });
      throw null;
    }
    catch (error) {
      assert(error, "Expected an error but did not get one");
      assert(error.message.includes(REVERT), "Expected '" + REVERT + "' but got '" + error.message + "' instead");
    }
  });


  it('Should allow multiple different governance to vote and check their status', async function() {
    await governanceMock.castGovernanceValidatingVote(fixedProductMarketMaker.address, true, { from: investor2 });
    await governanceMock.castGovernanceValidatingVote(fixedProductMarketMaker.address, false, { from: trader });
    await governanceMock.castGovernanceValidatingVote(fixedProductMarketMaker.address, false, { from: oracle });

    // Checking the results of the votes.
    let v2ValidatingVoter = await governanceMock.isValidatingVoter(fixedProductMarketMaker.address, investor2);
    let traderValidatingVoter = await governanceMock.isValidatingVoter(fixedProductMarketMaker.address, trader);
    let oracleValidatingVoter = await governanceMock.isValidatingVoter(fixedProductMarketMaker.address, oracle);
    let creatorValidatingVoter = await governanceMock.isValidatingVoter(fixedProductMarketMaker.address, creator);

    // We don't want to check on the third number as its insignificant to us.
    expect(new BigNumber(v2ValidatingVoter[0]).isEqualTo(new BigNumber(1))).to.equal(true);
    expect(v2ValidatingVoter[1]).to.equal(true);
    expect(new BigNumber(v2ValidatingVoter[2]).isEqualTo(new BigNumber(1))).to.equal(true);

    expect(new BigNumber(traderValidatingVoter[0]).isEqualTo(new BigNumber(2))).to.equal(true);
    expect(traderValidatingVoter[1]).to.equal(true);
    expect(new BigNumber(traderValidatingVoter[2]).isEqualTo(new BigNumber(0))).to.equal(true);

    expect(new BigNumber(oracleValidatingVoter[0]).isEqualTo(new BigNumber(3))).to.equal(true);
    expect(oracleValidatingVoter[1]).to.equal(true);
    expect(new BigNumber(oracleValidatingVoter[2]).isEqualTo(new BigNumber(0))).to.equal(true);

    expect(new BigNumber(creatorValidatingVoter[0]).isEqualTo(new BigNumber(0))).to.equal(true);
    expect(creatorValidatingVoter[1]).to.equal(false);
    expect(new BigNumber(creatorValidatingVoter[2]).isEqualTo(new BigNumber(0))).to.equal(true);
  });


  it('Should check on the state change when voting from governance', async function() {
    let marketInformation = await governanceMock.getMarketInfo(fixedProductMarketMaker.address);
    let validatingVotesCount = marketInformation['validatingVotesCount'];

    // Two voted no and 1 voted yes
    expect(new BigNumber(validatingVotesCount[0]).isEqualTo(new BigNumber(5))).to.equal(true);
    expect(new BigNumber(validatingVotesCount[1]).isEqualTo(new BigNumber(1))).to.equal(true);

    await resetTimeIncrease();
    await increaseTime(marketPendingPeriod);

    // Start should be shown as rejected.
    let state = await governanceMock.getMarketState(fixedProductMarketMaker.address);
    expect(new BigNumber(state).isEqualTo(new BigNumber(2))).to.equal(true);

    await resetTimeIncrease();

    // First try to reject it
    await governanceMock.withdrawGovernanceValidatingVote(fixedProductMarketMaker.address, { from: investor2 });
    await governanceMock.withdrawGovernanceValidatingVote(fixedProductMarketMaker.address, { from: trader });
    await governanceMock.withdrawGovernanceValidatingVote(fixedProductMarketMaker.address, { from: oracle });

    // approve it.
    await governanceMock.castGovernanceValidatingVote(fixedProductMarketMaker.address,true,  { from: investor2 });
    await governanceMock.castGovernanceValidatingVote(fixedProductMarketMaker.address, true, { from: trader });
    await governanceMock.castGovernanceValidatingVote(fixedProductMarketMaker.address,true,  { from: oracle });

    await increaseTime(marketPendingPeriod);
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

  it('Should return the 1-1 result', async function() {
    let outcome = await governanceMock.getResolvingOutcome(fixedProductMarketMaker.address);
    // We know the market is not in resolving yet.
    expect(new BigNumber(outcome[0]).isEqualTo(new BigNumber(1))).to.equal(true);
    expect(new BigNumber(outcome[1]).isEqualTo(new BigNumber(1))).to.equal(true);
  });


  it('Should revert because we are not in resolving period', async function() {
    const REVERT = "Market is not in resolving/ResolvingAfterDispute states";

    try {
      await governanceMock.castGovernanceResolvingVote(fixedProductMarketMaker.address, 0, { from: investor1 });
      throw null;
    }
    catch (error) {
      assert(error, "Expected an error but did not get one");
      assert(error.message.includes(REVERT), "Expected '" + REVERT + "' but got '" + error.message + "' instead");
    }
  });

  let firstTimeResolve;
  it('Should be able to cast a resolving vote for gov', async function() {
    await resetTimeIncrease();
    await increaseTime(marketPendingPeriod);

    let days = ((86400 * 3) + 10);

    await increaseTime(days);
    await governanceMock.castGovernanceResolvingVote(fixedProductMarketMaker.address, 0, { from: investor1 });
  });

  it('Should return a resolved result after a vote', async function() {
    let outcome = await governanceMock.getResolvingOutcome(fixedProductMarketMaker.address);
    // We know the market is not in resolving yet.
    expect(new BigNumber(outcome[0]).isEqualTo(new BigNumber(1))).to.equal(true);
    expect(new BigNumber(outcome[1]).isEqualTo(new BigNumber(0))).to.equal(true);
  });

  it('Should allow multiple voters for the resolve', async function() {
    await governanceMock.castGovernanceResolvingVote(fixedProductMarketMaker.address, 1, { from: investor2 });
    await governanceMock.castGovernanceResolvingVote(fixedProductMarketMaker.address, 1, { from: trader });
    await governanceMock.castGovernanceResolvingVote(fixedProductMarketMaker.address, 1, { from: oracle });
  });

  it('Should check the pending voters from gov', async function() {
    let govPendingVotersResults = await governanceMock.isResolvingVoter(fixedProductMarketMaker.address, investor2);
    let voteFlag = govPendingVotersResults["voteFlag"];
    let selection = govPendingVotersResults["selection"];
    let power = govPendingVotersResults["power"];

    expect(voteFlag).to.equal(true);
    expect(new BigNumber(selection).isEqualTo(new BigNumber(1))).to.equal(true);
    expect(new BigNumber(power).isEqualTo(new BigNumber(1))).to.equal(true);
  });

  it('Should test marketPendingVotersInfo to return the correct information', async function() {
    // Checking the results of the votes.
    let v2ResolvingVoter = await governanceMock.isResolvingVoter(fixedProductMarketMaker.address, investor2);
    let traderResolvingVoter = await governanceMock.isResolvingVoter(fixedProductMarketMaker.address, trader);
    let oracleResolvingVoter = await governanceMock.isResolvingVoter(fixedProductMarketMaker.address, oracle);
    let creatorResolvingVoter = await governanceMock.isResolvingVoter(fixedProductMarketMaker.address, creator);

    expect(new BigNumber(v2ResolvingVoter[0]).isEqualTo(new BigNumber(1))).to.equal(true);
    expect(v2ResolvingVoter[1]).to.equal(true);
    expect(new BigNumber(v2ResolvingVoter[2]).isEqualTo(new BigNumber(1))).to.equal(true);

    expect(new BigNumber(traderResolvingVoter[0]).isEqualTo(new BigNumber(2))).to.equal(true);
    expect(traderResolvingVoter[1]).to.equal(true);
    expect(new BigNumber(traderResolvingVoter[2]).isEqualTo(new BigNumber(1))).to.equal(true);

    expect(new BigNumber(oracleResolvingVoter[0]).isEqualTo(new BigNumber(3))).to.equal(true);
    expect(oracleResolvingVoter[1]).to.equal(true);
    expect(new BigNumber(oracleResolvingVoter[2]).isEqualTo(new BigNumber(1))).to.equal(true);

    expect(new BigNumber(creatorResolvingVoter[0]).isEqualTo(new BigNumber(0))).to.equal(true);
    expect(creatorResolvingVoter[1]).to.equal(false);
    expect(new BigNumber(creatorResolvingVoter[2]).isEqualTo(new BigNumber(0))).to.equal(true);
  });

  it('Should return not resolved after the voting', async function() {
    let outcome = await governanceMock.getResolvingOutcome(fixedProductMarketMaker.address);
    // We know the market is not in resolving yet.
    expect(new BigNumber(outcome[0]).isEqualTo(new BigNumber(0))).to.equal(true);
    expect(new BigNumber(outcome[1]).isEqualTo(new BigNumber(1))).to.equal(true);
  });

  it('Should check the validating voters from gov', async function() {
    let govPendingVotersResults = await governanceMock.isResolvingVoter(fixedProductMarketMaker.address, investor2);

    let voteFlag = govPendingVotersResults["voteFlag"];
    let selection = govPendingVotersResults["selection"];
    let power = govPendingVotersResults["power"];

    expect(voteFlag).to.equal(true);
    expect(new BigNumber(selection).isEqualTo(new BigNumber(1))).to.equal(true);
    expect(new BigNumber(power).isEqualTo(new BigNumber(1))).to.equal(true);
  });
})
