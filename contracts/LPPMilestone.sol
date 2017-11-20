pragma solidity ^0.4.13;

import "liquidpledging/contracts/LiquidPledging.sol";

contract LPPMilestone {
    uint constant FROM_OWNER = 0;
    uint constant FROM_INTENDEDPROJECT = 255;
    uint constant TO_OWNER = 256;
    uint constant TO_INTENDEDPROJECT = 511;

    LiquidPledging public liquidPledging;

    address public milestoneReviewer;
    address public campaignReviewer;
    address public recipient;

    uint public maxAmount;
    address public newMilestoneReviewer;
    address public newCampaignReviewer;
    address public newRecipient;
    uint64 public idProject;
    bool public accepted;
    bool public initPending;

    uint public cumulatedReceived;

    event MilestoneAccepted(address indexed liquidPledging);

    function LPPMilestone() {
        require(msg.sender != tx.origin);
        initPending = true;
    }

    function init(
        LiquidPledging _liquidPledging,
        string name,
        string url,
        uint64 parentProject,
        address _recipient,
        uint _maxAmount,
        address _milestoneReviewer,
        address _campaignReviewer
    ) {
        require(initPending);
        liquidPledging = _liquidPledging;
        idProject = liquidPledging.addProject(name, url, address(this), parentProject, uint64(0), ILiquidPledgingPlugin(this));
        maxAmount = _maxAmount;
        recipient = _recipient;
        milestoneReviewer = _milestoneReviewer;
        campaignReviewer = _campaignReviewer;
        initPending = false;
    }

    modifier initialized() {
        require(!initPending);
        _;
    }

    modifier onlyRecipient() {
        require(msg.sender == recipient);
        _;
    }

    modifier onlyReviewer() {
        require(msg.sender == milestoneReviewer || msg.sender == campaignReviewer);
        _;
    }

    function changeRecipient(address _newRecipient) initialized onlyRecipient {
        newRecipient = _newRecipient;
    }

    function changeMilestoneReviewer(address _newReviewer) initialized {
        require(msg.sender == milestoneReviewer);
        newMilestoneReviewer = _newReviewer;
    }

    function changeCampaignReviewer(address _newReviewer) initialized {
        require(msg.sender == campaignReviewer);
        newCampaignReviewer = _newReviewer;
    }

    function acceptNewRecipient() initialized {
        require(newRecipient == msg.sender);
        recipient = newRecipient;
        newRecipient = 0;
    }

    function acceptNewMilestoneReviewer() initialized {
        require(newMilestoneReviewer == msg.sender);
        milestoneReviewer = newMilestoneReviewer;
        newMilestoneReviewer = 0;
    }

    function acceptNewCampaignReviewer() initialized {
        require(newCampaignReviewer == msg.sender);
        campaignReviewer = newCampaignReviewer;
        newCampaignReviewer = 0;
    }

    /// @dev Plugins are used (much like web hooks) to initiate an action
    ///  upon any donation, delegation, or transfer; this is an optional feature
    ///  and allows for extreme customization of the contract
    /// @dev Context The situation that is triggering the plugin:
    ///  0 -> Plugin for the owner transferring pledge to another party
    ///  1 -> Plugin for the first delegate transferring pledge to another party
    ///  2 -> Plugin for the second delegate transferring pledge to another party
    ///  ...
    ///  255 -> Plugin for the intendedProject transferring pledge to another party
    ///
    ///  256 -> Plugin for the owner receiving pledge from another party
    ///  257 -> Plugin for the first delegate receiving pledge from another party
    ///  258 -> Plugin for the second delegate receiving pledge from another party
    ///  ...
    ///  511 -> Plugin for the intendedProject receiving pledge from another party
    function beforeTransfer(
        uint64 pledgeManager,
        uint64 pledgeFrom,
        uint64 pledgeTo,
        uint64 context,
        uint amount
        ) initialized returns (uint maxAllowed){
        require(msg.sender == address(liquidPledging));
        var (, , , fromIntendedProject , , , ) = liquidPledging.getPledge(pledgeFrom);
        var (, , , , , , toPaymentState ) = liquidPledging.getPledge(pledgeTo);
        // If it is proposed or comes from somewhere else of a proposed project, do not allow.
        // only allow from the proposed project to the project in order normalize it.
        if (   (context == TO_INTENDEDPROJECT)
            || (   (context == TO_OWNER)
                && (fromIntendedProject != idProject) && (toPaymentState == LiquidPledgingBase.PaymentState.Pledged)))
        {
            if (accepted || isCanceled()) return 0;
        }
        return amount;
    }
    /// @dev Plugins are used (much like web hooks) to initiate an action
    ///  upon any donation, delegation, or transfer; this is an optional feature
    ///  and allows for extreme customization of the contract
    /// @dev Context The situation that is triggering the plugin, see note for
    ///  `beforeTransfer()`
    function afterTransfer(
        uint64 pledgeManager,
        uint64 pledgeFrom,
        uint64 pledgeTo,
        uint64 context,
        uint amount
    ) initialized {
        uint returnFunds;
        require(msg.sender == address(liquidPledging));

        var (, oldOwner, , , , , ) = liquidPledging.getPledge(pledgeFrom);

        if ((context == TO_OWNER)&&(oldOwner != idProject)) {  // Recipient of the funds from a different owner

            cumulatedReceived += amount;
            if (accepted || isCanceled()) {
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

    function isCanceled() constant initialized returns (bool) {
        return liquidPledging.isProjectCanceled(idProject);
    }

    function acceptMilestone() initialized onlyReviewer {
        require(!isCanceled());
        require(!accepted);
        accepted = true;
        MilestoneAccepted(address(liquidPledging));
    }

    function cancelMilestone() initialized onlyReviewer {
        require(!isCanceled());
        require(!accepted);

        liquidPledging.cancelProject(idProject);
    }

    function withdraw(uint64 idPledge, uint amount) initialized onlyRecipient {
        require(!isCanceled());
        require(accepted);
        liquidPledging.withdraw(idPledge, amount);
        collect();
    }

    function mWithdraw(uint[] pledgesAmounts) initialized onlyRecipient {
        require(!isCanceled());
        require(accepted);
        liquidPledging.mWithdraw(pledgesAmounts);
        collect();
    }

    function collect() initialized onlyRecipient {
        if (this.balance>0) recipient.transfer(this.balance);
    }

    function () payable initialized {}
}
