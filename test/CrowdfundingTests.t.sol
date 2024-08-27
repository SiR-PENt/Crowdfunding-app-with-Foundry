// SPDX-License-Identifier: MIT

pragma solidity ^0.8.20;

import { Test, console } from "forge-std/Test.sol";
import { Crowdfunding } from "../src/Crowdfunding.sol";
import { DeployCrowdfunding } from "../script/DeployCrowdfunding.s.sol";

contract CrowdfundingTest is Test {

    Crowdfunding crowdFunding;
    address owner = makeAddr("user");
    address donor1 = makeAddr("donor1");
    address donor2 = makeAddr("donor2");
     
    uint256 campaignId;
    string constant TITLE = "Help Fund My Project";
    string constant DESCRIPTION = "A project that will change the world!";
    uint256 constant TARGET = 5 ether;
    uint256 deadline = block.timestamp + 7 days;
    string constant IMAGE = "image_link";

    function setUp() public {
        DeployCrowdfunding deployCrowdFunding = new DeployCrowdfunding();
        crowdFunding = deployCrowdFunding.run();
        vm.deal(owner, 10 ether);
        vm.deal(donor1, 5 ether);
        vm.deal(donor2, 5 ether);
    }

    function testCampaignCreationRevertsIfDeadlineIsNotInTheFuture() public {
        vm.warp(block.timestamp + deadline + 1);
        vm.expectRevert(Crowdfunding.Crowdfunding__DeadlineMustBeInTheFuture.selector);
        vm.prank(owner);
        crowdFunding.createCampaigns(TITLE, DESCRIPTION, TARGET, deadline, IMAGE);
    }

    modifier createCampaign() {
        vm.prank(owner);
        campaignId = crowdFunding.createCampaigns(TITLE, DESCRIPTION, TARGET, deadline, IMAGE);
        _;
    }

    function testCreateCampaign() public createCampaign {
        string memory campaignTitle = crowdFunding.getCampaign(campaignId).title;
        string memory campaignDescription = crowdFunding.getCampaign(campaignId).description;
        uint256 campaignTarget = crowdFunding.getCampaign(campaignId).target;
        uint256 campaignDeadline = crowdFunding.getCampaign(campaignId).deadline;
        uint256 campaignAmountCollected = crowdFunding.getCampaign(campaignId).amountCollected;

        assertEq(owner, owner);
        assertEq(campaignTitle, TITLE);
        assertEq(campaignDescription, DESCRIPTION);
        assertEq(campaignTarget, TARGET);
        assertEq(campaignDeadline, deadline);
        assertEq(campaignAmountCollected, 0);
    }
    // test donate to campaign
    function testDonationRevertsWhenZeroEthIsDonated() public createCampaign {
        vm.expectRevert(Crowdfunding.Crowdfunding__CantSendZeroEth.selector);
        // Donate to the campaign
        vm.prank(donor1);
        crowdFunding.donateToCampaign{value: 0}(campaignId);
    }

    function testDonationRevertsWhenDeadlinePasses() public createCampaign {
        vm.warp(block.timestamp + deadline + 1);
        vm.expectRevert();
        // Donate to the campaign
        vm.prank(donor1);
        crowdFunding.donateToCampaign{value: 2 ether}(campaignId);
    }

    function testDonationRevertsWhenTargetIsMet() public createCampaign {
        vm.prank(donor1);
        crowdFunding.donateToCampaign{value: 5 ether}(campaignId);

        vm.expectRevert(Crowdfunding.Crowdfunding__TargetMetForCampaign.selector);
        vm.prank(donor2);
        crowdFunding.donateToCampaign{value: 1 ether}(campaignId);
    }

    function testDonateToCampaign() public createCampaign {
        // Donate to the campaign
        vm.prank(donor1);
        crowdFunding.donateToCampaign{value: 2 ether}(campaignId);

        // Validate campaign donation data
        uint256 campaignAmountCollected = crowdFunding.getCampaign(campaignId).amountCollected;
        uint256[] memory donations = crowdFunding.getCampaign(campaignId).donations;
        address[] memory donators = crowdFunding.getCampaign(campaignId).donators;

        assert(campaignAmountCollected == 2 ether);
        assertEq(donators.length, 1);
        assertEq(donations[0], 2 ether);
    }

    function testReverseExcessAmountToSender() public createCampaign {
        vm.prank(donor1);
        crowdFunding.donateToCampaign{value: 2 ether}(campaignId);
        vm.prank(donor2);
        crowdFunding.donateToCampaign{value: 4 ether}(campaignId);
        assertEq(donor2.balance, 2 ether);
    }

    function testGetDonators() public createCampaign {
        // Donate to the campaign
        vm.prank(donor1);
        crowdFunding.donateToCampaign{value: 1 ether}(campaignId);

        vm.prank(donor2);
        crowdFunding.donateToCampaign{value: 1.5 ether}(campaignId);

        // Get donators
        address[] memory donators = crowdFunding.getDonators(campaignId);

        assertEq(donators.length, 2);
        assertEq(donators[0], donor1);
        assertEq(donators[1], donor2);
    }

    function testGetCampaigns() public {
        // Create multiple campaigns
        vm.prank(owner);
        crowdFunding.createCampaigns("Campaign 1", "First campaign", 3 ether, block.timestamp + 5 days, "image_1");

        vm.prank(owner);
        crowdFunding.createCampaigns("Campaign 2", "Second campaign", 4 ether, block.timestamp + 6 days, "image_2");

        vm.prank(owner);
        crowdFunding.createCampaigns("Campaign 3", "Third campaign", 5 ether, block.timestamp + 7 days, "image_3");

        // Get all campaigns
        Crowdfunding.Campaign[] memory campaigns = crowdFunding.getCampaigns();
        
        assertEq(campaigns.length, 3);
    }
}
