const { expectEvent } = require('openzeppelin-test-helpers')

const {
  prepareContracts, setDeployer, addDays,
} = require('../utils/oas-utils.js')
const { toBN } = web3.utils
const BigNumber = require('bignumber.js')

// Preparing the contract things.
contract('Test create OAS contract', function([deployer, creator, oracle, investor1, trader, investor2]) {

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
    const reward = toBN(1e18)
    const totalToApprove = toBN(2e18)
    const minRoomHolding = toBN(1e18)
    const minOptionalERC20Holding = toBN(1e18)

    // Set the fees
    await contractInstance.setAnonymousFees(fees, { from: deployer })

    let choices = ['1', '2', '3']
    let now = new Date()
    let endDate = addDays(now, 5)
    let questionEndTime = Math.floor(endDate.getTime() / 1000)

    await roomTokenFake.approve(contractInstance.address, totalToApprove, { from: deployer });

    let createTx = await contractInstance.createQuestion('QITest', choices, reward, questionEndTime, minRoomHolding,
      roomTokenFake.address, minOptionalERC20Holding, { from: deployer })

    expectEvent.inLogs(createTx.logs, 'QuestionCreated', {
      creator: deployer
    });

    const { qid } = createTx.logs.find(
      ({ event }) => event === 'QuestionCreated'
    ).args;

    // let questions = await contractInstance.questions.call(0)
    // createdQuestionId = questions[0]

    createdQuestionId = qid;
    expect(new BigNumber(qid).isEqualTo(new BigNumber(0))).to.equal(true)
  })

  it('Should show the question results', async function() {
    let questionInformation = await contractInstance.getQuestionInfo(toBN(createdQuestionId))

    let qid = questionInformation['qid'];
    let creator = questionInformation['creator'];
    let minRoomHolding = questionInformation['minRoomHolding'];
    let optionalERC20Address = questionInformation['optionalERC20Address'];
    let minOptionalERC20Holding = questionInformation['minOptionalERC20Holding'];
    let reward = questionInformation['reward'];
    let choicesLen = questionInformation['choicesLen'];
    let question = questionInformation['question'];
    let choices = questionInformation['choices'];
    let votersCount = questionInformation['votersCount'];
    let votesCounts = questionInformation['votesCounts'];
    let roomHolding = questionInformation['roomHolding'];
    let optionalTokenHolding = questionInformation['optionalTokenHolding'];
    let createdTime = questionInformation['createdTime'];
    let endTime = questionInformation['endTime'];

    expect(new BigNumber(qid).isEqualTo(new BigNumber(0))).to.equal(true)
    expect(creator).to.equal(deployer);
  })

  it('Should return the correct question count', async function() {
    let count = await contractInstance.getQuestionsCount();
    expect(new BigNumber(count).isEqualTo(new BigNumber(1))).to.equal(true)
  })

  it('Should return the correct question count', async function() {
    let questionsArray = await contractInstance.getAllQuestions();

    for (let i = 0; i < questionsArray.length;i++) {
      let questions = questionsArray[i];
      let qid = questions['qid'];
      expect(new BigNumber(qid).isEqualTo(new BigNumber(0))).to.equal(true)
    }
  })

  it('Should return the correct choices values of a question', async function() {
    let choicesArray = await contractInstance.getChoices(toBN(createdQuestionId));

    // should be like this.
    // let choices = ['1', '2', '3']
    for (let i = 0; i < choicesArray.length;i++) {
      let choice = choicesArray[i];
      if (i == 0)
        expect(choice).to.equal("1");
      else if (i == 1)
        expect(choice).to.equal("2");
      else if (i == 2)
        expect(choice).to.equal("3");
    }
  })

  it('Should be able to vote on a question', async function() {
    await contractInstance.vote(toBN(createdQuestionId), toBN(1), { from: deployer })

    let question = await contractInstance.questions.call(0)
    let votersCount = question.votersCount
    expect(new BigNumber(votersCount).isEqualTo(new BigNumber(1))).to.equal(true)
  })

  it('Should return the correct question result', async function() {
    let questionResults = await contractInstance.getQuestionResult(toBN(createdQuestionId))
    let votes = questionResults['votes'];
    let votesPower = questionResults['votesPower'];

    // We voted for the second option.
    expect(new BigNumber(votes[1]).isEqualTo(new BigNumber(1))).to.equal(true)
    expect(new BigNumber(votes[0]).isEqualTo(new BigNumber(0))).to.equal(true)
    expect(new BigNumber(votes[2]).isEqualTo(new BigNumber(0))).to.equal(true)

    let roomBalance = await roomTokenFake.balanceOf(deployer);

    expect(new BigNumber(votesPower[0]).isEqualTo(new BigNumber(0))).to.equal(true)
    expect(new BigNumber(votesPower[1]).isEqualTo(new BigNumber(roomBalance))).to.equal(true)
    expect(new BigNumber(votesPower[2]).isEqualTo(new BigNumber(0))).to.equal(true)
  })


  it('Should pass because we did not set the fees for the anonymous fees to 0', async function() {
    const rewards = toBN(1e18)
    const minRoomHolding = toBN(1e18)
    const minOptionalERC20Holding = toBN(1e18)
    let choices = ['1', '2', '3', '4']
    let now = new Date()
    let endDate = addDays(now, 5)
    let questionEndTime = Math.floor(endDate.getTime() / 1000)
    await contractInstance.setAnonymousFees(toBN(0), { from: deployer })

    await roomTokenFake.approve(contractInstance.address, rewards, { from: deployer });

    await contractInstance.createQuestion('QITest', choices, rewards, questionEndTime, minRoomHolding,
      roomTokenFake.address, minOptionalERC20Holding, { from: deployer })
  })

  it('Should fail fees is not 0 and oracle do not have enough ROOM tokens', async function() {
    const REVERT = 'transfer amount exceeds balance';
    try {
    const rewards = toBN(1e18)
    const minRoomHolding = toBN(1e18)
    const minOptionalERC20Holding = toBN(1e18)
    let choices = ['1', '2', '3', '4']
    let now = new Date()
    let endDate = addDays(now, 5)
    let questionEndTime = Math.floor(endDate.getTime() / 1000)
    await contractInstance.setAnonymousFees(toBN(1e17), { from: deployer })

    await contractInstance.createQuestion('QITest', choices, rewards, questionEndTime, minRoomHolding,
      roomTokenFake.address, minOptionalERC20Holding, { from: oracle })

    throw null
    } catch (error) {
      assert(error, 'Expected an error but did not get one')
      assert(error.message.includes(REVERT), 'Expected \'' + REVERT + '\' but got \'' + error.message + '\' instead')
    }
  })

  it('Should revert because we do not hold enough', async function() {
    const REVERT = 'User already voted for this question'
    try {
      await contractInstance.vote(toBN(createdQuestionId), toBN(1), { from: deployer })
      throw null
    } catch (error) {
      assert(error, 'Expected an error but did not get one')
      assert(error.message.includes(REVERT), 'Expected \'' + REVERT + '\' but got \'' + error.message + '\' instead')
    }
  })

  it('Should revert because we do not hold enough', async function() {
    const REVERT = 'User does not hold minimum optional room'
    try {
      await contractInstance.vote(toBN(createdQuestionId), toBN(2), { from: oracle })
      throw null
    } catch (error) {
      assert(error, 'Expected an error but did not get one')
      assert(error.message.includes(REVERT), 'Expected \'' + REVERT + '\' but got \'' + error.message + '\' instead')
    }
  })


  it('Should fail because we did not send enough choices', async function() {
    const REVERT = 'choices must be at least 2';
    try {
      const rewards = toBN(1e18)
      const totalToApprove = toBN(2e18)
      const minRoomHolding = toBN(1e18)
      const minOptionalERC20Holding = toBN(1e18)
      let choices = ['1']
      let now = new Date()
      let endDate = addDays(now, 5)
      let questionEndTime = Math.floor(endDate.getTime() / 1000)

      await roomTokenFake.approve(contractInstance.address, totalToApprove, { from: deployer });

      await contractInstance.createQuestion('QITest', choices, rewards, questionEndTime, minRoomHolding,
        roomTokenFake.address, minOptionalERC20Holding, { from: deployer })

      throw null
    } catch (error) {
      assert(error, 'Expected an error but did not get one')
      assert(error.message.includes(REVERT), 'Expected \'' + REVERT + '\' but got \'' + error.message + '\' instead')
    }
  })
})
