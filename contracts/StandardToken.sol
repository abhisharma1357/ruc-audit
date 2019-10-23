pragma solidity ^0.4.24;

import "./ERC20.sol";
import "./SafeMath.sol";

/**
 * @title Standard ERC20 token
 *
 * @dev Implementation of the basic standard token.
 * @dev https://github.com/ethereum/EIPs/issues/20
 * @dev Based on code by FirstBlood: https://github.com/Firstbloodio/token/blob/master/smart_contract/FirstBloodToken.sol
 */
contract StandardToken is ERC20 {
    using SafeMath for uint256;
    mapping (address => mapping (address => uint256)) internal allowed;
    mapping(address => uint256) balances;

  /// @dev Returns number of tokens owned by given address
  /// @param _owner Address of token owner
  /// @return Balance of owner

  // it is recommended to define functions which can read the state of blockchain but cannot write in it as view instead of constant

    function balanceOf(address _owner) public view returns (uint256) {
        return balances[_owner];
    }

  /// @dev Transfers sender's tokens to a given address. Returns success
  /// @param _to Address of token receiver
  /// @param _value Number of tokens to transfer
  /// @return Was transfer successful?

    function transfer(address _to, uint256 _value) public onlyPayloadSize(2) returns (bool success) {
        if (balances[msg.sender] >= _value && _value > 0 && balances[_to].add(_value) > balances[_to]) {
            balances[msg.sender] = balances[msg.sender].sub(_value);
            balances[_to] = balances[_to].add(_value);
            emit Transfer(msg.sender, _to, _value); // solhint-disable-line
            return true;
        } else {
            return false;
        }
    }

    /// @dev Allows allowed third party to transfer tokens from one address to another. Returns success
    /// @param _from Address from where tokens are withdrawn
    /// @param _to Address to where tokens are sent
    /// @param _value Number of tokens to transfer
    /// @return Was transfer successful?

    function transferFrom(address _from, address _to, uint256 _value) public onlyPayloadSize(3) returns (bool) {
        require(_to != address(0));
        require(_value <= balances[_from]);
        require(_value <= allowed[_from][msg.sender]);

        balances[_from] = balances[_from].sub(_value);
        balances[_to] = balances[_to].add(_value);
        allowed[_from][msg.sender] = allowed[_from][msg.sender].sub(_value);
        emit Transfer(_from, _to, _value); // solhint-disable-line
        return true;
    }

  /**
   * @dev Approve the passed address to spend the specified amount of tokens on behalf of msg.sender.
   *
   * Beware that changing an allowance with this method brings the risk that someone may use both the old
   * and the new allowance by unfortunate transaction ordering. One possible solution to mitigate this
   * race condition is to first reduce the spender's allowance to 0 and set the desired value afterwards:
   * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
   * @param _spender The address which will spend the funds.
   * @param _value The amount of tokens to be spent.
   */


    function approve(address _spender, uint256 _value) public onlyPayloadSize(2) returns (bool) {
      // To change the approve amount you first have to reduce the addresses`
      //  allowance to zero by calling `approve(_spender, 0)` if it is not
      //  already 0 to mitigate the race condition described here:
      //  https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729

        require(_value == 0 || (allowed[msg.sender][_spender] == 0));
        allowed[msg.sender][_spender] = _value;
        emit Approval(msg.sender, _spender, _value); // solhint-disable-line
        return true;
    }

    function changeApproval(address _spender, uint256 _oldValue, uint256 _newValue) public onlyPayloadSize(3) returns (bool success) {
        require(allowed[msg.sender][_spender] == _oldValue);
        allowed[msg.sender][_spender] = _newValue;
        emit Approval(msg.sender, _spender, _newValue); // solhint-disable-line
        return true;
    }

  /**
   * @dev Function to check the amount of tokens that an owner allowed to a spender.
   * @param _owner address The address which owns the funds.
   * @param _spender address The address which will spend the funds.
   * @return A uint256 specifying the amount of tokens still available for the spender.
   */
    function allowance(address _owner, address _spender) public view returns (uint256) {
        return allowed[_owner][_spender];
    }

 /**
  * @dev Burns a specific amount of tokens.
  * @param _value The amount of token to be burned.
  */
    function burn(uint256 _value) public returns (bool burnSuccess) {
        require(_value > 0);
        require(_value <= balances[msg.sender]);
        // no need to require value <= totalSupply, since that would imply the
        // sender's balance is greater than the totalSupply, which *should* be an assertion failure

        address burner = msg.sender;
        balances[burner] = balances[burner].sub(_value);
        totalSupply = totalSupply.sub(_value);
        emit Burn(burner, _value); // solhint-disable-line
        return true;
    }
    
    

}
