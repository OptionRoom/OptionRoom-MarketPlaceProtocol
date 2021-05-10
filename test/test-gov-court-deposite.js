const ORMarketLib = artifacts.require('ORMarketLib')

const IERC20Contract = artifacts.require("../../contracts/mocks/ERC20DemoToken.sol");
const CourtStakeContract = artifacts.require("../../contracts/CourtStake/CourtStake.sol");
const CentralTimeForTestingContract = artifacts.require('CentralTimeForTesting')

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
  let rewardsProgram;
  
  let courtReservoir;
  let centralTime;
  let courtToken;
  
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
    await courtToken.mint(toBN(100e18), {from : trader});
    await courtReservoir.setCourtTokenAddress(courtToken.address, {from : deployer});
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
  })

  it('Should return the correct amount of tokens at court contract', async function() {
    let courtReservoirBalance = await courtToken.balanceOf(courtReservoir.address);
    expect(new BigNumber(courtReservoirBalance).isEqualTo(new BigNumber(amount))).to.equal(true)
  })

  it('Should be able to deposit more tokens', async function() {
    await courtToken.approve(courtReservoir.address, amount, { from: trader })
    await courtReservoir.deposit(amount, {from : trader});
  })
  
  it('Should return the correct value of the user power', async function() {
    let rightSideValue = (new BigNumber(3).multipliedBy(new BigNumber(amount).multipliedBy(0/50))).multipliedBy(toBN(2));
    let leftSideValue = new BigNumber(amount).multipliedBy(2);
    let result = rightSideValue.plus(leftSideValue);
    let userPower = await courtReservoir.getUserPower(trader);
    expect(new BigNumber(userPower).isEqualTo(result)).to.equal(true)
  })

  // For some reason its not working !!!
  it('Should be able to withdraw immediately from court contract', async function() {
    await courtReservoir.withdraw(amount, {from : trader});

    let courtReservoirBalance = await courtToken.balanceOf(courtReservoir.address);
    expect(new BigNumber(courtReservoirBalance).isEqualTo(new BigNumber(amount))).to.equal(true)

    let userBalanace = await courtToken.balanceOf(courtReservoir.address);
    expect(new BigNumber(userBalanace).isEqualTo(new BigNumber(amount))).to.equal(true)
  })
})
