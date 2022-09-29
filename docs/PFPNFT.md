# Solidity API

## PFPNFT

### _tokenIdCounter

```solidity
struct Counters.Counter _tokenIdCounter
```

### _baseTokenURI

```solidity
string _baseTokenURI
```

### burnAccount

```solidity
address burnAccount
```

### NFTINFO

```solidity
struct NFTINFO {
  string uri;
  uint256 tokenId;
}
```

### constructor

```solidity
constructor(address _burnAccount) public
```

### _beforeTokenTransfer

```solidity
function _beforeTokenTransfer(address from, address to, uint256 tokenId) internal
```

### supportsInterface

```solidity
function supportsInterface(bytes4 interfaceId) public view returns (bool)
```

### _burn

```solidity
function _burn(uint256 tokenId) internal
```

### setAddress

```solidity
function setAddress(address _burnAccount) external
```

### burn

```solidity
function burn(uint256 tokenId) external
```

### tokenURI

```solidity
function tokenURI(uint256 tokenId) public view returns (string)
```

### setBaseURI

```solidity
function setBaseURI(string _uri) external
```

### mintWithTokenURI

```solidity
function mintWithTokenURI(address to) external
```

### preNMint

```solidity
function preNMint(address to, uint256 mintCount) external
```

### tokensURI

```solidity
function tokensURI() external view returns (struct PFPNFT.NFTINFO[] list)
```

