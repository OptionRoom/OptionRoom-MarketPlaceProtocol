const ORMarketLib = artifacts.require('ORMarketLib')
const IERC20Contract = artifacts.require("../../contracts/mocks/ERC20DemoToken.sol");
const OracleMockContract = artifacts.require("../../contracts/mocks/RoomOraclePriceMock.sol");

const {
  prepareContracts, createNewMarket,
  executeControllerMethod,
  moveOneDay,createNewMarketWithCollateral,resetTimeIncrease,increaseTime,setDeployer,moveToResolved,
} = require('./utils/market.js')
const { toBN } = web3.utils
var BigNumber = require('bignumber.js')

contract('Options room, testing penalty system for governance', function([deployer, creator, oracle, investor1, trader, investor2]) {
  let controller;
  let rewardsProgram;
  let rewardCenter;

  let roomTokenFake;
  let oracleInstance;

  let rewardCenterBalance;

  let marketsCreated = new Map()
  const minLiquidityFunding = toBN(1e18)
  
  let governance;

  before(async function() {
    let retArray = await prepareContracts(creator, oracle, investor1, trader, investor2)
    controller = retArray[0];
    rewardsProgram = retArray[1];
    rewardCenter = retArray[2];
    governance = retArray[4];

    await controller.setMarketMinShareLiq(minLiquidityFunding)

    roomTokenFake = await IERC20Contract.new();
    oracleInstance = await OracleMockContract.new();

    // Mint some of the rooms at the system.
    await roomTokenFake.mint(toBN(200e18), {from : creator});
    await roomTokenFake.mint(toBN(200e18), {from : deployer});

    await rewardCenter.setRoomOracleAddress(oracleInstance.address, {from : deployer});
    await rewardCenter.setRoomAddress(roomTokenFake.address, {from : deployer});

    await roomTokenFake.mint(toBN(200e18), {from : deployer});
    await roomTokenFake.transfer(rewardCenter.address, toBN(200e18), {from : deployer});

    rewardCenterBalance = await roomTokenFake.balanceOf(rewardCenter.address);
    
    // Allowing the penalty in system blocking.
    await controller.setpenaltyOnWrongResolving(true, {from : deployer}); 
  })

  const marketMinToProvide1 = toBN(1e18);
  const marketMinToProvide2 = toBN(1e18);
  
  it('can be to create multiple markets', async function() {
    let retValues = await createNewMarketWithCollateral(creator, false, marketMinToProvide2, "test");
    marketsCreated.set(1,retValues );

    retValues = await createNewMarketWithCollateral(creator, false, marketMinToProvide2, "test 1");
    marketsCreated.set(2,retValues );

    retValues = await createNewMarketWithCollateral(creator, true, marketMinToProvide1, "test 2");
    marketsCreated.set(3,retValues);
  })


  it('Should validate markets', async function() {
    let mapToArray = Array.from(marketsCreated.values());
    for (let i = 0; i < mapToArray.length ;i++) {
      let marketDetails = mapToArray[i];
      let fixedProductMarketMaker = marketDetails[0]

      let inv1Attr = [fixedProductMarketMaker.address, true, { from: investor1 }]
      let inv2Attr = [fixedProductMarketMaker.address, false, { from: investor2 }]
      let oracleAttr = [fixedProductMarketMaker.address, false, { from: oracle }]

      await executeControllerMethod('castGovernanceValidatingVote', inv1Attr)
      await executeControllerMethod('castGovernanceValidatingVote', inv2Attr)
      await executeControllerMethod('castGovernanceValidatingVote', oracleAttr)
    }
  })
  
  let firstTimeResolve;
  let marketPendingPeriod = 1800;

  it('Should resolve markets', async function() {
    await resetTimeIncrease();
    await increaseTime(marketPendingPeriod);

    let days = ((86400 * 3) + 10);

    await increaseTime(days);
    let latestMarketSelected;
    let mapToArray = Array.from(marketsCreated.values());
    for (let i = 0; i < mapToArray.length ;i++) {
      let marketDetails = mapToArray[i];
      let fixedProductMarketMaker = marketDetails[0]
      
      latestMarketSelected = fixedProductMarketMaker;

      let result = 0;
      if (i > 0)
        result = 1;
      await controller.castGovernanceResolvingVote(fixedProductMarketMaker.address, result, { from: investor1 });
      
      // Make this user voted something wrong by providing another votes that will make him wrong
      if (result == 0) {
        await controller.castGovernanceResolvingVote(fixedProductMarketMaker.address, 1, { from: trader });
        await controller.castGovernanceResolvingVote(fixedProductMarketMaker.address, 1, { from: investor2 });
        await controller.castGovernanceResolvingVote(fixedProductMarketMaker.address, 1, { from: oracle });
      }
      
      // let state = await controller.getMarketState(fixedProductMarketMaker.address);
      // the state should be resolving here.
    }

    await moveToResolved();
  });


  it('Should check resolved markets', async function() {
    let mapToArray = Array.from(marketsCreated.values());
    for (let i = 0; i < mapToArray.length ;i++) {
      let marketDetails = mapToArray[i];
      let fixedProductMarketMaker = marketDetails[0]
      let state = await controller.getMarketState(fixedProductMarketMaker.address);
      expect(new BigNumber(state).isEqualTo(new BigNumber(ORMarketLib.MarketState.Resolved))).to.equal(true);
      
      let resolvingOutcome = await controller.getResolvingOutcome(fixedProductMarketMaker.address);
    }
  });

  it('Should revert because the user should be baned', async function() {
    let retValues = await createNewMarketWithCollateral(creator, false, marketMinToProvide2, "test 3");
    let fixedProductMarketMaker = retValues[0];


    let inv1Attr = [fixedProductMarketMaker.address, true, { from: investor1 }]
    await executeControllerMethod('castGovernanceValidatingVote', inv1Attr)

    // Then increase the day here to move the market to resolving and see the result of the vote.
    let days = ((86400 * 3) + 10);
    await increaseTime(days);
    
    let accountInfo = await governance.getAccountInfo(investor1);
    let userPower = accountInfo['power'];
    expect(new BigNumber(userPower).isEqualTo(new BigNumber(5)));

    accountInfo = await governance.getAccountInfo(oracle);
    userPower = accountInfo['power'];
    expect(new BigNumber(userPower).isEqualTo(new BigNumber(3)));
    
    // This guys should have a single invalid vote for a market.
    // investor1 has more power to trader lets see
    await controller.castGovernanceResolvingVote(fixedProductMarketMaker.address, 0, { from: investor1 });
    await controller.castGovernanceResolvingVote(fixedProductMarketMaker.address, 1, { from: trader });
    let state = await controller.getMarketState(fixedProductMarketMaker.address);

    let wrongVotings = await governance.WrongVoting.call(investor1);
    let lastwrongVotingCount = wrongVotings['lastwrongVotingCount'];
    expect(new BigNumber(lastwrongVotingCount).isEqualTo(new BigNumber(1)));

    wrongVotings = await governance.WrongVoting.call(trader);
    lastwrongVotingCount = wrongVotings['lastwrongVotingCount'];
    expect(new BigNumber(lastwrongVotingCount).isEqualTo(new BigNumber(0)));

    wrongVotings = await governance.WrongVoting.call(investor2);
    lastwrongVotingCount = wrongVotings['lastwrongVotingCount'];
    expect(new BigNumber(lastwrongVotingCount).isEqualTo(new BigNumber(0)));
    
    await  moveToResolved();

    let resolvingOutcome = await controller.getResolvingOutcome(fixedProductMarketMaker.address);
    expect(new BigNumber(resolvingOutcome[0]).isEqualTo(new BigNumber(0)));
    expect(new BigNumber(resolvingOutcome[1]).isEqualTo(new BigNumber(1)));

  });
})
