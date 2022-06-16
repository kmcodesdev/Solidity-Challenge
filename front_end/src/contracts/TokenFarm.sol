// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";

 

contract TokenFarm is Ownable {

    mapping(address => mapping(address => uint256)) public stakingBalance;
    mapping(address => uint256) public uniqueTokensStaked;
    mapping(address => address) public tokenPriceFeedMapping;
    
  address[] public stakers;
address[] public allowedTokens; 
    IERC20 public devUsdc;





   constructor(address _devUsdcAddress) public {
        devUsdc = IERC20(_devUsdcAddress);
    }

    function setPriceFeedContract(address token, address pricefeed)
    public 
    onlyOwner 
    {
        tokenPriceFeedMapping[token] = pricefeed;
    }

 // Issue Tokens
function issueTokens() public onlyOwner {
     for (
            uint256 stakersIndex = 0;
            stakersIndex < stakers.length;
            stakersIndex++
        ) 
        {
            address recipient = stakers[stakersIndex];
            uint256 userTotalValue = getUserTotalValue(recipient);
            //send token reward based on TVL
            devUsdc.transfer(recipient,userTotalValue);

        }
}

    function getUserTotalValue(address user) public view returns (uint256) {
        uint256 totalValue = 0;
      require(uniqueTokensStaked [user] > 0, "no tokens staked!");
      for (
        uint256 allowedTokensIndex = 0;
      allowedTokensIndex < allowedTokens.length;
      allowedTokensIndex++
      ){
          totalValue =
                    totalValue + getUserSingleTokenValue(user, allowedTokens[allowedTokensIndex]);
               
      }

      return totalValue;

     }

     function getUserSingleTokenValue(address user, address token) 
     public 
     view 
     returns (uint256) {
        if (uniqueTokensStaked[user] <= 0) {
            return 0;
        }
        //price of the token * stakingBalance[token][user]
        (uint256 price, uint256 decimals) = getTokenValue(token);
        return  
              (stakingBalance[token][user] * price / (10**decimals));
     }

     function getTokenValue(address token) public view returns (uint256, uint256) {
        // get price feeed address
        address priceFeedAddress = tokenPriceFeedMapping[token];
        AggregatorV3Interface priceFeed = AggregatorV3Interface(priceFeedAddress);
        (,int256 price,,,)= priceFeed.latestRoundData();
        uint256 decimals = uint256(priceFeed.decimals());
        return (uint256(price), decimals);
     }


 function stakeTokens(uint256 _amount, address _token) public {
 //how much ETH can they stake?
 require(_amount > 5, "amount must be greater than 5"); 
        require(tokenIsAllowed(_token), "Token currently isn't allowed");
        updateUniqueTokensStaked(msg.sender, _token);
        IERC20(_token).transferFrom(msg.sender, address(this), _amount);
   stakingBalance[_token][msg.sender] =
            stakingBalance[_token][msg.sender] +
            _amount;
           if (uniqueTokensStaked[msg.sender] == 1) {
            stakers.push(msg.sender);
        }      
 }

 function unstakeTokens(address token) public {
    uint256 balance = stakingBalance[token][msg.sender];
    require(balance > 0, "staking balance cannot be 0");
    IERC20(token).transfer(msg.sender, balance);
    stakingBalance[token][msg.sender] = 0;
    uniqueTokensStaked[msg.sender] = uniqueTokensStaked[msg.sender] - 1;
 }

 function updateUniqueTokensStaked(address user, address token) internal {
              if (stakingBalance[token][user] <= 0) {
            uniqueTokensStaked[user] = uniqueTokensStaked[user] + 1;
        }
 }

 function addAllowedTokens(address _token) public onlyOwner {
    allowedTokens.push(_token);
 }

function tokenIsAllowed(address _token) public returns (bool) {
   for( uint256 allowedTokensIndex=0; allowedTokensIndex < allowedTokens.length; allowedTokensIndex++){
   if(allowedTokens[allowedTokensIndex] == _token) {
    return true;

      }
    } 
    return false;
   }
}

