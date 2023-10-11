// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.4.22 <0.9.0;

import "remix_tests.sol";
import "remix_accounts.sol";
import "../contracts/Auction.sol";

contract testSuite {
    ArtworkAuction auction;
    address acc0;
    address acc1;
    address acc2;

    function getBalance() public view returns (uint256) {
        return address(this).balance;
    }

    receive() external payable {}

    constructor() {
        auction = ArtworkAuction(
            payable(0x9d83e140330758a8fFD07F8Bd73e86ebcA8a5692)
        );
    }

    fallback() external payable {}

    function beforeAll() public {
        acc0 = TestsAccounts.getAccount(0);
        acc1 = TestsAccounts.getAccount(1);
        acc2 = TestsAccounts.getAccount(2);
    }

    function checkInitialSetup() public {
        uint256 initialLiveAuctions = auction.getNumberOfLiveAuctions();
        uint256 initialEndedAuctions = auction.getNumberOfEndedAuctions();

        Assert.ok(
            initialLiveAuctions >= 0,
            "Initial live auctions should be >= 0"
        );

        Assert.ok(
            initialEndedAuctions >= 0,
            "Initial ended auctions should be >= 0"
        );

        Assert.equal(
            auction.getBalance(),
            uint256(2000000000000000000),
            "Initial contract balance should be 2 ether"
        );
    }

    function shouldListArtwork() public {
        uint256 initialLiveAuctions = auction.getNumberOfLiveAuctions();

        auction.listArtwork(
            "Artist A",
            "2023-01-01",
            "Oil",
            "50x50",
            1 ether,
            5 seconds
        );

        ArtworkAuction.Artwork memory artwork = auction.getArtwork(
            initialLiveAuctions + 1
        );
        Assert.equal(artwork.artistName, "Artist A", "Artwork listing failed.");
        Assert.equal(
            auction.getNumberOfLiveAuctions(),
            initialLiveAuctions + 1,
            "Live auctions count should have incremented by 1"
        );
    }

    function shouldAllowBidding() public payable {
        uint256 initialLiveAuctions = auction.getNumberOfLiveAuctions();

        auction.listArtwork(
            "Artist B",
            "2023-01-02",
            "Watercolor",
            "40x40",
            1 ether,
            5 seconds
        );

        Assert.equal(
            auction.getBalance(),
            uint256(10000000000000000000),
            "Initial contract balance should be 10"
        );

        auction.bid{value: 1.5 ether}(initialLiveAuctions + 1);
        ArtworkAuction.Artwork memory artwork = auction.getArtwork(
            initialLiveAuctions + 1
        );
        Assert.equal(artwork.currentBid, 1.5 ether, "Bid amount incorrect.");
    }

    function shouldEndExistingAuction() public {
        uint256 initialLiveAuctions = auction.getNumberOfLiveAuctions();
        uint256 initialEndedAuctions = auction.getNumberOfEndedAuctions();

        // Ensure there's at least one live auction to end
        require(initialLiveAuctions > 0, "No live auctions to end.");

        // End the last ongoing auction
        auction.endAuction(1);

        Assert.equal(
            auction.getNumberOfEndedAuctions(),
            initialEndedAuctions + 1,
            "Ended auctions count should have incremented by 1"
        );
    }

    function checkSenderAndValue() public payable {
        Assert.equal(msg.sender, TestsAccounts.getAccount(1), "Invalid sender");
        Assert.equal(msg.value, 100, "Invalid value");
    }

    function shouldUpdateArtwork() public {
        uint256 initialLiveAuctions = auction.getNumberOfLiveAuctions();
        auction.listArtwork(
            "Artist D",
            "2023-01-04",
            "Charcoal",
            "30x30",
            1 ether,
            7 days
        );
        auction.updateArtwork(
            initialLiveAuctions + 1,
            "Updated Artist",
            "2023-01-05",
            "Updated Medium",
            "60x60"
        );
        ArtworkAuction.Artwork memory artwork = auction.getArtwork(
            initialLiveAuctions + 1
        );
        Assert.equal(
            artwork.artistName,
            "Updated Artist",
            "Artwork update failed."
        );
    }

    function shouldUpdateAuction() public {
        uint256 initialLiveAuctions = auction.getNumberOfLiveAuctions();
        auction.listArtwork(
            "Artist E",
            "2023-01-06",
            "Pencil",
            "20x20",
            1 ether,
            7 days
        );
        auction.updateAuction(
            initialLiveAuctions + 1,
            block.timestamp + 10 days,
            2 ether
        );
        ArtworkAuction.Artwork memory artwork = auction.getArtwork(
            initialLiveAuctions + 1
        );
        Assert.equal(artwork.startingPrice, 2 ether, "Auction update failed.");
    }

    function shouldJoinAuctionWithInitialBid() public payable {
        uint256 initialLiveAuctions = auction.getNumberOfLiveAuctions();
        auction.listArtwork(
            "Artist F",
            "2023-01-07",
            "Pastel",
            "70x70",
            1 ether,
            7 days
        );
        auction.joinAuctionWithInitialBid{value: 1.5 ether}(
            initialLiveAuctions + 1
        );
        ArtworkAuction.Artwork memory artwork = auction.getArtwork(
            initialLiveAuctions + 1
        );
        Assert.equal(
            artwork.currentBid,
            1.5 ether,
            "Initial bid amount incorrect."
        );
    }

    function shouldRetrieveAllArtworks() public {
        uint256 initialCount = auction.getNumberOfLiveAuctions();
        auction.listArtwork(
            "Artist G",
            "2023-01-08",
            "Crayon",
            "80x80",
            1 ether,
            7 days
        );
        ArtworkAuction.Artwork[] memory allArtworks = auction.getAllArtworks();
        Assert.equal(
            allArtworks.length,
            initialCount + 1,
            "Artwork retrieval failed."
        );
    }
}
