const LPPMilestoneAbi = require('../build/LPPMilestone.sol').LPPMilestoneAbi;
const LPPMilestoneByteCode = require('../build/LPPMilestone.sol').LPPMilestoneByteCode;
const generateClass = require('eth-contract-class').default;

const LPPMilestone = generateClass(LPPMilestoneAbi, LPPMilestoneByteCode);

LPPMilestone.prototype.getState = function () {
  return Promise.all([
    this.liquidPledging(),
    this.idProject(),
    this.maxAmount(),
    this.cumulatedReceived(),
    this.reviewer(),
    this.recipient(),
    this.newReviewer(),
    this.newRecipient(),
    this.accepted(),
    this.canceled(),
  ])
  .then(results => ({
    liquidPledging: results[0],
    idProject: results[1],
    maxAmount: results[2],
    cumulatedReceived: results[3],
    reviewer: results[4],
    recipeint: results[5],
    newReviewer: results[6],
    newRecipient: results[7],
    accepted: results[8],
    canceled: results[9],
  }));
};

module.exports = LPPMilestone;
