// migrations/2_deploy.js
const Casino = artifacts.require('Casino');
const Token = artifacts.require('Token');
const PriceConsumerV3 = artifacts.require('PriceConsumerV3');

module.exports = async function (deployer) {
  await deployer.deploy(Casino);
  await deployer.deploy(Token);
  await deployer.deploy(PriceConsumerV3);
};