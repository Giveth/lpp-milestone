const LPPMilestoneFactoryABI = require('../build/LPPMilestoneFactory.sol').LPPMilestoneFactoryAbi;
const LPPMilestoneFactoryByteCode = require('../build/LPPMilestoneFactory.sol').LPPMilestoneFactoryByteCode;
const generateClass = require('eth-contract-class').default;

module.exports = generateClass(LPPMilestoneFactoryABI, LPPMilestoneFactoryByteCode);
