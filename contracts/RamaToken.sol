pragma solidity ^0.4.24;

import "./Pausable.sol";
import "./Owned.sol";
import "./ERC20.sol";
import "./SafeMath.sol";
import "./StandardToken.sol";

 /**
 * @title RamaToken
 */
contract RamaToken is StandardToken, Owned, Pausable {
    using SafeMath for uint;
    string public symbol;
    string public name;
    uint8 public decimals;
    uint public totalReleased;
    uint public tokensForSale = 750000000 * 1 ether;   
    uint public vestingTokens = 225000000 * 1 ether;
    uint public bountyTokens = 75000000 * 1 ether;
    uint public reservedTokens = 450000000 * 1 ether; 
    uint public icoStartTime;
    uint256 public icoFinalizedTime;
    address[] public allPrivateInvestor;
    address public saleContract;
    address public vestingContract;
    bool public fundraising = true;

 
    mapping (address => bool) public frozenAccounts;
    mapping (address => bool) public fundReleasedFromForthStage;
    mapping (address => bool) public privateSaleInvestor;
    mapping (address => uint256) public privateSaleInvestorFundInitially;
    mapping (address => uint256) public privateSaleInvestorFundNow;
    mapping (address => uint256) public privateSaleInvestorFundReleasedOne;
    mapping (address => uint256) public privateSaleInvestorFundReleasedTwo;
    mapping (address => uint256) public privateSaleInvestorFundReleasedThree;
    mapping (address => uint256) public privateSaleInvestorFundReleasedFour;
    
    uint256 public privateTokenLockedPhaseOne;
    uint256 public privateTokenLockedPhaseTwo;
    uint256 public privateTokenLockedPhaseThree;
    uint256 public privateTokenLockedPhaseFour;
    
    event FrozenFund(address target, bool frozen);
    event PriceLog(string text);

    modifier onlyPayloadSize(uint numWords) {
        assert(msg.data.length >= numWords * 32 + 4);
        _;
    }

    modifier manageTransfer() {
        if (msg.sender == owner) {
            _;
        } else {
            require(fundraising == false);
            _;
        }
    }
    
    modifier managePrivateTransfer() {
        
        require(privateSaleInvestor[msg.sender]==true); 
        require(fundraising == false);
        require(icoFinalizedTime + 2 minutes <= now); //7776000
            _;
        
    }

    /**
    * @dev constructor of a token contract
    * @param _tokenOwner address of the owner of contract.
    */
    constructor (address _tokenOwner ) public Owned(_tokenOwner) {
        symbol ="RUC";
        name = "RUC";
        decimals = 18;
        totalSupply = 1500000000 * 1 ether;
    }


    /**
    * @dev  Investor can Transfer token from this method
    * @param _to address of the reciever
    * @param _value amount of tokens to transfer
    */
    function transfer(address _to, uint256 _value) public manageTransfer whenNotPaused onlyPayloadSize(2) returns (bool success) {
        require(_value>0);
        require(_to != address(0));
        require(!frozenAccounts[msg.sender]);
        if(privateSaleInvestor[msg.sender]==true){
            
             require(now >= privateTokenLockedPhaseOne);
             if(now < privateTokenLockedPhaseFour){
                calculateTransferableAmount(_value,msg.sender);
                super.transfer(_to,_value);
                return true;
             }
             else if(now >= privateTokenLockedPhaseFour && privateSaleInvestorFundNow[msg.sender]!=0){
                calculateTransferableAmount(_value,msg.sender);
                super.transfer(_to,_value);
                return true;
             }
             else if(now >= privateTokenLockedPhaseFour && privateSaleInvestorFundNow[msg.sender]==0){
                super.transfer(_to,_value);
                return true;
             }

            
        }   
           
        else{
            require(privateSaleInvestor[msg.sender]==false);    
            super.transfer(_to,_value);
            return true;
        }
          
    }
    
    /**
    * @dev  Transfer from allow to trasfer token 
    * @param _from address of sender 
    * @param _to address of the reciever
    * @param _value amount of tokens to transfer
    */
    function transferFrom(address _from, address _to, uint256 _value) public manageTransfer whenNotPaused onlyPayloadSize(3) returns (bool) {
        require(_value>0);
        require(_to != address(0));
        require(_from != address(0));
        require(!frozenAccounts[_from]);
        
          if(privateSaleInvestor[_from]==true){
            
              require(now >= privateTokenLockedPhaseOne);
              if(now < privateTokenLockedPhaseFour){
                calculateTransferableAmount(_value,_from); 
                super.transferFrom(_from,_to,_value);
                return true;
              }
              else if (now >= privateTokenLockedPhaseFour && privateSaleInvestorFundNow[_from]!=0){
                calculateTransferableAmount(_value,_from); 
                super.transferFrom(_from,_to,_value);
                return true;
              }
              else if(now >= privateTokenLockedPhaseFour && privateSaleInvestorFundNow[_from]==0){
                super.transferFrom(_from,_to,_value);
                return true;  
              }
          }
          else{
            require(privateSaleInvestor[_from]==false);  
            super.transferFrom(_from,_to,_value);
            return true;  
          }
    }

    /**
    * activates the sale contract (i.e. transfers saleable contracts)
    * @param _saleContract ,address of crowdsale contract
    */
    function activateSaleContract(address _saleContract) public whenNotPaused onlyOwner {
        require(_saleContract != address(0));
        require(saleContract == address(0));
        saleContract = _saleContract;
        balances[saleContract] = balances[saleContract].add(tokensForSale);
        totalReleased = totalReleased.add(tokensForSale);
        tokensForSale = 0;  
        icoStartTime = now;
        assert(totalReleased <= totalSupply);
        emit Transfer(address(this), saleContract, 750000000 * 1 ether);
    }
     
    /**
    * activates the sale contract (i.e. transfers saleable contracts)
    * @param _vestingContract ,address of crowdsale contract
    */
    function activateVestingContract(address _vestingContract) public whenNotPaused onlyOwner {
        
        require(_vestingContract != address(0));
        require(vestingContract == address(0));
        vestingContract = _vestingContract;
        uint256 vestableTokens = vestingTokens;
        balances[vestingContract] = balances[vestingContract].add(vestableTokens);
        totalReleased = totalReleased.add(vestableTokens);
        assert(totalReleased <= totalSupply);
    }

    /**
    * @dev function to check whether passed address is a contract address
    */
    function isContract(address _address) private view returns (bool is_contract) {
        uint256 length;
        assembly {
        //retrieve the size of the code on target address, this needs assembly
            length := extcodesize(_address)
        }
        return (length > 0);
    }
    
    function burn(uint256 _value) public whenNotPaused returns (bool success) {
        require(balances[msg.sender] >= _value);
        balances[msg.sender] = balances[msg.sender].sub(_value);
        totalSupply = totalSupply.sub(_value);
        totalReleased = totalReleased.sub(_value);
        emit Burn(msg.sender, _value);
        return true;
    }
  
    /**
   * @dev this function can only be called by crowdsale contract to transfer tokens to investor
   * @param _to address The address of the investor.
   * @param _value uint256 The amount of tokens to be send
   */
    function saleTransfer(address _to, uint256 _value,bool _investorStatus) public whenNotPaused returns (bool) {
        require(saleContract != address(0));
        require(msg.sender == saleContract);
        require(!frozenAccounts[_to]);
        allPrivateInvestor.push(_to);
        privateSaleInvestor[_to] = _investorStatus;
        privateSaleInvestorFundInitially[_to] = privateSaleInvestorFundInitially[_to].add(_value);
        privateSaleInvestorFundNow[_to] = privateSaleInvestorFundNow[_to].add(_value); 
        return super.transfer(_to, _value);
    }


   /**
   * @dev this function can only be called by  contract to transfer tokens to vesting beneficiary
   * @param _to address The address of the beneficiary.
   * @param _value uint256 The amount of tokens to be send
   */
    function vestingTransfer(address _to, uint256 _value) public whenNotPaused returns (bool) {
        require(vestingContract != address(0));
        require(msg.sender == vestingContract);
        return super.transfer(_to, _value);
    }

    /**
    * @dev this function will burn the unsold tokens after crowdsale is over and this can be called
    *  from crowdsale contract only when crowdsale is over
    */
    function burnTokensForSale() public whenNotPaused returns (bool) {
        require(saleContract != address(0));
        require(msg.sender == saleContract);
        uint256 tokens = balances[saleContract];
        require(tokens > 0);
        require(tokens <= totalSupply);
        balances[saleContract] = 0;
        totalSupply = totalSupply.sub(tokens);
        totalReleased = totalReleased.sub(tokens);
        emit Burn(saleContract, tokens);
        return true;
    }

    /**
    * @dev this function will closes the sale ,after this anyone can transfer their tokens to others.
    */
    function finalize() public whenNotPaused {
        require(fundraising != false);
        require(msg.sender == saleContract);
        // Switch to Operational state. This is the only place this can happen.
        fundraising = false;
        icoFinalizedTime = now;
        privateTokenLockedPhaseOne = icoFinalizedTime.add(2 minutes);// 3 months
        privateTokenLockedPhaseTwo = privateTokenLockedPhaseOne.add(5 minutes);// 6 months
        privateTokenLockedPhaseThree = privateTokenLockedPhaseTwo.add(5 minutes);// 9 months
        privateTokenLockedPhaseFour = privateTokenLockedPhaseThree.add(5 minutes);//12 months
    }

   /**
   * @dev this function will freeze the any account so that the frozen account will not able to participate in crowdsale.
   * @param target ,address of the target account 
   * @param freeze ,boolean value to freeze or unfreeze the account ,true to freeze and false to unfreeze
   */
   function freezeAccount (address target, bool freeze) public onlyOwner {
        require(target != 0x0);
        frozenAccounts[target] = freeze;
        emit FrozenFund(target, freeze); // solhint-disable-line
    }

    /**
    * @dev this function will send the bounty tokens to given address
    * @param _to ,address of the bounty receiver.
    * @param _value , number of tokens to be sent.
    */
    function sendBounty(address _to, uint256 _value) public whenNotPaused onlyOwner returns (bool) {
        uint256 value = _value.mul(1 ether);
        require(bountyTokens >= value);
        totalReleased = totalReleased.add(value);
        require(totalReleased <= totalSupply);
        balances[_to] = balances[_to].add(value);
        bountyTokens = bountyTokens.sub(value);
        emit Transfer(address(this), _to, value);
        return true;
   }
   
    function sendReserveTokens(address _to, uint256 _value) public whenNotPaused onlyOwner returns (bool) {
        uint256 value = _value.mul(1 ether);
        require(reservedTokens >= value);
        totalReleased = totalReleased.add(value);
        require(totalReleased <= totalSupply);
        balances[_to] = balances[_to].add(value);
        reservedTokens = reservedTokens.sub(value);
        emit Transfer(address(this), _to, value);
        return true;
   }



    /**
    * @dev Function to transfer any ERC20 token  to owner address which gets accidentally transferred to this contract
    * @param tokenAddress The address of the ERC20 contract
    * @param tokens The amount of tokens to transfer.
    * @return A boolean that indicates if the operation was successful.
    */
    function transferAnyERC20Token(address tokenAddress, uint tokens) public whenNotPaused onlyOwner returns (bool success) {
        require(tokenAddress != address(0));
        require(isContract(tokenAddress));
        return ERC20(tokenAddress).transfer(owner, tokens);
    }
    
    function calculateTransferableAmount(uint256 _value,address _sender) internal {

        require(balances[_sender]>=_value);
        require(privateSaleInvestorFundNow[_sender]>=_value);
        require(now > privateTokenLockedPhaseOne);
        //7776000,23328000,31104000,41472000
        if(now >= privateTokenLockedPhaseOne && now < privateTokenLockedPhaseTwo){ // greater than 3 months and less than 6 months
            uint256 amountOne;
            amountOne = privateSaleInvestorFundInitially[_sender].div(4);
            require(_value<=amountOne);
            require(privateSaleInvestorFundReleasedOne[_sender].add(_value)<=amountOne);
            privateSaleInvestorFundNow[_sender] = privateSaleInvestorFundNow[_sender].sub(_value);
            privateSaleInvestorFundReleasedOne[_sender] = privateSaleInvestorFundReleasedOne[_sender].add(_value);
            require(privateSaleInvestorFundReleasedOne[_sender] <= privateSaleInvestorFundInitially[_sender]);
        }
    
        else if(now >= privateTokenLockedPhaseTwo && now < privateTokenLockedPhaseThree){// greater than 6 months and less than 12 months
            uint256 amountTwo;
            amountTwo = privateSaleInvestorFundInitially[_sender].div(2);
            require(_value<=amountTwo);
            require(privateSaleInvestorFundReleasedOne[_sender].add(_value).add(privateSaleInvestorFundReleasedTwo[_sender])<=amountTwo);
            privateSaleInvestorFundNow[_sender] = privateSaleInvestorFundNow[_sender].sub(_value);
            privateSaleInvestorFundReleasedTwo[_sender] = privateSaleInvestorFundReleasedTwo[_sender].add(_value);
            require(privateSaleInvestorFundReleasedTwo[_sender] <= amountTwo);
            require(privateSaleInvestorFundReleasedOne[_sender].add(privateSaleInvestorFundReleasedTwo[_sender]) <= privateSaleInvestorFundInitially[_sender]);
        }
        else if(now >= privateTokenLockedPhaseThree && now < privateTokenLockedPhaseFour){// greater than 12 months and less than 16 months
            uint256 amountThree;
            amountThree = privateSaleInvestorFundInitially[_sender].div(4).mul(3);
            require(_value<=amountThree);
            require(privateSaleInvestorFundReleasedOne[_sender].add(_value).add(privateSaleInvestorFundReleasedTwo[_sender]).add(privateSaleInvestorFundReleasedThree[_sender])<=amountThree);
            privateSaleInvestorFundNow[_sender] = privateSaleInvestorFundNow[_sender].sub(_value);
            privateSaleInvestorFundReleasedThree[_sender] = privateSaleInvestorFundReleasedThree[_sender].add(_value);
            require(privateSaleInvestorFundReleasedThree[_sender] <= amountThree);
            require(privateSaleInvestorFundReleasedOne[_sender].add(privateSaleInvestorFundReleasedTwo[_sender]).add(privateSaleInvestorFundReleasedThree[_sender]) <= privateSaleInvestorFundInitially[_sender]);
        }
        else if(now >= privateTokenLockedPhaseFour){ // greater than 16 months
            uint256 amountFour;
            amountFour = privateSaleInvestorFundInitially[_sender];
            require(_value<=amountFour);
            require(privateSaleInvestorFundReleasedOne[_sender].add(_value).add(privateSaleInvestorFundReleasedTwo[_sender]).add(privateSaleInvestorFundReleasedThree[_sender]).add(privateSaleInvestorFundReleasedFour[_sender])<=amountFour);
            privateSaleInvestorFundNow[_sender] = privateSaleInvestorFundNow[_sender].sub(_value);
            privateSaleInvestorFundReleasedFour[_sender] = privateSaleInvestorFundReleasedFour[_sender].add(_value);
            require(privateSaleInvestorFundReleasedFour[_sender] <= amountFour);
            require(privateSaleInvestorFundReleasedOne[_sender].add(privateSaleInvestorFundReleasedTwo[_sender]).add(privateSaleInvestorFundReleasedThree[_sender]).add(privateSaleInvestorFundReleasedFour[_sender]) <= privateSaleInvestorFundInitially[_sender]);
            fundReleasedFromForthStage[_sender]=true;
        }
        else{
            revert();
        }

    }
    
    function privateInvestorLockStage() public view returns (string){
        if(now < privateTokenLockedPhaseOne){
            return ' 25 % Token locked till 3 months';
        }
        else if(now >= privateTokenLockedPhaseOne && now < privateTokenLockedPhaseTwo){
            return ' 25 % Token are transferable';
        }
        else if(now >= privateTokenLockedPhaseTwo && now < privateTokenLockedPhaseThree){
            return ' 50 % Token are transferable';
        }
        else if(now >= privateTokenLockedPhaseThree && now < privateTokenLockedPhaseFour){
            return ' 75 % Token are transferable';
        }
        else if (now >= privateTokenLockedPhaseFour && icoFinalizedTime !=0){
            return ' 100 % Token are transferable';
        }
        else if (icoFinalizedTime == 0){
            return 'Token Locked phase not started Yet';
        }

        
    }
    
    function unlockPrivateInvestorFund() public onlyOwner returns(bool){
        require(now>privateTokenLockedPhaseFour);
        
        for(uint256 i = 0; i<allPrivateInvestor.length; i++)
        {
            privateSaleInvestorFundNow[allPrivateInvestor[i]]=0;
        }
        return true;
    }

    function () public payable {
        revert();
    }
    
}