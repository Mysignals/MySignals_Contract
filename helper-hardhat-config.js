const { ethers } = require("hardhat");

const networkConfig = {
    31337: {
        name: "localhost",
        registrar: "",
        fallbackAddress: "",
        fee: ethers.utils.parseEther("0.1"),
        payPercent: 60,
    },
    5: {
        name: "goerli",
        registrar: "",
        fallbackAddress: "",
        fee: ethers.utils.parseEther("0.1"),
        payPercent: 60,
    },
    97: {
        name: "BSCTest",
        registrar: process.env.WALLET,
        fallbackAddress: process.env.WALLET,
        fee: ethers.utils.parseEther("0.1"),
        payPercent: 60,
    },
    56: {
        name: "BSC",
        registrar: process.env.WALLET,
        fallbackAddress: process.env.WALLET,
        fee: ethers.utils.parseEther("0.1"),
        payPercent: 60,
    },
};

const developmentChains = ["hardhat", "localhost"];

module.exports = {
    developmentChains,
    networkConfig,
};
