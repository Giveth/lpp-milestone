const LPPMilestoneAbi = require('../build/LPPMilestone.sol').LPPMilestoneAbi;
const LPPMilestoneByteCode = require('../build/LPPMilestone.sol').LPPMilestoneByteCode;
const generateClass = require('eth-contract-class').default;

const LPPMilestone = generateClass(LPPMilestoneAbi, LPPMilestoneByteCode);

const translateState = (state) => {
  switch (state) {
    case '0':
      return 'InProgress';
    case '1':
      return 'NeedsReview';
    case '2':
      return 'Completed';
    case '3':
      return 'Canceled';
    default:
      return 'Unknown';
  }
};

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
    this.state(),
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
    state: translateState(results[8]),
  }));
};

module.exports = LPPMilestone;
