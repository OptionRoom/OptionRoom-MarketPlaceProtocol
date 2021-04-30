var chai = require('chai');

chai.use(require('chai-bignumber')());

const { expectEvent } = require('openzeppelin-test-helpers')
const { toBN } = web3.utils

let ConditionalTokensContract = artifacts.require("../../contracts/OR/ORConditionalTokens.sol");

const WETH9 = artifacts.require('WETH9')
const PredictionMarketFactoryMock = artifacts.require('PredictionMarketFactoryMock')
const ORFPMarket = artifacts.require('ORFPMarket')
const BigNumber = require('bignumber.js');

const ORMarketController = artifacts.require('ORMarketController')
const CentralTimeForTesting = artifacts.require('CentralTimeForTesting')

contract('FixedProductMarketMaker: test min liquidity', function([, creator, oracle, investor1, trader, investor2]) {
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

  // const minLiquidityFunding = toBN(1e18)
  const minLiquidityFunding = toBN(100e18)
  const addedFunds = toBN(2e18)

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
    await collateralToken.deposit({ value: addedFunds, from: investor1 });
    await collateralToken.approve(fixedProductMarketMaker.address, addedFunds, { from: investor1 });
    await fixedProductMarketMaker.addLiquidity(addedFunds, { from: investor1 });
  });

  it('can be funded', async function() {
    const minLiq = await governanceMock.marketMinShareLiq.call();

    // Checking that the value is the min liquidity
    expect(new BigNumber(minLiq).isEqualTo(new BigNumber(minLiquidityFunding))).to.equal(true);
  });

  it('Should fail to withdraw because we are trying to remove more than initial liq', async function() {
    const REVERT = "burn amount exceeds balance";

    try {
      await fixedProductMarketMaker.removeLiquidity(addedFunds, { from: investor1 });
      throw null;
    }
    catch (error) {
      assert(error, "Expected an error but did not get one");
      assert(error.message.includes(REVERT), "Expected '" + REVERT + "' but got '" + error.message + "' instead");
    }
  });

  it('Should withdraw because we are trying to get less then the min liquidity', async function() {
    let accountBalance =  await fixedProductMarketMaker.balanceOf(investor1);
    await fixedProductMarketMaker.removeLiquidity(toBN(1e17), false, { from : investor1 });
  });
})
