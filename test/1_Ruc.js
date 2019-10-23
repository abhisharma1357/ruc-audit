const RUC = artifacts.require('RamaToken.sol');
const TokenVesting = artifacts.require('TokenVesting.sol');
const Crowdsale = artifacts.require('Crowdsale.sol');
//const shouldFail = require('openzeppelin-solidity/test/helpers/shouldFail');
//const { expectThrow } = require('openzeppelin-solidity/test/helpers/expectThrow');
//const { EVMRevert } = require('openzeppelin-solidity/test/helpers/EVMRevert');
var Web3 = require("web3");
var web3 = new Web3(new Web3.providers.HttpProvider("http://localhost:8545"));

//account 0 owner
//account 1 wallet

//account 2 beneficeary of private sale round one 
//account 3 beneficeary of private sale round Two
//account 4 beneficeary of pre sale 
//account 5 beneficeary of public sale
//account 6 Strategic Investor to participate in both round of private sale
//account 7 Bounty benefieceary
//account 8 team token vested
//account 9 Advisor token Vested

contract('RamaToken Contract', async (accounts) => {

  it('Should correctly initialize constructor values of Token Contract', async () => {

    this.tokenhold = await RUC.new(accounts[0], { gas: 60000000 });
    let totalSupply = await this.tokenhold.totalSupply.call();
    let owner = await this.tokenhold.owner.call();
    assert.equal(totalSupply.toNumber(), 1500000000000000000000000000);
    assert.equal(owner, accounts[0]);

  });

  it("Should Deploy Crowdsale only", async () => {

    this.crowdhold = await Crowdsale.new(accounts[0], accounts[1], this.tokenhold.address, 5000000, { gas: 600000000 });

  });

  it("Should Deploy Vesting Contract only", async () => {

    this.vesthold = await TokenVesting.new(this.tokenhold.address, this.crowdhold.address, accounts[0], { gas: 6000000 });

  });

  it("Should set Vesting Contract Address to Crowdsale Contract", async () => {

    await this.crowdhold.setVestingAddress(this.vesthold.address, { gas: 600000000, from: accounts[0] });

  });

  it("Should Activate Sale contract", async () => {

    var Activate = await this.tokenhold.activateSaleContract(this.crowdhold.address, { gas: 500000000 });
  });

  it("Should check balance of Crowdsale after, crowdsale activate from token contract", async () => {
    let balancOfCrowdsale = 750000000000000000000000000;
    var balance = await this.tokenhold.balanceOf.call(this.crowdhold.address, { gas: 500000000 });
    assert.equal(balance.toNumber(), balancOfCrowdsale);
  });

  it("Should set minimum Investment Amount for private sale round one, two , presale", async () => {
    let minimumInvest1 = await this.crowdhold.privateRoundOneMinimumInvestment.call({ gas: 500000000 });
    let minimumInvest2 = await this.crowdhold.privateRoundTwoMinimumInvestment.call({ gas: 500000000 });
    let minimumInvest3 = await this.crowdhold.preSaleMinimumInvestment.call({ gas: 500000000 });
    assert.equal(minimumInvest1.toNumber(), 0);
    assert.equal(minimumInvest2.toNumber(), 0);
    assert.equal(minimumInvest3.toNumber(), 0);
    let setMinimumInvestment = await this.crowdhold.setMinInvestmentAmmount(1000, 500, 100, { gas: 500000000 });
    let minimumInvest1Now = await this.crowdhold.privateRoundOneMinimumInvestment.call({ gas: 500000000 });
    let minimumInvest2Now = await this.crowdhold.privateRoundTwoMinimumInvestment.call({ gas: 500000000 });
    let minimumInvest3Now = await this.crowdhold.preSaleMinimumInvestment.call({ gas: 500000000 });
    assert.equal(minimumInvest1Now.toNumber(), 1000);
    assert.equal(minimumInvest2Now.toNumber(), 500);
    assert.equal(minimumInvest3Now.toNumber(), 100);

  });

  it("Should Authorize KYC for account 6", async () => {

    var whiteListAddress = await this.crowdhold.whitelistedContributors.call(accounts[6], { gas: 500000000 });
    assert.equal(whiteListAddress, false, 'not white listed');
    var authorizeKYC = await this.crowdhold.authorizeKyc([accounts[6]], { from: accounts[0] });
    var whiteListAddressNow = await this.crowdhold.whitelistedContributors.call(accounts[6]);
    assert.equal(whiteListAddressNow, true, ' now white listed');

  });

  it("Should Authorize KYC for account 2", async () => {

    var whiteListAddress = await this.crowdhold.whitelistedContributors.call(accounts[2], { gas: 500000000 });
    assert.equal(whiteListAddress, false, 'not white listed');
    var authorizeKYC = await this.crowdhold.authorizeKyc([accounts[2]], { from: accounts[0] });
    var whiteListAddressNow = await this.crowdhold.whitelistedContributors.call(accounts[2]);
    assert.equal(whiteListAddressNow, true, ' now white listed');

  });

  it("Should Freeze Account", async () => {

    var frozen_Account = await this.tokenhold.frozenAccounts.call(accounts[9], { gas: 500000000 });
    assert.equal(frozen_Account, false, 'not freeze Account');
    var freezeAccounts = await this.tokenhold.freezeAccount([accounts[9]],true, { from: accounts[0] });
    var frozen_Account1 = await this.tokenhold.frozenAccounts.call(accounts[9], { gas: 500000000 });
    assert.equal(frozen_Account1, true, ' Account Freezed');
  });

  it("Should un Freeze Account", async () => {

    var frozen_Account1 = await this.tokenhold.frozenAccounts.call(accounts[9], { gas: 500000000 });
    assert.equal(frozen_Account1, true, 'not freeze Account');
    var freezeAccounts = await this.tokenhold.freezeAccount([accounts[9]],false, { from: accounts[0] });
    var frozen_Account = await this.tokenhold.frozenAccounts.call(accounts[9], { gas: 500000000 });
    assert.equal(frozen_Account, false, ' Account Freezed');
  });

  it("Should Start CrowdSale ", async () => {

    var getTheStagebefore = await this.crowdhold.getStage.call();
    var stageBefore = 'crowdSale Not Started yet';
    assert.equal(getTheStagebefore, stageBefore, 'Sale not started yet');
    var crowdsaleStart = await this.crowdhold.startPrivateSaleRoundOne({ from: accounts[0], gas: 500000000 });
    var getTheStage = await this.crowdhold.getStage.call();
    var _presale = 'Private sale Round one';
    assert.equal(getTheStage, _presale, ' Private Sale started now');

  });

  it("Should Send Private Tokens Directly", async () => {

    let fundWalletBefore5 = await web3.eth.getBalance(accounts[1]);
    let AccountBalance_oneBefore5 = await web3.eth.getBalance(accounts[6]);
    var sendPrivateTokens = await this.crowdhold.sendPrivateSaleTokens(accounts[6], 20, { from: accounts[0] });
    var tokens = 20;
    var balance_after5 = await this.tokenhold.balanceOf.call(accounts[6]);
    let fundWalletAfter5 = await web3.eth.getBalance(accounts[1]);
    let AccountBalance_oneAfter5 = await web3.eth.getBalance(accounts[6]);
    assert.equal(balance_after5.toNumber(), tokens * (10 ** 18), 'Token ammount');
    let privateSaleInvestor5 = await this.tokenhold.privateSaleInvestor.call(accounts[6]);
    assert.equal(privateSaleInvestor5, true, 'private Sale Investor');
  });

  it("Should be able to pause and unPause Crowdsale contract", async () => {

    var getTheStagebefore1 = await this.crowdhold.getStage.call();
    var stageBefore1 = 'Private sale Round one';
    assert.equal(getTheStagebefore1, stageBefore1, 'Private Sale started');
    var pauseStautsBefore = await this.crowdhold.Paused.call();
    assert.equal(pauseStautsBefore, false, 'Unpaused');
    var pause = await this.crowdhold.pause();
    var pauseStatusAfter = await this.crowdhold.Paused.call();
    assert.equal(pauseStatusAfter, true, 'Now Paused');
    var restartSale = await this.crowdhold.restartSale();
    var pauseStatusAfter1 = await this.crowdhold.Paused.call();
    assert.equal(pauseStatusAfter1, false, 'again UnPaused');
  });


  it("Should set Price of Token per dollar for Private Investor", async () => {

    await this.crowdhold.setPriceforAllPhases(20,10,5,5, { gas: 500000000 });
    var checkprice1 = await this.crowdhold.privateSaleRoundOneTokensPerDollar.call();
    var checkprice2 = await this.crowdhold.privateSaleRoundTwoTokensPerDollar.call();
    var checkPrice3 = await this.crowdhold.presaleTokensPerDollar.call();
    var checkPrice4 = await this.crowdhold.publicsaleTokensPerDollar.call();

    assert.equal(checkprice1.toNumber()/10**18, 20 , 'price is wrong 1');
    assert.equal(checkprice2.toNumber()/10**18, 10 , 'price is wrong 2');
    assert.equal(checkPrice3.toNumber()/10**18, 5, 'bonus percentage is wrong 1');
    assert.equal(checkPrice4.toNumber()/10**18, 5, 'bonus percentage is wrong 2');

  });

  it("Should set bonus of Token per dollar for Private Investor", async () => {

    await this.crowdhold.setBonusforAllPhases(10,10,20,20, { gas: 500000000 });
    var checkprice1 = await this.crowdhold.bonusInPrivateSaleRoundOne.call();
    var checkprice2 = await this.crowdhold.bonusInPrivateSaleRoundTwo.call();
    var checkPrice3 = await this.crowdhold.bonusInPreSale.call();
    var checkPrice4 = await this.crowdhold.bonusInPublicSale.call();
    assert.equal(checkprice1.toNumber(), 10 , 'price is wrong 1');
    assert.equal(checkprice2.toNumber(), 10 , 'price is wrong 2');
    assert.equal(checkPrice3.toNumber(), 20, 'bonus percentage is wrong 1');
    assert.equal(checkPrice4.toNumber(), 20, 'bonus percentage is wrong 2');

  });

  it("Should be able to buy Tokens  according to private sale", async () => {

    let fundWalletBefore = await web3.eth.getBalance(accounts[1]);
    let AccountBalance_oneBefore = await web3.eth.getBalance(accounts[2]);
    var buy_PrivateSaleTokens = await this.crowdhold.buyTokens(accounts[2], { from: accounts[2], value: web3.utils.toWei("1", "ether") });

    var tokens = 1100000;
    var balance_after = await this.tokenhold.balanceOf.call(accounts[2]);
    let fundWalletAfter = await web3.eth.getBalance(accounts[1]);
    let AccountBalance_oneAfter = await web3.eth.getBalance(accounts[2]);
    assert.equal(balance_after.toNumber(), tokens * (10 ** 18), 'Token ammount');
    let privateSaleInvestor1 = await this.tokenhold.privateSaleInvestor.call(accounts[2]);
    assert.equal(privateSaleInvestor1, true, 'private Sale Investor');
    let currentBonus = await this.crowdhold.bonusInCurrentSale();
    assert.equal(currentBonus.toNumber(),10, 'private Sale Bonus');
  });

  it("Should Authorize KYC for account 3", async () => {

    var whiteListAddress = await this.crowdhold.whitelistedContributors.call(accounts[3], { gas: 500000000 });
    assert.equal(whiteListAddress, false, 'not white listed');
    var authorizeKYC = await this.crowdhold.authorizeKyc([accounts[3]], { from: accounts[0] });
    var whiteListAddressNow = await this.crowdhold.whitelistedContributors.call(accounts[3]);
    assert.equal(whiteListAddressNow, true, ' now white listed');
  });

  it("Should be able end private sale round one and buy Tokens according to private sale round two", async () => {

    await this.crowdhold.endPrivateSaleRoundOne();
    let stage = await this.crowdhold.getStage();
    //console.log(stage);
    assert.equal(stage, "Private sale Round one end", "Stage is wrong");
    await this.crowdhold.startPrivateSaleRoundTwo();
    let newStage = await this.crowdhold.getStage();
    assert.equal(newStage, "Private sale Round Two", "Stage is wrong");

    var balance_Before = await this.tokenhold.balanceOf.call(accounts[3]);
    var buy_PrivateSaleTokens = await this.crowdhold.buyTokens(accounts[3], { from: accounts[3], value: web3.utils.toWei("1", "ether") });

    var tokens = 550000;
    console
    var balance_after = await this.tokenhold.balanceOf.call(accounts[3]);
    let fundWalletAfter = await web3.eth.getBalance(accounts[1]);
    let AccountBalance_oneAfter = await web3.eth.getBalance(accounts[3]);
    //console.log(fundWalletAfter.toNumber(),'fund wallet After buy');
    //console.log(AccountBalance_oneAfter.toNumber(),'account three After buy');
    assert.equal(balance_after.toNumber(), tokens * (10 ** 18), 'Token ammount');
    let privateSaleInvestor2 = await this.tokenhold.privateSaleInvestor.call(accounts[3]);
    assert.equal(privateSaleInvestor2, true, 'private Sale Investor');
    let currentBonus1 = await this.crowdhold.bonusInCurrentSale();
    assert.equal(currentBonus1.toNumber(),10, 'private Sale Bonus');

  });

  it("Should Authorize KYC for account 4", async () => {

    var whiteListAddress = await this.crowdhold.whitelistedContributors.call(accounts[4], { gas: 500000000 });
    assert.equal(whiteListAddress, false, 'not white listed');
    var authorizeKYC = await this.crowdhold.authorizeKyc([accounts[4],accounts[9]], { from: accounts[0] });
    var whiteListAddressNow = await this.crowdhold.whitelistedContributors.call(accounts[4]);
    assert.equal(whiteListAddressNow, true, ' now white listed');

  });



  it("Should be able end private sale round Two and buy Tokens according to pre sale ", async () => {

    await this.crowdhold.endPrivateSaleRoundTwo();
    let stage = await this.crowdhold.getStage();
    //console.log(stage);
    assert.equal(stage, "Private sale Round Two End", "Stage is wrong");
    await this.crowdhold.startPreIco();
    let newStage = await this.crowdhold.getStage();
    assert.equal(newStage, "Pre ICO", "Stage is wrong");

    var balance_Before = await this.tokenhold.balanceOf.call(accounts[4]);
    var buy_PrivateSaleTokens = await this.crowdhold.buyTokens(accounts[4], { from: accounts[4], value: web3.utils.toWei("1", "ether") });

    var tokens = 300000;
    var balance_after = await this.tokenhold.balanceOf.call(accounts[4]);
    //console.log(balance_after.toNumber());
    let fundWalletAfter = await web3.eth.getBalance(accounts[1]);
    let AccountBalance_oneAfter = await web3.eth.getBalance(accounts[4]);
    //console.log(fundWalletAfter.toNumber(),'fund wallet After buy');
    //console.log(AccountBalance_oneAfter.toNumber(),'account three After buy');
    assert.equal(balance_after.toNumber(), tokens * (10 ** 18), 'Token ammount');
    let privateSaleInvestor3 = await this.tokenhold.privateSaleInvestor.call(accounts[4]);
    assert.equal(privateSaleInvestor3, false, 'private Sale Investor');
    let currentBonus2 = await this.crowdhold.bonusInCurrentSale();
    assert.equal(currentBonus2.toNumber(),20, 'private Sale Bonus');

  });

  it("Should Authorize KYC for account 5", async () => {

    var whiteListAddress = await this.crowdhold.whitelistedContributors.call(accounts[5], { gas: 500000000 });
    assert.equal(whiteListAddress, false, 'not white listed');
    var authorizeKYC = await this.crowdhold.authorizeKyc([accounts[5]], { from: accounts[0] });
    var whiteListAddressNow = await this.crowdhold.whitelistedContributors.call(accounts[5]);
    assert.equal(whiteListAddressNow, true, ' now white listed');

  });

  it("Should be able end pre sale and buy Tokens according to public Sale ", async () => {

    await this.crowdhold.endPreIco();
    let stage = await this.crowdhold.getStage();
    //console.log(stage);
    assert.equal(stage, "Pre ICO End", "Stage is wrong");
    await this.crowdhold.startIco();
    let newStage = await this.crowdhold.getStage();
    assert.equal(newStage, "Public Ico", "Stage is wrong");

    var balance_Before = await this.tokenhold.balanceOf.call(accounts[5]);
    var buy_PrivateSaleTokens = await this.crowdhold.buyTokens(accounts[5], { from: accounts[5], value: web3.utils.toWei("1", "ether") });

    var tokens = 262500;
    var balance_after = await this.tokenhold.balanceOf.call(accounts[5]);
    let fundWalletAfter = await web3.eth.getBalance(accounts[5]);
    let AccountBalance_oneAfter = await web3.eth.getBalance(accounts[5]);
    //console.log(fundWalletAfter.toNumber(),'fund wallet After buy');
    //console.log(AccountBalance_oneAfter.toNumber(),'account three After buy');
    assert.equal(balance_after.toNumber(), tokens * (10 ** 18), 'Token ammount');
    let privateSaleInvestor4 = await this.tokenhold.privateSaleInvestor.call(accounts[5]);
    assert.equal(privateSaleInvestor4, false, 'private Sale Investor');
    let currentBonus3 = await this.crowdhold.bonusInCurrentSale();
    assert.equal(currentBonus3.toNumber(),20, 'private Sale Bonus');


  });

  it("Should Send Private Tokens Directly", async () => {


    await this.crowdhold.sendPrivateSaleTokens(accounts[6], 2000, { from: accounts[0] });

  });

  it("Should Send Private Tokens Directly", async () => {


    await this.crowdhold.sendPublicSaleTokens(accounts[9], 2000, { from: accounts[0] });

  });

  it("Should be able to end public sale and finalize sale", async () => {

    await this.crowdhold.endIco();
    let stage = await this.crowdhold.getStage();
    //console.log(stage);
    assert.equal(stage, "Public Ico End", "Stage is wrong");
    var contract_before = await this.tokenhold.balanceOf.call(this.crowdhold.address);
    //console.log(contract_before.toNumber());
    await this.crowdhold.burnTokens();
    var contract_after = await this.tokenhold.balanceOf.call(this.crowdhold.address);
    //console.log(contract_after.toNumber());
    assert.equal(contract_after.toNumber(), 0, "not able to correctly burn tokens");

  });

  

  it("Should vest Token of Team ", async () => {


    var vestTokens1 = await this.vesthold.vestTokens(accounts[8], 10, 1);
  });

  it("Should vest Token of Advisor ", async () => {


    var vestTokens1 = await this.vesthold.vestTokens(accounts[9], 10, 2);
  });

  it("Should be able to finalize Sale after sale is Over", async () => {

    let stage = await this.crowdhold.getStage();
    //console.log(stage);
    assert.equal(stage, "Public Ico End", "Stage is wrong");
    let fundRaisingbefore = await this.tokenhold.fundraising.call();
    assert.equal(fundRaisingbefore, true, "FundRaising is true");
    await this.crowdhold.finalizeSale();
    let fundRaising = await this.tokenhold.fundraising.call();
    assert.equal(fundRaising, false, "FundRaising is false");

  });

  it("Should send Bounty Tokens  ", async () => {
    let initialBounty = await this.tokenhold.bountyTokens.call();
    //console.log(initialBounty.toNumber());
    var sendbountyTokens = await this.tokenhold.sendBounty(accounts[7], 5, { gas: 5000000 });
    var BountySendValue = 5;
    var balanceOfbounty = await this.tokenhold.balanceOf.call(accounts[7]);
    let bountyLeft = await this.tokenhold.bountyTokens.call();
    assert.equal(balanceOfbounty.toNumber() / 10 ** 18, BountySendValue, 'Wrong bounty sent');

  });

  it("Should be able to transfer Tokens got in pre Sale after Sale is Over ", async () => {

    let balanceSenderBefore = await this.tokenhold.balanceOf.call(accounts[4]);
    //console.log(balanceSenderBefore.toNumber());
    let balanceRecieverBefore = await this.tokenhold.balanceOf.call(accounts[8]);
    //console.log(balanceRecieverBefore.toNumber());
    //assert.equal(balanceRecieverBefore, 0, 'balance of beneficery(reciever)');
    await this.tokenhold.transfer(accounts[8], 1000000000000000000, { from: accounts[4], gas: 5000000 });
    let balanceSenderAfter = await this.tokenhold.balanceOf.call(accounts[4]);
    //console.log(balanceSenderAfter.toNumber());
    let balanceRecieverAfter = await this.tokenhold.balanceOf.call(accounts[8]);
    //console.log(balanceRecieverAfter.toNumber());
    assert.equal(balanceRecieverAfter, 1000000000000000000, 'balance of beneficery(reciever) after');

  });

  it("Should be able to transfer Tokens got public Sale after Sale is Over ", async () => {

    let balanceSenderBefore = await this.tokenhold.balanceOf.call(accounts[5]);
    //console.log(balanceSenderBefore.toNumber());
    let balanceRecieverBefore = await this.tokenhold.balanceOf.call(accounts[8]);
    //console.log(balanceRecieverBefore.toNumber());
    //assert.equal(balanceRecieverBefore, 0, 'balance of beneficery(reciever)');
    await this.tokenhold.transfer(accounts[8], 1000000000000000000, { from: accounts[5], gas: 5000000 });
    let balanceSenderAfter = await this.tokenhold.balanceOf.call(accounts[5]);
    //console.log(balanceSenderAfter.toNumber());
    let balanceRecieverAfter = await this.tokenhold.balanceOf.call(accounts[8]);
    //console.log(balanceRecieverAfter.toNumber());
    assert.equal(balanceRecieverAfter, 2000000000000000000, 'balance of beneficery(reciever) after');

  });

  it("Should be able to transfer ownership of Crowdsale Contract ", async () => {

    let ownerOld1 = await this.crowdhold.owner.call();
    let newowner1 = await this.crowdhold.transferOwnership(accounts[4], { from: accounts[0] });
    let acceptOwner = await this.crowdhold.acceptOwnership({ from: accounts[4] });
    let ownerNew1 = await this.crowdhold.owner.call();
    assert.equal(ownerNew1, accounts[4], 'Transfered ownership');

  });

  it("should Approve address to spend specific token ", async () => {

    this.tokenhold.approve(accounts[9], 1000000000000000000, { from: accounts[4] });
    let allowance = await this.tokenhold.allowance.call(accounts[4], accounts[9]);
    assert.equal(allowance, 1000000000000000000, "allowance is wrong when approve");

  });

  it("should increase Approval ", async () => {

    let allowance1 = await this.tokenhold.allowance.call(accounts[4], accounts[9]);
    assert.equal(allowance1, 1000000000000000000, "allowance is wrong when increase approval");
    this.tokenhold.changeApproval(accounts[9], 1000000000000000000, 2000000000000000000, { from: accounts[4] });
    let allowanceNew = await this.tokenhold.allowance.call(accounts[4], accounts[9]);
    assert.equal(allowanceNew, 2000000000000000000, "allowance is wrong when increase approval done");

  });

  it("should not increase Approval for Negative Tokens", async () => {

    try {

      this.tokenhold.changeApproval(accounts[9], 2000000000000000000, -1000000000000000000, { from: accounts[4] });

    }
    catch (error) {
      var error_ = 'VM Exception while processing transaction: invalid opcode';
      assert.equal(error.message, error_, 'Token ammount');

    }
  });

  it("should Not Approve address to spend Negative token ", async () => {

    try {
      this.tokenhold.approve(accounts[9], -1000000000000000000, { from: accounts[4] });
    } catch (error) {
      var error_ = 'VM Exception while processing transaction: revert';
      assert.equal(error.message, error_, 'Token ammount');
    }

  });

})

