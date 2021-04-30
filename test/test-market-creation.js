var chai = require('chai');

chai.use(require('chai-bignumber')());

const { expectEvent } = require('openzeppelin-test-helpers')
const { toBN } = web3.utils

let ConditionalTokensContract = artifacts.require("../../contracts/OR/ORConditionalTokens.sol");

const WETH9 = artifacts.require('WETH9')
const ERC20DemoToken = artifacts.require('ERC20DemoToken')
const PredictionMarketFactoryMock = artifacts.require('PredictionMarketFactoryMock')
const ORFPMarket = artifacts.require('ORFPMarket')
const ORMarketController = artifacts.require('ORMarketController')
const CentralTimeForTesting = artifacts.require('CentralTimeForTesting')

contract('FixedProductMarketMaker', function([, creator, oracle, investor1, trader, investor2]) {
  let conditionalTokens
  let collateralToken1
  let collateralToken2
  let fixedProductMarketMakerFactory
  let governanceMock
  let centralTime;
  let marketMakers = [];

  const questionString = "Test"
  const feeFactor = toBN(0) // (0.3%)

  async  function createConditionalTokensContract(theDate, days) {
    conditionalTokens = await ConditionalTokensContract.new();
  }

  // let positionIds
  before(async function() {
    await createConditionalTokensContract();

    collateralToken1 = await WETH9.deployed();
    collateralToken2 = await ERC20DemoToken.deployed();
    fixedProductMarketMakerFactory = await PredictionMarketFactoryMock.deployed()
    governanceMock = await ORMarketController.deployed()
    centralTime = await CentralTimeForTesting.deployed();

    // Assign the timer to the governance.
    await fixedProductMarketMakerFactory.setCentralTimeForTesting(centralTime.address);
    await governanceMock.setCentralTimeForTesting(centralTime.address);

    // Assign the timer to the governance.
    await fixedProductMarketMakerFactory.setCentralTimeForTesting(centralTime.address);
    await governanceMock.setCentralTimeForTesting(centralTime.address);

    let deployedMarketMakerContract = await ORFPMarket.deployed();
    await fixedProductMarketMakerFactory.setTemplateAddress(deployedMarketMakerContract.address);

    await fixedProductMarketMakerFactory.assign(conditionalTokens.address);
    await fixedProductMarketMakerFactory.assignGovernanceContract(governanceMock.address);

    await governanceMock.setPower(investor1, 5);
    await governanceMock.setPower(investor2, 1);
    await governanceMock.setPower(trader, 2);
    await governanceMock.setPower(oracle, 3);
  })

  function addDays(theDate, days) {
    return new Date(theDate.getTime() + days*24*60*60*1000);
  }

  const addedFunds1 = toBN(10e18)
  const addedFunds = toBN(1e18)
  async function createNewMarket(collateralToken, isERC20) {
    let now = new Date();
    let resolvingEndDate = addDays(now, 5);
    let endTime = Math.floor(addDays(now,3).getTime() / 1000);
    let resolvingEndTime = Math.floor(resolvingEndDate.getTime() / 1000);

    if (isERC20) {
      await collateralToken.mint(addedFunds1, { from: creator })
      await collateralToken.transfer(creator, addedFunds, { from: creator })
      let accountValue = await collateralToken.balanceOf(creator);
    }  else {
      await collateralToken.deposit({ value: addedFunds1, from: creator });
    }

    await collateralToken.approve(fixedProductMarketMakerFactory.address, addedFunds, { from: creator });

    const createArgs = [
      questionString,
      endTime,
      resolvingEndTime,
      collateralToken.address,
      addedFunds,
      feeFactor,
      { from: creator }
    ]
    const fixedProductMarketMakerAddress = await fixedProductMarketMakerFactory.createMarketProposalWithCollateralTest.call(...createArgs)
    const createTx = await fixedProductMarketMakerFactory.createMarketProposalWithCollateralTest(...createArgs);
    expectEvent.inLogs(createTx.logs, 'FixedProductMarketMakerCreation', {
      creator,
      fixedProductMarketMaker: fixedProductMarketMakerAddress,
      conditionalTokens: conditionalTokens.address,
      collateralToken: collateralToken.address,
    });

    let fixedProductMarketMaker = await ORFPMarket.at(fixedProductMarketMakerAddress);
    marketMakers.push(fixedProductMarketMaker);
  }

  it('Should create a new market with collateral tokens assigned', async function() {
    await createNewMarket(collateralToken1, false);
    await createNewMarket(collateralToken2, true);
  });
})
