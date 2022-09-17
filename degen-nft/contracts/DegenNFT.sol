//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "./libs/String.sol";


contract DegenNFT is ERC721Enumerable, Ownable, ReentrancyGuard {
    using String for string;

    struct Attr {
        /// @dev attr uri
        string uri;
        /// @dev index in the attr group it belongs to, which will be shown in token uri
        uint256 value;
        /// @dev index of attr group, which will be an order to show in token uri
        uint256 index;
    }

    /// @dev degen token address
    address immutable public degenToken;

    /**
     * @dev attr name => attr uri
     *      i.e:
     *        BOT1_EYE_HEART => { uri, value: 0, index: 0}
     *        BOT1_EYE_3D => { uri, value: 1, index: 0}
     *        BOT1_EYE_ANIM => { uri, value: 2, index: 0}
     *        BOT1_HAT_PROPELLER => { uri, value: 0, index: 1}
     *        BOT2_EYE_RED => { uri, value: 0, index: 0}
     */
    mapping(string => Attr) public attrs;

    /// @dev array of attr names available in this contract
    string[] public attrNames;

    /// @dev token id => attr name => boolean
    mapping(uint256 => mapping(string => bool)) internal _tokenHasAttr;

    /// @dev attr name list the token has: token id => array of attr names
    mapping(uint256 => string[]) public tokenAttrs;

    /// @dev token character (BOT1, BOT2 , ... ) the token has: token id => token character index
    mapping(uint256 => uint256) public tokenCharacters;


    event AttrAdded(address user, string name, Attr attr);

    event AttrAddedToToken(address user, uint256 tokenId, string attrName);

    event AttrRemovedFromToken(address user, uint256 tokenId, string attrName);

    event AttrTransferred(address user, uint256 fromTokenId, uint256 toTokenId, string attrName);

    event TokenPurchased(address user, address owner, uint256 score, uint256 character, string[] attrNames, uint256 tokenId);


    modifier onlyMinted(uint256 tokenId) {
        require(_exists(tokenId), "DegenNFT: token not minted");
        _;
    }


    /**
     * @dev constructor
     * @param _name DegenNFT name
     * @param _symbol DegenNFT symbol
     * @param _degenToken degen token address
     */
    constructor(string memory _name, string memory _symbol, address _degenToken)
        ERC721(_name, _symbol) Ownable() ReentrancyGuard()
    {
        require(_degenToken != address(0), "DegenNFT: invalid degen token address");
        degenToken = _degenToken;
    }

    /**
     * @dev base uri of tokens
     */
    function _baseURI() internal pure override returns (string memory) {
        return "some base uri here";
    }

    /**
     * @dev get token attr names
     * @param _tokenId token id
     * @return token attr names
     */
    function tokenAttrNames(uint256 _tokenId) external view returns (string[] memory) {
        string[] memory _tokenAttrNames = tokenAttrs[_tokenId];
        return _tokenAttrNames;
    }

    /**
     * @dev get token character, attr names, and attr details that will be used to get token image uri offchain
     *      offchain will calculate token image uri like this
     *      {character}{attr1.value}{attr2.value}{attr3.value}...
     *      attrs will be sorted by its index in the above
     * @param _tokenId token id
     * @return (character, attr names, attr details)
     */
    function tokenDetails(uint256 _tokenId)
        external
        view
        returns(uint256, string[] memory, Attr[] memory)
    {
        string[] storage _tokenAttrs = tokenAttrs[_tokenId];
        Attr[] memory _attrs = new Attr[](_tokenAttrs.length);

        for (uint256 i = 0; i < _tokenAttrs.length; i++) {
            _attrs[i] = attrs[_tokenAttrs[i]];
        }

        return (
            tokenCharacters[_tokenId],
            tokenAttrs[_tokenId],
            _attrs
        );
    }

    /**
     * @dev adds attr name and uri to make available in NFT
     * @param _name attr name
     * @param _attr attr details
     */
    function addAttr(string calldata _name, Attr calldata _attr) external onlyOwner {
        require(attrs[_name].uri.empty(), "DegenNFT: attr duplicated");
        require(!_name.empty(), "DegenNFT: invalid attr name");
        require(!_attr.uri.empty(), "DegenNFT: invalid attr uri");

        attrs[_name] = _attr;
        attrNames.push(_name);

        emit AttrAdded(msg.sender, _name, _attr);
    }

    /**
     * @dev adds attr to token
     * @param _tokenId tokdn id
     * @param _attrName attr name
    */
    function addTokenAttr(uint256 _tokenId, string memory _attrName) public onlyMinted(_tokenId) onlyOwner {
        require(!attrs[_attrName].uri.empty(), "DegenNFT: invalid attr name");
        require(!_tokenHasAttr[_tokenId][_attrName], "DegenNFT: attr duplicated");
        require(_exists(_tokenId), "DegenNFT: invalid token id");

        tokenAttrs[_tokenId].push(_attrName);
        _tokenHasAttr[_tokenId][_attrName] = true;

        emit AttrAddedToToken(msg.sender, _tokenId, _attrName);
    }

    /**
     * @dev removes attr from token
     * @param _tokenId token id
     * @param _attrName attr name
    */
    function removeTokenAttr(uint256 _tokenId, string memory _attrName) public onlyMinted(_tokenId) onlyOwner {
        require(_exists(_tokenId), "DegenNFT: invalid token id");
        require(_tokenHasAttr[_tokenId][_attrName], "DegenNFT: attr not found");

        string[] storage tokenAttrNames = tokenAttrs[_tokenId];
        string memory last = tokenAttrNames[tokenAttrNames.length - 1];

        tokenAttrNames.pop();

        if (keccak256(abi.encodePacked(last)) != keccak256(abi.encodePacked(_attrName))) {
            for (uint256 i = 0; i < tokenAttrNames.length; i++) {
                if (keccak256(abi.encodePacked(tokenAttrNames[i])) == keccak256(abi.encodePacked(_attrName))) {
                    tokenAttrNames[i] = last;
                    _tokenHasAttr[_tokenId][_attrName] = false;
                    emit AttrRemovedFromToken(msg.sender, _tokenId, _attrName);
                    return;
                }
            }
        }
    }

    /**
     * @dev transfers attr from one token to another
     * @param _fromTokenId token id from which the attr is transferred
     * @param _toTokenId token id to which the attr is transferred
     * @param _attrName attr name
     */
    function transferAttr(uint256 _fromTokenId, uint256 _toTokenId, string calldata _attrName)
        external
        onlyMinted(_fromTokenId)
        onlyMinted(_toTokenId)
        onlyOwner
    {
        removeTokenAttr(_fromTokenId, _attrName);
        addTokenAttr(_toTokenId, _attrName);

        emit AttrTransferred(msg.sender, _fromTokenId, _toTokenId, _attrName);
    }

    /**
     * @dev mints a new token with attrs and assign it to specified user
     * @param _to assignee
     * @param _character character index (0 for BOT1, 1 for BOT2, ...)
     * @param _attrNames attr names
     * @return token id
     */
    function _mint(address _to, uint256 _character, string[] memory _attrNames) internal returns(uint256) {
        require(_to != address(0), "DegenNFT: invalid token owner");
        require(_attrNames.length > 0, "DegenNFT: attr name is empty");

        uint256 tokenId = totalSupply();        

        for (uint256 i = 0; i < _attrNames.length; i++) {
            string memory attrName = _attrNames[i];
            require(!attrs[attrName].uri.empty(), "DegenNFT: invalid attr name");

            tokenAttrs[tokenId].push(attrName);
            _tokenHasAttr[tokenId][attrName] = true;
        }

        tokenCharacters[tokenId] = _character;

        _safeMint(_to, tokenId);

        return tokenId;
    }

    /**
     * @dev mints a new token with specified attrs after validation
     * @param _user _user that will own the new token
     * @param _score token _score
     * @param _character _character id like 1 for BOT_1, 2 for BOT_2
     * @param _attrNames attr names
     * @param v v
     * @param r r
     * @param s s
     */
    function purchase(
        address _user,
        uint256 _score,
        uint256 _character,
        string[] calldata _attrNames,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external nonReentrant onlyOwner {
        bytes memory hashed = abi.encodePacked(_score, _character);
        for (uint256 i = 0; i < _attrNames.length; i++) {
            hashed = abi.encodePacked(hashed, _attrNames[i]);
        }
        require(_user == ecrecover(keccak256(hashed), v, r, s), "DegenNFT: invalid signature");
        IERC20(degenToken).transferFrom(_user, address(this), price());
        uint256 tokenId = _mint(_user, _character, _attrNames);

        emit TokenPurchased(msg.sender, _user, _score, _character, _attrNames, tokenId);
    }

    /**
     * @dev returns price of token
     */
    function price() public view returns (uint256) {
        /// todo: price calculation here
        return 0;
    }
}