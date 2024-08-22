// SPDX-License-Identifier: MIT

pragma solidity ^0.8.20;

//  import { Ownable } from "@openzeppelin/contracts/access/Ownable.sol";

/**
 * @title Crowdfunding App
 * @author Olasunkanmi Balogun 
 * @notice Users can create crowdfunding campaigns with a funding goal and deadline.
 * Other users can donate to campaigns.
 * Campaign creators can withdraw funds if the goal is met by the deadline.
 * Refunds to donors if the goal is not met.
 */ 

contract Crowdfunding {

    struct Campaign {
        address owner;
        string title;
        string description;
        uint256 target;
        uint256 deadline;
        uint256 amountCollected;
        string image;
        address[] donators;
        uint256[] donations;
    }

    mapping(uint256 => Campaign) public campaigns;

    uint256 public numberOfCampaigns = 0;

    //  what did we do here?
    // 

    function createCampaigns(address _owner, string memory _title, string memory _description, 
    uint256 _target, uint256 _deadline, string memory _image) public returns (uint256) {
       Campaign storage campaign = campaigns[numberOfCampaigns]; // adding value to the mapping

       require(_deadline > block.timestamp, "The deadline should be a date in the future");
       
       campaign.owner = _owner;
       campaign.title = _title;
       campaign.description = _description;
       campaign.target = _target;
       campaign.deadline = _deadline;
       campaign.amountCollected = 0;
       campaign.image = _image;

       numberOfCampaigns++; // after a campaign has been added, we want to increment it
       return numberOfCampaigns - 1; // this is going to be the index of the most recent campaign
    }

    function donateToCampaign(uint256 _id) public payable {
       uint256 amount = msg.value;
       Campaign storage campaign = campaigns[_id];

       campaign.donators.push(msg.sender);
       campaign.donations.push(amount);

       (bool callSuccess, ) = payable(campaign.owner).call{value: amount}("");
       
       if(callSuccess) campaign.amountCollected = campaign.amountCollected + amount;
    }

    // getter functions

    function getDonators(uint256 _campaignId) view public returns (address[] memory) {
       return campaigns[_campaignId].donators;
    }

    function getCampaigns() public view returns (Campaign[] memory) {
       Campaign[] memory allCampaigns = new Campaign[](numberOfCampaigns); // create a new array of length numberOfCampaigns

       for(uint i = 0; i < numberOfCampaigns; i++) {
          allCampaigns[i] = campaigns[i];
       }
       return allCampaigns;
    }

    function getCampaign(uint256 _campaignId) public view returns (Campaign memory) {
       return campaigns[_campaignId];
    } 
  
}