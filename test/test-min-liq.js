var chai = require('chai');

chai.use(require('chai-bignumber')());

const { expectEvent } = require('openzeppelin-test-helpers')
const { toBN } = web3.utils

let ConditionalTokensContract = artifacts.require("../../contracts/OR/ORConditionalTokens.sol");

const WETH9 = artifacts.require('WETH9')
const PredictionMarketFactoryMock = artifacts.require('PredictionMarketFactoryMock')
const ORFPMarket = artifacts.require('ORFPMarket')
const BigNumber = require('bignumber.js');
const ORMarketLib = artifacts.require('ORMarketLib')

const ORMarketController = artifacts.require('ORMarketController')
const CentralTimeForTesting = artifacts.require('CentralTimeForTesting')

contract('FixedProductMarketMaker: test min liquidity and withdrawal', function([, creator, oracle, investor1, trader, investor2]) {
  let conditionalTokens
  let collateralToken
  let fixedProductMarketMakerFactory
  let governanceMock
  let marketMakers = [];
  let centralTime;
  let fixedProductMarketMaker

  let pendingMarketMakersMap = new Map()

  const questionString = "Test"
  const feeFactor = toBN(3e15) // (0.3%)

  let marketValidationPeriod = 1800;

  // const minLiquidityFunding = toBN(1e18)
  const minLiquidityFunding = toBN(1e18)
  const addedFunds = toBN(2e18)
  const toRemoveFunds1 = toBN(1e18)

  async  function createConditionalTokensContract(theDate, days) {
    conditionalTokens = await ConditionalTokensContract.new();
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

    // set the min liquidity from here
    await governanceMock.setMarketMinShareLiq(minLiquidityFunding);

    // Setting the voting power.
    await governanceMock.setPower(investor1, 5);
    await governanceMock.setPower(investor2, 1);
    await governanceMock.setPower(trader, 2);
    await governanceMock.setPower(oracle, 3);
  })

  function addDays(theDate, days) {
    return new Date(theDate.getTime() + days*24*60*60*1000);
  }

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
    await centralTime.initializeTime();

    const fixedProductMarketMakerAddress = await fixedProductMarketMakerFactory.createMarketProposalTest.call(...createArgs)
    const createTx = await fixedProductMarketMakerFactory.createMarketProposalTest(...createArgs);
    expectEvent.inLogs(createTx.logs, 'FixedProductMarketMakerCreation', {
      creator,
      fixedProductMarketMaker: fixedProductMarketMakerAddress,
      conditionalTokens: conditionalTokens.address,
      collateralToken: collateralToken.address,
    });

    fixedProductMarketMaker = await ORFPMarket.at(fixedProductMarketMakerAddress);

    marketMakers.push(fixedProductMarketMaker);
    pendingMarketMakersMap.set(fixedProductMarketMaker.address,fixedProductMarketMaker );
  }

  it('can be funded', async function() {
    await createNewMarket();
    await collateralToken.deposit({ value: addedFunds, from: creator });
    await collateralToken.approve(fixedProductMarketMaker.address, addedFunds, { from: creator });
    await fixedProductMarketMaker.addLiquidity(addedFunds, { from: creator });
  });

  it('Should return the correct values for market min liq and controller min liq', async function() {
    const minLiq = await governanceMock.marketMinShareLiq.call();
    const marketCreatedMinLiq = await fixedProductMarketMaker.minShareLiq.call();

    // Checking that the value is the min liquidity
    expect(new BigNumber(minLiq).isEqualTo(new BigNumber(minLiquidityFunding))).to.equal(true);
    expect(new BigNumber(marketCreatedMinLiq).isEqualTo(new BigNumber(minLiquidityFunding))).to.equal(true);
  });

  it('Should fail to withdraw trying to remove more liquidity than min liquidity', async function() {
    const REVERT = "The remaining shares dropped under the minimum";

    try {
      await fixedProductMarketMaker.removeLiquidity(addedFunds,false, { from: creator });
      throw null;
    }
    catch (error) {
      assert(error, "Expected an error but did not get one");
      assert(error.message.includes(REVERT), "Expected '" + REVERT + "' but got '" + error.message + "' instead");
    }
  });

  it('Should withdraw, amount is lesser then the min liquidity and state in validation.', async function() {
    // let accountBalance =  await fixedProductMarketMaker.balanceOf(creator);
    await fixedProductMarketMaker.removeLiquidity(toRemoveFunds1, false, { from : creator });
  });


  it('Should fail to withdraw trying to remove more liquidity than min liquidity', async function() {
    const REVERT = "The remaining shares dropped under the minimum";

    await governanceMock.castGovernanceValidatingVote(fixedProductMarketMaker.address, false, { from: investor1 });
    await governanceMock.castGovernanceValidatingVote(fixedProductMarketMaker.address, false, { from: oracle });
    await governanceMock.castGovernanceValidatingVote(fixedProductMarketMaker.address, true, { from: investor2 });
    
    await centralTime.increaseTime(marketValidationPeriod + 100);

    let state = await governanceMock.getMarketState(fixedProductMarketMaker.address);
    
    // Rejected...
    expect(new BigNumber(state).isEqualTo(new BigNumber(ORMarketLib.MarketState.Rejected))).to.equal(true);
    
    // Got to manage to remove all of the rest of the liquidity because we are rejected.
    await fixedProductMarketMaker.removeLiquidity(toRemoveFunds1, false, { from: creator });
  });
})
