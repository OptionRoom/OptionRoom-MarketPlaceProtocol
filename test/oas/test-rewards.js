const ORMarketLib = artifacts.require('ORMarketLib')
const { expectEvent } = require('openzeppelin-test-helpers')

const {
  prepareContracts, setDeployer, addDays,moveMoveOneDay
} = require('../utils/oas-utils.js')
const { toBN } = web3.utils
var BigNumber = require('bignumber.js')

// Preparing the contract things.
contract('Test rewards', function([deployer, creator, oracle, investor1, trader, investor2]) {

  let contractInstance

  let roomTokenFake

  before(async function() {
    setDeployer(deployer)
    let retArray = await prepareContracts(creator, oracle, investor1, trader, investor2, deployer)
    contractInstance = retArray[0]
    roomTokenFake = retArray[1]

    // Mint some of the rooms at the system.
    await roomTokenFake.mint(toBN(200e18), { from: creator })
    await roomTokenFake.mint(toBN(200e18), { from: deployer })

    await roomTokenFake.mint(toBN(200e18), { from: deployer })
    await roomTokenFake.transfer(contractInstance.address, toBN(200e18), { from: deployer })

  })

  let createdQuestionId

  it('Should be able to create a new question', async function() {
    const fees = toBN(1e17)
    const rewards = toBN(1e18)
    const minRoomHolding = toBN(1e18)
    const minOptionalERC20Holding = toBN(1e18)

    // Set the fees
    await contractInstance.setAnonymousFees(fees, { from: deployer })

    let choices = ['1', '2', '3']
    let now = new Date()
    let endDate = addDays(now, 5)
    let questionEndTime = Math.floor(endDate.getTime() / 1000)


    await roomTokenFake.approve(contractInstance.address, rewards, { from: deployer });

    let createTx = await contractInstance.createQuestion('QITest', choices, rewards, questionEndTime, minRoomHolding,
      roomTokenFake.address, minOptionalERC20Holding, { from: deployer })

    expectEvent.inLogs(createTx.logs, 'QuestionCreated', {
      creator: deployer
    });

    const { qid } = createTx.logs.find(
      ({ event }) => event === 'QuestionCreated'
    ).args;

    createdQuestionId = qid;
    expect(new BigNumber(qid).isEqualTo(new BigNumber(0))).to.equal(true)
  })

  it('Should be able to vote on a question', async function() {
    await contractInstance.vote(toBN(createdQuestionId), toBN(1), { from: deployer })
  })

  it('Should return the correct rewards information after we progress with time after the pol is done', async function() {
    let rewardsInformation = await contractInstance.getRewardsInfo(deployer)
    let expectedRewardsBefore = rewardsInformation['expectedRewards'];
    let claimableRewards = rewardsInformation['claimableRewards'];
    expect(new BigNumber(claimableRewards).isEqualTo(new BigNumber(0))).to.equal(true)

    let now = new Date()
    let afterEndDate = addDays(now, 6)
    let afterEndTime = Math.floor(afterEndDate.getTime() / 1000)

    await contractInstance.increaseTime(afterEndTime)

    rewardsInformation = await contractInstance.getRewardsInfo(deployer)
    let expectedRewards = rewardsInformation['expectedRewards'];
    claimableRewards = rewardsInformation['claimableRewards'];

    expect(new BigNumber(expectedRewards).isEqualTo(new BigNumber(0))).to.equal(true)
    expect(new BigNumber(claimableRewards).isEqualTo(new BigNumber(expectedRewardsBefore))).to.equal(true)
  })

  it('Should be able to claim the rewards for the call account and show it as room', async function() {
    let roomBalanceBeforeClaim = new BigNumber( await roomTokenFake.balanceOf(deployer) );
    let contractRoomBalance = await roomTokenFake.balanceOf(contractInstance.address);
    await contractInstance.claimRewards({from : deployer})
    let roomBalanceAfterClaim = await roomTokenFake.balanceOf(deployer);
    expect(new BigNumber(roomBalanceBeforeClaim).isLessThan(new BigNumber(roomBalanceAfterClaim))).to.equal(true)
  })
})
