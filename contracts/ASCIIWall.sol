// SPDX-License-Identifier: MIT
pragma solidity ^0.8.2;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

import "./Base64.sol";

contract ASCIIWall is ERC721, ERC721Enumerable, Pausable, Ownable {
    using Counters for Counters.Counter;

    Counters.Counter private _tokenIdCounter;
    int public constant MAX_LINE_COUNT = 18;
    int public constant MAX_LINE_LENGTH = 41;
    uint public constant TEXT_LINE_HEIGHT = 16;
    uint public constant MAX_TOKEN_COUNT = 100;
    uint256 public constant TOKEN_COST = 25000000000000000;
    address public constant DEPOSIT_ADDRESS = 0x095f1fD53A56C01c76A2a56B7273995Ce915d8C4;
    string public PROJECT_DESCRIPTION = "Death is only the beginning";

    struct WordPlacement {
        string color;
        string message;
        int line;
        int offset;
    }

    WordPlacement[] public  wordPlacements;

    constructor() ERC721("ASCIIWall", "ASC") {}

    function _baseURI() internal pure override returns (string memory) {
        return "https://j4.is/foo/";
    }

    function pause() public onlyOwner {
        _pause();
    }

    function unpause() public onlyOwner {
        _unpause();
    }


    function safeMint(address to, string memory wordColor, string memory message, int line, int offset) public payable {
        require(offset >= 0, "The offset must be zero or positive");
        require(line >= 0, "The line number must be zero or positive");
        require(offset + int(bytes(message).length) <= MAX_LINE_LENGTH, "Message with offset is too long");
        require(isValidColor(wordColor), "The color needs to be a valid HEX string like #012ABC");
        require(isValidMessage(message), "The message contains an invalid character (&'\"#<>)");
        require(line < MAX_LINE_COUNT, "The line number is too high");
        require(this.totalSupply() < MAX_TOKEN_COUNT, "The supply has been exhausted.");
        require(msg.value >= TOKEN_COST, "Value below price");
        require(address(msg.sender).balance > TOKEN_COST, "Not enough ETH!");
        address payable p = payable(DEPOSIT_ADDRESS);
        p.transfer(TOKEN_COST);

        uint256 tokenId = _tokenIdCounter.current();
        _tokenIdCounter.increment();
        _safeMint(to, tokenId);

        wordPlacements.push(WordPlacement({
                color: wordColor,
                message: message,
                line: line,
                offset: offset
                }));
    }

    function _beforeTokenTransfer(address from, address to, uint256 tokenId)
        internal
        whenNotPaused
        override(ERC721, ERC721Enumerable)
    {
        super._beforeTokenTransfer(from, to, tokenId);
    }

    // The following functions are overrides required by Solidity.
    function supportsInterface(bytes4 interfaceId)
        public
        view
        override(ERC721, ERC721Enumerable)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }

    function isValidColor(string memory color) public pure returns(bool) {
        bytes memory b = bytes(color);
        if(b.length != 7) {
            return false;
        }

        if (b[0] != 0x23) {
            return false;
        }

        for(uint i = 1; i < 7; i++){
            bytes1 char = b[i];
            if(
               !(char >= 0x30 && char <= 0x39) && // 9-0
               !(char >= 0x41 && char <= 0x46) && // A-F
               !(char >= 0x61 && char <= 0x66) // a-f
               ){
                return false;
            }
        }

        return true;
    }
    function isValidMessage(string memory message) public pure returns(bool) {
        bytes memory b = bytes(message);
        for(uint i = 0; i < b.length; i++){
            bytes1 char = b[i];
            if(
               !(char >= 0x20 && char <= 0x21) && // [ !]
               !(char >= 0x23 && char <= 0x25) && // [#$%]
               !(char >= 0x28 && char <= 0x3B) && // [(-;]
               !(char >= 0x3F && char <= 0x7E) && // [?-~]
               char != 0x3D // =
               ){
                return false;
            }
        }
        return true;
    }

    function renderForIndex(uint256 idx) public view returns (string memory) {
        require(idx < wordPlacements.length, "Can't render for a placement that doesn't exist yet");
        string memory foo = "<svg version=\"1.1\" width=\"297\" height=\"292\" xmlns=\"http://www.w3.org/2000/svg\"><rect width=\"100%\" height=\"100%\" fill=\"black\" /><style> text { font-family: monospace; font-size: 12px;} </style>";

        for(uint i = 0; i <= idx && i < wordPlacements.length; i = i + 1) {
            WordPlacement memory wp = wordPlacements[i];
            foo = string(abi.encodePacked(foo, abi.encodePacked("<text fill=\"", wp.color, "\" y=\"", Strings.toString(TEXT_LINE_HEIGHT * uint(wp.line) + TEXT_LINE_HEIGHT), "\">", wp.message , "</text>")));
        }
        foo = string(abi.encodePacked(foo,  "</svg>"));
        return foo;
    }

    function tokenURI(uint tokenId) public view override(ERC721) returns (string memory) {
        require(_exists(tokenId), "ERC721Metadata: URI query for nonexistent token");
        bytes memory svg = bytes(renderForIndex(tokenId));

        bytes memory json = abi.encodePacked( "{\"name\": \"ASCII Wall #", Strings.toString(tokenId), "\", \"description\": \"", PROJECT_DESCRIPTION, "\", \"image\": \"data:image/svg+xml;base64,", Base64.encode(svg), "\"}");
                                                      
        return string(abi.encodePacked("data:application/json;base64,", Base64.encode(json)));
    }

}

