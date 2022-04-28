//SPDX-License-Identifier: UNLICENSED








//             ▄▀▀▄▀▀▀▄  ▄▀▀█▄▄▄▄  ▄▀▀▄▀▀▀▄  ▄▀▀▀█▀▀▄  ▄▀▀█▀▄    ▄▀▀▄ █  ▄▀▀█▄   ▄▀▀▀▀▄             
//            █   █   █ ▐  ▄▀   ▐ █   █   █ █    █  ▐ █   █  █  █  █ ▄▀ ▐ ▄▀ ▀▄ █ █   ▐             
//            ▐  █▀▀█▀    █▄▄▄▄▄  ▐  █▀▀▀▀  ▐   █     ▐   █  ▐  ▐  █▀▄    █▄▄▄█    ▀▄               
//             ▄▀    █    █    ▌     █         █          █       █   █  ▄▀   █ ▀▄   █              
//            █     █    ▄▀▄▄▄▄    ▄▀        ▄▀        ▄▀▀▀▀▀▄  ▄▀   █  █   ▄▀   █▀▀▀               
//            ▐     ▐    █    ▐   █         █         █       █ █    ▐  ▐   ▐    ▐                  
//                       ▐        ▐         ▐         ▐       ▐ ▐                                   
// ▄▀▄▄▄▄   ▄▀▀▀▀▄   ▄▀▀▀▀▄    ▄▀▀▀▀▄     ▄▀▀█▄▄▄▄  ▄▀▄▄▄▄   ▄▀▀▀█▀▀▄  ▄▀▀█▀▄   ▄▀▀▄ ▄▀▀▄  ▄▀▀█▄▄▄▄ 
//█ █    ▌ █      █ █    █    █    █     ▐  ▄▀   ▐ █ █    ▌ █    █  ▐ █   █  █ █   █    █ ▐  ▄▀   ▐ 
//▐ █      █      █ ▐    █    ▐    █       █▄▄▄▄▄  ▐ █      ▐   █     ▐   █  ▐ ▐  █    █    █▄▄▄▄▄  
//  █      ▀▄    ▄▀     █         █        █    ▌    █         █          █       █   ▄▀    █    ▌  
// ▄▀▄▄▄▄▀   ▀▀▀▀     ▄▀▄▄▄▄▄▄▀ ▄▀▄▄▄▄▄▄▀ ▄▀▄▄▄▄    ▄▀▄▄▄▄▀  ▄▀        ▄▀▀▀▀▀▄     ▀▄▀     ▄▀▄▄▄▄   
//█     ▐             █         █         █    ▐   █     ▐  █         █       █            █    ▐   
//▐                   ▐         ▐         ▐        ▐        ▐         ▐       ▐            ▐    

pragma solidity ^0.8.0;








contract Reptikas_Collective is ERC721, Ownable, ReentrancyGuard{
  using Counters for Counters.Counter;
  using Strings for uint256;

  Counters.Counter private supply;
  string public uriPrefix = "";
  string public uriSuffix = ".json";

  bool public saleIsActive;
  bool public presaleIsActive;

    uint256 public constant WHITELIST_SALE_PRICE = 0.02 ether;
    uint256 public constant PUBLIC_SALE_PRICE = 0.03 ether;
    uint256 public maxSupplyPlusOne = 6667;

    // used to validate whitelists
    bytes32 public giftMerkleRoot;
    bytes32 public whitelistMerkleRoot;

    // keep track of those on whitelist who have claimed their NFT
    mapping(address => bool) public claimed;
    mapping(address => bool) public giftclaimed;

    constructor() ERC721("Reptikas Collective", "RPTKA") {
    _mintLoop(msg.sender, 35);
    saleIsActive = false;
    presaleIsActive = false;
    }


    modifier isValidMerkleProof(bytes32[] calldata merkleProof, bytes32 root) {
        require(
            MerkleProof.verify(
                merkleProof,
                root,
                keccak256(abi.encodePacked(msg.sender))
            ),
            "Address does not exist in list"
        );
        _;
    }

    modifier isCorrectPayment(uint256 price, uint256 numberOfTokens) {
        require(
            price * numberOfTokens == msg.value,
            "Incorrect ETH value sent"
        );
        _;
    }

    modifier canMint(uint256 numberOfTokens) {
        require(supply.current() + 1 < maxSupplyPlusOne, "Max supply exceeded!");
        _;
    }

    function mintGift(
        bytes32[] calldata merkleProof
    )
        public
        isValidMerkleProof(merkleProof, giftMerkleRoot)
        nonReentrant
    {
      require(!giftclaimed[msg.sender], "NFT is already claimed by this wallet");
      require(presaleIsActive == true, "Pre-sale is not active");
    _mintLoop(msg.sender, 1);
    giftclaimed[msg.sender] = true;
    }

    function mintWhitelist(
      bytes32[] calldata merkleProof
    )
        public
        payable
        isValidMerkleProof(merkleProof, whitelistMerkleRoot)
        isCorrectPayment(WHITELIST_SALE_PRICE, 1)
        nonReentrant
    {
        require(!claimed[msg.sender], "NFT is already claimed by this wallet");
        require(presaleIsActive == true, "Pre-sale is not active");
        _mintLoop(msg.sender, 1);
        claimed[msg.sender] = true;
    }

    function publicMint(
      uint256 numberOfTokens
    )
        public
        payable
        isCorrectPayment(PUBLIC_SALE_PRICE, numberOfTokens)
        canMint(numberOfTokens)
        nonReentrant
    {
        require(saleIsActive == true, "Sale is not active");
        for (uint256 i = 0; i < numberOfTokens; i++) {
        _mintLoop(msg.sender, numberOfTokens);
        }
    }

  function setSale(bool newState) public onlyOwner {
    saleIsActive = newState;
  }

  function setPreSale(bool newState) public onlyOwner {
    presaleIsActive = newState;
  }

  function totalSupply() public view returns (uint256) {
    return supply.current();
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

  function _baseURI() internal view virtual override returns (string memory) {
    return uriPrefix;
  }

   function setUriPrefix(string memory _uriPrefix) public onlyOwner {
    uriPrefix = _uriPrefix;
  }

  function setUriSuffix(string memory _uriSuffix) public onlyOwner {
    uriSuffix = _uriSuffix;
  }

    function setGiftMerkleRoot(bytes32 merkleRoot) external onlyOwner {
        giftMerkleRoot = merkleRoot;
    }

    function setWhitelistMerkleRoot(bytes32 merkleRoot) external onlyOwner {
        whitelistMerkleRoot = merkleRoot;
    }

  function _mintLoop(address _receiver, uint256 _mintAmount) internal {
    for (uint256 i = 0; i < _mintAmount; i++) {
      supply.increment();
      _safeMint(_receiver, supply.current());
    }
  }

  function withdraw() public onlyOwner {
 //pays treasury 75%
    (bool hs, ) = payable(0xd5A44EF877A5ff62f234aC016456B51e7C2bFf54).call{value: address(this).balance * 75 / 100}("");
    require(hs);
//pays owner 25%
    (bool os, ) = payable(owner()).call{value: address(this).balance}("");
    require(os);
  }
}
