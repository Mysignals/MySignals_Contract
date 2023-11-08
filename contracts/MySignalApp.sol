// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity 0.8.18;

error MySignalApp__InsufficientBalance();
error MySignalApp__TransferFailed();
error MySignalApp__InvalidAddress();
error MySignalApp__NotRegistrar();
error MySignalApp__NotProvider();
error MySignalApp__NotFallback();
error MySignalApp__InvalidFee();

import {ERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract MySignalApp is ERC20 {
    uint256 private s_registrarBalance;
    uint256 private s_singleDepositBalance;
    uint256 private s_fees;
    uint256 public immutable i_payPercent;

    address private s_registrar;
    address private s_fallbackAddress;

    mapping(address => bool) private s_validProvider;
    mapping(address => uint256) private s_providerBalance;

    event CompensateProvider(
        address indexed provider,
        uint256 amount,
        uint256 indexed signalId,
        string indexed userId
    );
    event SingleDeposit(string indexed id, string indexed userId, uint256 amount);
    event AddressProviderChange(address oldAddress, address newAddress);
    event TransferDeposits(address indexed provider, uint256 amount);
    event ProviderWithdraw(address indexed provider, uint256 amount);
    event RegistrarChange(address oldAddress, address newAddress);
    event FallbackChange(address oldAddress, address newAddress);
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
        uint256 _payPercent
    ) ERC20("Signal Token", "SSN") {
        s_registrar = _registrar;
        s_fallbackAddress = _fallbackAddress;
        s_fees = _fee;
        i_payPercent = _payPercent;

        _mint(msg.sender, 1000 * 10 ** decimals());
    }

    function payProvider(
        address _provider,
        uint256 _signalId,
        string calldata _userId
    ) external {
        if (!s_validProvider[_provider]) revert MySignalApp__NotProvider();
        uint256 charge = s_fees;
        uint256 fee = (charge * i_payPercent) / 100;

        s_providerBalance[_provider] += (charge - fee);
        s_registrarBalance += fee;
        _transfer(msg.sender, address(this), charge);

        emit CompensateProvider(_provider, charge - fee, _signalId, _userId);
    }

    function singleDeposit(
        string calldata _id,
        string calldata _userId,
        uint256 _amount
    ) external {
        uint256 fee = (_amount * i_payPercent) / 100;
        s_singleDepositBalance += (_amount - fee);
        s_registrarBalance += fee;
        _transfer(msg.sender, address(this), _amount);
        emit SingleDeposit(_id, _userId, _amount - fee);
    }

    function addProvider(address _provider) external onlyRegistrar {
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

    function transferDeposit(address _provider, uint256 _amount) external onlyRegistrar {
        if (!s_validProvider[_provider]) revert MySignalApp__NotProvider();
        if (_amount > s_singleDepositBalance) revert MySignalApp__InsufficientBalance();

        s_singleDepositBalance -= _amount;
        _transfer(address(this), _provider, _amount);

        emit TransferDeposits(_provider, _amount);
    }

    function fallbackWithdraw(uint256 _amount) external {
        if (msg.sender != s_fallbackAddress) revert MySignalApp__NotFallback();
        if (_amount > address(this).balance) revert MySignalApp__InsufficientBalance();

        (bool sent, ) = payable(msg.sender).call{value: address(this).balance}("");
        if (!sent) revert MySignalApp__TransferFailed();
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
}
