pragma solidity ^0.8.0;

// SPDX-License-Identifier: UNLICENSED
import '@openzeppelin/contracts/token/ERC20/ERC20.sol';
import '@openzeppelin/contracts/utils/Context.sol';
import '@openzeppelin/contracts/access/Ownable.sol';
pragma solidity ^0.8.0;
contract TimeLockedWallet {

    address public creator;
    uint256 public unlockDate;
    uint256 public createdAt;
    address public owner;

     constructor(
        address _creator,
        address _owner,
        uint256 _unlockDate
    )  {
        creator = _creator;
        owner = address(_owner);
        unlockDate = _unlockDate;
        createdAt = block.timestamp;
    }

    // keep all the ether sent to this address
    //  receive() external payable {
    //     buyToken();
    // }

    // callable by owner only, after specified time
    // function withdraw() onlyOwner public {
    //    require(block.timestamp >= unlockDate);
    //    //now send all the balance
    //    msg.sender.transfer(this.balance);
    //    emit Withdrew(msg.sender, this.balance);
    // }

    // callable by owner only, after specified time, only for Tokens implementing ERC20
    function withdrawTokens(address _tokenContract)  public {
       require(block.timestamp >= unlockDate, "Unlock date is not reached yet");
       require( msg.sender==owner,"You are not the owner");
       ERC20 token = ERC20(_tokenContract);
       //now send all the token balance
       uint256 tokenBalance = token.balanceOf(address(this));
       token.transfer(msg.sender, tokenBalance);
       emit WithdrewTokens(_tokenContract, msg.sender, tokenBalance);
    }

     function info(address _tokenContract) public view returns(address, address, uint256, uint256, uint256) {
         ERC20 token = ERC20(_tokenContract);
         uint256 balance = token.balanceOf(address(this));
         return (creator, owner, unlockDate , createdAt, balance);
     }

    event Received(address from, uint256 amount);
    event Withdrew(address to, uint256 amount);
    event WithdrewTokens(address tokenContract, address to, uint256 amount);
}

interface ITimeLockedWalletFactory {

    function getWallets(address _user) external view returns (address[] memory);

    function newTimeLockedWallet(address _owner, uint256 _unlockDate)
        external
        returns(address wallet);
}
contract TimeLockedWalletFactory is ITimeLockedWalletFactory{
 
    mapping(address => address[]) wallets;

    function getWallets(address _user)  
        override external view
        returns (address[] memory)
    {
        return wallets[_user];
    }

    function newTimeLockedWallet(address _owner, uint256 _unlockDate)
       override external 
        returns(address wallet)
    {
        // Create new wallet.
        wallet = address(new TimeLockedWallet(msg.sender,_owner,_unlockDate));
       
       // ERC20 _tokenAddress = tokenAddress;
        // Add wallet to sender's wallets.
        wallets[msg.sender].push(wallet);

        // If owner is the same as sender then add wallet to sender's wallets too.
        if(msg.sender != _owner){
            wallets[_owner].push(wallet);
        }

        // Send ether from this transaction to the created contract.
       // wallet.transfer(msg.value);
       //_tokenAddress.transfer(wallet,amount);

        // Emit event.
        emit Created(wallet, msg.sender, _owner, block.timestamp, _unlockDate);
        return wallet;
        
    }

    // // Prevents accidental sending of ether to the factory
    // function () public {
    //     revert();
    // }

    event Created(address wallet, address from, address to, uint256 createdAt, uint256 unlockDate);
}