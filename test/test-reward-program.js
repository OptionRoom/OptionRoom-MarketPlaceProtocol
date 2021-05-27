const ORMarketLib = artifacts.require('ORMarketLib')
const IERC20Contract = artifacts.require("../../contracts/mocks/ERC20DemoToken.sol");
const OracleMockContract = artifacts.require("../../contracts/mocks/RoomOraclePriceMock.sol");

const {
  prepareContracts, createNewMarket,setDeployer,
  executeControllerMethod, moveToActive, callControllerMethod,increaseTime,resetTimeIncrease,
  moveOneDay,forwardMarketToResolving,
} = require('./utils/market.js')
const { toBN } = web3.utils
var BigNumber = require('bignumber.js')

contract('Option room Reward program permissions check', function([deployer,
                                                                    creator, oracle, investor1, trader, investor2]) {

  let collateralToken
  let fixedProductMarketMaker
  let positionIds
  let controller;
  let rewardsProgram;

  let roomTokenFake;
  let oracleInstance;
  
  before(async function() {
    // assign the deployer for now, I will have to refactor things later.
    setDeployer(deployer);
    let retArray = await prepareContracts(creator, oracle, investor1, trader, investor2,deployer)
    controller = retArray[0];
    rewardsProgram = retArray[1];
    
    let rewardCenter = retArray[2];

    roomTokenFake = await IERC20Contract.new();
    oracleInstance = await OracleMockContract.new();

    // Mint some of the rooms at the system.
    await roomTokenFake.mint(toBN(200e18), {from : creator});

    await rewardCenter.setRoomOracleAddress(oracleInstance.address, {from : deployer});
  })

  it('can be created by factory', async function() {
    let retValues = await createNewMarket(creator)
    fixedProductMarketMaker = retValues[0]
    collateralToken = retValues[1]
    positionIds = retValues[2]
  })

  it('Should pass and change the attributes of the reward program', async function() {
    await rewardsProgram.setValidationRewardPerDay(toBN(1e17), {from : deployer});
    await rewardsProgram.setResolveRewardPerDay(toBN(1e17), {from : deployer});
    await rewardsProgram.setTradeRewardPerDay(toBN(1e17), {from : deployer});
    await rewardsProgram.setLPRewardPerDay(toBN(1e17), {from : deployer});
    await rewardsProgram.setMarketWeight(fixedProductMarketMaker.address, toBN(1e18), {from : deployer});
    await rewardsProgram.setIncludeSellInTradeRewards(false, {from : deployer});

    let validationRewardPerDay = await rewardsProgram.validationRewardPerDay.call();
    expect(new BigNumber(validationRewardPerDay).isEqualTo(new BigNumber(toBN(1e17)))).to.equal(true)

    let resolveRewardPerDay = await rewardsProgram.resolveRewardPerDay.call();
    expect(new BigNumber(resolveRewardPerDay).isEqualTo(new BigNumber(toBN(1e17)))).to.equal(true)

    let tradeRewardPerDay = await rewardsProgram.tradeRewardPerDay.call();
    expect(new BigNumber(tradeRewardPerDay).isEqualTo(new BigNumber(toBN(1e17)))).to.equal(true)

    let lpRewardPerDay = await rewardsProgram.lpRewardPerDay.call();
    expect(new BigNumber(lpRewardPerDay).isEqualTo(new BigNumber(toBN(1e17)))).to.equal(true)

    let lpMarketsWeights = await rewardsProgram.lpMarketsWeight.call(fixedProductMarketMaker.address);
    expect(new BigNumber(lpMarketsWeights).isEqualTo(new BigNumber(toBN(1e18)))).to.equal(true)

    let includeSellInTradeRewards = await rewardsProgram.includeSellInTradeRewards.call();
    expect(includeSellInTradeRewards).to.equal(false);
  })

  it('Should revert because we are not in proper state', async function() {
    const REVERT = 'can not claim in Invalid, Validating, Rejected state';
    try {
      await rewardsProgram.claimLPReward(fixedProductMarketMaker.address, {from : creator});
      throw null
    } catch (error) {
      assert(error, 'Expected an error but did not get one')
      assert(error.message.includes(REVERT), 'Expected \'' + REVERT + '\' but got \'' + error.message + '\' instead')
    }
  })

  it('Should not revert and continue with no issues.', async function() {
      await forwardMarketToResolving(fixedProductMarketMaker, investor1, trader, investor2);
      await rewardsProgram.claimLPReward(fixedProductMarketMaker.address, {from : creator});
  })
})
