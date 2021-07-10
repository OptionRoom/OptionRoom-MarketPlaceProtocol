var chai = require('chai');

//use default BigNumber
chai.use(require('chai-bignumber')());

const { expectEvent } = require('openzeppelin-test-helpers')
const { toBN } = web3.utils

const OASContract = artifacts.require("../../../contracts/OR/OROracleInfoForTest.sol");
const IERC20Contract = artifacts.require('../../../contracts/mocks/ERC20DemoToken.sol')

var BigNumber = require('bignumber.js');


let oasContractInstance
let deployer;
let roomTokenFake;

function addDays(theDate, days) {
  return new Date(theDate.getTime() + days * 24 * 60 * 60 * 1000)
}

function setDeployer(deployerAccount) {
  deployer = deployerAccount;
}

async function prepareContracts(creator, oracle, investor1, trader, investor2) {
  oasContractInstance = await OASContract.new();
  roomTokenFake = await IERC20Contract.new()

  // Setting the room address.
  await oasContractInstance.setRoomAddress(roomTokenFake.address, { from: deployer })

  return [oasContractInstance, roomTokenFake];
}

module.exports = {
  setDeployer,
  prepareContracts,
  addDays,
}

