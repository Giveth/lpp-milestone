const LPPMilestoneAbi = require("../build/LPPMilestone.sol").LPPMilestoneAbi;
const LPPMilestoneByteCode = require("../build/LPPMilestone.sol").LPPMilestoneByteCode;
const generateClass = require('eth-contract-class').default;

module.exports = generateClass(LPPMilestoneAbi, LPPMilestoneByteCode);
