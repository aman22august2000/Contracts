// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;
import "@openzeppelin/contracts/interfaces/IERC20.sol";

contract Staking {
    IERC20 private token;

    constructor(IERC20 _token) {
        token = _token;
    }

    //structure to store address, amount, startTime and plan
    struct stakeInfo {
        address stakerAddress;
        uint256 stakeAmount;
        uint256 startTime;
        uint256 tarrif;
    }

    //Array which store detail of address, amount, time and tarrif at different idx[]
    stakeInfo[] public userStakes;

    //mapping to store id's corressponding to a particular address
    mapping(address => uint256[]) internal stakedIdsByAddress;

    //mapping of id to time
    mapping (uint256=> uint256) internal idToTime;

    //function to get details of stakers
    function getDetails(uint256 id) public view returns (stakeInfo memory) {
        return userStakes[id-1];
    }

    //function to stake the token with input params -> amount and time
    function stake(uint256 stakeAmount, uint256 time) public returns (stakeInfo memory) {
        require(stakeAmount>0, "Invalid input : You cannot stak negative amount");
        // require(token.balanceOf(msg.sender)>=stakeAmount, "Invalid input : You does not have enough token to stake");        
        require(time == 2 || time == 4 || time == 6 || time == 8 || time == 10, "Time can only be 2, 4, 6, 8, or 10 minutes");
        uint256 startTime = block.timestamp;
        token.transferFrom(msg.sender, address(this), stakeAmount);
        userStakes.push(stakeInfo(msg.sender, stakeAmount, time,startTime));
        uint256 id =userStakes.length;
        stakedIdsByAddress[msg.sender].push(id);
        return userStakes[id];
    }

    //function to find staked ids corresponding to particular address
    function idByAddress(address user) public view returns(uint256 [] memory){
        return stakedIdsByAddress[user];
    }

    //function 
    function min(uint256 a, uint256 b) public pure returns (uint256){
        return (a < b) ? a : b;
    }

    //function to calculate reward using -> taffir and plan
    function calculateReward(uint256 id) internal view returns (uint256){
        stakeInfo memory _info = userStakes[id-1];
        uint256 currentTarrif = _info.tarrif;
        uint256 currentTime = _info.startTime;
        uint256 reward;
        if(currentTarrif == 2) {
            reward = (((min(currentTime, currentTarrif*60)*_info.stakeAmount)*1)/100);
        }
        else if(currentTarrif == 4) {
            reward = (((min(currentTime, currentTarrif*60)*_info.stakeAmount)*2)/100);
        }
        else if(currentTarrif == 6) {
            reward = (((min(currentTime, currentTarrif*60)*_info.stakeAmount)*3)/100);
        }
        else if(currentTarrif == 8) {
            reward = (((min(currentTime, currentTarrif*60)*_info.stakeAmount)*4)/100);
        }
        else {
            reward = (((min(currentTime, currentTarrif*60)*_info.stakeAmount)*5)/100);
        }
        return reward;
    }

    //this function is used to calculate reward till a particular time
    function calculateRewardTillTime(uint256 id) public view returns (uint256, uint256) {
        require(userStakes.length>=id,"Invalid input: Input id doesnt exist");
        stakeInfo memory _info = userStakes[id-1];
        require(_info.stakerAddress != address(0) , "This address corresonding to id is already used");
        uint256 currentTime = block.timestamp - _info.startTime;
        uint256 currentTarrif = _info.tarrif;
        return (calculateReward(id),min(currentTime,currentTarrif));
    }

    //function to claim reward using various condition
    function claimRewards(uint256 id) public {
        require(userStakes.length >= id, "This id does not exist");
        stakeInfo memory _info = userStakes[id-1];
        require(_info.stakerAddress != address(0), "You use this ID before at present time this id does not exist");
        require(msg.sender == _info.stakerAddress, "You not claim this reward because you are not owner of this id");
        uint256 time = block.timestamp-_info.startTime;
        require(time >= _info.tarrif*60, "You does not claim reward because maturity period is not completed");
        uint256 reward = calculateReward(id);
        require(token.balanceOf(address(this)) >= reward, "Sorry contract have no enough tokens. We resolve this problem shortly");
        idToTime[id] = block.timestamp;
        token.transfer(_info.stakerAddress , reward);
        userStakes[id-1].tarrif = 0;
        userStakes[id-1].startTime = 0;
    }

    //function used to claim amount staked initially
    function claimAmount(uint256 id) public {
        require(userStakes.length >= id, "This id does not exist");
        stakeInfo memory _info = userStakes[id-1];
        require(_info.stakerAddress != address(0), "You use this ID before at present time this id does not exist");
        require(msg.sender == _info.stakerAddress, "You not claim this amount because you are not owner of this id");
        require(userStakes[id-1].tarrif == 0, "You only claim amount after claiming reward");
        require(block.timestamp-idToTime[id] >= 120, "You can claim amount only after 2 minutes from the time of Claim Rewards");
        idToTime[id] = 0;
        uint256 amount = _info.stakeAmount;
        require(token.balanceOf(address(this)) >= amount, "Sorry contract have no enough tokens. We resolve this problem shortly");
        token.transfer(_info.stakerAddress, amount);
        userStakes[id-1].stakerAddress = address(0);
        userStakes[id-1].stakeAmount = 0;
        idToTime[id] = 0;
    }

}
