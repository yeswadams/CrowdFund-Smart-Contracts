// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

interface IERC20 {
    function transfer(address, uint256) external returns (bool);
    function transferFrom(address, address, uint256) external returns (bool);
}

contract CrowdFund {
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
    mapping(uint256 => Campaign) public campaigns;

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
    }





}


















