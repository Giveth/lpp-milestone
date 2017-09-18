/* eslint-env mocha */
/* eslint-disable no-await-in-loop */
const ethConnector = require('ethconnector');
const chai = require('chai');
const getBalance = require('runethtx').getBalance;
const liquidpledging = require('liquidpledging');

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
  assert.equal(st.notes.length, 13);
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
  let adminProject1;
  let project;
  before((done) => {
    ethConnector.init('testrpc', { gasLimit: 5200000 }, () => {
      web3 = ethConnector.web3;
      accounts = ethConnector.accounts;
      donor1 = accounts[1];
      delegate1 = accounts[2];
      adminProject1 = accounts[3];
      done();
    });
  });
  it('Should deploy LiquidPledgin contract', async () => {
    vault = await Vault.new(web3);
    liquidPledging = await LiquidPledging.new(web3, vault.$address, { $gas: 5200000 });
    await vault.setLiquidPledging(liquidPledging.$address);
  }).timeout(6000);
  it('Should create a donor', async () => {
    await liquidPledging.addDonor('Donor1', 86400, 0, { from: donor1 });
    const nManagers = await liquidPledging.numberOfNoteManagers();
    assert.equal(nManagers, 1);
    const res = await liquidPledging.getNoteManager(1);
    assert.equal(res[0], 0); // Donor
    assert.equal(res[1], donor1);
    assert.equal(res[2], 'Donor1');
    assert.equal(res[3], 86400);
  }).timeout(6000);
  it('Should make a donation', async () => {
    await liquidPledging.donate(1, 1, { from: donor1, value: web3.toWei(1) });
    const nNotes = await liquidPledging.numberOfNotes();
    assert.equal(nNotes.toNumber(), 1);
    await liquidPledging.getNote(1);
  }).timeout(6000);
  it('Should create a delegate', async () => {
    await liquidPledging.addDelegate('Delegate1', 0, 0, { from: delegate1 });
    const nManagers = await liquidPledging.numberOfNoteManagers();
    assert.equal(nManagers, 2);
    const res = await liquidPledging.getNoteManager(2);
    assert.equal(res[0], 1); // Donor
    assert.equal(res[1], delegate1);
    assert.equal(res[2], 'Delegate1');
  }).timeout(6000);
  it('Donor should delegate on the delegate', async () => {
    await liquidPledging.transfer(1, 1, web3.toWei(0.5), 2, { from: donor1 });
    const nNotes = await liquidPledging.numberOfNotes();
    assert.equal(nNotes.toNumber(), 2);
    const res1 = await liquidPledging.getNote(1);
    assert.equal(res1[0].toNumber(), web3.toWei(0.5));
    const res2 = await liquidPledging.getNote(2);
    assert.equal(res2[0].toNumber(), web3.toWei(0.5));
    assert.equal(res2[1].toNumber(), 1); // One delegate

    const d = await liquidPledging.getNoteDelegate(2, 1);
    assert.equal(d[0], 2);
    assert.equal(d[1], delegate1);
    assert.equal(d[2], 'Delegate1');
  }).timeout(6000);
  it('Should deploy the plugin', async () => {
    project = await LPPMilestone.new(web3, liquidPledging.$address, 'Project1', 0);
    const nManagers = await liquidPledging.numberOfNoteManagers();
    assert.equal(nManagers, 3);
    const res = await liquidPledging.getNoteManager(3);
    assert.equal(res[0], 2); // Project type
    assert.equal(res[1], project.$address);
    assert.equal(res[2], 'Project1');
    assert.equal(res[3], 0);
    assert.equal(res[4], 0);
    assert.equal(res[5], false);
    const idProject = await project.idProject();
    assert.equal(idProject, 3);
  }).timeout(6000);
});
