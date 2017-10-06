/* eslint-env mocha */
/* eslint-disable no-await-in-loop */
const TestRPC = require('ethereumjs-testrpc');
const Web3 = require('web3');
const chai = require('chai');
const liquidpledging = require('liquidpledging');
const assertFail = require('./helpers/assertFail');

const { utils } = Web3;

const LiquidPledging = liquidpledging.LiquidPledging(true);
const LPPMilestone = require('../index.js');

const Vault = liquidpledging.Vault;
const assert = chai.assert;


const printState = async(liquidPledging) => {
  console.log(liquidPledging.b);
  const st = await liquidPledging.getState();
  console.log(JSON.stringify(st, null, 2));
};

const printBalances = async(liquidPledging) => {
  const st = await liquidPledging.getState();
  assert.equal(st.pledges.length, 13);
  for (let i = 1; i <= 12; i += 1) {
    console.log(i, ethConnector.web3.fromWei(st.notes[i].amount).toNumber());
  }
};

const readTest = async(liquidPledging) => {
  const t1 = await liquidPledging.test1();
  const t2 = await liquidPledging.test2();
  const t3 = await liquidPledging.test3();
  const t4 = await liquidPledging.test4();
  console.log('t1: ', t1.toNumber());
  console.log('t2: ', t2.toNumber());
  console.log('t3: ', t3.toNumber());
  console.log('t4: ', t4.toNumber());
};

describe('LiquidPledging test', () => {
  let web3;
  let accounts;
  let liquidPledging;
  let vault;
  let donor1;
  let delegate1;
  let adminMilestone1;
  let milestone;
  let recipient;
  let reviewer;
  before(async () => {
    const testrpc = TestRPC.server({
      ws: true,
      gasLimit: 5800000,
      total_accounts: 10,
    });

    testrpc.listen(8546, '127.0.0.1');

    web3 = new Web3('ws://localhost:8546');
    accounts = await web3.eth.getAccounts();
    donor1 = accounts[1];
    delegate1 = accounts[2];
    adminMilestone1 = accounts[3];
    recipient = accounts[4];
    reviewer = accounts[5];
  });
  it('Should deploy LiquidPledgin contract', async () => {
    vault = await Vault.new(web3);
    liquidPledging = await LiquidPledging.new(web3, vault.$address, { $gas: 5800000 });
    await vault.setLiquidPledging(liquidPledging.$address);
  }).timeout(6000);
  it('Should create a donor', async () => {
    await liquidPledging.addGiver('Donor1', 'URLDonor1', 86400, 0, { from: donor1 });
    const nManagers = await liquidPledging.numberOfPledgeAdmins();
    assert.equal(nManagers, 1);
    const res = await liquidPledging.getPledgeAdmin(1);
    assert.equal(res[0], 0); // Donor
    assert.equal(res[1], donor1);
    assert.equal(res[2], 'Donor1');
    assert.equal(res[3], 'URLDonor1');
    assert.equal(res[4], 86400);
  }).timeout(6000);
  it('Should make a donation', async () => {
    await liquidPledging.donate(1, 1, { from: donor1, value: utils.toWei(1) });
    const nPledges = await liquidPledging.numberOfPledges();
    assert.equal(nPledges, 1);
    await liquidPledging.getPledge(1);
  }).timeout(6000);
  it('Should create a delegate', async () => {
    await liquidPledging.addDelegate('Delegate1', 'URLDelegate1', 0, 0, { from: delegate1 });
    const nAdmins = await liquidPledging.numberOfPledgeAdmins();
    assert.equal(nAdmins, 2);
    const res = await liquidPledging.getPledgeAdmin(2);
    assert.equal(res[0], 1); // Donor
    assert.equal(res[1], delegate1);
    assert.equal(res[2], 'Delegate1');
    assert.equal(res[3], 'URLDelegate1');
  }).timeout(6000);
  it('Donor should delegate on the delegate', async () => {
    await liquidPledging.transfer(1, 1, utils.toWei(0.5), 2, { from: donor1 });
    const nPledges = await liquidPledging.numberOfPledges();
    assert.equal(nPledges, 2);
    const res1 = await liquidPledging.getPledge(1);
    assert.equal(res1[0], utils.toWei(0.5));
    const res2 = await liquidPledging.getPledge(2);
    assert.equal(res2[0], utils.toWei(0.5));
    assert.equal(res2[1], 1); // One delegate

    const d = await liquidPledging.getPledgeDelegate(2, 1);
    assert.equal(d[0], 2);
    assert.equal(d[1], delegate1);
    assert.equal(d[2], 'Delegate1');
  }).timeout(6000);
  it('Should deploy the plugin', async () => {
    milestone = await LPPMilestone.new(web3, liquidPledging.$address, 'Milestone1', 'URLMilestone1', 0, recipient, utils.toWei(1), reviewer, { from: adminMilestone1});
    const nAdmins = await liquidPledging.numberOfPledgeAdmins();
    assert.equal(nAdmins, 3);
    const res = await liquidPledging.getPledgeAdmin(3);
    assert.equal(res[0], 2); // Project type
    assert.equal(res[1], milestone.$address);
    assert.equal(res[2], 'Milestone1');
    assert.equal(res[3], 'URLMilestone1');
    assert.equal(res[4], 0);
    assert.equal(res[5], 0);
    assert.equal(res[6], false);
    const idProject = await milestone.idProject();
    assert.equal(idProject, 3);
  }).timeout(6000);

  it('Should make a donation to milestone', async () => {
    await liquidPledging.donate(1, 3, { from: donor1, value: '1000' });
    const nPledges = await liquidPledging.numberOfPledges();
    assert.equal(nPledges, 3);

    const res = await liquidPledging.getPledge(3);
    assert.equal(res.amount, '1000');
    assert.equal(res.owner, 3);
    assert.equal(res.nDelegates, 0);
    assert.equal(res.intendedProject, 0);
    assert.equal(res.commitTime, 0);
    assert.equal(res.oldPledge, 1);
    assert.equal(res.paymentState, 0);
  }).timeout(6000);

  it('Should not be able to withdraw non-accepted milestone', async () => {
    await assertFail(async () => {
      await milestone.withdraw(3, '1000', { from: adminMilestone1 });
    });
  }).timeout(6000);

  it('Should mark milestone Completed', async () => {
    await milestone.acceptMilestone({ from: reviewer});
    assert.equal(await milestone.accepted(), true);
  }).timeout(6000);

  it('Should withdraw pledge for completed milestone', async () => {
    await milestone.withdraw(3, '1000', { from: recipient});

    const st = await liquidPledging.getState();

    assert.equal(st.pledges.length, 5);

    const oldPledge = st.pledges[3];
    const payingPledge = st.pledges[4];

    assert.equal(oldPledge.amount, '0');
    assert.equal(oldPledge.paymentState, 'Pledged');

    assert.equal(payingPledge.amount, '1000');
    assert.equal(payingPledge.owner, 3);
    assert.equal(payingPledge.delegates.length, 0);
    assert.equal(payingPledge.intendedProject, 0);
    assert.equal(payingPledge.oldPledge, 1);
    assert.equal(payingPledge.paymentState, 'Paying');
  }).timeout(6000);
});
