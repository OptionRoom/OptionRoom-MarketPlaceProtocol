const ORMarketLib = artifacts.require('ORMarketLib')


const { prepareContracts, createNewMarket ,setDeployer,
  executeControllerMethod, moveToActive,callViewFactoryMethod ,
  resetTimeIncrease} = require("./utils/market.js")
const { toBN } = web3.utils
var BigNumber = require('bignumber.js');
let ORMarketsQueryContract = artifacts.require("../../../contracts/OR/ORMarketsQuery.sol");


contract('OR markets: test markets queries', function([deployer, creator, oracle, investor1, trader, investor2]) {

  let marketMakers = [];
  let pendingMarketMakersMap = new Map()
  
  let controller;
  let markets;
  before(async function() {
    setDeployer(deployer);
    let retArray = await prepareContracts(creator, oracle, investor1, trader, investor2,deployer)
    controller = retArray[0];

    markets = await ORMarketsQueryContract.new();
    
  })

  it('Should Should revert because you are not a gov or gua', async function() {
    const REVERT = 'caller is not governor or guardian';
    try {
      await markets.setMarketsController(controller.address, {from: creator});
      throw null
    } catch (error) {
      assert(error, 'Expected an error but did not get one')
      assert(error.message.includes(REVERT), 'Expected \'' + REVERT + '\' but got \'' + error.message + '\' instead')
    }
  });

  it('Should pass because you are a deployer', async function() {
    await markets.setMarketsController(controller.address, {from: deployer});
  });
  
  it('Should create and return correct validating markets count', async function() {
    let marketCreated = (await createNewMarket(creator))[0];
    marketMakers.push(marketCreated);
    pendingMarketMakersMap.set(marketCreated.address,marketCreated );

    let marketCreated1 = (await createNewMarket(creator))[0];
    marketMakers.push(marketCreated1);
    pendingMarketMakersMap.set(marketCreated1.address,marketCreated1 );

    let marketCreated2 = (await createNewMarket(creator))[0];
    marketMakers.push(marketCreated2);
    pendingMarketMakersMap.set(marketCreated2.address,marketCreated2 );

    let marketsCount = await markets.getMarketsCount(ORMarketLib.MarketState.Validating);
    expect(marketsCount.toString()).to.equal("3");
  });

  it('Should check for correct markets numbers', async function() {
    let marketMaker = marketMakers[0];
    const invArgs = [
      marketMaker.address,
      true,
      { from: investor1 },
    ]
    
    await executeControllerMethod("castGovernanceValidatingVote" , invArgs);
    
    await moveToActive();

    let invalidMarketsCount = await markets.getMarketsCount(ORMarketLib.MarketState.Invalid);
    let activeMarketsCount = await markets.getMarketsCount(ORMarketLib.MarketState.Active);
    let rejectedMarketsCount = await markets.getMarketsCount(ORMarketLib.MarketState.Rejected);
    let validatingMarketsCount = await markets.getMarketsCount(ORMarketLib.MarketState.Validating);
    let resolvingMarketsCount = await markets.getMarketsCount(ORMarketLib.MarketState.Resolving);
    
    expect(invalidMarketsCount.toString()).to.equal("0");
    expect(activeMarketsCount.toString()).to.equal("1");
    expect(rejectedMarketsCount.toString()).to.equal("2");
    expect(validatingMarketsCount.toString()).to.equal("0");
    expect(resolvingMarketsCount.toString()).to.equal("0");

    // remove this market from pending states.
    pendingMarketMakersMap.delete(marketMaker.address + "");
  });

  it('Should return paginated markets according to the state', async function() {
    let rejectedMarketsCount = await markets.getMarkets(ORMarketLib.MarketState.Rejected, 0, 10);

    let retPendingCount = 0;

    for (let i = 0; i < rejectedMarketsCount .length; i++) {
      if (rejectedMarketsCount[i] !== "0x0000000000000000000000000000000000000000") {
        retPendingCount++;
      }
    }

    expect(retPendingCount).to.equal(2);

    rejectedMarketsCount = await markets.getMarketsQuestionIDs(ORMarketLib.MarketState.Rejected, 0, 5);

    let marketsCount = rejectedMarketsCount["markets"];
    let questionsIds = rejectedMarketsCount["questionsIDs"];

    let firstFoundMarket;
    for (let j = 0; j < marketsCount .length; j++) {
      if (marketsCount[j] !== "0x0000000000000000000000000000000000000000") {
        firstFoundMarket = marketsCount[j];
        break;
      }
    }

    let firstAddressInMap = pendingMarketMakersMap.keys().next().value

    expect(firstFoundMarket).to.equal(firstAddressInMap);
  });


  it('Should return markets for the proposer', async function() {
    await resetTimeIncrease();

    // Create another three markets for another account
    await createNewMarket(investor1);
    await createNewMarket(investor1);
    await createNewMarket(investor1);

    await moveToActive();

    let creatorMarketsCount = await markets.getMarketCountByProposer(creator);

    let creatorRejectedMarketsCount = await markets.getMarketCountByProposerNState(creator, ORMarketLib.MarketState.Rejected);

    let creatorResolvingMarketsCount = await markets.getMarketCountByProposerNState(creator, ORMarketLib.MarketState.Active);

    let investor1MarketsCount = await markets.getMarketCountByProposer(investor1);

    let investor1RejectedMarketsCount = await markets.getMarketCountByProposerNState(investor1, ORMarketLib.MarketState.Rejected);

    expect(new BigNumber(creatorMarketsCount).isEqualTo(3)).to.equal(true);
    expect(new BigNumber(investor1MarketsCount).isEqualTo(3)).to.equal(true);
    expect(new BigNumber(investor1RejectedMarketsCount).isEqualTo(3)).to.equal(true);

    // TODO: Tareq I will have to revise those.
    // expect(new BigNumber(creatorRejectedMarketsCount).isEqualTo(2)).to.equal(true);
    // expect(new BigNumber(creatorResolvingMarketsCount).isEqualTo(1)).to.equal(true);

  });

})
