// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity 0.8.18;

error MySignalApp__NotProvider();

contract MySignalApp {


    uint256 private s_registrarBalance;
    uint256 private s_fallbacks;
    uint256 private s_fee;

    address private s_registrar;
    address private s_fallbackAddress;

    mapping (address=>bool)private s_validProvider;
    mapping (address=>uint256)private s_providerBalance;

    modifier onlyProvider(){

        if (s_validProvider[msg.sender]){
            _;
        }
        revert MySignalApp__NotProvider();
    }

    constructor(address _registrar, address _fallbackAddress, uint256 _fee) {
        s_registrar=_registrar;
        s_fallbackAddress=_fallbackAddress;
        s_fee=_fee;
    }

    fallback()external payable{
        s_fallbacks+=msg.value;
    }

    receive()external payable{
        s_fallbacks+=msg.value;
    }

    
}