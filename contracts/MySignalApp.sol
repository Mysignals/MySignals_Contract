// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity 0.8.18;

error MySignalApp__NotProvider();

contract MySignalApp {


    uint256 public s_registrarBalance;
    uint256 public s_fee;

    address public s_registrar;

    mapping (address=>bool)public s_validProvider;
    mapping (address=>uint256)public s_providerBalance;

    modifier onlyProvider(){

        if (s_validProvider[msg.sender]){
            _;
        }
        revert MySignalApp__NotProvider();
    }

    constructor(address _registrar, uint256 _fee) {
        s_registrar=_registrar;
        s_fee=_fee;
    }
}