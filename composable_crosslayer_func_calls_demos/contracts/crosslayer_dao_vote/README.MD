# DEMO 
In this demo, we are going to show how to interact with Mosaice crosslayer functionalities to vote on one network and send the vote to a list contracts deployed on different networks so they share the same vote information
## Preparation and instantiation of contracts.
For this demo, we have implemented a pair of CrosslayerVote and Reward Vault contracts which will be deployed in 2 different networks. The idea is to allow user deposit collateral in network 1 and receive staking rewards in a second network
Here are steps need to prepare the contracts: 

* Deploy ```CrosslayerVote``` contract in Network 1
   ```
   const msgSender = ""; //msgsender address which will receive cross layer function calls located in network 1
  
   const crosslayerVote = await CrosslayerVote.deploy(msgSender);
   ```

* Deploy ```CrosslayerVote``` ```Persona``` contract in network 2, so CrosslayerVote could communicate with CrosslayerVoteCopy without intermediary
   ```
   const crosslayerVote = ""; 
   const crosslayerVotePersona = await MsgReceiverFactory.createPersona(crosslayerVote)
   ```
  
* Deploy ```CrosslayerVoteCopy``` contract in Network 2
   ```
   const msgSender = ""; //msgsender address which will receive cross layer function calls located in network 2
   const crosslayerVotePersona = ""; //crosslayerVote persona address deployed in network 2
  
   crosslayerVoteCopy = await crosslayerVoteCopy.deploy(msgSender, crosslayerVotePersona)
   ```

* Configure in crosslayerVote to set corresponding crosslayerVoteCopy to finalize the communication bridges setup
   ```
   const crosslayerVoteCopy = "" // releasse vault address deployed in network l2
   await crosslayerVote.setCrosslayerVoteCopyAddressByChainId(networkId2, crosslayerVoteCopy) 
   ```
  
* Now all communication bridges are configured, sending messages from crosslayerVote to crosslayerVoteCopy can be done seamlessly, from the contract perspectives operative permissions are configured in a way that only Persona contracts could interact to.
   ```
   // crosslayerVote contract
   function vote(uint256 _amount, address _to) external onlyReleaseVaultPersona;
   ```
* from now on, the copy of the votes will be synced with contracts deployed in other networks

### Interaction
In the following flow chart we can see how we start a transaction from network 1 to create a vote, then the vote is sent to other registered contracts deployed in different networks .

![Crosslayer vote protocol demo](crosslayer_calls_vote_demo.png "Crosslayer vote protocal demo")