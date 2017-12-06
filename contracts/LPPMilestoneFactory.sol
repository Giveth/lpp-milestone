pragma solidity ^0.4.13;

import "./LPPMilestone.sol";

contract LPPMilestoneFactory is Escapable {

    function LPPMilestoneFactory(address _escapeHatchCaller, address _escapeHatchDestination)
        Escapable(_escapeHatchCaller, _escapeHatchDestination)
    {
    }

    function deploy(
        LiquidPledging _liquidPledging,
        string name,
        string url,
        uint64 parentProject,
        address _recipient,
        uint _maxAmount,
        address _milestoneReviewer,
        address _campaignReviewer,
        address _escapeHatchCaller,
        address _escapeHatchDestination
    )
    {
        LPPMilestone milestone = new LPPMilestone(_escapeHatchCaller, _escapeHatchDestination);
        milestone.init(
            _liquidPledging,
            name,
            url,
            parentProject,
            _recipient,
            _maxAmount,
            _milestoneReviewer,
            _campaignReviewer
        );
    }
}
