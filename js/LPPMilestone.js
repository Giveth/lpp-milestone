const LPPMilestoneAbi = require('../build/LPPMilestone.sol').LPPMilestoneAbi;
const LPPMilestoneByteCode = require('../build/LPPMilestone.sol').LPPMilestoneByteCode;
const generateClass = require('eth-contract-class').default;

const LPPMilestone = generateClass(LPPMilestoneAbi, LPPMilestoneByteCode);

// TODO use this when web3 concurrancy bug is fixed https://github.com/ethereum/web3.js/issues/1069
// LPPMilestone.prototype.getState = function () {
//   return Promise.all([
//     this.liquidPledging(),
//     this.idProject(),
//     this.maxAmount(),
//     this.cumulatedReceived(),
//     this.reviewer(),
//     this.recipient(),
//     this.newReviewer(),
//     this.newRecipient(),
//     this.accepted(),
//     this.canceled(),
//   ])
//   .then((results) => {
//     return {
//       liquidPledging: results[0],
//       idProject: results[1],
//       maxAmount: results[2],
//       cumulatedReceived: results[3],
//       reviewer: results[4],
//       recipeint: results[5],
//       newReviewer: results[6],
//       newRecipient: results[7],
//       accepted: results[8],
//       canceled: results[9],
//     };
//   });
// };

// tmp function
LPPMilestone.prototype.getState = async function() {
    const st = {};

    st.liquidPledging = await this.liquidPledging();
    st.idProject = await this.idProject();
    st.maxAmount = await this.maxAmount();
    st.cumulatedReceived = await this.cumulatedReceived();
    st.reviewer = await this.reviewer();
    st.recipient = await this.recipient();
    st.newReviewer = await this.newReviewer();
    st.newRecipient = await this.newRecipient();
    st.accepted = await this.accepted();
    st.canceled = await this.canceled();

    return st;
}

module.exports = LPPMilestone;
