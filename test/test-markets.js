const ORMarketLib = artifacts.require('ORMarketLib')

const { prepareContracts, createNewMarket ,invokeFactoryMethod,
  executeControllerMethod, moveToActive,callViewFactoryMethod ,
  resetTimeIncrease} = require("./utils/market.js")
const { toBN } = web3.utils
var BigNumber = require('bignumber.js');

contract('OR markets: create multiple markets test', function([, creator, oracle, investor1, trader, investor2]) {

  let marketMakers = [];
  let pendingMarketMakersMap = new Map()
  
  let controller;
  before(async function() {
    controller = await prepareContracts(creator, oracle, investor1, trader, investor2)
  })

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

    let marketsCount = await callViewFactoryMethod("getMarketsCount", [ORMarketLib.MarketState.Validating]);
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

    let invalidMarketsCount = await callViewFactoryMethod("getMarketsCount", [ORMarketLib.MarketState.Invalid]);
    let activeMarketsCount = await callViewFactoryMethod("getMarketsCount", [ORMarketLib.MarketState.Active]);
    let rejectedMarketsCount = await callViewFactoryMethod("getMarketsCount", [ORMarketLib.MarketState.Rejected]);
    let validatingMarketsCount = await callViewFactoryMethod("getMarketsCount", [ORMarketLib.MarketState.Validating]);
    let resolvingMarketsCount = await callViewFactoryMethod("getMarketsCount", [ORMarketLib.MarketState.Resolving]);
    
    expect(invalidMarketsCount.toString()).to.equal("0");
    expect(activeMarketsCount.toString()).to.equal("1");
    expect(rejectedMarketsCount.toString()).to.equal("2");
    expect(validatingMarketsCount.toString()).to.equal("0");
    expect(resolvingMarketsCount.toString()).to.equal("0");

    // remove this market from pending states.
    pendingMarketMakersMap.delete(marketMaker.address + "");
  });

  it('Should return paginated markets according to the state', async function() {
    let rejectedMarketsCount = await callViewFactoryMethod("getMarkets", [ORMarketLib.MarketState.Rejected, 0, 10]);

    let retPendingCount = 0;

    for (let i = 0; i < rejectedMarketsCount .length; i++) {
      if (rejectedMarketsCount[i] !== "0x0000000000000000000000000000000000000000") {
        retPendingCount++;
      }
    }

    expect(retPendingCount).to.equal(2);

    // rejectedMarketsCount = await fixedProductMarketMakerFactory.getMarketsQuestionIDs(ORMarketLib.MarketState.Rejected, 0, 5);
    rejectedMarketsCount = await callViewFactoryMethod("getMarketsQuestionIDs", [ORMarketLib.MarketState.Rejected, 0, 5]);

    let markets = rejectedMarketsCount["markets"];
    let questionsIds = rejectedMarketsCount["questionsIDs"];

    let firstFoundMarket;
    for (let j = 0; j < markets .length; j++) {
      if (markets[j] !== "0x0000000000000000000000000000000000000000") {
        firstFoundMarket = markets[j];
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

    let creatorMarketsCount = await callViewFactoryMethod("getMarketCountByProposer", [creator]);
    let creatorRejectedMarketsCount = await callViewFactoryMethod("getMarketCountByProposerNState", [creator, ORMarketLib.MarketState.Rejected]);
    let creatorResolvingMarketsCount = await callViewFactoryMethod("getMarketCountByProposerNState", [creator, ORMarketLib.MarketState.Active]);
    let investor1MarketsCount = await callViewFactoryMethod("getMarketCountByProposer", [investor1]);
    let investor1RejectedMarketsCount = await callViewFactoryMethod("getMarketCountByProposerNState", [investor1, ORMarketLib.MarketState.Rejected]);

    expect(new BigNumber(creatorMarketsCount).isEqualTo(3)).to.equal(true);
    expect(new BigNumber(investor1MarketsCount).isEqualTo(3)).to.equal(true);
    expect(new BigNumber(investor1RejectedMarketsCount).isEqualTo(3)).to.equal(true);

    // TODO: Tareq I will have to revise those.
    // expect(new BigNumber(creatorRejectedMarketsCount).isEqualTo(2)).to.equal(true);
    // expect(new BigNumber(creatorResolvingMarketsCount).isEqualTo(1)).to.equal(true);

  });

})
