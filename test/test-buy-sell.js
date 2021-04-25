var chai = require('chai');

//use default BigNumber
chai.use(require('chai-bignumber')());

const { expectEvent } = require('openzeppelin-test-helpers')
// const { getConditionId, getCollectionId, getPositionId } = require('@gnosis.pm/conditional-tokens-contracts/utils/id-helpers')(web3.utils)
const { randomHex, toBN, fromAscii, toAscii } = web3.utils

const ConditionalTokens = artifacts.require('ConditionalTokens')
const WETH9 = artifacts.require('WETH9')
const PredictionMarketFactoryMock = artifacts.require('PredictionMarketFactoryMock')
const ORFPMarket = artifacts.require('ORFPMarket')

var BigNumber = require('bignumber.js');

contract('FixedProductMarketMakerBuySell', function([, creator, oracle, investor1, trader, investor2]) {

  const questionString = "Test";
  let conditionalTokens
  let collateralToken
  let fixedProductMarketMakerFactory
  let fixedProductMarketMaker

  let positionIds
  const feeFactor = toBN(0) // (0.3%)

  function addDays(theDate, days) {
    return new Date(theDate.getTime() + days*24*60*60*1000);
  }

  before(async function() {
    conditionalTokens = await ConditionalTokens.deployed();
    collateralToken = await WETH9.deployed();
    fixedProductMarketMakerFactory = await PredictionMarketFactoryMock.deployed()
    let deployedMarketMakerContract = await ORFPMarket.deployed();
    await fixedProductMarketMakerFactory.setTemplateAddress(deployedMarketMakerContract.address);
    await fixedProductMarketMakerFactory.assign(conditionalTokens.address);
    await fixedProductMarketMakerFactory.assignCollateralTokenAddress(collateralToken.address);
  })

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
    const fixedProductMarketMakerAddress = await fixedProductMarketMakerFactory.createMarketProposalTest.call(...createArgs)
    const createTx = await fixedProductMarketMakerFactory.createMarketProposalTest(...createArgs);
    expectEvent.inLogs(createTx.logs, 'FixedProductMarketMakerCreation', {
      creator: creator,
      fixedProductMarketMaker: fixedProductMarketMakerAddress,
      conditionalTokens: conditionalTokens.address,
      collateralToken: collateralToken.address,
    });

    fixedProductMarketMaker = await ORFPMarket.at(fixedProductMarketMakerAddress)
    positionIds = await fixedProductMarketMaker.getPositionIds();
  })

  const addedFunds1 = toBN(1e18)
  const expectedFundedAmounts = new Array(2).fill(addedFunds1)
  it('can be funded', async function() {
    await collateralToken.deposit({ value: addedFunds1, from: investor1 });
    await collateralToken.approve(fixedProductMarketMaker.address, addedFunds1, { from: investor1 });
    await fixedProductMarketMaker.addLiquidity(addedFunds1, { from: investor1 });

    // All of the amount have been converted...
    expect((await collateralToken.balanceOf(investor1)).toString()).to.equal("0");
    expect((await fixedProductMarketMaker.balanceOf(investor1)).toString()).to.equal(addedFunds1.toString());
  });


  it('Should return balance of account', async function() {
    // This should be zeros because we have the same rations of the both options.
    let retArray = await fixedProductMarketMaker.getBalances(investor1);
    expect(retArray[0].toString()).to.equal("0");
    expect(retArray[1].toString()).to.equal("0");

  })

  let marketMakerPool;
  it('can buy tokens from it', async function() {
    const investmentAmount = toBN(1e18)
    const buyOutcomeIndex = 1;

    // we already have 2 yeses and 2 nos
    await collateralToken.deposit({ value: investmentAmount, from: trader });
    await collateralToken.approve(fixedProductMarketMaker.address, investmentAmount, { from: trader });

    const outcomeTokensToBuy = await fixedProductMarketMaker.calcBuyAmount(investmentAmount, buyOutcomeIndex);

    await fixedProductMarketMaker.buy(investmentAmount, buyOutcomeIndex, outcomeTokensToBuy, { from: trader });

    expect((await collateralToken.balanceOf(trader)).toString()).to.equal("0");
    expect((await fixedProductMarketMaker.balanceOf(trader)).toString()).to.equal("0");
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

    let outcome1 = new BigNumber(await conditionalTokens.balanceOf(investor2, positionIds[0]));
    let outcome2 = new BigNumber(await conditionalTokens.balanceOf(investor2, positionIds[1]));

    // This should be zeros because we have the same rations of the both options.
    let retArray = await fixedProductMarketMaker.getBalances(investor1);
    expect(retArray[0].toString()).to.equal("0");
    expect(retArray[1].toString()).to.equal("0");

    retArray = await fixedProductMarketMaker.getBalances(investor2);
    expect(new BigNumber(retArray[0]).isEqualTo(outcome1)).to.equal(true);
    expect(new BigNumber(retArray[1]).isEqualTo(outcome2)).to.equal(true);
  })

  it('Should check balance after selling shares', async function() {
    let traderNoBalanceBefore= (await fixedProductMarketMaker.getBalances(trader))[1];
    let expectedSellValue = await fixedProductMarketMaker.calcSellReturnInv(toBN(traderNoBalanceBefore), 1, { from: trader })

    await conditionalTokens.setApprovalForAll(fixedProductMarketMaker.address, true, { from: trader });
    await fixedProductMarketMaker.sell(expectedSellValue, 1, { from: trader })

    let traderNoBalance = (await fixedProductMarketMaker.getBalances(trader))[1];
    let summation = new BigNumber(expectedSellValue).plus(new BigNumber(traderNoBalance));

    traderNoBalanceBefore = new BigNumber(traderNoBalanceBefore)

    let devision = summation.dividedBy(traderNoBalanceBefore).toFixed(0, BigNumber.ROUND_CEIL);
    expect(new BigNumber(devision).isEqualTo(new BigNumber(1))).to.equal(true);

    let colTokenBalance = new BigNumber((await collateralToken.balanceOf(trader)));
    expect(colTokenBalance.isGreaterThan(new BigNumber(0)));
  })
})