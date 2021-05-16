const ORFPMarket = artifacts.require('ORFPMarket')
const ORGovernanceMock = artifacts.require('ORGovernanceMock')
const PredictionMarketFactoryMock = artifacts.require('PredictionMarketFactoryMock')
const RewardProgramMock = artifacts.require('RewardProgramMock')

module.exports = function(deployer) {
  deployer.deploy(artifacts.require("ERC20DemoToken"), {});
  deployer.deploy(artifacts.require("WETH9"), { overwrite: false });
  deployer.deploy(artifacts.require("CentralTimeForTesting"), { overwrite: false });
  deployer.deploy(artifacts.require("TimeDependent"), { overwrite: false });
  deployer.deploy(ORFPMarket);
  deployer.deploy(PredictionMarketFactoryMock);
  deployer.deploy(ORGovernanceMock);
  deployer.deploy(RewardProgramMock);
};
