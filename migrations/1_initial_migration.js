const Migrations = artifacts.require("Migrations");
//const Tournament = artifacts.require("TrollerArtTournament");
const LuckyBlock = artifacts.require("LuckyBlock.sol");
const Presale = artifacts.require('Presale.sol');
const TimeLockedWalletFactory = artifacts.require('TimeLockedWalletFactory.sol');
module.exports = async function  (deployer) {
  //deployer.deploy(Migrations);
  //await deployer.deploy(TimeLockedWalletFactory);
  await deployer.deploy(LuckyBlock,'0x10ED43C718714eb63d5aA57B78B54704E256024E');
  //await deployer.deploy(Presale,LuckyBlock.address,'0x01103B62a82071442Aa56F1Fb496b9C0c8844797',100000000)
  
 
};
