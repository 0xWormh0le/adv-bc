## DEMO for v2-contracts-sdk
Here is an example project to send a function call from matic mumbai to rinkeby network.

* using crosslayer project to deploy MsgSender contract in mumbai
* using crosslayer project to deploy MsgReceiverFactory contract in rinkeby
* run `npx hardhat deploy_crosslayerFunctionCallsMock --network matic_mumbai` to create mock contract in mumbai
* run `npx hardhat deploy_crosslayerFunctionCallsMock --network rinkeby` to crate mock contract in rinkeby
* run `NODE_ENV=live npm run task:deploy_dummy_setter --network rinkeby ` to create dummy setter contract in rinkeby
* run `npx hardhat deploy_msgReceiver --network rinkeby --wrapaddress 0x649BFa626d7C5C385B126C251Bed44cA7DBEbC48 --factoryaddress 0x06AeBA4C319409E9Efb794c18Fe1c44871E46461`  to deploy user msg receiver contract through msg receiver factory in rinkeby
* run `npx hardhat configure_msgReceiver --network rinkeby --wrapaddress 0x649BFa626d7C5C385B126C251Bed44cA7DBEbC48 --factoryaddress 0x06AeBA4C319409E9Efb794c18Fe1c44871E46461 --msgreceiveraddress 0x2551376fb7FEe3e300AD48eF5AD04BcF7285E3cc` configure msg receiver by creating a dummy ERC20 token and add some balance to msg receiver and register the token in the factory as a fee token
* run `npx hardhat  add_msg_sender_chain_id --network matic_mumbai --msgsenderaddress 0x4Ce4c4DBd9BdeBB0B359cc3Eab23305c93Bb1398   --chainid 4 `  add msg sender network, id 4 is rinkeby network chain id in mumbai network
* run `npx hardhat send_function_call  --network matic_mumbai --wrapaddress 0x649BFa626d7C5C385B126C251Bed44cA7DBEbC48  --msgsenderaddress 0x4Ce4c4DBd9BdeBB0B359cc3Eab23305c93Bb1398   --chainid 4 --contractaddress  0xd6B7B91d039A45bB04ff5364ECFCDaDDda291810 npx hardhat simulate_crosslayer_call_from_relayer  --network rinkeby   --msgreceiveraddress 0x2551376fb7FEe3e300AD48eF5AD04BcF7285E3cc  --feetokenaddress 0x62b0664abaf63745f766cCa695b4b8D44ebA4a0A --contractaddress  0xd6B7B91d039A45bB04ff5364ECFCDaDDda291810` send actual function call msg to msg sender contract in mumbai
* run `npx hardhat simulate_crosslayer_call_from_relayer  --network rinkeby   --msgreceiveraddress 0x2551376fb7FEe3e300AD48eF5AD04BcF7285E3cc  --feetokenaddress 0x56f7a1bDD260115d102A5e0eEf37600c5a90469D --contractaddress  0xd6B7B91d039A45bB04ff5364ECFCDaDDda291810` simulate relayer by calling from relayer to msg receiver contract, passing function call parameters in rinkeby
