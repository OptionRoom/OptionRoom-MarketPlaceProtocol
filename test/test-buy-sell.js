const ORMarketLib = artifacts.require('ORMarketLib')

const { prepareContracts, createNewMarket,
  executeControllerMethod, moveToActive, conditionalApproveForAll, callControllerMethod,
  conditionalBalanceOf} = require("./utils/market.js")
const { toBN } = web3.utils
var BigNumber = require('bignumber.js');

contract('Markets buy sell redeem test', function([, creator, oracle, investor1, trader, investor2]) {

  let collateralToken
  let fixedProductMarketMaker
  let positionIds

  before(async function() {
    await prepareContracts(creator, oracle, investor1, trader, investor2)
  })

  it('can be created by factory', async function() {
    let retValues = await createNewMarket(creator);
    fixedProductMarketMaker = retValues[0];
    collateralToken = retValues[1];
    positionIds = retValues[2];
  })

  const addedFunds1 = toBN(1e18)
  it('can be funded', async function() {
    await collateralToken.deposit({ value: addedFunds1, from: investor1 });
    await collateralToken.approve(fixedProductMarketMaker.address, addedFunds1, { from: investor1 });
    await fixedProductMarketMaker.addLiquidity(addedFunds1, { from: investor1 });

    // All of the amount have been converted...
    expect((await collateralToken.balanceOf(investor1)).toString()).to.equal("0");
    expect((await fixedProductMarketMaker.balanceOf(investor1)).toString()).to.equal(addedFunds1.toString());
  });
  
  it('Should return balance of account', async function() {
    // This should be zeros because we have the same ratios of the both options.
    let retArray = await fixedProductMarketMaker.getBalances(investor1);
    expect(new BigNumber(retArray[0]).isEqualTo(0)).to.equal(true);
    expect(new BigNumber(retArray[1]).isEqualTo(0)).to.equal(true);

  })

  let marketMakerPool;
  it('Can not buy when the market is not in active state', async function() {
    const investmentAmount = toBN(1e18)
    const buyOutcomeIndex = 1;

    // we already have 2 yeses and 2 nos
    await collateralToken.deposit({ value: investmentAmount, from: trader });
    await collateralToken.approve(fixedProductMarketMaker.address, investmentAmount, { from: trader });
    const outcomeTokensToBuy = await fixedProductMarketMaker.calcBuyAmount(investmentAmount, buyOutcomeIndex);

    const REVERT = "Market is not in active state";
    try {
      await fixedProductMarketMaker.buy(investmentAmount, buyOutcomeIndex, outcomeTokensToBuy, { from: trader });
      throw null;
    }
    catch (error) {
      assert(error, "Expected an error but did not get one");
      assert(error.message.includes(REVERT), "Expected '" + REVERT + "' but got '" + error.message + "' instead");
    }
  })

  it('Should not be able to sell while market is not active', async function() {
    let traderNoBalanceBefore= (await fixedProductMarketMaker.getBalances(trader))[1];
    let expectedSellValue = await fixedProductMarketMaker.calcSellReturnInv(toBN(traderNoBalanceBefore), 1, { from: trader })

    await conditionalApproveForAll(fixedProductMarketMaker, trader);

    const REVERT = "Market is not in active state";
    try {
      await fixedProductMarketMaker.sell(expectedSellValue, 1, { from: trader })
      throw null;
    }
    catch (error) {
      assert(error, "Expected an error but did not get one");
      assert(error.message.includes(REVERT), "Expected '" + REVERT + "' but got '" + error.message + "' instead");
    }
  })

  it('Should vote for the approval of this created market', async function() {
    const inv1Attr = [ fixedProductMarketMaker.address, true, { from: investor1 },]
    const inv2Attr = [ fixedProductMarketMaker.address, false, { from: investor2 },]
    const oracleAttr = [ fixedProductMarketMaker.address, false, { from: oracle },]

    await executeControllerMethod("castGovernanceValidatingVote" , inv1Attr);
    await executeControllerMethod("castGovernanceValidatingVote" , inv2Attr);
    await executeControllerMethod("castGovernanceValidatingVote" , oracleAttr);
  });

  it('can buy tokens from it', async function() {
    const investmentAmount = toBN(1e18)
    const buyOutcomeIndex = 1;

    // await fixedProductMarketMaker.increaseTime(marketPendingPeriod);
    // await centralTime.increaseTime(marketPendingPeriod);
    await moveToActive();

    // let state = await governanceMock.getMarketState(fixedProductMarketMaker.address);
    let state = await callControllerMethod("getMarketState" , [fixedProductMarketMaker.address]);
    expect(new BigNumber(state).isEqualTo(new BigNumber(ORMarketLib.MarketState.Active))).to.equal(true);

    // we already have 2 yeses and 2 nos
    await collateralToken.deposit({ value: investmentAmount, from: trader });
    await collateralToken.approve(fixedProductMarketMaker.address, investmentAmount, { from: trader });

    const outcomeTokensToBuy = await fixedProductMarketMaker.calcBuyAmount(investmentAmount, buyOutcomeIndex);
    await fixedProductMarketMaker.buy(investmentAmount, buyOutcomeIndex, outcomeTokensToBuy, { from: trader });
  })

  const addedFunds2 = toBN(1e18)
  it('can continue being funded', async function() {
    await collateralToken.deposit({ value: addedFunds2, from: investor2 });
    await collateralToken.approve(fixedProductMarketMaker.address, addedFunds2, { from: investor2 });
    await fixedProductMarketMaker.addLiquidity(addedFunds2, {from : investor2 });

    expect((await collateralToken.balanceOf(investor2))).to.eql(toBN(0));
    let inv2Balance = new BigNumber(await fixedProductMarketMaker.balanceOf(investor2));
    expect(inv2Balance.isGreaterThan(new BigNumber("0"))).to.equal(true);
  });

  it('Should return balance of account', async function() {
    let outcome1 = new BigNumber(await conditionalBalanceOf(investor2, positionIds[0]));
    let outcome2 = new BigNumber(await conditionalBalanceOf(investor2, positionIds[1]));
    
    // This should be zeros because we have the same rations of the both options.
    let retArray = await fixedProductMarketMaker.getBalances(investor1);
    expect(new BigNumber(retArray[0]).isEqualTo(new BigNumber(0))).to.equal(true);
    expect(new BigNumber(retArray[1]).isEqualTo(new BigNumber(0))).to.equal(true);

    retArray = await fixedProductMarketMaker.getBalances(investor2);
    expect(new BigNumber(retArray[0]).isEqualTo(new BigNumber(outcome1))).to.equal(true);
    expect(new BigNumber(retArray[1]).isEqualTo(new BigNumber(outcome2))).to.equal(true);
  })

  let traderNoBalanceBefore
  let expectedSellValue
  
  it('Should be able to sell', async function() {
    traderNoBalanceBefore= (await fixedProductMarketMaker.getBalances(trader))[1];
    expectedSellValue = await fixedProductMarketMaker.calcSellReturnInv(toBN(traderNoBalanceBefore), 1, { from: trader })
    
    // the first attribute is the amount, then the index you want to sell.
    await fixedProductMarketMaker.sell(expectedSellValue, 1, { from: trader })
  })

  it('Should give the correct results after selling options', async function() {
    let traderNoBalanceAfterSell = (await fixedProductMarketMaker.getBalances(trader))[1];
    let summation = new BigNumber(expectedSellValue).plus(new BigNumber(traderNoBalanceAfterSell));

    traderNoBalanceBefore = new BigNumber(traderNoBalanceBefore)

    let divisionResult = summation.dividedBy(traderNoBalanceBefore).toFixed(0, BigNumber.ROUND_FLOOR);
    expect(new BigNumber(divisionResult).isEqualTo(new BigNumber(1))).to.equal(true);

    let colTokenBalance = new BigNumber((await collateralToken.balanceOf(trader)));
    expect(colTokenBalance.isGreaterThan(new BigNumber(0)));
  })
})
