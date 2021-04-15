module.exports = function(deployer) {
  deployer.then(async () => {
    
	const GovernencyDemoArt = artifacts.require("AAA0GovernencyDemo");
    const demoGovernence = await GovernencyDemoArt.deployed();
	
    const DemoTokenArt = artifacts.require("AAA1DemoToken1");
    const demoToken = await DemoTokenArt.deployed();
    
    const CondTokenArt = artifacts.require("AAA2ConditnalToken1");
    const condToken = await CondTokenArt.deployed();
    
    const FactoryArt = artifacts.require("AAA3MarketFactory1");
    const factoryC = await FactoryArt.deployed();
    
    await factoryC.setA0(demoGovernence.address);
	await factoryC.setA1(demoToken.address);
	await factoryC.setA2(CondTokenArt.address);
	 
	console.log("demoGovernence.address (AAA0)");
	console.log(demoGovernence.address);
	console.log("demoToken.address (AAA1)");
	console.log(demoToken.address);
	console.log("condToken.address (AAA2)");
	console.log(condToken.address);
	console.log("factoryC.address (AAA3)");
	console.log(factoryC.address);
	
  });
};