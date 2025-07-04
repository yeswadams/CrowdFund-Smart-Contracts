// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

interface IERC20 {
    function transfer(address, uint256) external returns (bool);
    function transferFrom(address, address, uint256) external returns (bool);
}

contract CrowdFund {
    event Launch(uint256 id, address indexed creator, uint256 goal, uint32 startAt, uint32 endAt);    
    event Cancel(uint256 id);
    event Pledge(uint256 indexed id, address indexed caller, uint256 amount);
    event UnPledge(uint256 indexed id, address indexed caller, uint256 amount);
    event Claim(uint256 id);
    event Refund(uint256 id, address indexed caller, uint256 amount);

    struct Campaign {
        address creator;
        uint256 goal;
        uint256 pledged;
        uint32 startAt;
        uint32 endAt;
        bool claimed;
    }
    
    IERC20 public immutable token; 
    uint256 public count;
    // mapping from campaign id to Campaign struct
    mapping(uint256 => Campaign) public campaigns;

    // Double mapping from campaign 
    mapping(uint256 => mapping(address=> uint256)) public pledgedAmount;

    constructor(address _token) {
        token = IERC20(_token);
    }

    function launch( uint256 _goal, uint32 _startAt, uint32 _endAt ) external { 
        require(_startAt >= block.timestamp, "start at < now");
        require(_endAt >= _startAt, "end at < start at ");
        require(_endAt <= block.timestamp + 90 days, "end at > max duration");
        count += 1;

        campaigns[count] = Campaign({
          creator: msg.sender,
          goal: _goal,
          pledged: 0,
          startAt: _startAt,
          endAt: _endAt,
          claimed: false
      });
      emit Launch(count, msg.sender,_goal,_startAt,_endAt);
    }

    
    function cancel(uint256 _id) external {
        Campaign memory campaign = campaigns[_id];
        require(campaign.creator == msg.sender, "not creator");
        require(block.timestamp < campaign.startAt, "started");
        delete campaigns[_id];
        emit Cancel(_id);
    }

    // Create a pledge
    function pledge(uint256 _id, uint256 _amount) external {
        Campaign storage campaign = campaigns[_id];  // mapping, struct, storage
        require(block.timestamp >= campaign.startAt, "not started");
        require(block.timestamp <= campaign.endAt, "ended");

        campaign.pledged += _amount;
        pledgedAmount[_id][msg.sender] += _amount;

        token.transferFrom(msg.sender, address(this), _amount);
        emit Pledge(_id, msg.sender, _amount);
    }

    //Cancel a pledge
    function unpledge(uint256 _id, uint256 _amount) external {
        Campaign storage campaign = campaigns[_id];
        require(block.timestamp <= campaign.endAt, "ended");

        campaign.pledged -= _amount;
        pledgedAmount[_id][msg.sender] -= _amount;

        token.transfer(msg.sender, _amount);
        emit UnPledge(_id, msg.sender, _amount);
    }

    // Claim the funds if the goal is reached
    function claim(uint256 _id) external {
        Campaign storage campaign = campaigns[_id];
        require(campaign.creator == msg.sender, "not creator");
        require(block.timestamp >=  campaign.endAt, "not ended");
        require(campaign.pledged >= campaign.goal, "pledged < goal");
        //require(campaign.claimed == false, "claimed");
        require(!campaign.claimed, "claimed");

        campaign.claimed = true;
        token.transfer(campaign.creator, campaign.pledged);
        emit Claim(_id);

    }

    // Refunds
    function refund(uint256 _id) external {
        Campaign memory campaign = campaigns[_id];
        require(block.timestamp > campaign.endAt, "not ended");
        require(campaign.pledged < campaign.goal, "pledged >= goal");

        //Users Refund Process
        uint256 bal= pledgedAmount[_id][msg.sender];
        pledgedAmount[_id][msg.sender]= 0;
        token.transfer(msg.sender, bal);
        emit Refund(_id, msg.sender, bal);
    }



}


















