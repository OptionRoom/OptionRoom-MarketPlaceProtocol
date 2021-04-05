var chai = require('chai');

//use default BigNumber
chai.use(require('chai-bignumber')());

const { expectEvent } = require('openzeppelin-test-helpers')
const { getConditionId, getCollectionId, getPositionId } = require('@gnosis.pm/conditional-tokens-contracts/utils/id-helpers')(web3.utils)
const { randomHex, toBN } = web3.utils

const ConditionalTokens = artifacts.require('ConditionalTokens')
const WETH9 = artifacts.require('WETH9')
const FixedProductMarketMakerFactory = artifacts.require('FixedProductMarketMakerFactory')
const FixedProductMarketMaker = artifacts.require('FixedProductMarketMaker')

var BigNumber = require('bignumber.js');

contract('FixedProductMarketMaker', function([, creator, oracle, investor1, trader, investor2]) {
  const questionId = randomHex(32)
  const numOutcomes = 2
  const conditionId = getConditionId(oracle, questionId, numOutcomes)
  const collectionIds = Array.from(
    { length: numOutcomes },
    (_, i) => getCollectionId(conditionId, toBN(1).shln(i))
  );

  let conditionalTokens
  let collateralToken
  let fixedProductMarketMakerFactory
  let positionIds
  before(async function() {
    conditionalTokens = await ConditionalTokens.deployed();
    collateralToken = await WETH9.deployed();
    fixedProductMarketMakerFactory = await FixedProductMarketMakerFactory.deployed()
    positionIds = collectionIds.map(collectionId => getPositionId(collateralToken.address, collectionId))
  })

  let fixedProductMarketMaker;
  const feeFactor = toBN(3e15) // (0.3%)
  it('can be created by factory', async function() {
    await conditionalTokens.prepareCondition(oracle, questionId, numOutcomes);
    const createArgs = [
      conditionalTokens.address,
      collateralToken.address,
      [conditionId],
      feeFactor,
      { from: creator }
    ]
    const fixedProductMarketMakerAddress = await fixedProductMarketMakerFactory.createFixedProductMarketMaker.call(...createArgs)
    const createTx = await fixedProductMarketMakerFactory.createFixedProductMarketMaker(...createArgs);
    expectEvent.inLogs(createTx.logs, 'FixedProductMarketMakerCreation', {
      creator,
      fixedProductMarketMaker: fixedProductMarketMakerAddress,
      conditionalTokens: conditionalTokens.address,
      collateralToken: collateralToken.address,
      // conditionIds: [conditionId],
      fee: feeFactor,
    });

    fixedProductMarketMaker = await FixedProductMarketMaker.at(fixedProductMarketMakerAddress)
  })

  const addedFunds1 = toBN(10e18)
  const initialDistribution = [1, 1]
  const expectedFundedAmounts = new Array(2).fill(addedFunds1)
  it('can be funded', async function() {
    await collateralToken.deposit({ value: addedFunds1, from: investor1 });
    await collateralToken.approve(fixedProductMarketMaker.address, addedFunds1, { from: investor1 });
    const fundingTx = await fixedProductMarketMaker.addFunding(addedFunds1, initialDistribution, { from: investor1 });
    expectEvent.inLogs(fundingTx.logs, 'FPMMFundingAdded', {
      funder: investor1,
      // amountsAdded: expectedFundedAmounts,
      sharesMinted: addedFunds1,
    });

    const { amountsAdded } = fundingTx.logs.find(
      ({ event }) => event === 'FPMMFundingAdded'
    ).args;

    const { sharesMinted } = fundingTx.logs.find(
      ({ event }) => event === 'FPMMFundingAdded'
    ).args;

    expect(amountsAdded).to.have.lengthOf(expectedFundedAmounts.length);
    for (let i = 0; i < amountsAdded.length; i++) {
      expect(amountsAdded[i].toString()).to.equal(expectedFundedAmounts[i].toString());
    }

    expect((await collateralToken.balanceOf(investor1)).toString()).to.equal("0");
    expect((await fixedProductMarketMaker.balanceOf(investor1)).toString()).to.equal(addedFunds1.toString());

    for(let i = 0; i < positionIds.length; i++) {
      expect((await conditionalTokens.balanceOf(fixedProductMarketMaker.address, positionIds[i])).toString())
        .to.equal(expectedFundedAmounts[i].toString());
    }
  });

  let marketMakerPool;
  it('can buy tokens from it', async function() {
    const investmentAmount = toBN(1e18)
    const buyOutcomeIndex = 1;
    await collateralToken.deposit({ value: investmentAmount, from: trader });
    await collateralToken.approve(fixedProductMarketMaker.address, investmentAmount, { from: trader });

    const feeAmount = investmentAmount.mul(feeFactor).div(toBN(1e18));

    const outcomeTokensToBuy = await fixedProductMarketMaker.calcBuyAmount(investmentAmount, buyOutcomeIndex);

    await fixedProductMarketMaker.buy(investmentAmount, buyOutcomeIndex, outcomeTokensToBuy, { from: trader });

    expect((await collateralToken.balanceOf(trader)).toString()).to.equal("0");
    expect((await fixedProductMarketMaker.balanceOf(trader)).toString()).to.equal("0");

    marketMakerPool = []
    for(let i = 0; i < positionIds.length; i++) {
      let newMarketMakerBalance;
      if(i === buyOutcomeIndex) {
        newMarketMakerBalance = expectedFundedAmounts[i].add(investmentAmount).sub(feeAmount).sub(outcomeTokensToBuy);
        expect((await conditionalTokens.balanceOf(trader, positionIds[i])).toString()).
        to.equal(outcomeTokensToBuy.toString());
      } else {
        newMarketMakerBalance = expectedFundedAmounts[i].add(investmentAmount).sub(feeAmount);
        expect((await conditionalTokens.balanceOf(trader, positionIds[i])).toString()).to.equal("0");
      }
      expect((await conditionalTokens.balanceOf(fixedProductMarketMaker.address,
          positionIds[i])).toString()).to.equal(newMarketMakerBalance.toString());

      marketMakerPool[i] = newMarketMakerBalance
    }
  })

  it('can sell tokens to it', async function() {
    const returnAmount = toBN(5e17)
    const sellOutcomeIndex = 1;
    await conditionalTokens.setApprovalForAll(fixedProductMarketMaker.address, true, { from: trader });

    const feeAmount = returnAmount.mul(feeFactor).div(toBN(1e18).sub(feeFactor));

    const outcomeTokensToSell = await fixedProductMarketMaker.calcSellAmount(returnAmount, sellOutcomeIndex);

    await fixedProductMarketMaker.sell(returnAmount, sellOutcomeIndex, outcomeTokensToSell,  { from: trader } );

    expect((await collateralToken.balanceOf(trader)).toString()).to.equal(returnAmount.toString());
    expect((await fixedProductMarketMaker.balanceOf(trader)).toString()).to.equal("0");

    for(let i = 0; i < positionIds.length; i++) {
      let newMarketMakerBalance;
      if(i === sellOutcomeIndex) {
        newMarketMakerBalance = marketMakerPool[i].sub(returnAmount).sub(feeAmount).add(outcomeTokensToSell)
      } else {
        newMarketMakerBalance = marketMakerPool[i].sub(returnAmount).sub(feeAmount)
      }
      expect((await conditionalTokens.balanceOf(fixedProductMarketMaker.address, positionIds[i]))
        .toString()).to.equal(newMarketMakerBalance.toString());

      marketMakerPool[i] = newMarketMakerBalance
    }
  })

  const addedFunds2 = toBN(5e18)
  it('can continue being funded', async function() {
    await collateralToken.deposit({ value: addedFunds2, from: investor2 });
    await collateralToken.approve(fixedProductMarketMaker.address, addedFunds2, { from: investor2 });
    await fixedProductMarketMaker.addFunding(addedFunds2, [], {from : investor2 });

    expect((await collateralToken.balanceOf(investor2))).to.eql(toBN(0));
    let inv2Balance = new BigNumber(await fixedProductMarketMaker.balanceOf(investor2));
    expect(inv2Balance.isGreaterThan(new BigNumber("0"))).to.equal(true);

    for(let i = 0; i < positionIds.length; i++) {
      let newMarketMakerBalance =new BigNumber(await conditionalTokens.balanceOf(fixedProductMarketMaker.address, positionIds[i]))
      let marketPoolValueI = new BigNumber(marketMakerPool[i]);
      let marketPoolValueFundAdded = new BigNumber(marketMakerPool[i].add(addedFunds2));
      expect(newMarketMakerBalance.isGreaterThan(marketPoolValueI)).to.equal(true);

      // We need to make small adjustment here.
      marketMakerPool[i] = newMarketMakerBalance;

      let balanaceOfInvestor = new BigNumber(await conditionalTokens.balanceOf(investor2, positionIds[i]));
      expect(balanaceOfInvestor.isGreaterThanOrEqualTo(new BigNumber(0))).to.equal(true);
      expect(balanaceOfInvestor.isLessThan(new BigNumber(addedFunds2))).to.equal(true);
    }
  });

  const burnedShares1 = toBN(5e18)
  it('can be defunded', async function() {
    await fixedProductMarketMaker.removeFunding(burnedShares1,  {from : investor1 });

    let invCollateralToken = new BigNumber(await collateralToken.balanceOf(investor1));
    expect(invCollateralToken.isGreaterThanOrEqualTo(new BigNumber(0))).to.equal(true);

    let invFixedProductMarketMakerBalance = new BigNumber(await fixedProductMarketMaker.balanceOf(investor1));
    expect(invFixedProductMarketMakerBalance.isEqualTo(new BigNumber(addedFunds1.sub(burnedShares1)))).to.equal(true);

    for(let i = 0; i < positionIds.length; i++) {
      let newMarketMakerBalance = new BigNumber(await conditionalTokens.balanceOf(fixedProductMarketMaker.address, positionIds[i]))
      expect(newMarketMakerBalance.isLessThan(marketMakerPool[i])).to.equal(true);

      let conditionalTokensBalanace = new BigNumber(await conditionalTokens.balanceOf(investor1, positionIds[i]));

      let fundsFinal = new BigNumber(addedFunds1).minus(new BigNumber(expectedFundedAmounts[i]))
        .plus(new BigNumber(marketMakerPool[i])).minus(new BigNumber(newMarketMakerBalance));

      expect(conditionalTokensBalanace.isEqualTo(fundsFinal)).to.equal(true);

      marketMakerPool[i] = newMarketMakerBalance;
    }
  })
})
