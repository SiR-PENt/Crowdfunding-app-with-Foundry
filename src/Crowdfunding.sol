// Layout of Contract:
// version
// imports
// errors
// interfaces, libraries, contracts
// Type declarations
// State variables
// Events
// Modifiers
// Functions

// Layout of Functions:
// constructor
// receive function (if exists)
// fallback function (if exists)
// external
// public
// internal
// private
// view & pure functions

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.20;

import { ReentrancyGuard } from "@openzeppelin/contracts/security/ReentrancyGuard.sol";
/**
 * @title Crowdfunding App
 * @author Olasunkanmi Balogun 
 * @notice Users can create crowdfunding campaigns with a funding goal and deadline.
 * Other users can donate to campaigns.
 * Campaign creators can withdraw funds if the goal is met by the deadline.
 * Refunds to donors if the goal is not met.
 */ 


contract Crowdfunding is ReentrancyGuard {

   error Crowdfunding__DeadlineMustBeInTheFuture();
   error Crowdfunding__CantSendZeroEth();
   error Crowdfunding__CampaignDeadlineElapsed();
   error Crowdfunding__TargetMetForCampaign();

   struct Campaign {
        string title;
        string description;
        uint256 target;
        uint256 deadline;
        uint256 amountCollected;
        string image;
        address[] donators;
        uint256[] donations;
    }

    address immutable private i_owner;
    mapping(uint256 => Campaign) public campaigns;
    uint256 public campaignId = 0;

   //  events
   event CreatedCampaign (address indexed owner, uint256 campignId);
   event MadeDonation (address indexed donor, uint256 indexed amountDonated, uint256 campaignId);

   constructor() {
      i_owner = msg.sender;
   }

   //  what did we do here?
   // 
   function createCampaigns(string memory _title, string memory _description, 
    uint256 _target, uint256 _deadline, string memory _image) public returns (uint256) {
       Campaign storage campaign = campaigns[campaignId]; // adding value to the mapping

       if(_deadline < block.timestamp) {
         revert Crowdfunding__DeadlineMustBeInTheFuture();
       } 
       
       campaign.title = _title;
       campaign.description = _description;
       campaign.target = _target;
       campaign.deadline = _deadline;
       campaign.amountCollected = 0;
       campaign.image = _image;

       campaignId++; // after a campaign has been added, we want to increment it
       emit CreatedCampaign(msg.sender, campaignId);
       return campaignId - 1; // this is going to be the index of the most recent campaign
    }

    function donateToCampaign(uint256 _campaignId) public payable nonReentrant {
      // revert if donor isnt sending anything
      if(msg.value <= 0) {
         revert Crowdfunding__CantSendZeroEth();
      }
      //  revert if deadline is in the past
      if(campaigns[_campaignId].deadline < block.timestamp) {
         revert Crowdfunding__CampaignDeadlineElapsed();
      } 
       // revert if target is met 
      if(campaigns[_campaignId].amountCollected == campaigns[_campaignId].target) {
         revert Crowdfunding__TargetMetForCampaign();
      } 

      Campaign storage campaign = campaigns[_campaignId];

      uint256 remainingFundsNeeded = campaign.target - campaign.amountCollected;
       // Handle contributions based on the remaining funds needed
       // next code block optimized for CEI
      if (msg.value <= remainingFundsNeeded) {
            campaign.amountCollected += msg.value;
            campaign.donators.push(msg.sender);
            campaign.donations.push(msg.value);
            emit MadeDonation(msg.sender, msg.value, _campaignId);
            (bool callSuccess, ) = payable(i_owner).call{value: msg.value}("");
            // reupdate state variables
            if (!callSuccess) {
            campaign.amountCollected -= msg.value;
            campaign.donators.pop();
            campaign.donations.pop();
            }
      } else {
         // Handle excess contributions and refunds
         uint excessAmount = msg.value - remainingFundsNeeded;
         uint amountToDonate = msg.value - excessAmount;

         // Refund the excess amount to the contributor
         payable(msg.sender).transfer(excessAmount);

         // Update the total contributions with the amount that was supposed to be donated
         campaign.amountCollected += amountToDonate;
         campaign.donators.push(msg.sender);
         campaign.donations.push(amountToDonate);
         emit MadeDonation(msg.sender, msg.value, _campaignId);
         (bool callSuccess, ) = payable(i_owner).call{value: amountToDonate}("");
         if(!callSuccess) {
            campaign.amountCollected -= amountToDonate;
            campaign.donators.pop();
            campaign.donations.pop();
         }
      }
    }

    // special functions

   fallback() external payable {
      donateToCampaign(campaignId);
    }

   receive() external payable {
      donateToCampaign(campaignId);
    }

    // getter functions

   function getOwner() view external returns (address) {
      return i_owner;
   }

   function getDonators(uint256 _campaignId) view public returns (address[] memory) {
       return campaigns[_campaignId].donators;
    }

   function getCampaigns() public view returns (Campaign[] memory) {
       Campaign[] memory allCampaigns = new Campaign[](campaignId); // create a new array of length campaignId
       require(allCampaigns.length > 0, "No campaign has been created yet");
       for(uint i = 0; i < campaignId; i++) {
          allCampaigns[i] = campaigns[i];
       }
       return allCampaigns;
    }

   function getCampaign(uint256 _campaignId) public view returns (Campaign memory) {
       return campaigns[_campaignId];
    } 
  
}