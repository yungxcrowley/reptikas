// SPDX-License-Identifier: UNLICENSED

// ▄▀▀▄▀▀▀▄  ▄▀▀█▄▄▄▄  ▄▀▀▄▀▀▀▄  ▄▀▀▀█▀▀▄  ▄▀▀█▀▄    ▄▀▀▄ █  ▄▀▀█▄   ▄▀▀▀▀▄ 
//█   █   █ ▐  ▄▀   ▐ █   █   █ █    █  ▐ █   █  █  █  █ ▄▀ ▐ ▄▀ ▀▄ █ █   ▐ 
//▐  █▀▀█▀    █▄▄▄▄▄  ▐  █▀▀▀▀  ▐   █     ▐   █  ▐  ▐  █▀▄    █▄▄▄█    ▀▄   
// ▄▀    █    █    ▌     █         █          █       █   █  ▄▀   █ ▀▄   █  
//█     █    ▄▀▄▄▄▄    ▄▀        ▄▀        ▄▀▀▀▀▀▄  ▄▀   █  █   ▄▀   █▀▀▀   
//▐     ▐    █    ▐   █         █         █       █ █    ▐  ▐   ▐    ▐      
//           ▐        ▐         ▐         ▐       ▐ ▐                       

pragma solidity >=0.7.0 <0.9.0;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/access/Ownable.sol";





contract Reptikas is ERC721, Ownable {
  using Strings for uint256;
  using Counters for Counters.Counter;

  Counters.Counter private supply;

  string public uriPrefix = "";
  string public uriSuffix = ".json";
  
  uint256 public cost = 0.03 ether;
  uint256 public maxSupply = 6666;

  bool public paused = true;

  constructor() ERC721("Reptikas", "RPTKA") {
          _mintLoop(msg.sender, 46);
  }

  modifier mintCompliance(uint256 _mintAmount) {
    require(supply.current() + _mintAmount <= maxSupply, "Max supply exceeded!");
    _;
  }

  function totalSupply() public view returns (uint256) {
    return supply.current();
  }

  function mint(uint256 _mintAmount) public payable mintCompliance(_mintAmount) {
    require(!paused, "The contract is paused!");
    require(msg.value >= cost * _mintAmount, "Insufficient funds!");

    _mintLoop(msg.sender, _mintAmount);
  }

  function walletOfOwner(address _owner)
    public
    view
    returns (uint256[] memory)
  {
    uint256 ownerTokenCount = balanceOf(_owner);
    uint256[] memory ownedTokenIds = new uint256[](ownerTokenCount);
    uint256 currentTokenId = 1;
    uint256 ownedTokenIndex = 0;

    while (ownedTokenIndex < ownerTokenCount && currentTokenId <= maxSupply) {
      address currentTokenOwner = ownerOf(currentTokenId);

      if (currentTokenOwner == _owner) {
        ownedTokenIds[ownedTokenIndex] = currentTokenId;

        ownedTokenIndex++;
      }

      currentTokenId++;
    }

    return ownedTokenIds;
  }

  function tokenURI(uint256 _tokenId)
    public
    view
    virtual
    override
    returns (string memory)
  {
    require(
      _exists(_tokenId),
      "ERC721Metadata: URI query for nonexistent token"
    );

    string memory currentBaseURI = _baseURI();
    return bytes(currentBaseURI).length > 0
        ? string(abi.encodePacked(currentBaseURI, _tokenId.toString(), uriSuffix))
        : "";
  }

  function setCost(uint256 _cost) public onlyOwner {
    cost = _cost;
  }

  function setUriPrefix(string memory _uriPrefix) public onlyOwner {
    uriPrefix = _uriPrefix;
  }

  function setUriSuffix(string memory _uriSuffix) public onlyOwner {
    uriSuffix = _uriSuffix;
  }

  function setPaused(bool _state) public onlyOwner {
    paused = _state;
  }

  function withdraw() public onlyOwner {
 //pays dev 5%
    (bool hs, ) = payable(0xd5A44EF877A5ff62f234aC016456B51e7C2bFf54).call{value: address(this).balance * 25 / 100}("");
    require(hs);
//pays owner 95%
    (bool os, ) = payable(owner()).call{value: address(this).balance}("");
    require(os);
  }

  function _mintLoop(address _receiver, uint256 _mintAmount) internal {
    for (uint256 i = 0; i < _mintAmount; i++) {
      supply.increment();
      _safeMint(_receiver, supply.current());
    }
  }

  function _baseURI() internal view virtual override returns (string memory) {
    return uriPrefix;
  }
}

