'use strict';

var LPPMilestoneFactoryABI = require('../build/LPPMilestoneFactory.sol').LPPMilestoneFactoryAbi;
var LPPMilestoneFactoryByteCode = require('../build/LPPMilestoneFactory.sol').LPPMilestoneFactoryByteCode;
var generateClass = require('eth-contract-class').default;

module.exports = generateClass(LPPMilestoneFactoryABI, LPPMilestoneFactoryByteCode);