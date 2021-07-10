
const {
  prepareContracts, setDeployer, addDays,
} = require('../utils/oas-utils.js')
const { toBN } = web3.utils

// Preparing the contract things.
contract('Test create OAS permissions', function([deployer, creator, oracle, investor1, trader, investor2]) {

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

  it('Should fail because sender is not governor or guardian', async function() {
    const REVERT = 'caller is not governor or guardian';
    try {
      const rewards = toBN(1e18)
      const fees = toBN(1e17)
      await contractInstance.addProposer(oracle,rewards,fees,  "oracle user",  {from : oracle});
      throw null
    } catch (error) {
      assert(error, 'Expected an error but did not get one')
      assert(error.message.includes(REVERT), 'Expected \'' + REVERT + '\' but got \'' + error.message + '\' instead')
    }
  })

  it('Should pass because we are owners.', async function() {
    const rewards = toBN(1e18)
    const fees = toBN(1e17)

    await contractInstance.addProposer(oracle,rewards, fees,"oracle user",  {from : deployer});
  })


  it('Should fail because sender is not governor or guardian', async function() {
    const REVERT = 'caller is not governor or guardian';
    try {
      const rewards = toBN(1e18)
      const fees = toBN(1e17)
      await contractInstance.updateProposer(oracle,rewards,fees, true,  "oracle user",  {from : oracle});
      throw null
    } catch (error) {
      assert(error, 'Expected an error but did not get one')
      assert(error.message.includes(REVERT), 'Expected \'' + REVERT + '\' but got \'' + error.message + '\' instead')
    }
  })

  it('Should pass because we are owners.', async function() {
    const rewards = toBN(1e18)
    const fees = toBN(1e17)

    await contractInstance.updateProposer(oracle,rewards,fees, true,  "oracle user",  {from : deployer});
  })

  it('Should fail because sender is not governor or guardian', async function() {
    const REVERT = 'caller is not governor or guardian';
    try {
      await contractInstance.setRoomAddress(roomTokenFake.address, {from : oracle});
      throw null
    } catch (error) {
      assert(error, 'Expected an error but did not get one')
      assert(error.message.includes(REVERT), 'Expected \'' + REVERT + '\' but got \'' + error.message + '\' instead')
    }
  })

  it('Should pass because we are owners.', async function() {
    await contractInstance.setRoomAddress(roomTokenFake.address, {from : deployer});
  })


  it('Should fail because sender is not governor or guardian', async function() {
    const REVERT = 'caller is not governor or guardian';
    try {
      const minHolding = toBN(1e18)

      await contractInstance.setMinRoomHolding(minHolding, {from : oracle});
      throw null
    } catch (error) {
      assert(error, 'Expected an error but did not get one')
      assert(error.message.includes(REVERT), 'Expected \'' + REVERT + '\' but got \'' + error.message + '\' instead')
    }
  })

  it('Should pass because we are owners.', async function() {
    const minHolding = toBN(1e18)

    await contractInstance.setMinRoomHolding(minHolding, {from : deployer});
  })

  it('Should fail because sender is not governor or guardian', async function() {
    const REVERT = 'caller is not governor or guardian';
    try {
      await contractInstance.setAnonymousProposerAllowed(false, {from : oracle});
      throw null
    } catch (error) {
      assert(error, 'Expected an error but did not get one')
      assert(error.message.includes(REVERT), 'Expected \'' + REVERT + '\' but got \'' + error.message + '\' instead')
    }
  })

  it('Should pass because we are owners.', async function() {
    await contractInstance.setAnonymousProposerAllowed(false, {from : deployer});
  })


  it('Should fail because sender is not governor or guardian', async function() {
    const REVERT = 'caller is not governor or guardian';
    const minHolding = toBN(1e18)

    try {
      await contractInstance.setAnonymousFees(minHolding, {from : oracle});
      throw null
    } catch (error) {
      assert(error, 'Expected an error but did not get one')
      assert(error.message.includes(REVERT), 'Expected \'' + REVERT + '\' but got \'' + error.message + '\' instead')
    }
  })

  it('Should pass because we are owners.', async function() {
    const minHolding = toBN(1e18)

    await contractInstance.setAnonymousFees(minHolding, {from : deployer});
  })


  it('Should fail because sender is not governor or guardian', async function() {
    const REVERT = 'caller is not governor or guardian';
    const minHolding = toBN(1e18)

    try {
      await contractInstance.setAnonymousMinReward(minHolding, {from : oracle});
      throw null
    } catch (error) {
      assert(error, 'Expected an error but did not get one')
      assert(error.message.includes(REVERT), 'Expected \'' + REVERT + '\' but got \'' + error.message + '\' instead')
    }
  })

  it('Should pass because we are owners.', async function() {
    const minHolding = toBN(1e18)

    await contractInstance.setAnonymousMinReward(minHolding, {from : deployer});
  })


  it('Should fail because sender is not governor or guardian', async function() {
    const REVERT = 'caller is not governor or guardian';
    try {
      await contractInstance.transferCollectedFees({from : oracle});
      throw null
    } catch (error) {
      assert(error, 'Expected an error but did not get one')
      assert(error.message.includes(REVERT), 'Expected \'' + REVERT + '\' but got \'' + error.message + '\' instead')
    }
  })

  it('Should pass because we are owners.', async function() {
    await contractInstance.transferCollectedFees({from : deployer});
  })
})
