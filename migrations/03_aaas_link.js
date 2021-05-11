module.exports = function(deployer) {
  deployer.then(async () => {

   const aaa0Art = artifacts.require("AAA0Time");
    const aaa0 = await aaa0Art.deployed();
	
	const aaa1Art = artifacts.require("AAA1DemoToken1");
    const aaa1 = await aaa1Art.deployed();
	
	const aaa2Art = artifacts.require("AAA2ConditnalToken1");
    const aaa2 = await aaa2Art.deployed();
	
	const aaa3Art = artifacts.require("AAA3MarketController1");
    const aaa3 = await aaa3Art.deployed();
	
	const aaa4Art = artifacts.require("AAA4Market");
    const aaa4 = await aaa4Art.deployed();
	
	const aaa5Art = artifacts.require("AAA5RewardProgram");
    const aaa5 = await aaa5Art.deployed();
	
	const aaa6Art = artifacts.require("AAA6RewardCenter");
    const aaa6 = await aaa6Art.deployed();
	
	const aaa7Art = artifacts.require("AAA7ORGovernor");
    const aaa7 = await aaa7Art.deployed();
	
	const aaa8Art = artifacts.require("AAA8CourtStakeDummy");
    const aaa8CS = await aaa8Art.deployed();
	
	const aaa9Art = artifacts.require("AAA9ORMarketsQuery");
    const aaa9 = await aaa9Art.deployed();
    
	console.log("set time ");
	//await aaa1.setCentralTimeAddressForTesting(aaa0.address);
	//await aaa2.setCentralTimeAddressForTesting(aaa0.address);
	await aaa3.setCentralTimeAddressForTesting(aaa0.address);
	//await aaa4.setCentralTimeAddressForTesting(aaa0.address);
	await aaa5.setCentralTimeAddressForTesting(aaa0.address);
	//await aaa6.setCentralTimeAddressForTesting(aaa0.address);
	await aaa7.setCentralTimeAddressForTesting(aaa0.address);
	await aaa8CS.setCentralTimeAddressForTesting(aaa0.address);
	//await aaa9.setCentralTimeAddressForTesting(aaa0.address);
	
	console.log("a3 config (marketController) ");
	await aaa3.setConditionalToken(aaa2.address);
	await aaa3.setRewardCenter(aaa6.address);
	await aaa3.setIORGoverner(aaa7.address);
	await aaa3.setTemplateAddress(aaa4.address);
	
	console.log("a5 config (RewardProgram) ");
	await aaa5.setMarketControllerAddress(aaa3.address);
	await aaa5.setRewardCenter(aaa6.address);
	
	console.log("a6 config (RewardCenter) ");
	await aaa6.setRewardProgram(aaa5.address);
	
	console.log("a7 config (AAA7ORGovernor)");
	await aaa7.setCourtStake(aaa8CS.address);
	
	//a8 config (AAA8CourtStake)
    //aa8.setCourtTokenAddress(courtTokenAddress)
	
	console.log("a9 config (AAA9ORMarketsQuery)");
	await aaa9.setMarketsController(aaa3.address);

	console.log("aaa0.address ");
	console.log(aaa0.address);
	
	console.log("aaa1.address ");
	console.log(aaa1.address);
	
	console.log("aaa2.address ");
	console.log(aaa2.address);
	
	console.log("aaa3.address ");
	console.log(aaa3.address);
	
	console.log("aaa4.address ");
	console.log(aaa4.address);
	
	console.log("aaa5.address ");
	console.log(aaa5.address);
	
	console.log("aaa6.address ");
	console.log(aaa6.address);
	
	console.log("aaa7.address ");
	console.log(aaa7.address);
	
	console.log("aaa8CS.address ");
	console.log(aaa8CS.address);
	
	console.log("aaa9.address ");
	console.log(aaa9.address);

  });
};
