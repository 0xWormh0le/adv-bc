# Degen NFT

## Setup

```
yarn compile # compile the contract
yarn contract-size # check size of compiled output
```

## Overview

NFT generating project on which users can purchase NFT based on their score. The score is calculated by the system automatically with the events that users took place on several platforms. The higher the score is, the better NFT will be unlocked for them. Users can purchase unlocked NFTs by paying Degen Token.

## Architecture

1. NFT generator

Generate a lot of images for NFTs using assets including BG gifs, body, cigar, shirt, right hand, left hand, cap etc.

2. Front-end

Provides a company wallet for users to manage assets including Degen Token and NFTs they purchased.
Users see their score, NFTs unlocked and NFTs purchased.

3. Back-end

Automatically capture events for each user from several sources and calculate scores.
Interact with DB for managing user information, wallet management.
Interact with Smart contract to mint NFTs, purchase NFTs with Degn Token for users

4. Smart Contract

Mint and sell NFTs based on the users’ scores and receiving Degen Token. Manage NFTs and Degen Tokens.

5. DB

Stores user information including email, score, wallet, balance etc.

## Smart Contract

- Degen Token Contract

Utility Token that will be used as a payment on the platform.

- DegenNFT Contract

The main contract is in charge of the main logic of mint, purchase of NFTs. Once it gets a function call of minting from the back-end it mints a new NFT token based on the score to the user's address.

## Workflows

Users will use Metamask for sign in and purchase NFTs.
Users can see their score, token balance and unlocked NFTs that are available for them to purchase on the site.
Once they trigger events on several platforms the backend of the Degen NFT project will capture these and calculate scores automatically.
Once a user wants to purchase a NFT that is available for him on the site, he can purchase it by paying Degen Token from his Metamask wallet.

Then the FE will get the score of the user from the backend and call `purchase()` function of `DegenNFT` Contract with the parameter of user, score, bot character index, randomly generated zombie properties according to the score, and signature. The smart contract will mint a new NFT token with the properties including the link of a zombie gif file and send it to the user’s address. Also it will transfer Degen Token from the user’s wallet to the smart contract address. Front-end sign parameters and send it to smart contract as a parameter for verification.

```Solidity
function purchase(
  address user,
  uint256 score,
  uint256 character,
  string[] calldata attrNames,
  uint8 v,
  bytes32 r,
  bytes32 s
)
```

`purchase` will emit `TokenPurchased` event with token id minted.
The backend will call `tokenDetails` function and it will return (character, attr names, attr details).
The token URI of that token will be like below.

```
{character}{attr1.value}{attr2.value}{attr3.value}...
```

where attrs will be sorted by its index in the above

- Tiers

There are a total of 10 'tiers' that an NFT buyer can fall into based on their wallet's previous activity on the blockchain.  A wallet with lots of history / previous activity will typically fall into a high score 'tier'.
Each degen score 'tier' corresponds to a different subset of the NFTs available for minting.  A user may purchase any 'tier' of NFT up to their current wallet's degen score 'tier'.  There is no relation between the 'tier' of the NFT and its price.

- Attributes

Layering of assets with characteristics to be validated based on designer feedback; NFT characteristics here:  https://docs.google.com/spreadsheets/d/1GVmK8SKwiarnKb62VNVyEnAMI8wnUjPA-IGMQdzA4n4/edit?usp=sharing_eil_dm&ts=618c9f42
They are transferrable between NFTs
