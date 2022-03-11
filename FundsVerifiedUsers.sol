// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.7.0 <0.9.0;
import "@openzeppelin/contracts/access/AccessControl.sol";


contract FundsVerifiedUsers is AccessControl {

    /***********************************|
    |             Variables             |
    |__________________________________*/
    bytes32 public constant URI_SETTER_ROLE = keccak256("URI_SETTER_ROLE");
    mapping (address => bool) public verifiedUsers;  
    


    constructor() {
        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _grantRole(URI_SETTER_ROLE, msg.sender);
    }


    function addVerifiedUser(address _address) public onlyRole(URI_SETTER_ROLE) {
        verifiedUsers[_address] = true;
    }

    function removeVerifiedUser(address _address) public onlyRole(URI_SETTER_ROLE) {
        verifiedUsers[_address] = false;
    }


    function isUserVerified(address _address) public view returns (bool) {
        return verifiedUsers[_address];
    }


    // The following functions are overrides required by Solidity.

    function supportsInterface(bytes4 interfaceId)
        public
        view
        override(AccessControl)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }

}
