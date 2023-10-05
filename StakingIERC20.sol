//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

//// To run this staking contract first the owner have to mint or transfer some tokens to this contract

contract StakingIERC20 {

    IERC20 private token;

    // pass the address of the erc20 contract at the deployment of this staking contract
    constructor(address _token) {
        token = IERC20(_token);
    }

    /// this struct datatype stores information about particular stake id
    struct stake {
        address holder;
        uint256 amount;
        uint256 plan;
        uint256 stakedAt;
    }

    /// we can fetch/store the deatils of stakeholders by using this array
    stake[] internal stakeholders; 

    /// this mapping stores the info about how many ids an address can store
    mapping(address => uint256[]) internal stakedIdsByAddress;

    /// this mapping help us to calculate the time to claim amount only after 2 minutes
    mapping(uint256 => uint256) internal _timestamp;

    event Staked(address indexed holder, uint256 amount, uint256 stakeholderId, uint256 plan, uint256 stakedAt);

    /// from this function we get the ids an address is staked
    function getIdsByAddress(address account) public view returns(uint256[] memory) {
        return stakedIdsByAddress[account];
    }

    /// For staking {condition}
    /// 1 --- you have enough token in your account
    /// 2 --- you have to approve this contract an amount how much you want to stake
    /// 3 --- you stake amount 1 or greater value
    /// 4 --- choose a specific plan i.e., 2,4,6,8,10 minutes
    function Stake(uint256 amount, uint256 time) public returns(uint256) {
        require(amount > 0, "Stakable: you can only stake a positive non null amount");
        require(token.balanceOf(msg.sender) >= amount, "Not Enough Balance Tokens To Stake"); 
        require(time == 2 || time == 4 || time == 6 || time == 8 || time == 10, "You can only choose plan of time 2,4,6,8,10 minutes only");
        uint256 stakedAt = block.timestamp;
        token.transferFrom(msg.sender, address(this), amount);
        stakeholders.push(stake(msg.sender, amount, time, stakedAt));
        uint256 id = stakeholders.length;
        stakedIdsByAddress[msg.sender].push(id);
        emit Staked(msg.sender, amount, id, time,stakedAt);
        return id;
    }

    /// function to calculate the minimum of two values
    function min(uint256 a, uint256 b) internal pure returns (uint256) {
        return a < b ? a : b;
    }

    /// this function calculate the reward based on your choosen plan
    function _calculateReward(uint256 id) internal view returns (uint256) {
        stake memory _stake = stakeholders[id-1];
        uint256 _time = block.timestamp - _stake.stakedAt;
        uint256 _plan = _stake.plan;
        uint256 res;

        if(_plan == 2) {
            res = (((min(_time, _plan*60)*_stake.amount)*1)/100);
        }
        else if(_plan == 4) {
            res = (((min(_time, _plan*60)*_stake.amount)*2)/100);
        }
        else if(_plan == 6) {
            res = (((min(_time, _plan*60)*_stake.amount)*3)/100);
        }
        else if(_plan == 8) {
            res = (((min(_time, _plan*60)*_stake.amount)*4)/100);
        }
        else {
            res = (((min(_time, _plan*60)*_stake.amount)*5)/100);
        }

        return res;
    }

    /// By this function user check how much reward he/she can get at the present time 
    function CalculateReward(uint256 id) public view returns(uint256 reward, uint256 time) {
        require(stakeholders.length >= id, "This id does not exist");
        stake memory _stake = stakeholders[id-1];
        require(_stake.holder != address(0), "You use this ID before at present time this id does not exist");
        uint256 _time = block.timestamp - _stake.stakedAt;
        uint256 _plan = _stake.plan;
        return (_calculateReward(id), min(_time, _plan));
    }
    
    /// This is read only function by this any user can check all details about a specific id 
    function getInfo(uint256 id) public view returns(address stakeHolder, uint256 amount, uint256 plan) {
        require(stakeholders.length >= id, "This id does not exist");
        stake memory _stake = stakeholders[id-1];
        require(_stake.holder != address(0), "You use this ID before at present time this id does not exist");
        address _user = _stake.holder;
        uint256 _amount = _stake.amount;
        uint256 _plan = _stake.plan;
        return (_user, _amount, _plan);
    }
    
    //// By this function user can claim their reward {conditions}
    ///  1 --- only the owner of the id can claim the reward
    ///  2 --- user can claim reward only after the maturity period is over
    ///  3 --- user can claim reward only one time after claiming reward this id is expired 

    /// Note --- Your reward amount exceed only in the time of the maturity period after maturity period your reward does not exceed 
    ///          so this is recommended that you do not hold your amount and reward after your maturity period is over... Thanks!!!

    function ClaimRewards(uint256 id) public {
        require(stakeholders.length >= id, "This id does not exist");
        stake memory _stake = stakeholders[id-1];
        require(_stake.holder != address(0), "You use this ID before at present time this id does not exist");
        require(msg.sender == _stake.holder, "You not claim this reward because you are not owner of this id");
        uint256 time = block.timestamp-_stake.stakedAt;
        require(time >= _stake.plan*60, "You does not claim reward because maturity period is not completed");
        uint256 reward = _calculateReward(id);
        require(token.balanceOf(address(this)) >= reward, "Sorry contract have no enough tokens. We resolve this problem shortly");
        _timestamp[id] = block.timestamp;
        token.transfer(_stake.holder, reward);
        stakeholders[id-1].plan = 0;
        stakeholders[id-1].stakedAt = 0;
    }

    /// this function is used to claim amount {conditions}
    /// 1 --- only the owner of the id can claim the amount
    /// 2 --- user can claim amount after 2 minutes from the time of claim reward
    /// 3 --- user can claim amount only one time after claiming amount this id is expired
    /// 4 --- you does not claim amount before claiming the reward

    //// Note --- It is recommended to do not hold amount aftert 2 minutes of climaimg reward. No increament is happen in amount.

    function ClaimAmount(uint256 id) public {
        require(stakeholders.length >= id, "This id does not exist");
        stake memory _stake = stakeholders[id-1];
        require(_stake.holder != address(0), "You use this ID before at present time this id does not exist");
        require(msg.sender == _stake.holder, "You not claim this amount because you are not owner of this id");
        require(stakeholders[id-1].plan == 0, "You only claim amount after claiming reward");
        require(block.timestamp-_timestamp[id] >= 120, "You can claim amount only after 2 minutes from the time of Claim Rewards");
        _timestamp[id] = 0;
        uint256 amount = _stake.amount;
        require(token.balanceOf(address(this)) >= amount, "Sorry contract have no enough tokens. We resolve this problem shortly");
        token.transfer(_stake.holder, amount);
        stakeholders[id-1].holder = address(0);
        stakeholders[id-1].amount = 0;
        _timestamp[id] = 0;
    }
}