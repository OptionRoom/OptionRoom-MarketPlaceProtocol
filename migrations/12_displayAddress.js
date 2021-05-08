module.exports = function(deployer) {
  deployer.then(async () => {

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
	
	const rewardProgramArt = artifacts.require("AAA5RewardProgram");
	const rewardProgram = await rewardProgramArt.deployed();
	console.log("AAA5RewardProgram.address (AAA5)");
	console.log(rewardProgram.address);


    const FactoryArt = artifacts.require("AAA3MarketController1");
    const factoryC = await FactoryArt.deployed();

    await factoryC.setTemplateAddress(markettemplate.address);
	await factoryC.setRewardCenter(rewardProgram.address);
	await factoryC.setA1(demoToken.address);
	await factoryC.setA2(CondTokenArt.address);

	console.log("factoryC.address (AAA3)");
	console.log(factoryC.address);

  });
};
