const ORMarketLib = artifacts.require('ORMarketLib')
const { expectEvent } = require('openzeppelin-test-helpers')
const {
  prepareContracts, createNewMarket,resetTimeIncrease,increaseTime,
  setDeployer, moveToActive,moveToResolved11, moveOneDay,
} = require('./utils/market.js')
const { toBN } = web3.utils
var BigNumber = require('bignumber.js')

contract('MarketMakerStates: test dispute market', function([deployer, creator, oracle, investor1, trader, investor2]) {
  let collateralToken
  let controller
  let fixedProductMarketMaker;

  let marketPendingPeriod = 1800;
  
  before(async function() {
    setDeployer(deployer);
    let retArray = await prepareContracts(creator, oracle, investor1, trader, investor2,deployer)
    controller = retArray[0];
    
    // Need to change the dispute period to a value that we can measure. Do it for one day
    await controller.setMarketDisputePeriod(86400);
  })

  it('can be created by factory', async function() {
    let retValues = await createNewMarket(creator)
    fixedProductMarketMaker = retValues[0]
    collateralToken = retValues[1]
  })
  
  it('Should check on the state change when voting from governance', async function() {
    await resetTimeIncrease();

    // Start should be shown as rejected.
    let state = await controller.getMarketState(fixedProductMarketMaker.address);
    expect(new BigNumber(state).isEqualTo(new BigNumber(ORMarketLib.MarketState.Validating))).to.equal(true);

    // approve it.
    await controller.castGovernanceValidatingVote(fixedProductMarketMaker.address,true,  { from: investor2 });
    await controller.castGovernanceValidatingVote(fixedProductMarketMaker.address, true, { from: trader });
    await controller.castGovernanceValidatingVote(fixedProductMarketMaker.address,true,  { from: oracle });

    await increaseTime(marketPendingPeriod);
    
    state = await controller.getMarketState(fixedProductMarketMaker.address);
    expect(new BigNumber(state).isEqualTo(new BigNumber(3))).to.equal(true);
  });

  const addedFunds1 = toBN(1e18)
  it('can buy tokens from it', async function() {
    const investmentAmount = toBN(1e18)
    const buyOutcomeIndex = 1;

    await collateralToken.deposit({ value: addedFunds1, from: investor1 });
    await collateralToken.approve(controller.address, addedFunds1, { from: investor1 });
    await controller.marketAddLiquidity(fixedProductMarketMaker.address, addedFunds1, { from: investor1 });

    // we already have 2 yeses and 2 nos
    await collateralToken.deposit({ value: investmentAmount, from: trader });
    await collateralToken.approve(controller.address, investmentAmount, { from: trader });
    
    const FeeProtocol = await controller.FeeProtocol.call();
    const outcomeTokensToBuyFinal = await fixedProductMarketMaker.calcBuyAmountProtocolFeesIncluded(investmentAmount, buyOutcomeIndex, FeeProtocol);
    await controller.marketBuy(fixedProductMarketMaker.address, investmentAmount, buyOutcomeIndex, outcomeTokensToBuyFinal, { from: trader });
  })

  let firstTimeResolve;
  it('Should be able to cast a resolving vote for gov', async function() {
    await resetTimeIncrease();
    await increaseTime(marketPendingPeriod);

    let days = ((86400 * 3) + 10);

    await increaseTime(days);
    await controller.castGovernanceResolvingVote(fixedProductMarketMaker.address, 1, { from: investor1 });
    await controller.castGovernanceResolvingVote(fixedProductMarketMaker.address, 1, { from: investor2 });
    await controller.castGovernanceResolvingVote(fixedProductMarketMaker.address, 1, { from: trader });
    await controller.castGovernanceResolvingVote(fixedProductMarketMaker.address, 1, { from: oracle });
  });

  it('Should revert because we are not in dispute period', async function() {
    const REVERT = "Market is not in dispute state";

    try {
      await controller.disputeMarket(fixedProductMarketMaker.address, "I dont want to play", { from: trader });
      throw null;
    }
    catch (error) {
      assert(error, "Expected an error but did not get one");
      assert(error.message.includes(REVERT), "Expected '" + REVERT + "' but got '" + error.message + "' instead");
    }
  });

  it('Should be able to cast a dispute for a market', async function() {
    // Initially here we are the resolving state !
    let state = await controller.getMarketState(fixedProductMarketMaker.address);
    expect(new BigNumber(state).isEqualTo(new BigNumber(5))).to.equal(true);
    let days = ((86400 * 5) + 1000);
    await resetTimeIncrease();
    await increaseTime(days);
    const createTx = await controller.disputeMarket(fixedProductMarketMaker.address, "Might just pass", { from: trader });
    let marketsInfo = await controller.getMarketInfo(fixedProductMarketMaker.address);
    let dis =  marketsInfo['disputeTotalBalances'];
    expectEvent.inLogs(createTx.logs, 'DisputeSubmittedEvent', {
      disputer: trader,
      market: fixedProductMarketMaker.address,
      reachThresholdFlag: (marketsInfo['disputedFlag'] == 'true' ),
    });

    let traderBalances = await fixedProductMarketMaker.getBalances(trader);
    
    let totalBalances = new BigNumber(traderBalances[0]).plus(new BigNumber(traderBalances[1]));
    
    const { disputeTotalBalances } = createTx.logs.find(
      ({ event }) => event === 'DisputeSubmittedEvent'
    ).args;
    
    let disputeTotalBalancesValue = new BigNumber(disputeTotalBalances);
    expect(disputeTotalBalancesValue.isEqualTo(totalBalances)).to.equal(true);
    
    state = await controller.getMarketState(fixedProductMarketMaker.address);
    expect(new BigNumber(state).isEqualTo(new BigNumber(ORMarketLib.MarketState.DisputePeriod))).to.equal(true);

    const callArgs = [
      fixedProductMarketMaker.address,
      trader
    ]
    
    // some question about this one...
    let disputersInfo =await  controller.marketDisputersInfo.call(fixedProductMarketMaker.address, trader);
    // let balances = disputersInfo['balances'];
    // let reason = disputersInfo['reason'];
  });


  it('Should revert because address already submitted', async function() {
    const REVERT = "User already dispute";

    try {
      await controller.disputeMarket(fixedProductMarketMaker.address, "I will try again", { from: trader });
      throw null;
    }
    catch (error) {
      assert(error, "Expected an error but did not get one");
      assert(error.message.includes(REVERT), "Expected '" + REVERT + "' but got '" + error.message + "' instead");
    }
  });


  it('Should revert because address do not have any balance', async function() {
    const REVERT = "Low holding to dispute";

    try {
      await controller.disputeMarket(fixedProductMarketMaker.address, "I will try again", { from: oracle });
      throw null;
    }
    catch (error) {
      assert(error, "Expected an error but did not get one");
      assert(error.message.includes(REVERT), "Expected '" + REVERT + "' but got '" + error.message + "' instead");
    }
  });

  it('Should revert when adding new liquidity, we are not active', async function() {
    const REVERT = "liquidity can be added only in active/Validating state";

    try {
      await collateralToken.deposit({ value: addedFunds1, from: investor1 });
      await collateralToken.approve(controller.address, addedFunds1, { from: investor1 });
      await controller.marketAddLiquidity(fixedProductMarketMaker.address, addedFunds1, { from: investor1 });
      throw null;
    }
    catch (error) {
      assert(error, "Expected an error but did not get one");
      assert(error.message.includes(REVERT), "Expected '" + REVERT + "' but got '" + error.message + "' instead");
    }
  });

  it('Should revert when adding new liquidity, we are not active', async function() {
    const REVERT = "Market is not in active state";
    const investmentAmount = toBN(1e18)
    const buyOutcomeIndex = 1;
    try {
      const FeeProtocol = await controller.FeeProtocol.call();
      const outcomeTokensToBuyFinal = await fixedProductMarketMaker.calcBuyAmountProtocolFeesIncluded(investmentAmount, buyOutcomeIndex, FeeProtocol);
      await controller.marketBuy(fixedProductMarketMaker.address, investmentAmount, buyOutcomeIndex, outcomeTokensToBuyFinal, { from: trader });
      throw null;
    }
    catch (error) {
      assert(error, "Expected an error but did not get one");
      assert(error.message.includes(REVERT), "Expected '" + REVERT + "' but got '" + error.message + "' instead");
    }
  });

  it('Should revert because address already submitted', async function() {
    await moveOneDay();

    let state = await controller.getMarketState(fixedProductMarketMaker.address);
    expect(new BigNumber(state).isEqualTo(new BigNumber(ORMarketLib.MarketState.Resolved))).to.equal(true);
  });
})
