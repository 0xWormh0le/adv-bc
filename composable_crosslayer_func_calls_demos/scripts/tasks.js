const {task} = require("hardhat/config");
const {DummySetter} = require("../types");


task("deploy_crosslayerFunctionCallsMock", "deploy mock contract")
    .setAction(async (taskArgs, hre) => {
        const CrosslayerFunctionCallsMock = await ethers.getContractFactory('CrosslayerFunctionCallsMock');
        const contract = await CrosslayerFunctionCallsMock.deploy()
        console.log("wrap address", contract.address)
    })

task("deploy_dummy_setter", "deploy setter contract")
    .setAction(async (taskArgs, hre) => {
        const ContractFactory = await ethers.getContractFactory('DummySetter');
        const contract = await ContractFactory.deploy()
        console.log("dummy setter", contract.address)
    })

task("deploy_msgReceiver", "deploy msgReceiver contract")
    .addParam("factoryaddress", "Crosslayer function call wrap contract address")
    .addParam("wrapaddress", "Crosslayer function call wrap contract address")
    .setAction(async (taskArgs, hre) => {
        const {getNamedAccounts, ethers, deployments} = hre;
        const {account1, account2, account3} = await getNamedAccounts();
        const factory = await ethers.getContractAt('IMsgReceiverFactory', taskArgs.factoryaddress);
        const user = await ethers.getSigner(account1);
        const userAddress = await user.getAddress();
        const msgReceiverAddress = await factory.connect(user).callStatic.createPersona(userAddress);
        await factory.connect(user).createPersona(userAddress);
        console.log("mesReceiver address", msgReceiverAddress)
    })

task("configure_msgReceiver", "configure msgReceiver contract, add feetoken in deployer and topup to msgReceiver")
    .addParam("wrapaddress", "Crosslayer function call wrap contract address")
    .addParam("factoryaddress", "msgReceiver factory")
    .addParam("msgreceiveraddress", "msgReceiver address")
    .setAction(async (taskArgs, hre) => {
        const {getNamedAccounts, ethers, deployments} = hre;
        const crosslayerFunctionCallsMock = await ethers.getContractAt('CrosslayerFunctionCallsMock', taskArgs.wrapaddress);
        const MockERC20 = await ethers.getContractFactory('ERC20Mock')
        const mockERC20 = await MockERC20.deploy('t', 't');
        console.log("ERC20 address", mockERC20.address)
        await mockERC20.setBalanceTo(taskArgs.msgreceiveraddress, 100)
        const factory = await ethers.getContractAt('IMsgReceiverFactory', taskArgs.factoryaddress);
        await factory.addFeeToken(mockERC20.address)
    })

task("simulate_crosslayer_call_from_relayer", "simulate crosslayer call from relayer to msgReceiver")
    .addParam("msgreceiveraddress", "msg receiver address")
    .addParam("feetokenaddress", "fee token address")
    .addParam("contractaddress", "target contract address")
    .setAction(async (taskArgs, hre) => {
        const {getNamedAccounts, ethers, deployments} = hre;
        const {account1, account2, account3} = await getNamedAccounts();
        const user = await ethers.getSigner(account1);
        const userAddress = await user.getAddress()
        let ABI = [
            "function setX(uint256)"
        ];
        let iface = new ethers.utils.Interface(ABI);
        const ERC20Mock = await ethers.getContractAt('ERC20Mock', taskArgs.feetokenaddress);
        console.log(await ERC20Mock.balanceOf(taskArgs.msgreceiveraddress))

        const callData = iface.encodeFunctionData("setX", [100])
        const msgReceiver = await ethers.getContractAt('IMsgReceiver', taskArgs.msgreceiveraddress);
        const id = "0x0000000000000000000000000000000000000000000000000000000000000001"
        const tx = await msgReceiver.forwardCall(
            1,
            taskArgs.feetokenaddress,
            userAddress,
            id,
            taskArgs.contractaddress,
            callData
        )
        console.log(tx)


        const dummySetter = await ethers.getContractAt('DummySetter', taskArgs.contractaddress);
        console.log((await dummySetter.x()).toString())
    })


task("add_msg_sender_chain_id", "configure msg sender")
    .addParam("msgsenderaddress", "msg sender addres")
    .addParam("chainid", "chain id")
    .setAction(async (taskArgs, hre) => {
        const {getNamedAccounts, ethers, deployments} = hre;
        const {account1, account2, account3} = await getNamedAccounts();
        const msgSender = await ethers.getContractAt('IMsgSender', taskArgs.msgsenderaddress);
        await msgSender.addNetwork(taskArgs.chainid)
    })

task("send_function_call", "send function call to msgSender from matic mumbai")
    .addParam("msgsenderaddress", "MsgSender address")
    .addParam("chainid", "target chainId address")
    .addParam("contractaddress", "target contract address")
    .addParam("wrapaddress", "Crosslayer function call wrap contract address")
    .setAction(async (taskArgs, hre) => {
        const {getNamedAccounts, ethers, deployments} = hre;
        const {account1, account2, account3} = await getNamedAccounts();
        const replayer = await ethers.getSigner(account1);
        const user1 = await ethers.getSigner(account1);

        let ABI = [
            "function setX(uint256)"
        ];
        let iface = new ethers.utils.Interface(ABI);
        const callData = iface.encodeFunctionData("setX", [1])
        console.log("chainId", taskArgs.chainid)
        console.log("callData", callData)
        const crosslayerFunctionCallsMock = await ethers.getContractAt('CrosslayerFunctionCallsMock', taskArgs.wrapaddress);
        const tx = await crosslayerFunctionCallsMock.connect(user1).registerCrossFunctionCall(
            taskArgs.msgsenderaddress,
            taskArgs.chainid,
            taskArgs.contractaddress,
            callData
        )
        console.log(tx)
    });
