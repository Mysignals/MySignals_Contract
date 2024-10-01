// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity 0.8.18;

error MySignalApp__InvalidPresalePurchaseAmount();
error MySignalApp__AllocationExceedsTokensLeft();
error MySignalApp__InsufficientBalance();
error MySignalApp__PresaleMustEnd();
error MySignalApp__TransferFailed();
error MySignalApp__InvalidAddress();
error MySignalApp__NotInWhitelist();
error MySignalApp__AlreadyClaimed();
error MySignalApp__NotInitialized();
error MySignalApp__NotRegistrar();
error MySignalApp__NotProvider();
error MySignalApp__NotFallback();
error MySignalApp__InvalidFee();

import {ERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import {MerkleProof} from "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";

contract MySignalApp is ERC20 {
    uint256 public s_airdropBalance;
    uint256 private s_registrarBalance;
    // uint256 private s_singleDepositBalance;
    uint256 private s_fees;
    uint256 public s_tokensPerBnb;
    uint256 public immutable i_payPercent;
    uint256 public s_minBuy = 0.1 ether;
    uint256 public s_maxBuy = 1 ether;

    struct presaleDetails {
        uint256 saleCount;
        uint256 amountRaised;
        uint256 amountWithdrawable;
        uint256 tokensLeft;
        uint256 tokensSold;
        uint256 tokensPerBnb;
    }

    presaleDetails private s_preSaleDetails;

    bytes32 public immutable i_merkleRoot;

    address private s_registrar;
    address private s_fallbackAddress;

    bool public s_isPresale;
    bool public s_isInitialized;

    mapping(address => bool) private s_validProvider;
    mapping(address => uint256) private s_providerBalance;
    mapping(address => uint256) private s_referrerBalance;
    mapping(address => bool) private s_claimedAirdrop;
    mapping(address => uint256) private s_addressToTokensDeposited;

    event CompensateProvider(
        address indexed provider,
        address indexed referrer,
        uint256 amount,
        uint256 indexed signalId,
        string userId
    );
    // event SingleDeposit(string id, string userId, uint256 amount);
    event PreSaleTokensPurchased(address to, uint256 amount, uint256 tokensReceived);
    event AddressProviderChange(address oldAddress, address newAddress);
    event TransferDeposits(address indexed provider, uint256 amount);
    event ProviderWithdraw(address indexed provider, uint256 amount);
    event RegistrarChange(address oldAddress, address newAddress);
    event FallbackChange(address oldAddress, address newAddress);
    event AirdropClaimed(address to, uint256 amount);
    event FeeChange(uint256 oldFee, uint256 newFee);
    event ProviderAdded(address provider);

    modifier onlyProvider() {
        if (!s_validProvider[msg.sender]) {
            revert MySignalApp__NotProvider();
        }
        _;
    }

    modifier onlyRegistrar() {
        if (msg.sender != s_registrar) revert MySignalApp__NotRegistrar();
        _;
    }

    constructor(
        address _registrar,
        address _fallbackAddress,
        uint256 _fee,
        uint256 _payPercent,
        bytes32 _merkleRoot,
        uint256 _airdropBalance
    ) ERC20("Signals Token", "XSN") {
        s_registrar = _registrar;
        s_validProvider[_registrar] = true;
        s_fallbackAddress = _fallbackAddress;
        s_airdropBalance = _airdropBalance;
        s_fees = _fee;
        i_payPercent = _payPercent;
        i_merkleRoot = _merkleRoot;

        _mint(address(this), _airdropBalance);
    }

    receive() external payable {
        if (!s_isPresale) return;

        if (
            msg.value < s_minBuy ||
            msg.value > s_maxBuy ||
            s_addressToTokensDeposited[msg.sender] >= s_maxBuy
        ) revert MySignalApp__InvalidPresalePurchaseAmount();

        uint256 tokensReceived = msg.value * s_tokensPerBnb;
        if (s_preSaleDetails.tokensLeft < tokensReceived)
            revert MySignalApp__AllocationExceedsTokensLeft();

        s_preSaleDetails.amountRaised += msg.value;
        s_preSaleDetails.amountWithdrawable += msg.value;
        s_preSaleDetails.saleCount++;
        s_preSaleDetails.tokensLeft -= tokensReceived;
        s_preSaleDetails.tokensSold += tokensReceived;

        s_addressToTokensDeposited[msg.sender] += msg.value;
        emit PreSaleTokensPurchased(msg.sender, msg.value, tokensReceived);

        _transfer(address(this), msg.sender, tokensReceived);
    }

    function initialize(
        uint256 totalSupply,
        uint256 preSaleAmount,
        uint256 tokensPerBnb
    ) external onlyRegistrar {
        if (s_isInitialized) revert MySignalApp__NotInitialized();
        s_isInitialized = true;
        s_isPresale = true;
        uint256 remainingSupply = totalSupply - preSaleAmount - s_airdropBalance;

        s_preSaleDetails = presaleDetails({
            saleCount: 0,
            amountRaised: 0,
            tokensLeft: preSaleAmount,
            tokensSold: 0,
            tokensPerBnb: tokensPerBnb,
            amountWithdrawable: 0
        });
        s_tokensPerBnb = tokensPerBnb;

        _mint(msg.sender, remainingSupply);
        _mint(address(this), preSaleAmount);
    }

    function payProvider(
        address _provider,
        address _referrer,
        uint256 _signalId,
        string calldata _userId
    ) external {
        if (!s_validProvider[_provider]) revert MySignalApp__NotProvider();
        uint256 charge = s_fees;
        uint256 fee = (charge * i_payPercent) / 100;

        if (_referrer != address(0)) {
            uint256 sharedFee = (charge - fee) / 2;
            s_providerBalance[_provider] += sharedFee;
            s_referrerBalance[_referrer] += sharedFee;
            s_registrarBalance += fee;
            _transfer(msg.sender, address(this), charge);
            emit CompensateProvider(_provider, _referrer, sharedFee, _signalId, _userId);
            return;
        }

        s_providerBalance[_provider] += (charge - fee);
        s_registrarBalance += fee;
        _transfer(msg.sender, address(this), charge);

        emit CompensateProvider(_provider, _referrer, charge - fee, _signalId, _userId);
    }

    function addProvider(address _provider) external onlyRegistrar {
        if (_provider == address(0)) revert MySignalApp__InvalidAddress();
        s_validProvider[_provider] = true;
        emit ProviderAdded(_provider);
    }

    function providerChangeAddress(address _newAddr) external onlyProvider {
        uint256 oldAddressBalance = s_providerBalance[msg.sender];
        s_providerBalance[msg.sender] = 0;

        s_validProvider[msg.sender] = false;
        s_validProvider[_newAddr] = true;
        _transfer(address(this), msg.sender, oldAddressBalance);

        emit AddressProviderChange(msg.sender, _newAddr);
    }

    function providerWithdraw(uint256 _amount) external onlyProvider {
        if (_amount > s_providerBalance[msg.sender])
            revert MySignalApp__InsufficientBalance();

        s_providerBalance[msg.sender] -= _amount;
        _transfer(address(this), msg.sender, _amount);

        emit ProviderWithdraw(msg.sender, _amount);
    }

    function registrarWithdraw(uint256 _amount) external onlyRegistrar {
        if (_amount > s_registrarBalance) revert MySignalApp__InsufficientBalance();

        s_registrarBalance -= _amount;
        _transfer(address(this), msg.sender, _amount);
    }

    function referrerWithdraw() external {
        uint256 referrerBalance = s_referrerBalance[msg.sender];
        s_referrerBalance[msg.sender] = 0;
        _transfer(address(this), msg.sender, referrerBalance);
    }

    function fallbackWithdraw(uint256 _amount) external {
        if (s_isPresale) revert MySignalApp__PresaleMustEnd();
        if (msg.sender != s_fallbackAddress) revert MySignalApp__NotFallback();
        if (_amount > address(this).balance) revert MySignalApp__InsufficientBalance();

        (bool sent, ) = payable(msg.sender).call{value: _amount}("");
        if (!sent) revert MySignalApp__TransferFailed();
    }

    function withdrawPreSale() external onlyRegistrar {
        if (s_isPresale) revert MySignalApp__PresaleMustEnd();
        uint256 amount = s_preSaleDetails.amountWithdrawable;
        s_preSaleDetails.amountWithdrawable = 0;
        (bool sent, ) = payable(msg.sender).call{value: amount}("");
        if (!sent) revert MySignalApp__TransferFailed();
    }

    function endPreSale() external onlyRegistrar {
        s_isPresale = false;
        uint256 tokensLeft = s_preSaleDetails.tokensLeft;
        s_preSaleDetails.tokensLeft = 0;
        _burn(address(this), tokensLeft);
    }

    function changeFee(uint256 _fee) external onlyRegistrar {
        uint256 oldFee = s_fees;
        s_fees = _fee;
        emit FeeChange(oldFee, _fee);
    }

    function changeRegistrar(address _addr) external onlyRegistrar {
        if (_addr == address(0)) revert MySignalApp__InvalidAddress();
        address oldAddress = s_registrar;
        s_registrar = _addr;
        emit RegistrarChange(oldAddress, _addr);
    }

    function changeFallback(address _addr) external {
        if (msg.sender != s_fallbackAddress) revert MySignalApp__NotFallback();
        if (_addr == address(0)) revert MySignalApp__InvalidAddress();
        address oldAddress = s_fallbackAddress;
        s_fallbackAddress = _addr;
        emit FallbackChange(oldAddress, _addr);
    }

    function changeBuyLimits(uint256 _minBuy, uint256 _maxBuy) external onlyRegistrar {
        if (!s_isPresale) return;
        s_minBuy = _minBuy;
        s_maxBuy = _maxBuy;
    }

    function checkInWhitelist(
        bytes32[] calldata _proof,
        uint256 _amount
    ) public view returns (bool) {
        bytes32 leaf = keccak256(abi.encode(msg.sender, _amount));
        bool verified = MerkleProof.verify(_proof, i_merkleRoot, leaf);
        return verified;
    }

    function claimAirdrop(bytes32[] calldata _proof, uint256 _amount) external {
        if (s_claimedAirdrop[msg.sender]) revert MySignalApp__AlreadyClaimed();
        if (!checkInWhitelist(_proof, _amount)) revert MySignalApp__NotInWhitelist();

        s_claimedAirdrop[msg.sender] = true;
        s_airdropBalance -= _amount;
        emit AirdropClaimed(msg.sender, _amount);

        _transfer(address(this), msg.sender, _amount);
    }

    function getFee() external view returns (uint256) {
        return s_fees;
    }

    function getRegistrarBalance() external view returns (uint256) {
        return s_registrarBalance;
    }

    function getFallbacks() external view returns (uint256) {
        return address(this).balance;
    }

    function getProviderBalance(address _addr) external view returns (uint256) {
        return s_providerBalance[_addr];
    }

    function getReferrerBalance(address _addr) external view returns (uint256) {
        return s_referrerBalance[_addr];
    }

    function getPresaleDetails() external view returns (presaleDetails memory) {
        return s_preSaleDetails;
    }

    function isValidProvider(address _addr) external view returns (bool) {
        return s_validProvider[_addr];
    }
}
