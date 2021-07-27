pragma solidity ^0.6.6;

interface ERC20 {
    function balanceOf(address owner) external returns(uint256);
    function transfer(address _to, uint256 _value) external returns (bool success);

}
contract TimeLockedWallet {

address public creator;
address public owner;
uint256 public unlockDate;
uint256 public createdAt;

modifier onlyOwner {
    require(msg.sender == owner);
    _;
}

constructor (
    address _creator,
    address _owner,
    uint256 _unlockDate
) public {
    creator = _creator;
    owner = _owner;
    unlockDate = _unlockDate;
    createdAt = now;
}

// keep all the ether sent to this address
fallback() payable external { 
    emit Received(msg.sender, msg.value);
}

// callable by owner only, after specified time
function withdraw() onlyOwner public {
   require(now >= unlockDate);
   //now send all the balance
   msg.sender.transfer(address(this).balance);
   emit Withdrew(msg.sender, address(this).balance);
}

// callable by owner only, after specified time, only for Tokens implementing ERC20
function withdrawTokens(address _tokenContract) onlyOwner public {
   require(now >= unlockDate);
   ERC20 token = ERC20(_tokenContract);
   //now send all the token balance
   uint256 tokenBalance = token.balanceOf(address(this));
   token.transfer(owner, tokenBalance);
   WithdrewTokens(_tokenContract, msg.sender, tokenBalance);
}

function info() public view returns(address, address, uint256, uint256, uint256) {
    return (creator, owner, unlockDate, createdAt, address(this).balance);
}

event Received(address from, uint256 amount);
event Withdrew(address to, uint256 amount);
event WithdrewTokens(address tokenContract, address to, uint256 amount);
}

contract TimeLockedWalletFactory {

mapping(address => address[]) wallets;

function getWallets(address _user) 
    public
    view
    returns(address[] memory)
{
    return wallets[_user];
}

function newTimeLockedWallet(address _owner, uint256 _unlockDate)
    payable
    public
    returns(TimeLockedWallet wallet)
{
    // Create new wallet.
    wallet = new TimeLockedWallet(msg.sender, _owner, _unlockDate);
    
    // Add wallet to sender's wallets.
    wallets[msg.sender].push(address(wallet));

    // If owner is the same as sender then add wallet to sender's wallets too.
    if(msg.sender != _owner){
        wallets[_owner].push(address(wallet));
    }

    // Send ether from this transaction to the created contract.
    payable(wallet).transfer(msg.value);

    // Emit event.
    Created(address(wallet), msg.sender, _owner, now, _unlockDate, msg.value);
}

// Prevents accidental sending of ether to the factory
fallback () external {
    revert();
}

event Created(address wallet, address from, address to, uint256 createdAt, uint256 unlockDate, uint256 amount);
}
