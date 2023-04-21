// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity 0.8.18;


error MySignalApp__InvalidProviderOrFee();
error MySignalApp__InsufficientBalance();
error MySignalApp__TransferFailed();
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

    mapping (address=>bool)private s_validProvider;
    mapping (address=>uint256)private s_providerBalance;

    event CompensateProvide(address indexed provider,uint256 indexed amount,uint256 indexed signalId);

    modifier onlyProvider(){

        if (s_validProvider[msg.sender]){
            _;
        }
        revert MySignalApp__NotProvider();
    }

    constructor(address _registrar, address _fallbackAddress, uint256 _fee,uint256 _payPercent) {
        s_registrar=_registrar;
        s_fallbackAddress=_fallbackAddress;
        s_fees=_fee;
        i_payPercent=_payPercent;
    }

    fallback()external payable{
        s_fallbacks+=msg.value;
    }

    receive()external payable{
        s_fallbacks+=msg.value;
    }

    function payProvider(address _provider, uint256 _signalId)external payable{
        if (msg.value==s_fees && s_validProvider[_provider]){
            uint256 fee= (msg.value*i_payPercent)/100;
            s_providerBalance[_provider]+=msg.value-fee;
            s_fees+=fee;
            emit CompensateProvide(_provider,msg.value-fee,_signalId);
        }
        revert MySignalApp__InvalidProviderOrFee();
    }

    function providerWithdraw(uint256 _amount)external onlyProvider{
        if(_amount>s_providerBalance[msg.sender]) revert MySignalApp__InsufficientBalance();
            s_providerBalance[msg.sender]-=_amount;
            (bool sent, )=payable(msg.sender).call{value:_amount}("");
            if (!sent) revert MySignalApp__TransferFailed();
        
    }

    function registrarWithdraw(uint256 _amount)external{
        if(msg.sender!=s_registrar) revert MySignalApp__NotRegistrar();
        if (_amount>s_registrarBalance)revert MySignalApp__InsufficientBalance();

        s_registrarBalance-=_amount;
        (bool sent, )=payable(msg.sender).call{value:_amount}("");
        if (!sent) revert MySignalApp__TransferFailed();
    }

    function fallbackWithdraw(uint256 _amount)external{
        if(msg.sender!=s_fallbackAddress) revert MySignalApp__NotFallback();
        if (_amount>s_fallbacks)revert MySignalApp__InsufficientBalance();

        s_fallbacks-=_amount;
        (bool sent, )=payable(msg.sender).call{value:_amount}("");
        if (!sent) revert MySignalApp__TransferFailed();
    }
}