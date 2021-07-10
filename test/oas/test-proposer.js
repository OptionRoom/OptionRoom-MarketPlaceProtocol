
const {
  prepareContracts, setDeployer, addDays,
} = require('../utils/oas-utils.js')
const { toBN } = web3.utils
var BigNumber = require('bignumber.js')

// Preparing the contract things.
contract('Test OAS proposers', function([deployer, creator, oracle, investor1, trader, investor2]) {

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

  it('Should pass because we are owners.', async function() {
    const rewards = toBN(1e18)
    const fees = toBN(1e17)

    await contractInstance.addProposer(oracle,rewards, fees,"oracle user",  {from : deployer})
  })

  it('Should give the correct information about the account!', async function() {
    let accountInformation = await contractInstance.getAccountInfo(oracle);
    let account = accountInformation['account'];
    let allowed = accountInformation['allowed'];
    let minReward = new BigNumber(accountInformation['minReward']);
    let fees = new BigNumber(accountInformation['fees']);
    let name = accountInformation['name'];
    expect(account).to.equal(oracle);
    expect(allowed).to.equal(true);
    expect(name).to.equal("oracle user");

    expect(minReward.isEqualTo(new BigNumber(1e18))).to.equal(true)
    expect(fees.isEqualTo(new BigNumber(1e17))).to.equal(true)

  })

  it('Should fail because sender is not governor or guardian', async function() {
    const REVERT = 'address already added';
    try {
      const minReward = toBN(1e18)
      const fees = toBN(1e17)
      await contractInstance.addProposer(oracle,minReward, fees,"oracle user",  {from : deployer});
      throw null
    } catch (error) {
      assert(error, 'Expected an error but did not get one')
      assert(error.message.includes(REVERT), 'Expected \'' + REVERT + '\' but got \'' + error.message + '\' instead')
    }
  })


  it('Should pass because we are owners.', async function() {
    const minReward = toBN(2e18)
    const fees = toBN(2e17)

    await contractInstance.updateProposer(oracle,minReward,fees, true,  "oracle user",  {from : deployer});
  })


  it('Should give the correct information about the account after been updated!', async function() {
    let accountInformation = await contractInstance.getAccountInfo(oracle);
    let account = accountInformation['account'];
    let allowed = accountInformation['allowed'];
    let minReward = new BigNumber(accountInformation['minReward']);
    let fees = new BigNumber(accountInformation['fees']);
    let name = accountInformation['name'];
    expect(account).to.equal(oracle);
    expect(allowed).to.equal(true);
    expect(name).to.equal("oracle user");

    expect(minReward.isEqualTo(new BigNumber(2e18))).to.equal(true)
    expect(fees.isEqualTo(new BigNumber(2e17))).to.equal(true)

  })

  it('Should revert, we do not have any proposer with that id', async function() {
    const REVERT = 'account does not exist';
    try {
      const minReward = toBN(1e18)
      const fees = toBN(1e17)
      await contractInstance.updateProposer(creator,minReward,fees, true,  "oracle user",  {from : deployer});
      throw null
    } catch (error) {
      assert(error, 'Expected an error but did not get one')
      assert(error.message.includes(REVERT), 'Expected \'' + REVERT + '\' but got \'' + error.message + '\' instead')
    }
  })

})
