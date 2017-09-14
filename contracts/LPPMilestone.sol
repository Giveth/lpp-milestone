pragma solidity ^0.4.13;

import "../node_modules/liquidpledging/contracts/LiquidPledging.sol";

contract LPPMilestone {
    LiquidPledging public liquidPledging;
    uint public projectId;

    function LPPMilestone(LiquidPledging _liquidPledging, string name, uint parentProject) {
        liquidPledging = _liquidPledging;
        projectId = liquidPledging.addProject(name, address(this), 0, address(this));
    }

    function beforeTransfer(uint64 noteManager, uint64 noteFrom, uint64 noteTo, uint64 context, uint amount) returns (uint maxAllowed) {
        require(msg.sender== address(liquidPledging));
        return amount;
    }

    function afterTransfer(uint64 noteManager, uint64 noteFrom, uint64 noteTo, uint64 context, uint amount) {
        require(msg.sender== address(liquidPledging));
    }
}
