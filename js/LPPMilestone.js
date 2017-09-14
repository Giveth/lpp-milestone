const LPPMilestoneAbi = require("../build/LPPMilestone.sol").LPPMilestoneAbi;
const LPPMilestoneByteCode = require("../build/LPPMilestone.sol").LPPMilestoneByteCode;
const runethtx = require("runethtx");

module.exports = runethtx.generateClass(LPPMilestoneAbi, LPPMilestoneByteCode);
