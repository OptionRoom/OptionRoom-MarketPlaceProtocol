module.exports = function(deployer) {
  deployer.then(async () => {

	const aaa1Art = artifacts.require("Demo_USDT");
    const aaa1 = await aaa1Art.deployed();
	
	const aaa2Art = artifacts.require("HT_Farming");
    const aaa2 = await aaa2Art.deployed();
	
	const aaa3Art = artifacts.require("Matter_Farming");
    const aaa3 = await aaa3Art.deployed();
	
	const aaa4Art = artifacts.require("Room_Farming");
    const aaa4 = await aaa4Art.deployed();
	
	const aaa5Art = artifacts.require("RoomLP_Farming");
    const aaa5 = await aaa5Art.deployed();
	
	const aaa6Art = artifacts.require("Demo_Court");
    const aaa6 = await aaa6Art.deployed();
	
	const aaa7Art = artifacts.require("HT_Claim");
    const aaa7 = await aaa7Art.deployed();
	
	const aaa8Art = artifacts.require("Matter_Claim");
    const aaa8 = await aaa8Art.deployed();
	
	console.log("Demo_USDT");
	console.log(aaa1.address);
	
	console.log("HT_Farming");
	console.log(aaa2.address);
	
	console.log("Matter_Farming");
	console.log(aaa3.address);
	
	console.log("Room_Farming");
	console.log(aaa4.address);
	
	console.log("RoomLP_Farming");
	console.log(aaa5.address);
	
	console.log("Demo_Court");
	console.log(aaa6.address);
	
	console.log("HT_Claim");
	console.log(aaa7.address);
	
	console.log("Matter_Claim");
	console.log(aaa8.address);
	
	console.log("set court address");
	aaa2.setCourtToken(aaa6.address);
	aaa3.setCourtToken(aaa6.address);
	aaa4.setCourtToken(aaa6.address);
	aaa5.setCourtToken(aaa6.address);
	
	
	console.log("set claim parms");
	aaa7.changeParameters(aaa6.address,aaa1.address,6,2,1);
	aaa8.changeParameters(aaa6.address,aaa1.address,6,2,1);
	
	console.log("add minters");
	await aaa6.addMinter(aaa2.address);
	await aaa6.addMinter(aaa3.address);
	await aaa6.addMinter(aaa4.address);
	await aaa6.addMinter(aaa5.address);
	
	
	console.log("add HT and Matter");
	await aaa2.setCourtStake(aaa7.address);
	await aaa3.setCourtStake(aaa8.address);
	
	
	
	
	

  });
};
