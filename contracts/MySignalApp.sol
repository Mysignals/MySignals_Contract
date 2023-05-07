// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity 0.8.18;

error MySignalApp__InvalidProviderOrFee();
error MySignalApp__InsufficientBalance();
error MySignalApp__TransferFailed();
error MySignalApp__InvalidAddress();
error MySignalApp__NotRegistrar();
error MySignalApp__NotProvider();
error MySignalApp__NotFallback();
error MySignalApp__InvalidFee();

contract MySignalApp {
    uint256 private s_registrarBalance;
    uint256 private s_fallbacks;
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
        uint256 indexed userId
    );
    event AddressProviderChange(address oldAddress, address newAddress);
    event RegistrarChange(address oldAddress, address newAddress);
    event FallbackChange(address oldAddress, address newAddress);
    event FeeChange(uint256 oldFee, uint256 newFee);
    event ProviderAdded(address provider);

    modifier onlyProvider() {
        if (s_validProvider[msg.sender]) {
            _;
        }
        revert MySignalApp__NotProvider();
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
    ) {
        s_registrar = _registrar;
        s_fallbackAddress = _fallbackAddress;
        s_fees = _fee;
        i_payPercent = _payPercent;
    }

    fallback() external payable {
        s_fallbacks += msg.value;
    }

    receive() external payable {
        s_fallbacks += msg.value;
    }

    function payProvider(address _provider, uint256 _signalId,uint256 _userId) external payable {
        if ((msg.value == s_fees) && s_validProvider[_provider]) {
            uint256 fee = (msg.value * i_payPercent) / 100;
            s_providerBalance[_provider] += msg.value - fee;
            s_fees += fee;
            emit CompensateProvider(_provider, msg.value - fee, _signalId,_userId);
        }
        revert MySignalApp__InvalidProviderOrFee();
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
        (bool sent, ) = payable(msg.sender).call{value: oldAddressBalance}("");
        if (!sent) revert MySignalApp__TransferFailed();
        emit AddressProviderChange(msg.sender, _newAddr);
    }

    function providerWithdraw(uint256 _amount) external onlyProvider {
        if (_amount > s_providerBalance[msg.sender])
            revert MySignalApp__InsufficientBalance();
        s_providerBalance[msg.sender] -= _amount;
        (bool sent, ) = payable(msg.sender).call{value: _amount}("");
        if (!sent) revert MySignalApp__TransferFailed();
    }

    function registrarWithdraw(uint256 _amount) external onlyRegistrar {
        if (_amount > s_registrarBalance) revert MySignalApp__InsufficientBalance();

        s_registrarBalance -= _amount;
        (bool sent, ) = payable(msg.sender).call{value: _amount}("");
        if (!sent) revert MySignalApp__TransferFailed();
    }

    function fallbackWithdraw(uint256 _amount) external {
        if (msg.sender != s_fallbackAddress) revert MySignalApp__NotFallback();
        if (_amount > s_fallbacks) revert MySignalApp__InsufficientBalance();

        s_fallbacks -= _amount;
        (bool sent, ) = payable(msg.sender).call{value: _amount}("");
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
        return s_fallbacks;
    }

    function getProviderBalance(address _addr) external view returns (uint256) {
        return s_providerBalance[_addr];
    }
}
