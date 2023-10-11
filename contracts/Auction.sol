// SPDX-License-Identifier: MIT
pragma solidity ^0.8.21; //This specifies the version of the Solidity compiler that should be used.

//Imports the Counters library from the OpenZeppelin library, which provides a simple counter mechanism.
import "@openzeppelin/contracts/utils/Counters.sol";

contract ArtworkAuction {
    //Stored in Storage
    //persistent between function calls and transactions.
    //Changes are very costly in terms of gas.

    using Counters for Counters.Counter;
    Counters.Counter private _artworkCounter;
    Counters.Counter private _liveAuctions;
    Counters.Counter private _endedAuctions;

    struct Artwork {
        uint256 id;
        address payable owner;
        string artistName;
        string creationDate;
        string medium;
        string dimensions;
        uint256 startingPrice;
        uint256 currentBid;
        address payable highestBidder;
        uint256 auctionEndTime;
        bool auctionEnded;
    }

    //A mapping that associates each artwork's ID to its details.
    mapping(uint256 => Artwork) public artworks;
    uint256[] public artworkIds;

    //Events are used to log specific changes in the contract state. They are essential for dApps to react to contract state changes.
    //which in turn can be used to “call” JavaScript callbacks in the user interface of a dApp, which listen for these events.
    event ArtworkListed(
        uint256 indexed artworkId,
        string artistName,
        string creationDate,
        uint256 startingPrice
    );
    event ArtworkUpdated(uint256 indexed artworkId);
    event AuctionUpdated(
        uint256 indexed artworkId,
        uint256 newEndTime,
        uint256 newStartingPrice
    );
    event NewBid(
        uint256 indexed artworkId,
        address indexed bidder,
        uint256 amount
    );
    event AuctionEnded(
        uint256 indexed artworkId,
        address winner,
        uint256 winningBid
    );

    function getBalance() public view returns (uint256) {
        return address(this).balance;
    }

    //A special function without a name that gets executed when sending Ether to the contract without any other data.
    receive() external payable {}

    //fallback() external payable {}

    //Allows a user to list an artwork for auction by providing the necessary details.
    //_artistName - _creationDate - medium - dimensions: memory
    // startingPrice - _auctionDuration in stack
    function listArtwork(
        string memory _artistName,
        string memory _creationDate,
        string memory _medium,
        string memory _dimensions,
        uint256 _startingPrice,
        uint256 _auctionDuration
    ) external {
        _artworkCounter.increment();
        uint256 artworkId = _artworkCounter.current();

        artworks[artworkId] = Artwork({
            id: artworkId,
            owner: payable(msg.sender),
            artistName: _artistName,
            creationDate: _creationDate,
            medium: _medium,
            dimensions: _dimensions,
            startingPrice: _startingPrice,
            currentBid: 0,
            highestBidder: payable(address(0)),
            auctionEndTime: block.timestamp + _auctionDuration,
            auctionEnded: false
        });

        artworkIds.push(artworkId);
        _liveAuctions.increment();
        //trigger  event. When event is "emitted", it gets logged in the transaction log,
        //which can then be read from off-chain applications.
        emit ArtworkListed(
            artworkId,
            _artistName,
            _creationDate,
            _startingPrice
        );
    }

    //_artworkId in stack

    function updateArtwork(
        uint256 _artworkId,
        string memory _artistName,
        string memory _creationDate,
        string memory _medium,
        string memory _dimensions
    ) external {
        //Memory - erased between function calls - cheaper than storage
        Artwork storage artwork = artworks[_artworkId];
        require(
            msg.sender == artwork.owner,
            "Only the owner can update the artwork details."
        );

        artwork.artistName = _artistName;
        artwork.creationDate = _creationDate;
        artwork.medium = _medium;
        artwork.dimensions = _dimensions;
        //trigger  event. When event is "emitted", it gets logged in the transaction log,
        //which can then be read from off-chain applications.
        emit ArtworkUpdated(_artworkId);
    }

    //_artworkId in stack

    function updateAuction(
        uint256 _artworkId,
        uint256 _newEndTime,
        uint256 _newStartingPrice
    ) external {
        //Memory - erased between function calls - cheaper than storage
        Artwork storage artwork = artworks[_artworkId];
        require(
            msg.sender == artwork.owner,
            "Only the owner can update the auction details."
        );

        artwork.auctionEndTime = _newEndTime;
        artwork.startingPrice = _newStartingPrice;
        //trigger  event. When event is "emitted", it gets logged in the transaction log,
        //which can then be read from off-chain applications.
        emit AuctionUpdated(_artworkId, _newEndTime, _newStartingPrice);
    }

    //_artworkId in stack
    function joinAuctionWithInitialBid(uint256 _artworkId) external payable {
        //Memory - erased between function calls - cheaper than storage
        Artwork storage artwork = artworks[_artworkId];

        require(block.timestamp < artwork.auctionEndTime, "Auction has ended.");
        require(
            msg.value >= artwork.startingPrice,
            "Initial bid is below the starting price."
        );

        if (artwork.highestBidder != address(0)) {
            // Refund the previous highest bidder
            artwork.highestBidder.transfer(artwork.currentBid);
        }

        artwork.currentBid = msg.value;
        artwork.highestBidder = payable(msg.sender);
        //trigger  event. When event is "emitted", it gets logged in the transaction log,
        //which can then be read from off-chain applications.
        emit NewBid(_artworkId, msg.sender, msg.value);
    }

    function bid(uint256 _artworkId) external payable {
        //Memory - erased between function calls - cheaper than storage

        Artwork storage artwork = artworks[_artworkId];

        require(block.timestamp < artwork.auctionEndTime, "Auction has ended.");
        require(msg.value > artwork.currentBid, "Bid is not high enough.");

        if (artwork.highestBidder != address(0)) {
            // Refund the previous highest bidder
            artwork.highestBidder.transfer(artwork.currentBid);
        }

        artwork.currentBid = msg.value;
        artwork.highestBidder = payable(msg.sender);
        //trigger  event. When event is "emitted", it gets logged in the transaction log,
        //which can then be read from off-chain applications.
        emit NewBid(_artworkId, msg.sender, msg.value);
    }

    function endAuction(uint256 _artworkId) external {
        //Memory - erased between function calls - cheaper than storage
        Artwork storage artwork = artworks[_artworkId];

        require(
            msg.sender == artwork.owner,
            "Only the owner can end the auction."
        );
        require(
            block.timestamp >= artwork.auctionEndTime,
            "Auction is still ongoing."
        );
        require(!artwork.auctionEnded, "Auction has already ended.");

        artwork.auctionEnded = true;
        artwork.owner.transfer(artwork.currentBid);

        _liveAuctions.decrement();
        _endedAuctions.increment();

        //trigger  event. When event is "emitted", it gets logged in the transaction log,
        //which can then be read from off-chain applications.
        emit AuctionEnded(
            _artworkId,
            artwork.highestBidder,
            artwork.currentBid
        );
    }

    function getAllArtworks() external view returns (Artwork[] memory) {
        Artwork[] memory allArtworks = new Artwork[](artworkIds.length);
        for (uint256 i = 0; i < artworkIds.length; i++) {
            allArtworks[i] = artworks[artworkIds[i]];
        }
        return allArtworks;
    }

    function getNumberOfLiveAuctions() external view returns (uint256) {
        return _liveAuctions.current();
    }

    function getNumberOfEndedAuctions() external view returns (uint256) {
        return _endedAuctions.current();
    }

    function getArtwork(uint256 _id) public view returns (Artwork memory) {
        return artworks[_id];
    }
}
