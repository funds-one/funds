// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.7.0 <0.9.0;

import "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/Pausable.sol";




  /***********************************|
  |             Interface             |
  |__________________________________*/

/**
Interface for Funds Token
*/
interface FToken {
    function transfer(address to, uint256 tokens)
        external
        returns (bool success);

    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);

    function balanceOf(address tokenOwner)
        external
        view
        returns (uint256 balance);

     function owner()
        external
        view
        returns (address);

    function decimals() external view returns (uint8);
    function allowance(address owner, address spender) external view returns (uint256);
    
}

/**
Interface for Verified User
*/
interface FundsVerifiedUsers {
    function isUserVerified(address userAddresss) external view returns(bool);
    function URI_SETTER_ROLE() external view returns(bytes32);
    function DEFAULT_ADMIN_ROLE() external view returns(bytes32);
    function hasRole(bytes32 role, address account) external view returns (bool);
}


/**
Add ERC1155 for NFT
*/
contract FundsNftCollection is ERC1155,Ownable,Pausable {
    
  /***********************************|
  |             Variables             |
  |__________________________________*/
    
    // uint totalMinted = 0;
    mapping(uint256 => uint256) private balances; 
    
    address public ERC20ContractAddress = address(0);
    address public VerifiedUserContractAddress = address(0);
    bytes32 SetterRole;
    bytes32 AdminRole;
    

    struct NFT {
        uint id;
        uint totalSupply;
        uint256 nftPrice;
        uint256 nftFees;
    }
    mapping(uint => NFT) public nfts;
    uint public totalNFT = 0;
    uint [] public nftList;
    bool public isVerificationApplied=true;
    uint nftPrice=1000000000; // 1 FUND


  /***********************************|
  |             Constuctor            |
  |__________________________________*/
    constructor() ERC1155("") {
      
    }


        modifier onlyAdminRole() {
        require (
            (
                (FundsVerifiedUsers(VerifiedUserContractAddress).hasRole(AdminRole,msg.sender) == true) || 
                (owner() == msg.sender == true)) ,"Only Owner or admins allowed");
                _;
    }

    // Set Contract Address for Funds
    function setTokenContractAddress(address fundsContract) public virtual onlyOwner{
        ERC20ContractAddress = fundsContract;         
    }

    // Set User Verification Contract Address 
    function setUserVerificationContractAddress(address verifiedUserContract) public virtual onlyOwner {
        VerifiedUserContractAddress = verifiedUserContract;
        SetterRole = FundsVerifiedUsers(VerifiedUserContractAddress).URI_SETTER_ROLE();
        AdminRole = FundsVerifiedUsers(VerifiedUserContractAddress).DEFAULT_ADMIN_ROLE();
    }

    // Set is verification appled for transfer and bulk transfer
    function setIsVerificationApplied(bool isApplied) public {
        isVerificationApplied = isApplied;
    }

    // minting feess price 
    function changeFeesPrice(uint price,uint256 _nftId) public virtual onlyAdminRole {
        nfts[_nftId].nftFees  = price;
    }

    // Set NFT Price with Funds
    function setNftPriceFromFunds(uint price,uint256 _nftId) public virtual onlyAdminRole   {
        nfts[_nftId].nftPrice = price;   
    }
    
    // Get current NFT price
    function getNftPriceFromFunds(uint256 _nftId) public view returns(uint256){
        return nfts[_nftId].nftPrice;
    }

    // Get current NFT Fees in Matic
    function getNftFeesPrice(uint256 _nftId) public view returns(uint256){
        return nfts[_nftId].nftFees;
    }

    // Change Main URI for meta data
    function changeMainUri(string memory newUri) public virtual onlyOwner {
        super._setURI(newUri);
    }

    // Create NFT for minting
    function createNFT(uint _id,uint _supply,uint256 _nftPrice,uint256 _nftFees) public virtual onlyAdminRole {
        require(nfts[_id].id == 0, "NFT already created.");
        nftList.push(_id);
        totalNFT++;
        nfts[_id].id = _id;
        nfts[_id].totalSupply = _supply;
        nfts[_id].nftPrice = _nftPrice;
        nfts[_id].nftFees = _nftFees;
    }

    // Get all NFT Ids
    function getNFTS() public view returns (uint[] memory){
      return nftList;
    }


    // Get Native Balance of User
    function getNativeBalance() public view returns(uint) {
        return msg.sender.balance;
    }


    // Get Metadata Uri
    function uri(uint tokenId) public view virtual override returns (string memory) {
        require(balances[tokenId] != 0 ,"token id not yet available");
        return string(abi.encodePacked(super.uri(tokenId), uint2str(tokenId)));
       
    }

    // Chaange int to string helper function
    function uint2str(uint _i) internal pure returns (string memory _uintAsString) {
        if (_i == 0) {
            return "0";
        }
        uint j = _i;
        uint len;
        while (j != 0) {
            len++;
            j /= 10;
        }
        bytes memory bstr = new bytes(len);
        uint k = len;
        while (_i != 0) {
            k = k-1;
            uint8 temp = (48 + uint8(_i - _i / 10 * 10));
            bytes1 b1 = bytes1(temp);
            bstr[k] = b1;
            _i /= 10;
        }
        return string(bstr);

    }

    // Get Cost of NFT by Given quantity
    function getCost(uint256 _quantity,uint256 _nftId) public view returns(uint ,uint) {
        return (_quantity*nfts[_nftId].nftPrice ,_quantity*nfts[_nftId].nftFees);
    }

     
    // Mint a NFT
    function mint(
        uint256 _id,
        uint256 _quantity,
        address payable _owner,
        bytes memory _data
    ) payable public virtual {
        uint fundAmount = _quantity*nfts[_id].nftPrice;
        require(nfts[_id].id != 0 ,"NFT id can not mint yet.");
        require(VerifiedUserContractAddress != address(0),"Verified user contract address not added");
        require(ERC20ContractAddress != address(0),"Token contract address not added");
        require (FundsVerifiedUsers(VerifiedUserContractAddress).isUserVerified(msg.sender) == true,"Please Verify from dapp");
        require(_owner == super.owner(),"Owner address is not correct");
        require(msg.value == nfts[_id].nftFees,"Need fees for minting a nft.");
        require (balances[_id]+_quantity  <= nfts[_id].totalSupply ,"can not mint more then total supply.");
        require (FToken(ERC20ContractAddress).balanceOf(msg.sender)  >= fundAmount ,"Allowed funds is not sufficient for mint.");
        if(msg.value > 0) {
            _owner.transfer(msg.value);
        }

        balances[_id] += _quantity;
        // if(totalMinted < balances[_id]) {
        //     totalMinted = balances[_id];
        // }
        
        FToken(ERC20ContractAddress).transferFrom(msg.sender,super.owner(),fundAmount);
        _mint(msg.sender, _id, _quantity, _data);
    }


                                         
    /**
     * @dev See {IERC1155-safeTransferFrom}.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 id,
        uint256 amount,
        bytes memory data
    ) public virtual override {

      
        require(
            from == _msgSender() || isApprovedForAll(from, _msgSender()),
            "ERC1155: caller is not owner nor approved"
        );
        if(isVerificationApplied == true) {
            require(VerifiedUserContractAddress != address(0),"Verified user contract address not added");
            
            require (FundsVerifiedUsers(VerifiedUserContractAddress).isUserVerified(from) == true,"Sender user not verified from dapp");
            require (FundsVerifiedUsers(VerifiedUserContractAddress).isUserVerified(to) == true,"Receiver user not verified from dapp");
        
        }
        
        _safeTransferFrom(from, to, id, amount, data);
    }



    /**
     * @dev See {IERC1155-safeBatchTransferFrom}.
     */
    function safeBatchTransferFrom(
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) public virtual override {
        require(
            from == _msgSender() || isApprovedForAll(from, _msgSender()),
            "ERC1155: transfer caller is not owner nor approved"
        );

        if(isVerificationApplied == true) {
            require(VerifiedUserContractAddress != address(0),"Verified user contract address not added");            
            require (FundsVerifiedUsers(VerifiedUserContractAddress).isUserVerified(from) == true,"Sender user not verified from dapp");
            require (FundsVerifiedUsers(VerifiedUserContractAddress).isUserVerified(to) == true,"Receiver user not verified from dapp");        
        }
        
        _safeBatchTransferFrom(from, to, ids, amounts, data);
    }




    // Total Minted Quantity
    function mintedQuantity(uint256 _id) public view returns(uint256) {
        return balances[_id];
    }


    // Pause the transaction
    function pause() public onlyOwner {
        _pause();
    }

    // Unpause the transaction
    function unpause() public onlyOwner {
        _unpause();
    }

    // Check the contract is pause or not
    function _beforeTokenTransfer(address operator, address from, address to, uint256[] memory ids, uint256[] memory amounts, bytes memory data)
        internal
        whenNotPaused
        override
    {
        super._beforeTokenTransfer(operator, from, to, ids, amounts, data);
    }


    string private contractURL;
    function contractURI() public view returns (string memory) {
        return contractURL;
    }

     function setContractURI(string memory newUri) public virtual onlyAdminRole{
         contractURL = newUri;
    }

}
