// const FixedProductMarketMakerFactory = artifacts.require('FixedProductMarketMakerFactory')
const ORFPMarket = artifacts.require('ORFPMarket')
// const ORGovernanceMock = artifacts.require('ORGovernanceMock')
const ORMarketController = artifacts.require('ORMarketController')
const PredictionMarketFactoryMock = artifacts.require('PredictionMarketFactoryMock')

module.exports = function (deployer) {
  deployer.deploy(ORFPMarket);
  deployer.deploy(PredictionMarketFactoryMock);
  // deployer.deploy(FixedProductMarketMakerFactory);
  deployer.deploy(ORMarketController);
}
