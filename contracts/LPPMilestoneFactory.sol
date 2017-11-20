pragma solidity ^0.4.13;

import "./LPPMilestone.sol";

contract LPPMilestoneFactory {
    function deploy(
        LiquidPledging _liquidPledging,
        string name,
        string url,
        uint64 parentProject,
        address _recipient,
        uint _maxAmount,
        address _milestoneReviewer,
        address _campaignReviewer
  ) {
        LPPMilestone milestone = new LPPMilestone();
        milestone.init(_liquidPledging, name, url, parentProject, _recipient, _maxAmount, _milestoneReviewer, _campaignReviewer);
    }
}
