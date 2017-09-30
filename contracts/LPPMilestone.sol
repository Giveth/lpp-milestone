pragma solidity ^0.4.13;

import "../node_modules/liquidpledging/contracts/LiquidPledging.sol";

contract LPPMilestone {
    uint constant FROM_OWNER = 0;
    uint constant FROM_PROPOSEDPROJECT = 255;
    uint constant TO_OWNER = 256;
    uint constant TO_PROPOSEDPROJECT = 511;

    LiquidPledging public liquidPledging;
    uint64 public idProject;
    uint public maxAmount;
    address public reviewer;
    address public recipient;
    address public newReviewer;
    address public newRecipient;
    MilestoneState public state;

    enum MilestoneState { InProgress, NeedsReview, Completed, Canceled }

    uint public cumulatedReceived;

    event StateChanged(address indexed liquidPledging, MilestoneState state);

    function LPPMilestone(LiquidPledging _liquidPledging, string name, uint parentProject, address _recipient, uint _maxAmount, address _reviewer) {
        liquidPledging = _liquidPledging;
        idProject = liquidPledging.addProject(name, address(this), 0, 0, ILiquidPledgingPlugin(this));
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

    function beforeTransfer(uint64 noteManager, uint64 noteFrom, uint64 noteTo, uint64 context, uint amount) returns (uint maxAllowed) {
        require(msg.sender == address(liquidPledging));
        var (, , , fromProposedProject , , , ) = liquidPledging.getNote(noteFrom);
        // If it is proposed or comes from somewhere else of a proposed project, do not allow.
        // only allow from the proposed project to the project in order normalize it.
        if (   (context == TO_PROPOSEDPROJECT)
            || (   (context == TO_OWNER)
                && (fromProposedProject != idProject)))
        {
            if (state != MilestoneState.InProgress) return 0;
        }
        return amount;
    }

    function afterTransfer(uint64 noteManager, uint64 noteFrom, uint64 noteTo, uint64 context, uint amount) {
        uint returnFunds;
        require(msg.sender == address(liquidPledging));

        var (, oldOwner, , , , , ) = liquidPledging.getNote(noteFrom);
        var (, , , , , oldNote, ) = liquidPledging.getNote(noteTo);

        if ((context == TO_OWNER)&&(oldOwner != idProject)) {  // Recipient of the funds from a different owner

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
                liquidPledging.cancelNote(noteTo, returnFunds);
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

        liquidPledging.cancelProject(idProject);

        state = MilestoneState.Canceled;
        StateChanged(address(liquidPledging), state);
    }

    function withdraw(uint64 idNote, uint amount) onlyRecipient {
        require(state == MilestoneState.Completed);
        liquidPledging.withdraw(idNote, amount);
        collect();
    }

    function mWithdraw(uint[] notesAmounts) onlyRecipient {
        require(state == MilestoneState.Completed);
        liquidPledging.mWithdraw(notesAmounts);
        collect();
    }

    function collect() onlyRecipient {
        if (this.balance>0) recipient.transfer(this.balance);
    }
}
