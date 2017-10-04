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
    bool public accepted;
    bool public canceled;

    uint public cumulatedReceived;

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
            if (accepted || canceled) return 0;
        }
        return amount;
    }

    function afterTransfer(uint64 pledgeManager, uint64 pledgeFrom, uint64 pledgeTo, uint64 context, uint amount) {
        uint returnFunds;
        require(msg.sender == address(liquidPledging));

        var (, oldOwner, , , , , ) = liquidPledging.getPledge(pledgeFrom);

        if ((context == TO_OWNER)&&(oldOwner != idCampaign)) {  // Recipient of the funds from a different owner

            cumulatedReceived += amount;
            if (accepted || canceled) {
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

    function acceptMilestone() onlyReviewer {
        require(!canceled);
        require(!accepted);
        accepted = true;
    }

    function cancelMilestone() onlyReviewer {
        require(!canceled);
        require(!accepted);

        canceled = true;

        liquidPledging.cancelCampaign(idCampaign);
    }

    function withdraw(uint64 idPledge, uint amount) onlyRecipient {
        require(!canceled);
        require(accepted);
        liquidPledging.withdraw(idPledge, amount);
        collect();
    }

    function mWithdraw(uint[] pledgesAmounts) onlyRecipient {
        require(!canceled);
        require(accepted);
        liquidPledging.mWithdraw(pledgesAmounts);
        collect();
    }

    function collect() onlyRecipient {
        if (this.balance>0) recipient.transfer(this.balance);
    }
}
