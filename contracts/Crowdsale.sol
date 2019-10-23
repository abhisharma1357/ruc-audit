pragma solidity  ^0.4.24;
import "./SafeMath.sol";
import "./Owned.sol";
import "./Oraclize.sol";

contract RamaToken {

    function transfer (address, uint) public;
    function burnTokensForSale() public returns (bool);
    function saleTransfer(address, uint256,bool) public  returns (bool);
    function finalize() public;
}

contract TokenVesting{

    function setIcoFinalizedTime() public;

}


contract Crowdsale is Owned, usingOraclize { 
  
  using SafeMath for uint256;
  uint256 public ethPrice; // 1 Ether price in USD cents.
  uint256 constant CUSTOM_GASLIMIT = 150000;
  uint256 public updateTime = 0;
  // end oraclize variables

  //Oraclize events
  event LogConstructorInitiated(string nextStep);
  event newOraclizeQuery(string description);
  event newPriceTicker(bytes32 myid, string price, bytes proof);
  // End oraclize events

  // The token being sold
  RamaToken public token;
  uint256 public hardCap = 10000000000;
  uint256 public softCap = 500000000; 
  uint public tokensForSale = 750000000 * 1 ether;
  // Address where funds are collected
  address public wallet;
  address public vestingAddress;
  
  uint256 public privateRoundOneMinimumInvestment;
  uint256 public privateRoundTwoMinimumInvestment;
  uint256 public preSaleMinimumInvestment;
  
  uint256 public bonusInPrivateSaleRoundOne;
  uint256 public bonusInPrivateSaleRoundTwo;
  uint256 public bonusInPreSale;
  uint256 public bonusInPublicSale;

  
  bool public crowdSaleStarted = false;

  uint256 public privateSaleRoundOneRaised = 0;
  uint256 public privateSaleRoundTwoRaised = 0;
  uint256 public presaleRaised = 0;  
  uint256 public publicsaleRaised = 0;

  // Amount of wei raised
  uint256 public totalRaisedInCents;
  

  uint256 public privateSaleRoundOneTokensPerDollar;
  uint256 public privateSaleRoundTwoTokensPerDollar;
  uint256 public presaleTokensPerDollar;
  uint256 public publicsaleTokensPerDollar;
  
  enum Stages {CrowdSaleNotStarted, Pause, PrivateSaleRoundOneStart, PrivateSaleRoundOneEnd, PrivateSaleRoundTwoStart, PrivateSaleRoundTwoEnd, PreSaleStart, PreSaleEnd, PublicSaleStart, PublicSaleEnd}
  Stages currentStage;
  Stages previousStage;
  bool public Paused;

   // adreess vs state mapping (1 for exists , zero default);
   mapping (address => bool) public whitelistedContributors;
   mapping (address => bool) public PrivateSaleInvestor;
  
   modifier CrowdsaleStarted(){
      require(crowdSaleStarted);
      _;
   }
 
    /**
    * Event for token purchase logging
    * @param purchaser who paid for the tokens
    * @param beneficiary who got the tokens
    * @param value weis paid for purchase
    * @param amount amount of tokens purchased
    */
    event TokenPurchase(address indexed purchaser, address indexed beneficiary, uint256 value, uint256 amount);

    /**
    *@dev initializes the crowdsale contract 
    * @param _newOwner Address who has special power to change the ether price in cents according to the market price
    * @param _wallet Address where collected funds will be forwarded to
    * @param _token Address of the token being sold
    *  @param _ethPriceInCents ether price in cents
    */
    constructor(address _newOwner, address _wallet, RamaToken _token,uint256 _ethPriceInCents) Owned(_newOwner) public {
        require(_wallet != address(0));
        require(_token != address(0));
        require(_ethPriceInCents > 0);
        wallet = _wallet;
        owner = _newOwner;
        token = _token;
        ethPrice = _ethPriceInCents; //ethPrice in cents
        currentStage = Stages.CrowdSaleNotStarted;
        // oraclize_setProof(proofType_TLSNotary | proofStorage_IPFS);
        // LogConstructorInitiated("Constructor was initiated. Call 'update()' to send the Oraclize Query.");
    }
    

    function () external payable {
    
     if(msg.sender != owner){
        buyTokens(msg.sender); 
     }
     else{
     revert();
     }
     
    }
    /**
    * @dev whitelist addresses of investors.
    * @param addrs ,array of addresses of investors to be whitelisted
    * Note:= Array length must be less than 200.
    */
    function authorizeKyc(address[] addrs) external onlyOwner returns (bool success) {
        uint arrayLength = addrs.length;
        for (uint x = 0; x < arrayLength; x++) {
            whitelistedContributors[addrs[x]] = true;
        }

        return true;
    }
    
    // Begin : oraclize related functions 
    function __callback(bytes32 myid, string result, bytes proof) public {
        if (msg.sender != oraclize_cbAddress()) revert();
        ethPrice = parseInt(result, 2);
        emit newPriceTicker(myid, result, proof); //event
        if (updateTime > 0) updateAfter(updateTime);
    }

    function update() public onlyOwner {
        if (updateTime > 0) updateTime = 0;
        if (oraclize_getPrice("URL", CUSTOM_GASLIMIT) > address(this).balance) {
            emit newOraclizeQuery("Oraclize query was NOT sent, please add some ETH to cover for the query fee"); //event
        } else {
            emit newOraclizeQuery("Oraclize query was sent, standing by for the answer.."); //event
            oraclize_query("URL", "json(https://api.kraken.com/0/public/Ticker?pair=ETHUSD).result.XETHZUSD.c.0", CUSTOM_GASLIMIT);
        }
    }

    function updatePeriodically(uint256 _updateTime) public onlyOwner {
        updateTime = _updateTime;
        if (oraclize_getPrice("URL", CUSTOM_GASLIMIT) > address(this).balance) {
            emit newOraclizeQuery("Oraclize query was NOT sent, please add some ETH to cover for the query fee");
        } else {
            emit newOraclizeQuery("Oraclize query was sent, standing by for the answer..");
            oraclize_query("URL", "json(https://api.kraken.com/0/public/Ticker?pair=ETHUSD).result.XETHZUSD.c.0", CUSTOM_GASLIMIT);
        }
    }

    function updateAfter(uint256 _updateTime) internal {
        if (oraclize_getPrice("URL", CUSTOM_GASLIMIT) > address(this).balance) {
            emit newOraclizeQuery("Oraclize query was NOT sent, please add some ETH to cover for the query fee");
        } else {
            emit newOraclizeQuery("Oraclize query was sent, standing by for the answer..");
            oraclize_query(_updateTime, "URL", "json(https://api.kraken.com/0/public/Ticker?pair=ETHUSD).result.XETHZUSD.c.0", CUSTOM_GASLIMIT);
        }
    }

    // END : oraclize related functions 

    /**
    * @dev calling this function will pause the sale
    */
    
    function pause() public onlyOwner {
      require(Paused==false);
      require(crowdSaleStarted == true);
      previousStage=currentStage;
      currentStage=Stages.Pause;
      Paused = true;
    }
  
    function restartSale() public onlyOwner {
      require(currentStage==Stages.Pause);
      currentStage=previousStage;
      Paused = false;
    }

    function startPrivateSaleRoundOne() public onlyOwner {
      require(!crowdSaleStarted);
      crowdSaleStarted = true;
      currentStage = Stages.PrivateSaleRoundOneStart;
    }

    function endPrivateSaleRoundOne() public onlyOwner {

      require(currentStage == Stages.PrivateSaleRoundOneStart);
      currentStage = Stages.PrivateSaleRoundOneEnd;

    }

    function startPrivateSaleRoundTwo() public onlyOwner {

    require(currentStage == Stages.PrivateSaleRoundOneEnd);
    currentStage = Stages.PrivateSaleRoundTwoStart;
   
    }

    function endPrivateSaleRoundTwo() public onlyOwner {

    require(currentStage == Stages.PrivateSaleRoundTwoStart);
    currentStage = Stages.PrivateSaleRoundTwoEnd;
   
    }

    function startPreIco() public onlyOwner {
    require(currentStage == Stages.PrivateSaleRoundTwoEnd);
    currentStage = Stages.PreSaleStart;
   
    }

    function endPreIco() public onlyOwner {
    require(currentStage == Stages.PreSaleStart);
    currentStage = Stages.PreSaleEnd;
    }

    function startIco() public onlyOwner {
    require(currentStage == Stages.PreSaleEnd);
    currentStage = Stages.PublicSaleStart;
    }

    function endIco() public onlyOwner {
    require(currentStage == Stages.PublicSaleStart);
    currentStage = Stages.PublicSaleEnd;
    
    }

    function getStage() public view returns (string) {
    if (currentStage == Stages.PrivateSaleRoundOneStart) return 'Private sale Round one';
    else if (currentStage == Stages.PrivateSaleRoundOneEnd) return 'Private sale Round one end';
    else if (currentStage == Stages.PrivateSaleRoundTwoStart) return 'Private sale Round Two';
    else if (currentStage == Stages.PrivateSaleRoundTwoEnd) return 'Private sale Round Two End';
    else if (currentStage == Stages.PreSaleStart) return 'Pre ICO';
    else if (currentStage == Stages.PreSaleEnd) return 'Pre ICO End';
    else if (currentStage == Stages.PublicSaleStart) return 'Public Ico';
    else if (currentStage == Stages.PublicSaleEnd) return 'Public Ico End';
    else if (currentStage == Stages.CrowdSaleNotStarted) return 'crowdSale Not Started yet';
    else if (currentStage == Stages.Pause) return 'paused';
    }
    
    function setMinInvestmentAmmount(uint256 _privateRoundOne,uint256 _privateRoundTwo,uint256 _presale) public onlyOwner {
        privateRoundOneMinimumInvestment = _privateRoundOne;
        privateRoundTwoMinimumInvestment = _privateRoundTwo;
        preSaleMinimumInvestment = _presale;
    }
    
   /**
   * @param _beneficiary Address performing the token purchase
   */
   function buyTokens(address _beneficiary) CrowdsaleStarted public payable {
    require(whitelistedContributors[_beneficiary] == true );
    require(!PrivateSaleInvestor[_beneficiary]);
    require(Paused != true);
    uint256 weiAmount = msg.value;
    require(weiAmount > 0);
    require(ethPrice > 0);
    uint256 usdCents = weiAmount.mul(ethPrice).div(1 ether); 
    _preValidatePurchase(usdCents);
    // calculate token amount to be created
    uint256 tokens = _getTokenAmount(usdCents);
    
    _validateCapLimits(usdCents);
    _processPurchase(_beneficiary,tokens);
    wallet.transfer(msg.value);
    emit TokenPurchase(msg.sender, _beneficiary, weiAmount, tokens);
   }
  
   /**
   * @dev sets the value of ether price in cents.Can be called only by the owner account.
   * @param _ethPriceInCents price in cents .
   */
   function setEthPriceInCents(uint _ethPriceInCents) onlyOwner public returns(bool) {
        ethPrice = _ethPriceInCents;
        return true;
    }
   /**
   * @dev Validation of an incoming purchase. Use require statemens to revert state when conditions are not met. Use super to concatenate validations.
   * @param _usdCents Value in usdincents involved in the purchase
   */
   function _preValidatePurchase(uint256 _usdCents) internal view 
   {

     if (currentStage == Stages.PrivateSaleRoundOneStart) {
         
        require(_usdCents >= privateRoundOneMinimumInvestment);  
     }
     else if (currentStage == Stages.PrivateSaleRoundTwoStart) {
        require(_usdCents >= privateRoundTwoMinimumInvestment);
     }
     else if (currentStage == Stages.PreSaleStart){
        require(_usdCents >= preSaleMinimumInvestment);
     }
     else if (currentStage == Stages.PublicSaleStart) {
        require(_usdCents >= 0); 
     }
     else{
        revert();
     }
    }


    /**
    * @dev Validation of the capped restrictions.
    * @param _cents cents amount
    */
    function _validateCapLimits(uint256 _cents) internal {
     
    if (currentStage == Stages.PrivateSaleRoundOneStart) {
       privateSaleRoundOneRaised = privateSaleRoundOneRaised.add(_cents);
       totalRaisedInCents = totalRaisedInCents.add(_cents);
       require(totalRaisedInCents <= hardCap);
    } 
    else if(currentStage == Stages.PrivateSaleRoundTwoStart) {
      privateSaleRoundTwoRaised = privateSaleRoundTwoRaised.add(_cents);
      totalRaisedInCents = totalRaisedInCents.add(_cents);
      require(totalRaisedInCents <= hardCap);
    }
    else if(currentStage == Stages.PreSaleStart) {
      presaleRaised = presaleRaised.add(_cents);
      totalRaisedInCents = totalRaisedInCents.add(_cents);
      require(totalRaisedInCents <= hardCap);
    }
    else if(currentStage == Stages.PublicSaleStart) {
      publicsaleRaised = publicsaleRaised.add(_cents);
      totalRaisedInCents = totalRaisedInCents.add(_cents);
      require(totalRaisedInCents <= hardCap);
    }
    
    else{
    revert();
    }
  
   }
   
   function sendPrivateSaleTokens(address _beneficiary,uint256 _tokenAmount)  CrowdsaleStarted onlyOwner public{
     require(Paused != true);
     require(totalRaisedInCents <= hardCap);
     require(currentStage == Stages.PrivateSaleRoundOneStart || currentStage == Stages.PrivateSaleRoundTwoStart || currentStage == Stages.PreSaleStart || currentStage == Stages.PublicSaleStart);
     uint256 tokens = _tokenAmount * 1 ether;
     PrivateSaleInvestor[_beneficiary] = true;
     require(token.saleTransfer(_beneficiary, tokens, true)); 
   }

   function sendPublicSaleTokens(address _beneficiary,uint256 _tokenAmount)  CrowdsaleStarted onlyOwner public{
     require(Paused != true);
     require(totalRaisedInCents <= hardCap);
     require(currentStage == Stages.PreSaleStart || currentStage == Stages.PublicSaleStart);
     require(!PrivateSaleInvestor[_beneficiary]);
     uint256 tokens = _tokenAmount * 1 ether;
     require(token.saleTransfer(_beneficiary, tokens, false)); 
   }

   /**
   * @dev Source of tokens. Override this method to modify the way in which the crowdsale ultimately gets and sends its tokens.
   * @param _beneficiary Address performing the token purchase
   * @param _tokenAmount Number of tokens to be emitted
   */
   function _deliverTokens(address _beneficiary, uint256 _tokenAmount) internal {
    
    if(currentStage == Stages.PrivateSaleRoundOneStart || currentStage == Stages.PrivateSaleRoundTwoStart) {
        PrivateSaleInvestor[_beneficiary] = true;
        require(token.saleTransfer(_beneficiary, _tokenAmount, true)); 
    }
    else{
       PrivateSaleInvestor[_beneficiary] = false;
       require(token.saleTransfer(_beneficiary, _tokenAmount, false));    
    }
   }

   /**
   * @dev Executed when a purchase has been validated and is ready to be executed. Not necessarily emits/sends tokens.
   * @param _beneficiary Address receiving the tokens
   * @param _tokenAmount Number of tokens to be purchased
   */
   function _processPurchase(address _beneficiary, uint256 _tokenAmount) internal {
    _deliverTokens(_beneficiary, _tokenAmount);
   }
  

    /**
    * @param _usdCents Value in usd cents to be converted into tokens
    * @return Number of tokens that can be purchased with the specified _usdCents
    */
    function _getTokenAmount(uint256 _usdCents) CrowdsaleStarted public view returns (uint256) {
    uint256 tokens;
    
     
      if (currentStage == Stages.PrivateSaleRoundOneStart) {

         uint256 bonusPrivateSaleOne;
         uint256 privateOneToSent;
         bonusPrivateSaleOne = privateSaleRoundOneTokensPerDollar.div(100).mul(bonusInPrivateSaleRoundOne);
         privateOneToSent = bonusPrivateSaleOne.add(privateSaleRoundOneTokensPerDollar);
         tokens = _usdCents.div(100).mul(privateOneToSent);

      }

      if (currentStage == Stages.PrivateSaleRoundTwoStart) {

         uint256 bonusPrivateSaleTwo;
         uint256 privateTwoToSent;
         bonusPrivateSaleTwo = privateSaleRoundTwoTokensPerDollar.div(100).mul(bonusInPrivateSaleRoundTwo);
         privateTwoToSent = bonusPrivateSaleTwo.add(privateSaleRoundTwoTokensPerDollar);
         tokens = _usdCents.div(100).mul(privateTwoToSent);

      }

      if (currentStage == Stages.PreSaleStart) {
         uint256 bonusPreSale;
         uint256 pretokensToSent;
         bonusPreSale = presaleTokensPerDollar.div(100).mul(20);
         pretokensToSent = bonusPreSale.add(presaleTokensPerDollar);
         tokens = _usdCents.div(100).mul(pretokensToSent);
      }
      if (currentStage == Stages.PublicSaleStart) {
         uint256 bonusPublicSale;
         uint256 PublictokensToSent;
         bonusPublicSale = publicsaleTokensPerDollar.div(100).mul(5);
         PublictokensToSent = bonusPublicSale.add(publicsaleTokensPerDollar);
         tokens = _usdCents.div(100).mul(PublictokensToSent);
      }
    
      return tokens;
    }
    
    /**
       * @dev burn the unsold tokens.
       
       */
    function burnTokens() public onlyOwner {
        require(currentStage == Stages.PublicSaleEnd);
        require(token.burnTokensForSale());
    }
        
    /**
    * @dev finalize the crowdsale.After finalizing ,tokens transfer can be done.
    */
    function finalizeSale() public  onlyOwner {
        require(currentStage == Stages.PublicSaleEnd);
        require(vestingAddress != address(0));
        token.finalize();
        TokenVesting(vestingAddress).setIcoFinalizedTime();
    }

    
    function setPriceforAllPhases(uint256 _privateSaleRoundOne,uint256 _privateSaleRoundTwo, uint256 _preSale, uint256 _publicSale) public onlyOwner {
    
       privateSaleRoundOneTokensPerDollar = _privateSaleRoundOne * 1 ether;
       privateSaleRoundTwoTokensPerDollar = _privateSaleRoundTwo * 1 ether;
       presaleTokensPerDollar = _preSale * 1 ether;
       publicsaleTokensPerDollar = _publicSale * 1 ether;
    }

    function setBonusforAllPhases(uint256 _bonusInPrivateSaleRoundOne,uint256 _bonusInPrivateSaleRoundTwo, uint256 _bonusInPreSale, uint256 _bonusInPublicSale) public onlyOwner {
    
       bonusInPrivateSaleRoundOne = _bonusInPrivateSaleRoundOne ;
       bonusInPrivateSaleRoundTwo = _bonusInPrivateSaleRoundTwo;
       bonusInPreSale = _bonusInPreSale;
       bonusInPublicSale = _bonusInPublicSale;
    }

    
    function setVestingAddress(address _vestingAddress) public onlyOwner {
        require(_vestingAddress != address(0));
        require(vestingAddress == address(0));
        vestingAddress = _vestingAddress;
    }
    
    function isSoftCapReached() public view returns(bool){
        if(totalRaisedInCents >= softCap){
            return true;
        }
        else {
            return false;
        }
    }
    

    function bonusInCurrentSale() public view returns (uint256)
    {
     if (currentStage == Stages.PrivateSaleRoundOneStart) {
      return bonusInPrivateSaleRoundOne;  
     
     }
     else if (currentStage == Stages.PrivateSaleRoundTwoStart) {
      return bonusInPrivateSaleRoundTwo; 
     
     }
     else if (currentStage == Stages.PreSaleStart) {
      return bonusInPreSale; 
     
     }
    
     else if (currentStage == Stages.PublicSaleStart) {
      return bonusInPublicSale; 
     
     }
     else {
         return 0;
     }

    }
    
    
    function minimumInvestmentInCurrentSale() public view returns(uint256){
     if (currentStage == Stages.PrivateSaleRoundOneStart) {
      return privateRoundOneMinimumInvestment;  
     
     }
     else if (currentStage == Stages.PrivateSaleRoundTwoStart) {
      return privateRoundTwoMinimumInvestment; 
     
     }
     else if (currentStage == Stages.PreSaleStart) {
      return preSaleMinimumInvestment; 
     
     }
    
     else if (currentStage == Stages.PublicSaleStart) {
      return 0; 
     
     }

    } 

    function tokensPerDollarInCurrentSale() public view returns(uint256){

     if (currentStage == Stages.PrivateSaleRoundOneStart) {
      return privateSaleRoundOneTokensPerDollar;  
     
     }
     else if (currentStage == Stages.PrivateSaleRoundTwoStart) {
      return privateSaleRoundTwoTokensPerDollar; 
     
     }
     else if (currentStage == Stages.PreSaleStart) {
      return presaleTokensPerDollar; 
     
     }
    
     else if (currentStage == Stages.PublicSaleStart) {
      return publicsaleTokensPerDollar; 
     
     }

    } 



}