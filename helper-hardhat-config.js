const { ethers } = require("hardhat");

const networkConfig = {
    31337: {
        name: "localhost",
        registrar: "",
        fallbackAddress: "",
        fee: ethers.utils.parseEther("0.002"),
        payPercent: 5,
    },
    5: {
        name: "goerli",
        registrar: "",
        fallbackAddress: "",
        fee: ethers.utils.parseEther("0.002"),
        payPercent: 5,
    },
    97: {
        name: "BSCTest",
        registrar: "",
        fallbackAddress: "",
        fee: ethers.utils.parseEther("0.002"),
        payPercent: 5,
    },
    56: {
        name: "BSC",
        registrar: "",
        fallbackAddress: "",
        fee: ethers.utils.parseEther("0.002"),
        payPercent: 5,
    },
};

const developmentChains = ["hardhat", "localhost"];

module.exports = {
    developmentChains,
    networkConfig,
};
