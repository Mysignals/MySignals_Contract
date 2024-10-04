const { network } = require("hardhat");
const { verify } = require("../utils/verify");
const { developmentChains, networkConfig } = require("../helper-hardhat-config");

module.exports = async ({ getNamedAccounts, deployments }) => {
    const { deployer } = await getNamedAccounts();
    const { deploy, log } = deployments;
    const chainId = network.config.chainId;

    const netArgs = networkConfig[chainId];
    const args = [
        netArgs.registrar,
        netArgs.fallbackAddress,
        netArgs.fee,
        // netArgs.payPercent,
        netArgs.merkleRoot,
        netArgs.airdropBalance,
    ];

    log("-------------------------------------------------------");
    const MySignalApp = await deploy("MySignalApp", {
        from: deployer,
        args: args,
        log: true,
        waitConfirmations: network.config.blockConfirmations || 2,
    });

    log("-------------------------------");

    if (!developmentChains.includes(network.name) && process.env.BSCSCAN_API) {
        log("Verifying...");
        await verify(MySignalApp.address, args);
    }

    log("-------------------------------------------------------");
};

module.exports.tags = ["all", "main", "MySignalApp"];
