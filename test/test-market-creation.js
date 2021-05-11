const {
  prepareContracts,
  createNewMarketWithCollateral
} = require('./utils/market.js')
const { toBN } = web3.utils
// var BigNumber = require('bignumber.js')

contract('OR test creation of multiple markets', 
  function([, creator, oracle, investor1, trader, investor2]) {
  before(async function() {
    await prepareContracts(creator, oracle, investor1, trader, investor2)
  })

  it('Should be able to create multiple markets with different collaterals', async function() {
    await createNewMarketWithCollateral(creator, false, addedFunds);
    await createNewMarketWithCollateral(creator, true, addedFunds);
  })

  const addedFunds = toBN(1e18)
})
