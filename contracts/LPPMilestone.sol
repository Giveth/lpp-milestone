pragma solidity ^0.4.13;

import "../node_modules/liquidpledging/contracts/LiquidPledging.sol";

contract LPPMilestone {
    uint constant FROM_OWNER = 0;
    uint constant FROM_INTENDDCAMPAIGN = 255;
    uint constant TO_OWNER = 256;
    uint constant TO_INTENDEDCAMPAIGN = 511;

    LiquidPledging public liquidPledging;

    address public reviewer;
    address public recipient;

    uint64 public idCampaign;
    uint public maxAmount;
    address public newReviewer;
    address public newRecipient;
    MilestoneState public state;

    enum MilestoneState { InProgress, NeedsReview, Completed, Canceled }

    uint public cumulatedReceived;

    event StateChanged(address indexed liquidPledging, MilestoneState state);

    function LPPMilestone(LiquidPledging _liquidPledging, string name, string url, uint64 parentCampaign, address _recipient, uint _maxAmount, address _reviewer) {
        liquidPledging = _liquidPledging;
        idCampaign = liquidPledging.addCampaign(name, url, address(this), parentCampaign, uint64(0), ILiquidPledgingPlugin(this));
        maxAmount = _maxAmount;
        recipient = _recipient;
        reviewer = _reviewer;
    }

    modifier onlyRecipient() {
        require(msg.sender == recipient);
        _;
    }

    modifier onlyReviewer() {
        require(msg.sender == reviewer);
        _;
    }

    function changeRecipient(address _newRecipient) onlyRecipient {
        newRecipient = _newRecipient;
    }

    function changeReviewer(address _newReviewer) onlyReviewer {
        newReviewer = _newReviewer;
    }

    function acceptNewRecipient() {
        require(newRecipient == msg.sender);
        recipient = newRecipient;
        newRecipient = 0;
    }

    function acceptNewReviewer() {
        require(newReviewer == msg.sender);
        reviewer = newReviewer;
        newReviewer = 0;
    }

    function beforeTransfer(uint64 pledgeManager, uint64 pledgeFrom, uint64 pledgeTo, uint64 context, uint amount) returns (uint maxAllowed) {
        require(msg.sender == address(liquidPledging));
        var (, , , fromIntendedCampaign , , , ) = liquidPledging.getPledge(pledgeFrom);
        // If it is proposed or comes from somewhere else of a proposed campaign, do not allow.
        // only allow from the proposed campaign to the campaign in order normalize it.
        if (   (context == TO_INTENDEDCAMPAIGN)
            || (   (context == TO_OWNER)
                && (fromIntendedCampaign != idCampaign)))
        {
            if (state != MilestoneState.InProgress) return 0;
        }
        return amount;
    }

    function afterTransfer(uint64 pledgeManager, uint64 pledgeFrom, uint64 pledgeTo, uint64 context, uint amount) {
        uint returnFunds;
        require(msg.sender == address(liquidPledging));

        var (, oldOwner, , , , , ) = liquidPledging.getPledge(pledgeFrom);

        if ((context == TO_OWNER)&&(oldOwner != idCampaign)) {  // Recipient of the funds from a different owner

            cumulatedReceived += amount;
            if (state != MilestoneState.InProgress) {
                returnFunds = amount;
            } else if (cumulatedReceived > maxAmount) {
                returnFunds = cumulatedReceived - maxAmount;
            } else {
                returnFunds = 0;
            }

            if (returnFunds > 0) {  // Sends exceding money back
                cumulatedReceived -= returnFunds;
                liquidPledging.cancelPledge(pledgeTo, returnFunds);
            }
        }
    }

    function readyForReview() onlyRecipient {
        require(state == MilestoneState.InProgress);
        state = MilestoneState.NeedsReview;
        StateChanged(address(liquidPledging), state);
    }

    function acceptMilestone() onlyReviewer {
        require(state == MilestoneState.NeedsReview);
        state = MilestoneState.Completed;
        StateChanged(address(liquidPledging), state);
    }

    function rejectMilestone() onlyReviewer {
        require(state == MilestoneState.NeedsReview);
        state = MilestoneState.InProgress;
        StateChanged(address(liquidPledging), state);
    }

    function cancelMilestone() onlyReviewer {
        require(state == MilestoneState.InProgress || state == MilestoneState.NeedsReview);

        liquidPledging.cancelCampaign(idProject);

        state = MilestoneState.Canceled;
        StateChanged(address(liquidPledging), state);
    }

    function withdraw(uint64 idPledge, uint amount) onlyRecipient {
        require(state == MilestoneState.Completed);
        liquidPledging.withdraw(idPledge, amount);
        collect();
    }

    function mWithdraw(uint[] pledgesAmounts) onlyRecipient {
        require(state == MilestoneState.Completed);
        liquidPledging.mWithdraw(pledgesAmounts);
        collect();
    }

    function collect() onlyRecipient {
        if (this.balance>0) recipient.transfer(this.balance);
    }
}
