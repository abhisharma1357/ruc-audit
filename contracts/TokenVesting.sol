pragma solidity ^0.4.24;

import "./Owned.sol";
import "./SafeMath.sol";


contract RamaToken {
    function vestingTransfer(address, uint256) public pure returns (bool) {}
    
}


/**
 * @title TokenVesting
 * @dev A token holder contract that can release its token balance gradually like a
 * typical vesting scheme, with a cliff and vesting period. Optionally revocable by the
 * owner.
 */
contract TokenVesting is Owned {
    using SafeMath for uint256;
    event Released(uint256 amount);
  
    RamaToken public _token;
    address public CrowdsaleAddress;
    uint256 public teamTokensSent;
    uint256 public advisorsTokensSent;
    
    
    uint256 public tokensAvailableForVesting = 225000000 * 1 ether;
    
    
    
    mapping (address => bool) public vestedAfterIcoFinalize;// after ico finalised
    mapping (address => bool) public VestedAfterFirstphase;//after 3 months
    mapping (address => bool) public VestedAfterSecondphase; // after 6 months
    mapping (address => bool) public VestedAfterThirdphase;// after 12 months    
    
    uint256 public icoFinalizedTime;
    uint256 public tokenVestedFirstPhase;
    uint256 public tokenVestedSecondPhase;
    uint256 public tokenVestedThirdPhase;
    
    
    mapping (address => uint256) public released;
    
    struct beneficiary {
        address beneficiaryAddress;
        uint256 tokens;
        uint256 member;
        uint256 tokenVestedInitially;
        uint256 tokenreleasedFirstPhase;// ico completion
        uint256 tokenreleasedSecondPhase;// after 3 months
        uint256 tokenreleasedThirdPhase; // after 6 months
        uint256 tokenreleasedFourthPhase; // after 12 months
        uint256 tokenreleasedTotal;    
        
         
    }
    mapping(address => beneficiary) public beneficiaryDetails;
    
    constructor(RamaToken token,address _CrowdsaleAddress,address _owner) Owned(_owner) public {
      _token = token;
      CrowdsaleAddress = _CrowdsaleAddress;
    }
    
    /**
    * @dev Creates a vesting contract that vests its balance of any ERC20 token to the
    * _beneficiary, gradually in a linear fashion until _start  By then all
    * of the balance will have vested.
    * @param _beneficiary address of the beneficiary to whom vested tokens are transferred
    * @param _member ,uint value to identify vesting beneficiary ( 1 for core team,2 for advisor and 3 for marketing )
    */

    function vestTokens(address _beneficiary, uint256 _tokens, uint256 _member) public onlyOwner {    

      require(icoFinalizedTime ==0);
      require(_beneficiary != address(0));
      require(beneficiaryDetails[_beneficiary].beneficiaryAddress == (0x0));
      uint256 tokens = _tokens * 1 ether;
      
      beneficiaryDetails[_beneficiary].beneficiaryAddress  = _beneficiary;
      beneficiaryDetails[_beneficiary].tokens = _tokens * 1 ether;
      beneficiaryDetails[_beneficiary].member = _member;
      beneficiaryDetails[_beneficiary].tokenVestedInitially =_tokens * 1 ether;
      
      if(_member == 1 ) {
        teamTokensSent = teamTokensSent.add(tokens);
        require(teamTokensSent <= tokensAvailableForVesting); 
      } 
      else if(_member == 2) {
        advisorsTokensSent = advisorsTokensSent.add(tokens);
        require(advisorsTokensSent <= tokensAvailableForVesting);
      } 
      else {
          revert();
      }
    }

    /**
    * @notice Transfers vested tokens to beneficiary.
    * @param  _beneficiary address of benefeciary for which tokens are getting vested
    */
    function release(address _beneficiary) public onlyOwner {
       uint256 unreleased = vestedAmount(_beneficiary);
       require(unreleased > 0);
       released[_beneficiary] = released[_beneficiary].add(unreleased);
       _token.vestingTransfer(_beneficiary, unreleased);
       emit Released(unreleased);
    }

    //Calculate vested Amount  
    function vestedAmount(address _beneficiary)  internal  returns(uint256) {

        beneficiary storage benefeciaryOb = beneficiaryDetails[_beneficiary];
        uint256 vestedAmountNow;
        
        if(now >= icoFinalizedTime && now < tokenVestedFirstPhase ) // 25 % Released after ico finalised can be collected between ico finalised time to 3 months
        {
            
            require(vestedAfterIcoFinalize[_beneficiary]==false);
            vestedAmountNow = benefeciaryOb.tokenVestedInitially.div(4);
            benefeciaryOb.tokenreleasedFirstPhase = benefeciaryOb.tokenreleasedFirstPhase.add(vestedAmountNow);
            require(benefeciaryOb.tokenreleasedFirstPhase <= benefeciaryOb.tokenVestedInitially.div(4));
            benefeciaryOb.tokenreleasedTotal = benefeciaryOb.tokenreleasedFirstPhase.add(benefeciaryOb.tokenreleasedSecondPhase).add(benefeciaryOb.tokenreleasedThirdPhase).add(benefeciaryOb.tokenreleasedFourthPhase);
            vestedAfterIcoFinalize[_beneficiary]=true;
            return vestedAmountNow;
            
        }
    
        else if(now >= tokenVestedFirstPhase && now < tokenVestedSecondPhase )// total 50% released in between 3 months and 6 months 
        {
            
             if(benefeciaryOb.tokenreleasedTotal==0)//0% released
             {
              require(vestedAfterIcoFinalize[_beneficiary]==false);     
              require(VestedAfterFirstphase[_beneficiary]==false);     
              vestedAmountNow = benefeciaryOb.tokenVestedInitially.div(2);     
              benefeciaryOb.tokenreleasedSecondPhase = vestedAmountNow;
              require(benefeciaryOb.tokenreleasedFirstPhase.add(benefeciaryOb.tokenreleasedSecondPhase) <= benefeciaryOb.tokenVestedInitially.div(2));
              benefeciaryOb.tokenreleasedTotal = benefeciaryOb.tokenreleasedFirstPhase.add(benefeciaryOb.tokenreleasedSecondPhase).add(benefeciaryOb.tokenreleasedThirdPhase).add(benefeciaryOb.tokenreleasedFourthPhase);
              VestedAfterFirstphase[_beneficiary]=true;
              return vestedAmountNow;
             }
             else if(benefeciaryOb.tokenreleasedTotal>0 && benefeciaryOb.tokenreleasedTotal == benefeciaryOb.tokenVestedInitially.div(4))
             {
              require(VestedAfterFirstphase[_beneficiary]==false);     
              vestedAmountNow = benefeciaryOb.tokenVestedInitially.div(4);
              benefeciaryOb.tokenreleasedSecondPhase = vestedAmountNow;
              require(benefeciaryOb.tokenreleasedFirstPhase.add(benefeciaryOb.tokenreleasedSecondPhase) <= benefeciaryOb.tokenVestedInitially.div(2));   
              benefeciaryOb.tokenreleasedTotal = benefeciaryOb.tokenreleasedFirstPhase.add(benefeciaryOb.tokenreleasedSecondPhase).add(benefeciaryOb.tokenreleasedThirdPhase).add(benefeciaryOb.tokenreleasedFourthPhase);      
              VestedAfterFirstphase[_beneficiary]=true;
              return vestedAmountNow;
              }


        }
        
        else if(now >= tokenVestedSecondPhase && now < tokenVestedThirdPhase ) // total 75 % released in between 6 months and 12 months 
        {

            if(benefeciaryOb.tokenreleasedTotal==0)// 0% released
             {
              require(vestedAfterIcoFinalize[_beneficiary]==false);
              require(VestedAfterFirstphase[_beneficiary]==false);
              require(VestedAfterSecondphase[_beneficiary]==false);
              vestedAmountNow = benefeciaryOb.tokenVestedInitially.div(4).mul(3);     
              benefeciaryOb.tokenreleasedThirdPhase = benefeciaryOb.tokenreleasedThirdPhase.add(vestedAmountNow);
              require(benefeciaryOb.tokenreleasedFirstPhase.add(benefeciaryOb.tokenreleasedSecondPhase).add(benefeciaryOb.tokenreleasedThirdPhase) <= benefeciaryOb.tokenVestedInitially.div(4).mul(3));
              benefeciaryOb.tokenreleasedTotal = benefeciaryOb.tokenreleasedFirstPhase.add(benefeciaryOb.tokenreleasedSecondPhase).add(benefeciaryOb.tokenreleasedThirdPhase).add(benefeciaryOb.tokenreleasedFourthPhase);          
              VestedAfterSecondphase[_beneficiary]=true;
              return vestedAmountNow;
             }
             else if(benefeciaryOb.tokenreleasedTotal>0 && benefeciaryOb.tokenreleasedTotal == benefeciaryOb.tokenVestedInitially.div(4)) // 25%released
             {
              require(VestedAfterFirstphase[_beneficiary]==false);
              require(VestedAfterSecondphase[_beneficiary]==false);
              vestedAmountNow = benefeciaryOb.tokenVestedInitially.div(2);
              benefeciaryOb.tokenreleasedThirdPhase = benefeciaryOb.tokenreleasedThirdPhase.add(vestedAmountNow);  
              require(benefeciaryOb.tokenreleasedFirstPhase.add(benefeciaryOb.tokenreleasedSecondPhase).add(benefeciaryOb.tokenreleasedThirdPhase) <= benefeciaryOb.tokenVestedInitially.div(4).mul(3));   
              benefeciaryOb.tokenreleasedTotal = benefeciaryOb.tokenreleasedFirstPhase.add(benefeciaryOb.tokenreleasedSecondPhase).add(benefeciaryOb.tokenreleasedThirdPhase).add(benefeciaryOb.tokenreleasedFourthPhase);
              VestedAfterSecondphase[_beneficiary]=true;
              return vestedAmountNow;
             }
             else if(benefeciaryOb.tokenreleasedTotal>=benefeciaryOb.tokenVestedInitially.div(4) && benefeciaryOb.tokenreleasedTotal == benefeciaryOb.tokenVestedInitially.div(2) )//50% Released already
             {
              require(VestedAfterSecondphase[_beneficiary]==false);
              vestedAmountNow = benefeciaryOb.tokenVestedInitially.div(4);
              benefeciaryOb.tokenreleasedThirdPhase = benefeciaryOb.tokenreleasedThirdPhase.add(vestedAmountNow);  
              require(benefeciaryOb.tokenreleasedFirstPhase.add(benefeciaryOb.tokenreleasedSecondPhase).add(benefeciaryOb.tokenreleasedThirdPhase) <= benefeciaryOb.tokenVestedInitially.div(4).mul(3));   
              benefeciaryOb.tokenreleasedTotal = benefeciaryOb.tokenreleasedFirstPhase.add(benefeciaryOb.tokenreleasedSecondPhase).add(benefeciaryOb.tokenreleasedThirdPhase).add(benefeciaryOb.tokenreleasedFourthPhase);            
              VestedAfterSecondphase[_beneficiary]=true;
              return vestedAmountNow;
             }


        }
        
        else if(now >= tokenVestedThirdPhase) 
        {

            if(benefeciaryOb.tokenreleasedTotal==0)// 0 % released
             {
              require(VestedAfterThirdphase[_beneficiary]==false);     
              vestedAmountNow = benefeciaryOb.tokenVestedInitially;     
              benefeciaryOb.tokenreleasedFourthPhase = benefeciaryOb.tokenreleasedFourthPhase.add(vestedAmountNow);
              require(benefeciaryOb.tokenreleasedFirstPhase.add(benefeciaryOb.tokenreleasedSecondPhase).add(benefeciaryOb.tokenreleasedThirdPhase).add(benefeciaryOb.tokenreleasedFourthPhase) <= benefeciaryOb.tokenVestedInitially);
              benefeciaryOb.tokenreleasedTotal = benefeciaryOb.tokenreleasedFirstPhase.add(benefeciaryOb.tokenreleasedSecondPhase).add(benefeciaryOb.tokenreleasedThirdPhase).add(benefeciaryOb.tokenreleasedFourthPhase);              
              VestedAfterThirdphase[_beneficiary]=true;
              return vestedAmountNow;
             }
             else if(benefeciaryOb.tokenreleasedTotal>0 && benefeciaryOb.tokenreleasedTotal == benefeciaryOb.tokenVestedInitially.div(4) ) // 25 % released already
             {
              require(VestedAfterThirdphase[_beneficiary]==false);
              vestedAmountNow = benefeciaryOb.tokenVestedInitially.div(4).mul(3);
              benefeciaryOb.tokenreleasedFourthPhase = benefeciaryOb.tokenreleasedFourthPhase.add(vestedAmountNow);
              require(benefeciaryOb.tokenreleasedFirstPhase.add(benefeciaryOb.tokenreleasedSecondPhase).add(benefeciaryOb.tokenreleasedThirdPhase).add(benefeciaryOb.tokenreleasedFourthPhase) <= benefeciaryOb.tokenVestedInitially);
              benefeciaryOb.tokenreleasedTotal = benefeciaryOb.tokenreleasedFirstPhase.add(benefeciaryOb.tokenreleasedSecondPhase).add(benefeciaryOb.tokenreleasedThirdPhase).add(benefeciaryOb.tokenreleasedFourthPhase);              
              VestedAfterThirdphase[_beneficiary]=true;
              return vestedAmountNow;
             }
             else if(benefeciaryOb.tokenreleasedTotal>=benefeciaryOb.tokenVestedInitially.div(4) && benefeciaryOb.tokenreleasedTotal == benefeciaryOb.tokenVestedInitially.div(2) )//50 % released already
             {
              require(VestedAfterThirdphase[_beneficiary]==false);
              vestedAmountNow = benefeciaryOb.tokenVestedInitially.div(2);
              benefeciaryOb.tokenreleasedFourthPhase = benefeciaryOb.tokenreleasedFourthPhase.add(vestedAmountNow);
              require(benefeciaryOb.tokenreleasedFirstPhase.add(benefeciaryOb.tokenreleasedSecondPhase).add(benefeciaryOb.tokenreleasedThirdPhase).add(benefeciaryOb.tokenreleasedFourthPhase) <= benefeciaryOb.tokenVestedInitially);
              benefeciaryOb.tokenreleasedTotal = benefeciaryOb.tokenreleasedFirstPhase.add(benefeciaryOb.tokenreleasedSecondPhase).add(benefeciaryOb.tokenreleasedThirdPhase).add(benefeciaryOb.tokenreleasedFourthPhase);              
              VestedAfterThirdphase[_beneficiary]=true;
              return vestedAmountNow;
             }
             
             else if(benefeciaryOb.tokenreleasedTotal>=benefeciaryOb.tokenVestedInitially.div(2) && benefeciaryOb.tokenreleasedTotal == benefeciaryOb.tokenVestedInitially.div(4).mul(3) )//75% released already 
             {
              require(VestedAfterThirdphase[_beneficiary]==false);
              vestedAmountNow = benefeciaryOb.tokenVestedInitially.div(4);
              benefeciaryOb.tokenreleasedFourthPhase = benefeciaryOb.tokenreleasedFourthPhase.add(vestedAmountNow);
              require(benefeciaryOb.tokenreleasedFirstPhase.add(benefeciaryOb.tokenreleasedSecondPhase).add(benefeciaryOb.tokenreleasedThirdPhase).add(benefeciaryOb.tokenreleasedFourthPhase) <= benefeciaryOb.tokenVestedInitially);
              benefeciaryOb.tokenreleasedTotal = benefeciaryOb.tokenreleasedFirstPhase.add(benefeciaryOb.tokenreleasedSecondPhase).add(benefeciaryOb.tokenreleasedThirdPhase).add(benefeciaryOb.tokenreleasedFourthPhase); 
              VestedAfterThirdphase[_beneficiary]=true;
              return vestedAmountNow;
             }



        }
    }
    
    function setIcoFinalizedTime() public {
    
        require(msg.sender == CrowdsaleAddress);
        icoFinalizedTime = now ;// first phase after ico completion 25% Released
        tokenVestedFirstPhase = icoFinalizedTime.add(30 minutes);  //  3 months
        tokenVestedSecondPhase = tokenVestedFirstPhase.add(2 minutes); // after 6 months
        tokenVestedThirdPhase = tokenVestedSecondPhase.add(2 minutes); // after 12 months
        

    }
    
    function currentVestingPeriod() public view returns(string){
        if(icoFinalizedTime==0 )
        {
            
           return 'Vesting Period is not started Yet';
        }
        else if(now >= icoFinalizedTime && now < tokenVestedFirstPhase )
        {
            return 'Ico is Finalised 25% token is vested';
        }
        else if(now >= tokenVestedFirstPhase && now < tokenVestedSecondPhase )
        {
            return '3 months is completed 50% token is vested';        }
        else if(now >= tokenVestedSecondPhase && now < tokenVestedThirdPhase)
        {
            return '6 months is completed 75% token is vested';
        }
        else if (now >= tokenVestedThirdPhase) {return '12 months is completed 100% token is vested';}


    }

}