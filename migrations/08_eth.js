module.exports = function(deployer) {
  deployer.deploy(artifacts.require("WETH9"), { overwrite: false });
  deployer.deploy(artifacts.require("CentralTimeForTesting"), { overwrite: false });
  deployer.deploy(artifacts.require("TimeDependent"), { overwrite: false });

};
