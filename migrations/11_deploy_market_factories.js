const ORFPMarket = artifacts.require('ORFPMarket')
const ORGovernanceMock = artifacts.require('ORGovernanceMock')
const PredictionMarketFactoryMock = artifacts.require('PredictionMarketFactoryMock')
const RewardProgramMock = artifacts.require('RewardProgramMock')
const CourtStake = artifacts.require('CourtStake')

module.exports = function (deployer) {
  deployer.deploy(ORFPMarket);
  deployer.deploy(PredictionMarketFactoryMock);
  deployer.deploy(ORGovernanceMock);
  deployer.deploy(RewardProgramMock);
  deployer.deploy(CourtStake);
}
