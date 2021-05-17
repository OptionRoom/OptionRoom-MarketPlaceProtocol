const {
  prepareContracts,
  createNewMarketWithCollateral,setDeployer
} = require('./utils/market.js')
const { toBN } = web3.utils
const BigNumber = require('bignumber.js')

let controller;
const addedFunds = toBN(1e17)

contract('OR test creation of multiple markets', 
  function([deployer, creator, oracle, investor1, trader, investor2]) {
  before(async function() {
    setDeployer(deployer);
    let retArray = await prepareContracts(creator, oracle, investor1, trader, investor2,deployer)
    controller = retArray[0];  
  })

  it('Should be able to create multiple markets with different collaterals', async function() {
    const marketMinShareLiq = await controller.marketMinShareLiq.call();
    const marketMinToProvide1 = toBN(2e18);
    const marketMinToProvide2 = toBN(1e18);
    
    // nothing just sent the min liquidity here to a number that we can just deal with
    await controller.setMarketMinShareLiq(marketMinToProvide2);
    
    let retValues = await createNewMarketWithCollateral(creator, false, marketMinToProvide1);
    const market1 = retValues[0]
    const colToken1 = retValues[1]
    const posIds1 = retValues[2]
    
    let balanceOf = await market1.balanceOf(creator);
    expect(new BigNumber(balanceOf).isEqualTo(new BigNumber(marketMinToProvide1))).
      to.equal(true)


    let retValues2 = await createNewMarketWithCollateral(creator, true, marketMinToProvide2);
    const market2 = retValues2[0]
    const colToken2 = retValues2[1]
    const posIds2 = retValues2[2]

    let balanceOf2 = await market2.balanceOf(creator);
    expect(new BigNumber(balanceOf2).isEqualTo(new BigNumber(marketMinToProvide2))).
      to.equal(true)
    
  })
    
  it('Should revert because we did not provide enough liquidity ', async function() {
    const REVERT = "initial liquidity less than minimum liquidity required";

    try {
      await createNewMarketWithCollateral(creator, true, addedFunds);
      throw null;
    }
    catch (error) {
      assert(error, "Expected an error but did not get one");
      assert(error.message.includes(REVERT), "Expected '" + REVERT + "' but got '" + error.message + "' instead");
    }
  });
})
