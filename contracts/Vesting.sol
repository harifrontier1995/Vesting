// contracts/TokenVesting.sol
// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8;
import "./VestingToken.sol";
library SafeMath {
    /**
     * @dev Returns the addition of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `+` operator.
     *
     * Requirements:
     * - Addition cannot overflow.
     */
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");

        return c;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return sub(a, b, "SafeMath: subtraction overflow");
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        uint256 c = a - b;

        return c;
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `*` operator.
     *
     * Requirements:
     * - Multiplication cannot overflow.
     */
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");

        return c;
    }

    /**
     * @dev Returns the integer division of two unsigned integers. Reverts on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return div(a, b, "SafeMath: division by zero");
    }

    /**
     * @dev Returns the integer division of two unsigned integers. Reverts with custom message on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        // Solidity only automatically asserts when dividing by 0
        require(b > 0, errorMessage);
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold

        return c;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * Reverts when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return mod(a, b, "SafeMath: modulo by zero");
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * Reverts with custom message when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b != 0, errorMessage);
        return a % b;
    }
}
contract Vesting {
    using SafeMath for uint256;
    VestingToken public vestToken;

    struct Emp{
        uint amt;
        bool paid;
    }
    mapping(address => uint256) public balanceOf;
   // mapping(address => Founder) public founders;
    mapping(address => Emp) public emps;
    address public admin;
    //uint transactionValue;
    /// @notice start of vesting period as a timestamp
    uint256 public start;
    /// @notice end of vesting period as a timestamp
    uint256 public end;
    /// @notice cliff duration in seconds
    uint256 public cliffDuration;
    /// @notice cumulative total of tokens drawn down (and transferred from the deposit account) per beneficiary
    mapping(address => uint256) public totalDrawn;
    /// @notice last drawn down time (seconds) per beneficiary
    mapping(address => uint256) public lastDrawnAt;

    constructor(VestingToken _vestToken) {
        admin = msg.sender;  
        //transactionValue = msg.value;
        vestToken = _vestToken;
        start = block.timestamp;        // 2021-01-01T00:00:00.000Z
        end = block.timestamp + 1000;          // 2024-01-01T00:00:00.000Z
        cliffDuration = 60;   // 31*24*60*60 = 2678400
    }

    // function addFounder(address _founder, uint _maturity) external payable{
    //     require(_founder == admin, "only admin allowed");
    //     require(founders[_founder].amt == 0,"founder aldready exists");
    //     founders[_founder] = Founder(transactionValue, block.timestamp + _maturity, false);
    // }
    
    function addEmp(address _emp, uint amt) external payable{
        require(msg.sender == admin, "only admin allowed");
        require(emps[_emp].amt == 0,"emp aldready exists");
        emps[_emp] = Emp(amt, false);
    }

    function withdraw(address _emp) external payable{   
        Emp storage emp = emps[_emp];
        //Founder storage founder = founders[msg.sender];
        //require(emp.maturity <= block.timestamp, "too early");
        require(emp.paid == false,"aldready paid");
        //emp.paid = true;
        uint256 amount = _availableDrawDownAmount(_emp);
        require(
            totalDrawn[_emp] <= emp.amt,
            "Drawn exceeded Amount Vested"
        );
        vestToken.transfer(_emp , amount);
        //payable(_emp).transfer(amount);
        lastDrawnAt[_emp] = _getNow();
        totalDrawn[_emp] = totalDrawn[_emp].add(amount);
        //founder.amt = founder.amt.sub(emp.amt);
    }

    function _availableDrawDownAmount(address _beneficiary) public  returns (uint256 _amount) {
        if (_getNow() <= start.add(cliffDuration)) {
            return 0;
        }
        if (_getNow() > end) {
            emps[_beneficiary].paid = true;
            return emps[_beneficiary].amt.sub(totalDrawn[_beneficiary]);
        }
        uint256 timeLastDrawnOrStart = lastDrawnAt[_beneficiary] == 0 ? start : lastDrawnAt[_beneficiary];
        uint256 timePassedSinceLastInvocation = _getNow().sub(timeLastDrawnOrStart);
        uint256 drawDownRate = emps[_beneficiary].amt.div(end.sub(start));
        uint256 amount = timePassedSinceLastInvocation.mul(drawDownRate);
        return amount;
    }

    function vestingScheduleForBeneficiary(address _beneficiary)
    external view
    returns (uint256 _amount, uint256 _totalDrawn, uint256 _lastDrawnAt, uint256 _remainingBalance) {
        return (
        emps[_beneficiary].amt,
        totalDrawn[_beneficiary],
        lastDrawnAt[_beneficiary],
        emps[_beneficiary].amt.sub(totalDrawn[_beneficiary])
        );
    }

    function _getNow() public view returns (uint256) {
        return block.timestamp;
    }

    function getBalance() public view returns (uint256) {
        return vestToken.balanceOf(address(this));
    }

    
    
}
