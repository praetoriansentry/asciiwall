const wall = artifacts.require('ASCIIWall');

module.exports = async function (deployer) {
  await deployer.deploy(wall);
};
