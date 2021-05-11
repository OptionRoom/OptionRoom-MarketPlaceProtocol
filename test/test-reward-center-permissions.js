const ORMarketLib = artifacts.require('ORMarketLib')
const IERC20Contract = artifacts.require("../../contracts/mocks/ERC20DemoToken.sol");
const OracleMockContract = artifacts.require("../../contracts/mocks/RoomOraclePriceMock.sol");

const {
  prepareContracts, createNewMarket,setDeployer,
} = require('./utils/market.js')
const { toBN } = web3.utils
var BigNumber = require('bignumber.js')

contract('Option room Reward program permissions check', function([deployer,
                                                          creator, oracle, investor1, trader, investor2]) {

  let collateralToken
  let fixedProductMarketMaker
  let positionIds
  let controller;
  // let rewardsProgram;
  let rewardCenter;
  
  let roomTokenFake;
  let oracleInstance;

  before(async function() {
    // assign the deployer for now, I will have to refactor things later.
    setDeployer(deployer);
    let retArray = await prepareContracts(creator, oracle, investor1, trader, investor2,deployer)
    controller = retArray[0];
    // rewardsProgram = retArray[1];
    rewardCenter = retArray[2];
    

    // Setting the court token sample.
    roomTokenFake = await IERC20Contract.new();
    oracleInstance = await OracleMockContract.new();

    // Mint some of the rooms at the system.
    await roomTokenFake.mint(toBN(200e18), {from : creator});
  })

  it('can be created by factory', async function() {
    let retValues = await createNewMarket(creator)
    fixedProductMarketMaker = retValues[0]
    collateralToken = retValues[1]
    positionIds = retValues[2]
  })
  
  it('Should fail because sender is not governor or guardian', async function() {
    const REVERT = 'caller is not governor or guardian';
    try {
      await rewardCenter.setRewardProgram(trader, {from : controller.address});
      throw null
    } catch (error) {
      assert(error, 'Expected an error but did not get one')
      assert(error.message.includes(REVERT), 'Expected \'' + REVERT + '\' but got \'' + error.message + '\' instead')
    }
  })

  it('Should pass and change the reward program because I am the guardian.', async function() {
      await rewardCenter.setRewardProgram(oracle, {from : deployer});
  })


  it('Should fail to set room address', async function() {
    const REVERT = 'caller is not governor or guardian';
    try {
      await rewardCenter.setRoomAddress(roomTokenFake.address, {from : controller.address});
      throw null
    } catch (error) {
      assert(error, 'Expected an error but did not get one')
      assert(error.message.includes(REVERT), 'Expected \'' + REVERT + '\' but got \'' + error.message + '\' instead')
    }
  })

  it('Should set room address.', async function() {
    await rewardCenter.setRoomAddress(roomTokenFake.address, {from : deployer});

    await roomTokenFake.approve(rewardCenter.address, toBN(100e18), { from: creator })
    await rewardCenter.deposit(toBN(100e18), { from: creator })
  })


  it('Should fail to set room oracle', async function() {
    const REVERT = 'caller is not governor or guardian';
    try {
      await rewardCenter.setRoomOraclePrice(roomTokenFake.address, {from : controller.address});
      throw null
    } catch (error) {
      assert(error, 'Expected an error but did not get one')
      assert(error.message.includes(REVERT), 'Expected \'' + REVERT + '\' but got \'' + error.message + '\' instead')
    }
  })

  it('Should manage to set the room oracle', async function() {
    await rewardCenter.setRoomOraclePrice(oracleInstance.address, {from : deployer});
  })
  
  
  it('Should fail to send room reward', async function() {
    const REVERT = 'only reward program allowed to send rewards';
    try {
      await rewardCenter.sendRoomReward(trader, toBN(1e18), {from : controller.address});
      throw null
    } catch (error) {
      assert(error, 'Expected an error but did not get one')
      assert(error.message.includes(REVERT), 'Expected \'' + REVERT + '\' but got \'' + error.message + '\' instead')
    }
  })

  it('Should be able to send rewards.', async function() {
    let amount = toBN(1e18);
    await roomTokenFake.approve(rewardCenter.address, amount, { from: trader })
    await rewardCenter.sendRoomReward(trader, amount,  "test", {from : oracle});
  })

  it('Should fail to send room rewards ERC20', async function() {
    const REVERT = 'only reward program allowed to send rewards';
    try {
      await rewardCenter.sendRoomRewardByERC20Value(trader, toBN(0), roomTokenFake.address, "test", {from : controller.address});
      throw null
    } catch (error) {
      assert(error, 'Expected an error but did not get one')
      assert(error.message.includes(REVERT), 'Expected \'' + REVERT + '\' but got \'' + error.message + '\' instead')
    }
  })

  it('Should manage to send room rewards ERC20.', async function() {
    await rewardCenter.sendRoomRewardByERC20Value(trader, toBN(0), roomTokenFake.address, "test", {from : oracle});
  })
})
