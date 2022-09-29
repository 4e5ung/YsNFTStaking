// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import './token/ERC721/extensions/IERC721Enumerable.sol';
import "./token/ERC721/IERC721Receiver.sol";
import './token/ERC721/IERC721.sol';
import './token/ERC20/IERC20.sol';
import "./security/ReentrancyGuard.sol";


/// @dev This is a nft staking contract
contract NFTStaking is IERC721Receiver, ReentrancyGuard{
    
    address private admin;
    address private rewardToken;
    address private nftContract;

    uint256 private startTimestamp;
    uint256 private bonusEndTimestamp;

    uint256 public totalStakeBalance;

    
    mapping(uint8=>StakeOptions) private options;
    mapping(uint256=>uint8) private tokenIdToLevel;

    mapping(uint256=>userStakeInfo) private userStake;


    struct StakeOptions{
        uint256 rewardPerSecond;
        uint256 accReward;
        uint256 lastRewardTimestamp;
        uint256 lockupSecond;
    }

    struct NftLevelInfo{
        uint8 level;
        uint256 tokenId;
    }

    struct userStakeInfo{
        address user;
        uint256 startTimestamp;
        uint256 rewardDebt;
        uint256 accRewardDebt;
        uint256 lockupTimestamp;
    }


    event Stake(address indexed sender, uint256 tokenId);
    event UnStake(address indexed sender, uint256 tokenId);
    event Claim(address indexed sender, uint256 amount);


    modifier onlyAdmin(){
         require(admin == msg.sender, "NFTStaking: E01");
        _;
    }

    /// @dev Address setting constructor.
    /// @param _admin minter admin eoa
    /// @param _rewardToken erc20 address
    /// @param _nftContract nft address
    /// @param _startTimestamp start rewardtime
    /// @param _bonusEndTimestamp end reward time
    constructor(
        address _admin, 
        address _rewardToken, 
        address _nftContract,
        uint256 _startTimestamp,
        uint256 _bonusEndTimestamp
    ) {
        admin = _admin;
        rewardToken = _rewardToken;
        nftContract = _nftContract;
        startTimestamp = _startTimestamp;
        bonusEndTimestamp = _bonusEndTimestamp;

        IERC20(_rewardToken).approve(address(this), type(uint256).max);
	}

    /// @dev Set Staking options
    /// @param _nftLevel nft Level
    /// @param _rewardPerSecond rewardPerSecond token
    /// @param _lockupSecond minimum lockup period
    function setStakingOption(uint8 _nftLevel, uint256 _rewardPerSecond, uint256 _lockupSecond) external onlyAdmin{

        _updatePool(_nftLevel);

        options[_nftLevel].rewardPerSecond = _rewardPerSecond;
        options[_nftLevel].lockupSecond = _lockupSecond;
    }

    /// @dev Address setting.
    /// @param _admin minter admin eoa
    /// @param _rewardToken erc20 address
    /// @param _nftContract nft address
    function setAddress(address _admin, address _rewardToken, address _nftContract) external onlyAdmin{
        admin = _admin;
        rewardToken = _rewardToken;
        nftContract = _nftContract;
    }


    /// @dev import NftTokenIdToLevel
    /// @param _nftInfo NftLevelInfo struct
    function setNftLevel(bytes memory _nftInfo) external onlyAdmin{
        (NftLevelInfo[] memory nftInfo ) = abi.decode(_nftInfo, (NftLevelInfo[]));

        for( uint256 i = 0; i < nftInfo.length; i++ ){
            tokenIdToLevel[nftInfo[i].tokenId] = nftInfo[i].level;
        }
    }


    /// @dev nftStaking
    /// @param _tokenIds staking to tokenIds
    function nftStaking(uint256[] calldata _tokenIds) nonReentrant external {
        for( uint256 i = 0; i < _tokenIds.length; i++ ){
            uint256 tokenId = _tokenIds[i];
            address owner = IERC721(nftContract).ownerOf(tokenId);
            require(owner == msg.sender, "NFTStaking: E02");

            IERC721(nftContract).transferFrom(msg.sender, address(this), tokenId);

            uint8 tokenLevel = tokenIdToLevel[tokenId];
            StakeOptions memory stakeOption = options[tokenLevel];
            userStake[tokenId] = userStakeInfo(msg.sender, block.timestamp, 0, 0, stakeOption.lockupSecond+block.timestamp);
            totalStakeBalance++;
            
            _updatePool(tokenLevel);
            userStake[tokenId].rewardDebt = options[tokenLevel].accReward;

            emit Stake(msg.sender, tokenId);
        }
    }


    /// @dev nftUnStaking
    /// @param _tokenIds unstaking to tokenIds
    function nftUnStaking(uint256[] calldata _tokenIds) nonReentrant external {
        for( uint256 i = 0; i < _tokenIds.length; i++ ){
            uint256 tokenId = _tokenIds[i];
            address owner = userStake[tokenId].user;
            require(owner == msg.sender, "NFTStaking: E02");


            require( userStake[tokenId].lockupTimestamp <= block.timestamp, "NFTStaking: E03" );

            uint8 tokenLevel = tokenIdToLevel[tokenId];
            _updatePool(tokenLevel);

            _claimReward(tokenId);

            IERC721(nftContract).transferFrom(address(this), msg.sender, tokenId);
            totalStakeBalance--;

            delete userStake[tokenId];

            emit UnStake(msg.sender, tokenId);
        }
    }

    
    /// @dev claimRewards
    /// @param _tokenIds tokensId of claim
    function claimRewards(uint256[] calldata _tokenIds) nonReentrant external {
        for( uint256 i = 0; i < _tokenIds.length; i++ ){
            uint256 tokenId = _tokenIds[i];
            address owner = userStake[tokenId].user;
            require(owner == msg.sender, "NFTStaking: E02");

            _claimReward(tokenId);
        }
    }

    /// @dev _claimReward
    /// @param _tokenId tokenId of claim
    function _claimReward(uint256 _tokenId) private {
        uint256 rewardDebt = calcReward(_tokenId);
        IERC20(rewardToken).transferFrom(address(this), msg.sender, rewardDebt);

        userStake[_tokenId].rewardDebt = rewardDebt + rewardDebt;
        userStake[_tokenId].accRewardDebt = userStake[_tokenId].accRewardDebt + rewardDebt;

        emit Claim(msg.sender, rewardDebt);
    }

    /// @dev calceReward
    /// @param _tokenId tokenId of stake
    /// @return rewardDebt reward of stake
    function calcReward(uint256 _tokenId) public view returns(uint256 rewardDebt){
        require(userStake[_tokenId].user == msg.sender, "NFTStaking: E02");

        uint8 tokenLevel = tokenIdToLevel[_tokenId];

        StakeOptions memory stakeOption = options[tokenLevel];
        
        if( block.timestamp > stakeOption.lastRewardTimestamp ){
            uint256 accReward = _getMultiplier(stakeOption.lastRewardTimestamp, block.timestamp)*stakeOption.rewardPerSecond;
            rewardDebt = (stakeOption.accReward + accReward) - userStake[_tokenId].rewardDebt;
        }else{
            rewardDebt = stakeOption.accReward - userStake[_tokenId].rewardDebt;
        }
    }


    /// @dev stakeBalance
    /// @param _user stakebalance of user
    /// @return balance total stakebalance
    function stakeBalanceOf(address _user) public view returns(uint256 balance){
        uint256 totalTokens = IERC721Enumerable(nftContract).totalSupply();

        unchecked {
            for( uint256 i = 0; i <= totalTokens; i++ ) {
                if( userStake[i].user == _user ){
                    balance++;
                }
            }
        }
    }


    /// @dev tokensOfOwner
    /// @param _user tokens list of user
    /// @return tokens total tokens list
    function tokensOfOwner(address _user) external view returns(uint256[] memory tokens){
        uint256 balance = stakeBalanceOf(_user);
        uint256 totalTokens = IERC721Enumerable(nftContract).totalSupply();

        tokens = new uint256[](balance);

        if( balance == 0 ){
            return tokens;
        }

        unchecked {
            uint256 k;            
            for( uint256 i = 0; i < totalTokens; i++ ){
                if( userStake[i].user == _user){
                    tokens[k] = i;
                    k++;
                }

                if( k == balance )
                    return tokens;
            }
        }
    }
    
    /// @dev _updatePool
    /// @param _tokenLevel  updatePool of tokenLevel
    function _updatePool(uint8 _tokenLevel) private {
        StakeOptions storage stakeOption = options[_tokenLevel];

        if( block.timestamp <= stakeOption.lastRewardTimestamp)
            return;
        
        // 마지막 보상으로부터의 현재까지의 전체 보상금액
        uint256 accReward = _getMultiplier(stakeOption.lastRewardTimestamp, block.timestamp)*stakeOption.rewardPerSecond;
        stakeOption.accReward = stakeOption.accReward + accReward;
        stakeOption.lastRewardTimestamp = block.timestamp;
    }

    /// @dev Return reward multiplier over the given _from to _to block.
    /// @param _from: block to start
    /// @param _to: block to finish
    function _getMultiplier(uint256 _from, uint256 _to) private view returns (uint256) {
        if (_to <= bonusEndTimestamp) {
            return _to-_from; 
        } else if (_from >= bonusEndTimestamp) {
            return 0;
        } else {
            return bonusEndTimestamp-_from;
        }
    }


    /// @dev IERC721Receiver abstract
    function onERC721Received(
        address,
        address,
        uint256,
        bytes calldata
    ) external pure override returns (bytes4) {
        return IERC721Receiver.onERC721Received.selector;
    }
}