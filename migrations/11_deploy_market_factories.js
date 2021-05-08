const ORFPMarket = artifacts.require('ORFPMarket')
const ORGovernanceMock = artifacts.require('ORGovernanceMock')
// const ORMarketController = artifacts.require('ORMarketController')
const PredictionMarketFactoryMock = artifacts.require('PredictionMarketFactoryMock')
const RewardProgramMock = artifacts.require('RewardProgramMock')

module.exports = function (deployer) {
  deployer.deploy(ORFPMarket);
  deployer.deploy(PredictionMarketFactoryMock);
  // deployer.deploy(ORMarketController);
  deployer.deploy(ORGovernanceMock);
  deployer.deploy(RewardProgramMock);
}
