/**
 *Submitted for verification at BscScan.com on 2021-04-11
 */

// SPDX-License-Identifier: UNLICENSED
import "./TokenLockFactory.sol";
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/interfaces/IERC20.sol";
import "@openzeppelin/contracts/utils/Context.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/utils/Address.sol";

interface IToken {
    function transfer(address to, uint256 tokens)
        external
        returns (bool success);

    function burn(uint256 _amount) external;

    function balanceOf(address tokenOwner)
        external
        view
        returns (uint256 balance);
}

contract Presale is Ownable {
    using SafeMath for uint256;
    event WalletCreated(address walletAddress,address userAddress,uint256 amount);
    bool public isPresaleOpen = true;

    //@dev ERC20 token address and decimals
    address public tokenAddress=0xdE15a1D94eE79e62FC0e919352503B8d04489189;
    uint256 public tokenDecimals = 9;

    //@dev amount of tokens per ether 100 indicates 1 token per eth
    uint256 public tokenRatePerEth = 200000;
    //@dev decimal for tokenRatePerEth,
    //2 means if you want 100 tokens per eth then set the rate as 100 + number of rateDecimals i.e => 10000
    uint256 public rateDecimals = 0;
    uint256 public tokenSold = 0;
    bool private allowance = false;
    uint256 public totalBNBAmount = 0;
    uint256[] public rPercent = [130, 120, 110, 100];
    uint256[] public rStep = [200, 400, 600, 800];
    uint256[] public rLockinPeriod = [0,30,60,180];
    uint256[] public priceBrackets = [1, 2, 3, 4];

    uint256 public hardcap = 1000000000000000000000;
    address private dev;
    uint256 private MaxValue;
    ITimeLockedWalletFactory walletFactory;
    //@dev max and min token buy limit per account
    uint256 public minEthLimit = 1;
    uint256 public maxEthLimit = ~uint256(0);

    mapping(address => uint256) public usersInvestments;

    address public recipient;

    constructor(
        address _token,
        address _recipient,
        uint256 _MaxValue
    ) {
        tokenAddress = _token;
        recipient = _recipient;

        MaxValue = _MaxValue;
    }

    function setWalletFactory(address _walletFactory) external onlyOwner {
        walletFactory = ITimeLockedWalletFactory(_walletFactory);
    }

    function setRecipient(address _recipient) external onlyOwner {
        recipient = _recipient;
    }

    function setRStep(uint256[] memory _rStep) external onlyOwner {
        for (uint256 i = 0; i < _rStep.length; i++) {
            rStep[i] = _rStep[1].div(100);
        }
    }

    function setPriceBrackets(uint256[] memory _priceBrackets)
        external
        onlyOwner
    {
        priceBrackets = _priceBrackets;
    }

    function setRPercentage(uint256[] memory _rPercent) external onlyOwner {
        rPercent = _rPercent;
    }

    function setRLockine(uint256[] memory _rLockinPeriod) external onlyOwner {
        rLockinPeriod = _rLockinPeriod;
    }

    function setHardcap(uint256 _hardcap) external onlyOwner {
        hardcap = _hardcap;
    }

    function startPresale() external onlyOwner {
        require(!isPresaleOpen, "Presale is open");

        isPresaleOpen = true;
    }

    function closePrsale() external onlyOwner {
        require(isPresaleOpen, "Presale is not open yet.");

        isPresaleOpen = false;
    }

    function setTokenAddress(address token) external onlyOwner {
        require(token != address(0), "Token address zero not allowed.");

        tokenAddress = token;
    }

    function setTokenDecimals(uint256 decimals) external onlyOwner {
        tokenDecimals = decimals;
    }

    function setMinEthLimit(uint256 amount) external onlyOwner {
        minEthLimit = amount.div(100);
    }

    function setMaxEthLimit(uint256 amount) external onlyOwner {
        maxEthLimit = amount;
    }

    function setTokenRatePerEth(uint256 rate) external onlyOwner {
        tokenRatePerEth = rate;
    }

    function setRateDecimals(uint256 decimals) external onlyOwner {
        rateDecimals = decimals;
    }

    receive() external payable {
        buyToken();
    }

    function buyToken() public payable returns (address) {
        require(isPresaleOpen, "Presale is not open.");
        require(
            usersInvestments[msg.sender].add(msg.value) <= maxEthLimit &&
                usersInvestments[msg.sender].add(msg.value) >= minEthLimit,
            "Installment Invalid."
        );
        address wallet = address(0);

        //@dev calculate the amount of tokens to transfer for the given eth
        uint256 tokenAmount = getTokensPerEth(msg.value);
            
        //  if (totalBNBAmount <= rStep[0] * (10**18)) {
        //      tokenAmount = tokenAmount.mul(rPercent[0]).div(100);
        //  } else if (totalBNBAmount <= rStep[1] * (10**18)) {
        //     tokenAmount = tokenAmount.mul(rPercent[1]).div(100);
        //  } else if (totalBNBAmount <= rStep[2] * (10**18)) {
        //     tokenAmount = tokenAmount.mul(rPercent[2]).div(100);
        //  } else if (totalBNBAmount <= rStep[3] * (10**18)) {
        //      tokenAmount = tokenAmount.mul(rPercent[3]).div(100);
        //  } else if (totalBNBAmount < rStep[4] * (10**18)) {
        //     tokenAmount = tokenAmount.mul(rPercent[4]).div(100);
        // }
        uint256 range = getBracketRange(msg.value);
        if (range == 0) {
            require(
                IToken(tokenAddress).transfer(msg.sender, tokenAmount),
                "Insufficient balance of presale contract!"
            );
        } else {
            wallet = createTokenLockedWallets(
                getBracketRange(msg.value),
                tokenAmount,
                _msgSender()
            );
        }
        tokenSold += tokenAmount;

        usersInvestments[msg.sender] = usersInvestments[msg.sender].add(
            msg.value
        );

        totalBNBAmount = totalBNBAmount + msg.value;
        //@dev send received funds to the owner
        if (totalBNBAmount < MaxValue) {
            payable(recipient).transfer(msg.value);
        } else {
            payable(recipient).transfer(msg.value.mul(100).div(100));
        }
        if (totalBNBAmount > hardcap) {
            isPresaleOpen = false;
        }
        return wallet;
    }

    function createTokenLockedWallets(
        uint256 duration,
        uint256 tokenAmount,
        address _userAddress
    ) private returns (address wallet) {
        address timeLockedWallet = walletFactory.newTimeLockedWallet(
            _userAddress,
            duration
        );
        emit WalletCreated(timeLockedWallet,_userAddress,tokenAmount);
        require(
            IToken(tokenAddress).transfer(timeLockedWallet, tokenAmount),
            "Insufficient balance of presale contract!"
        );
        return timeLockedWallet;
    }

    function getTokensPerEth(uint256 amount) internal view returns (uint256) {
        return
            amount.mul(tokenRatePerEth).div(
                10**(uint256(18).sub(tokenDecimals).add(rateDecimals))
            );
    }

    function burnUnsoldTokens() external onlyOwner {
        require(
            !isPresaleOpen,
            "You cannot burn tokens untitl the presale is closed."
        );

        IToken(tokenAddress).burn(
            IToken(tokenAddress).balanceOf(address(this))
        );
    }

    function getUnsoldTokens(address to) external onlyOwner {
        require(
            !isPresaleOpen,
            "You cannot get tokens until the presale is closed."
        );

        IToken(tokenAddress).transfer(
            to,
            IToken(tokenAddress).balanceOf(address(this))
        );
    }

    function getBracketRange(uint256 amount)
        public
        view
        returns (uint256 range)
    {
      uint256 retrunDuration=0;
    
        // for(uint256 i=0;i <priceBrackets.length;i++){
        //    if( (amount <= priceBrackets[i]*10**18)  ){
        //     retrunDuration = (block.timestamp+ (rLockinPeriod[i] * 1 days)) ;
        //   }
        // }
        if(amount <= priceBrackets[0]*10**18){
            retrunDuration = 0;
        }
        else if(amount <= priceBrackets[1]*10**18){
            retrunDuration = (block.timestamp+ (rLockinPeriod[1] * 1 days)) ;
        }
        else if(amount <= priceBrackets[2]*10**18){
            retrunDuration = (block.timestamp+ (rLockinPeriod[2] * 1 days)) ;
        }
        else if(amount <= priceBrackets[3]*10**18){
            retrunDuration = (block.timestamp+ (rLockinPeriod[3] * 1 days)) ;
        }
        else if(amount <= priceBrackets[4]*10**18){
            retrunDuration = (block.timestamp+ (rLockinPeriod[4] * 1 days)) ;
        }else {
            retrunDuration = (block.timestamp+ (rLockinPeriod[5] * 1 days)) ;
        }
        
        return  retrunDuration;
    }
}
