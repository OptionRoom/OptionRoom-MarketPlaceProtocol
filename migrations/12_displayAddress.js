module.exports = function(deployer) {
  deployer.then(async () => {
    
	const GovernencyDemoArt = artifacts.require("AAA0GovernencyDemo");
    const demoGovernence = await GovernencyDemoArt.deployed();
	console.log("demoGovernence.address (AAA0)");
	console.log(demoGovernence.address);
	
    const DemoTokenArt = artifacts.require("AAA1DemoToken1");
    const demoToken = await DemoTokenArt.deployed();
    console.log("demoToken.address (AAA1)");
	console.log(demoToken.address);
	
    const CondTokenArt = artifacts.require("AAA2ConditnalToken1");
    const condToken = await CondTokenArt.deployed();
    console.log("condToken.address (AAA2)");
	console.log(condToken.address);
	
	const markettemplateArt = artifacts.require("ORFPMarket");
	const markettemplate = await markettemplateArt.deployed();
	console.log("markettemplate.address (AAA4)");
	console.log(markettemplate.address);
	
	
    const FactoryArt = artifacts.require("AAA3MarketFactory1");
    const factoryC = await FactoryArt.deployed();
	
    await factoryC.setTemplateAddress(markettemplate.address);
    await factoryC.setA0(demoGovernence.address);
	await factoryC.setA1(demoToken.address);
	await factoryC.setA2(CondTokenArt.address);	
	
	console.log("factoryC.address (AAA3)");
	console.log(factoryC.address);
	
  });
};