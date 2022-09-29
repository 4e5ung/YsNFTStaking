# Solidity API

## NFTStaking

_This is a nft staking contract_

### admin

```solidity
address admin
```

### rewardToken

```solidity
address rewardToken
```

### nftContract

```solidity
address nftContract
```

### startTimestamp

```solidity
uint256 startTimestamp
```

### bonusEndTimestamp

```solidity
uint256 bonusEndTimestamp
```

### totalStakeBalance

```solidity
uint256 totalStakeBalance
```

### options

```solidity
mapping(uint8 => struct NFTStaking.StakeOptions) options
```

### tokenIdToLevel

```solidity
mapping(uint256 => uint8) tokenIdToLevel
```

### userStake

```solidity
mapping(uint256 => struct NFTStaking.userStakeInfo) userStake
```

### StakeOptions

```solidity
struct StakeOptions {
  uint256 rewardPerSecond;
  uint256 accReward;
  uint256 lastRewardTimestamp;
  uint256 lockupSecond;
}
```

### NftLevelInfo

```solidity
struct NftLevelInfo {
  uint8 level;
  uint256 tokenId;
}
```

### userStakeInfo

```solidity
struct userStakeInfo {
  address user;
  uint256 startTimestamp;
  uint256 rewardDebt;
  uint256 accRewardDebt;
  uint256 lockupTimestamp;
}
```

### Stake

```solidity
event Stake(address sender, uint256 tokenId)
```

### UnStake

```solidity
event UnStake(address sender, uint256 tokenId)
```

### Claim

```solidity
event Claim(address sender, uint256 amount)
```

### onlyAdmin

```solidity
modifier onlyAdmin()
```

### constructor

```solidity
constructor(address _admin, address _rewardToken, address _nftContract, uint256 _startTimestamp, uint256 _bonusEndTimestamp) public
```

_Address setting constructor._

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| _admin | address | minter admin eoa |
| _rewardToken | address | erc20 address |
| _nftContract | address | nft address |
| _startTimestamp | uint256 | start rewardtime |
| _bonusEndTimestamp | uint256 | end reward time |

### setStakingOption

```solidity
function setStakingOption(uint8 _nftLevel, uint256 _rewardPerSecond, uint256 _lockupSecond) external
```

_Set Staking options_

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| _nftLevel | uint8 | nft Level |
| _rewardPerSecond | uint256 | rewardPerSecond token |
| _lockupSecond | uint256 | minimum lockup period |

### setAddress

```solidity
function setAddress(address _admin, address _rewardToken, address _nftContract) external
```

_Address setting._

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| _admin | address | minter admin eoa |
| _rewardToken | address | erc20 address |
| _nftContract | address | nft address |

### setNftLevel

```solidity
function setNftLevel(bytes _nftInfo) external
```

_import NftTokenIdToLevel_

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| _nftInfo | bytes | NftLevelInfo struct |

### nftStaking

```solidity
function nftStaking(uint256[] _tokenIds) external
```

_nftStaking_

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| _tokenIds | uint256[] | staking to tokenIds |

### nftUnStaking

```solidity
function nftUnStaking(uint256[] _tokenIds) external
```

_nftUnStaking_

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| _tokenIds | uint256[] | unstaking to tokenIds |

### claimRewards

```solidity
function claimRewards(uint256[] _tokenIds) external
```

_claimRewards_

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| _tokenIds | uint256[] | tokensId of claim |

### _claimReward

```solidity
function _claimReward(uint256 _tokenId) private
```

__claimReward_

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| _tokenId | uint256 | tokenId of claim |

### calcReward

```solidity
function calcReward(uint256 _tokenId) public view returns (uint256 rewardDebt)
```

_calceReward_

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| _tokenId | uint256 | tokenId of stake |

#### Return Values

| Name | Type | Description |
| ---- | ---- | ----------- |
| rewardDebt | uint256 | reward of stake |

### stakeBalanceOf

```solidity
function stakeBalanceOf(address _user) public view returns (uint256 balance)
```

_stakeBalance_

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| _user | address | stakebalance of user |

#### Return Values

| Name | Type | Description |
| ---- | ---- | ----------- |
| balance | uint256 | total stakebalance |

### tokensOfOwner

```solidity
function tokensOfOwner(address _user) external view returns (uint256[] tokens)
```

_tokensOfOwner_

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| _user | address | tokens list of user |

#### Return Values

| Name | Type | Description |
| ---- | ---- | ----------- |
| tokens | uint256[] | total tokens list |

### _updatePool

```solidity
function _updatePool(uint8 _tokenLevel) private
```

__updatePool_

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| _tokenLevel | uint8 | updatePool of tokenLevel |

### _getMultiplier

```solidity
function _getMultiplier(uint256 _from, uint256 _to) private view returns (uint256)
```

_Return reward multiplier over the given _from to _to block._

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| _from | uint256 |  |
| _to | uint256 |  |

### onERC721Received

```solidity
function onERC721Received(address, address, uint256, bytes) external pure returns (bytes4)
```

_IERC721Receiver abstract_

