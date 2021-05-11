const ORMarketLib = artifacts.require('ORMarketLib')

const IERC20Contract = artifacts.require("../../contracts/mocks/ERC20DemoToken.sol");
const CourtStakeContract = artifacts.require("../../contracts/CourtStake/CourtStake.sol");
const CentralTimeForTestingContract = artifacts.require('CentralTimeForTesting')

const {
  prepareContracts, createNewMarket,setDeployer,
} = require('./utils/market.js')

const {
  oneDay,
} = require('./utils/constants.js')

const { toBN } = web3.utils
var BigNumber = require('bignumber.js')

contract('Option room Reward program permissions check', function([deployer,
                                                                    creator, oracle, investor1, trader, investor2]) {

  let collateralToken
  let fixedProductMarketMaker
  let positionIds
  let controller;
  let rewardsProgram;
  
  let courtReservoir;
  let centralTime;
  let courtToken;
  
  let depositIndex1 = 0;
  let depositIndex2 = 0;
  
  before(async function() {
    // assign the deployer for now, I will have to refactor things later.
    setDeployer(deployer);
    let retArray = await prepareContracts(creator, oracle, investor1, trader, investor2,deployer)
    controller = retArray[0];
    rewardsProgram = retArray[1];

    centralTime = await CentralTimeForTestingContract.new();
    courtReservoir = await CourtStakeContract.new(deployer);
    
    // for the central time.
    await centralTime.initializeTime();
    await courtReservoir.setCentralTimeForTesting(centralTime.address);
    
    // Setting the court token sample.
    courtToken = await IERC20Contract.new();
    
    // Minting some tokens.
    await courtToken.mint(toBN(100e18), {from : trader});
    await courtToken.mint(toBN(10e18), {from : investor1});
    await courtToken.mint(toBN(2e18), {from : investor2});
    await courtToken.mint(toBN(1e18), {from : oracle});
    
    await courtReservoir.setCourtTokenAddress(courtToken.address, {from : deployer});
  })

  it('Should revert, can not set court if you are not gov or gua', async function() {
    const REVERT = 'caller is not governor or guardian';
    try {
      await courtReservoir.setCourtTokenAddress(courtToken.address, {from : investor2});
      throw null
    } catch (error) {
      assert(error, 'Expected an error but did not get one')
      assert(error.message.includes(REVERT), 'Expected \'' + REVERT + '\' but got \'' + error.message + '\' instead')
    }
  })
  
  it('can be created by factory', async function() {
    let retValues = await createNewMarket(creator)
    fixedProductMarketMaker = retValues[0]
    collateralToken = retValues[1]
    positionIds = retValues[2]
  })

  let amount = toBN(1e18);
  it('Should be able to deposit token at court', async function() {
    await courtToken.approve(courtReservoir.address, amount, { from: trader })
    await courtReservoir.deposit(amount, {from : trader});
    depositIndex1++;
  })

  it('Should return the correct amount of tokens at court contract', async function() {
    let courtReservoirBalance = await courtToken.balanceOf(courtReservoir.address);
    expect(new BigNumber(courtReservoirBalance).isEqualTo(new BigNumber(amount))).to.equal(true)
  })

  it('Should be able to deposit more tokens', async function() {
    await courtToken.approve(courtReservoir.address, amount, { from: trader })
    await courtReservoir.deposit(amount, {from : trader});
    depositIndex1++;
  })

  function getPower(amountToCalculate, daysPassed, depositIndex) {
    let rightSideValue = (new BigNumber(3).multipliedBy(new BigNumber(amountToCalculate).multipliedBy(daysPassed/50))).multipliedBy(toBN(depositIndex));
    let leftSideValue = new BigNumber(amountToCalculate).multipliedBy(depositIndex);
    return rightSideValue.plus(leftSideValue);
  }
  
  it('Should return the correct value of the user power', async function() {
    let result = getPower(amount, 0, depositIndex1);
    let userPower = await courtReservoir.getUserPower(trader);
    expect(new BigNumber(userPower).isEqualTo(result)).to.equal(true)
  })

  // For some reason its not working !!!
  it('Should be able to withdraw immediately from court contract', async function() {
    await courtReservoir.withdraw(amount, {from : trader});
    depositIndex1--;

    let courtReservoirBalance = await courtToken.balanceOf(courtReservoir.address);
    expect(new BigNumber(courtReservoirBalance).isEqualTo(new BigNumber(amount))).to.equal(true)

    let userBalanace = await courtToken.balanceOf(courtReservoir.address);
    expect(new BigNumber(userBalanace).isEqualTo(new BigNumber(amount))).to.equal(true)
  })

  it('Should return the correct result after a user withdrawn some of his tokens', async function() {
    let result = getPower(amount, 0, depositIndex1);
    let userPower = await courtReservoir.getUserPower(trader);
    expect(new BigNumber(userPower).isEqualTo(result)).to.equal(true)
  })


  it('Should fail to withdraw because amount is above', async function() {
    let amountToWithdraw = toBN(2e18);
    const REVERT = 'amount exceed deposited amount';
    try {
      await courtReservoir.withdraw(amountToWithdraw, {from : trader});
      throw null
    } catch (error) {
      assert(error, 'Expected an error but did not get one')
      assert(error.message.includes(REVERT), 'Expected \'' + REVERT + '\' but got \'' + error.message + '\' instead')
    }
  })


  let investorDepositAmount = toBN(1e18);
  it('Should be able to deposit court from another account', async function() {
    await courtToken.approve(courtReservoir.address, investorDepositAmount, { from: investor1 })
    await courtReservoir.deposit(investorDepositAmount, {from : investor1});
    depositIndex2++;
  })

  it('Should return the correct result for trader (User 1)', async function() {
    let result = getPower(amount, 0,depositIndex1);
    let userPower = await courtReservoir.getUserPower(trader);
    expect(new BigNumber(userPower).isEqualTo(result)).to.equal(true)
  })

  it('Should return the correct result for investor1 (User 2)', async function() {
    let result = getPower(amount, 0, depositIndex2);
    let userPower = await courtReservoir.getUserPower(investor1);
    expect(new BigNumber(userPower).isEqualTo(result)).to.equal(true)
  })


  it('Should work while withdrawing parts of the total values of an account numbers', async function() {
    let toRemoveAmount = toBN(1e17);
    let courtReservoirBalance;
    let resBalanceBefore = await courtToken.balanceOf(courtReservoir.address);
    let userBalanaceBefore = await courtToken.balanceOf(trader);
    
    for (let i = 0; i < 10; i++) {
      await courtReservoir.withdraw(toRemoveAmount, {from : trader});
      courtReservoirBalance = await courtToken.balanceOf(courtReservoir.address);
      let number = new BigNumber(courtReservoirBalance).plus(new BigNumber(toRemoveAmount).multipliedBy(i +1))
      expect(number.isEqualTo(new BigNumber(resBalanceBefore))).to.equal(true)

      let userBalanace = await courtToken.balanceOf(trader);
      let userBalanaceNumber = new BigNumber(userBalanace).minus(new BigNumber(toRemoveAmount).multipliedBy(i +1))
      expect(userBalanaceNumber.isEqualTo(userBalanaceBefore)).to.equal(true)
    }
  })
  
  it('Should revert because caller is not gov or guardian', async function() {
    const REVERT = 'caller is not governor or guardian';
    try {
      await courtReservoir.suspendPermission(investor1, true, {from : oracle});
      throw null
    } catch (error) {
      assert(error, 'Expected an error but did not get one')
      assert(error.message.includes(REVERT), 'Expected \'' + REVERT + '\' but got \'' + error.message + '\' instead')
    }
  })

  it('Should revert because caller is not gov or guardian', async function() {
    const REVERT = 'Caller has no permission to suspend';
    try {
      await courtReservoir.suspendAccount(oracle, oneDay, {from : investor1});
      throw null
    } catch (error) {
      assert(error, 'Expected an error but did not get one')
      assert(error.message.includes(REVERT), 'Expected \'' + REVERT + '\' but got \'' + error.message + '\' instead')
    }
  })

  it('Should pass and make investor1 able to suspend users', async function() {
    await courtReservoir.suspendPermission(investor1, true, {from : deployer});
  })

  it('Should return true because investor one can suspend users', async function() {
    let result = await courtReservoir.hasSuspendPermission.call(investor1);
    expect(result).to.equal(true)
  })

  it('Should pass and make remove investor1 from ability to suspend', async function() {
    await courtReservoir.suspendPermission(investor1, false, {from : deployer});
  })

  it('Should return false because investor one can not suspend users', async function() {
    let result = await courtReservoir.hasSuspendPermission.call(investor1);
    expect(result).to.equal(false)
  })


  it('Should revert because caller is not gov or guardian', async function() {
    const REVERT = 'caller is not governor or guardian';
    try {
      await courtReservoir.suspendAccountByGovOrGur(oracle, oneDay, {from : investor1});
      throw null
    } catch (error) {
      assert(error, 'Expected an error but did not get one')
      assert(error.message.includes(REVERT), 'Expected \'' + REVERT + '\' but got \'' + error.message + '\' instead')
    }
  })
  
  it('Should return false because investor one can not suspend users', async function() {
    await courtReservoir.suspendAccountByGovOrGur(investor2, 1, {from : deployer});
  })

  it('Should revert because caller is not gov or guardian', async function() {
    const REVERT = 'user can not deposit before suspended date';
    let valueToDep = toBN(1e18);
    try {
      await courtToken.approve(courtReservoir.address, valueToDep, { from: investor2 })
      await courtReservoir.deposit(valueToDep, {from : investor2});
      throw null
    } catch (error) {
      assert(error, 'Expected an error but did not get one')
      assert(error.message.includes(REVERT), 'Expected \'' + REVERT + '\' but got \'' + error.message + '\' instead')
    }
  })

  it('Should return false because investor one can not suspend users', async function() {
    let valueToDep = toBN(1e18);
    await centralTime.increaseTime(oneDay);
    await courtReservoir.deposit(valueToDep, {from : investor2});
  })
  
  it('Should revert because caller is not gov or guardian', async function() {
    const REVERT = 'user can not deposit before suspended date';
    await centralTime.resetTimeIncrease();
    try {
      let valueToDep = toBN(1e18);
      await courtToken.approve(courtReservoir.address, valueToDep, { from: investor2 })
      await centralTime.increaseTime(oneDay/3);
      await courtReservoir.deposit(valueToDep, {from : investor2});
      throw null
    } catch (error) {
      assert(error, 'Expected an error but did not get one')
      assert(error.message.includes(REVERT), 'Expected \'' + REVERT + '\' but got \'' + error.message + '\' instead')
    }
  })
})
