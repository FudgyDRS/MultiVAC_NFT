// SPDX-License-Identifier: MIT

pragma solidity >=0.8.11;

abstract contract Context {
    function _msgSender() internal view virtual returns (address payable) { return payable(msg.sender); }
    function _msgData() internal view virtual returns (bytes memory) {
        this;
        return msg.data;
        }
    }
abstract contract Ownable is Context {
    address private _owner;

    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);
    constructor () {
        address msgSender = _msgSender();
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
    }
    function owner() public view virtual returns (address) { return _owner; }
    function renounceOwnership() public virtual onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
        }
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
        }
    }
library SafeMath {
    function tryAdd(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        uint256 c = a + b;
        if (c < a) return (false, 0);
        return (true, c);
        }
    function trySub(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        if (b > a) return (false, 0);
        return (true, a - b);
        }
    function tryMul(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        if (a == 0) return (true, 0);
        uint256 c = a * b;
        if (c / a != b) return (false, 0);
        return (true, c);
        }
    function tryDiv(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        if (b == 0) return (false, 0);
        return (true, a / b);
        }
    function tryMod(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        if (b == 0) return (false, 0);
        return (true, a % b);
        }
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");
        return c;
        }
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b <= a, "SafeMath: subtraction overflow");
        return a - b;
        }
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) return 0;
        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");
        return c;
        }
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b > 0, "SafeMath: division by zero");
        return a / b;
        }
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b > 0, "SafeMath: modulo by zero");
        return a % b;
        }
    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        return a - b;
        }
    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        return a / b;
        }
    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        return a % b;
        }
    }
interface IERC165 {
    function supportsInterface(bytes4 interfaceId) external view returns (bool);
    }
interface IERC721 is IERC165 {
    event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);
    event Approval(address indexed owner, address indexed approved, uint256 indexed tokenId);
    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);

    function balanceOf(address owner) external view returns (uint256 balance);
    function ownerOf(uint256 tokenId) external view returns (address owner);
    function safeTransferFrom(address from, address to, uint256 tokenId) external;
    function transferFrom(address from, address to, uint256 tokenId) external;
    function approve(address to, uint256 tokenId) external;
    function getApproved(uint256 tokenId) external view returns (address operator);
    function setApprovalForAll(address operator, bool _approved) external;
    function isApprovedForAll(address owner, address operator) external view returns (bool);
    function safeTransferFrom(address from, address to, uint256 tokenId, bytes calldata data) external;
    }
contract TestContract is Ownable {
    using SafeMath for uint256;

    IERC721 public nftContract;
    constructor(address targetContract) { nftContract = IERC721(targetContract); }

    uint256 public volume;              // num of successfully traded
    uint256 public tradeVolume;         // value of successfully traded
    //uint256 public dailyVolume;         // num of daily successfully traded
    //uint256 public dailyTradeVolume;    // value of daily successfully traded
    uint256 public floor; // added by the most recent listing
    uint256 public listVolume;
    uint256 private escrow;

    // ongoing:   stop == 1 
    // canceled:  stop == 2
    // sent:      stop == 0 & start == 0
    // autioning: stop > start
    struct listing { uint256 id; address account; uint256 value; uint256 start; uint256 stop; }
    mapping(uint256 => listing[]) history;  // specific NFT's history, also indicates current status
    mapping(uint256 => listing) traded;     // iterator for ALL trades
    mapping(uint256 => uint256) sent;       // iterator for ALL sends

    struct bid { address account; uint256 amount; }
    mapping(uint256 => bid[]) bids;
    mapping(uint256 => bid) highestBid;
    mapping(address => mapping(uint256 => uint256)) myBids; 

    // last x minted from (totalSupply)
    // last x listed
    // last x traded
    // last x sent
    // bid escrow
    // auction if end > block.timestamp
    /*
    function addTraded(uint256 _id, address _account, uint256 _value, uint256 _start, uint256 _stop) internal {
        if(traded.length > 0)
        if(traded[traded.length.length-1].stop < _stop - 86400)
        traded = new listing[];
        traded.push(listing(_id, _account, _value, _start, _stop));
    }*/
    function listTrade(uint256 _id, uint256 _value, uint256 _duration) public {
        require(msg.sender == nftContract.ownerOf(_id), "Not NFT owner");
        require(history[_id][history[_id].length-1].stop == 1, "NFT already listed");

        _duration <= block.timestamp
            ? history[_id].push(listing(_id, msg.sender, _value, block.timestamp, 1))
            : history[_id].push(listing(_id, msg.sender, _value, block.timestamp, block.timestamp + _duration));
        listVolume++;
        }
    function cancelTrade(uint256 _id) public {
        require(msg.sender == nftContract.ownerOf(_id) || msg.sender == owner(), "Not NFT owner");
        uint256 _stop = history[_id][history[_id].length-1].stop;
        require(_stop == 1 || _stop > history[_id][history[_id].length-1].start, "NFT not listed");

        history[_id][history[_id].length-1].stop = 2;
        if(bids[_id].length > 0) { escrowRefund(_id); }
        
        }
    function cancelTrade2(uint256 _id) public {
        require(msg.sender == nftContract.ownerOf(_id) || msg.sender == owner(), "Not NFT owner");
        uint256 _stop = history[_id][history[_id].length-1].stop;
        require(_stop == 1 || _stop > history[_id][history[_id].length-1].start, "NFT not listed");

        history[_id][history[_id].length-1].stop = 2;
        }
    function escrowRefund(uint256 _id) internal {
        if(bids[_id].length > 0) {
            for(uint256 i=0; i<bids[_id].length; i++) {
                (bool success,) = bids[_id][i].account.call{value: bids[_id][i].amount}("");
                bids[_id][i].amount = 0;
            }
        }
        }
    function cancelBid(uint256 _id) public {
        require(bids[_id].length > 0);
        uint256 _stop = history[_id][history[_id].length-1].stop;
        require(_stop == 1 || _stop > history[_id][history[_id].length-1].start, "NFT sale complete");
        
        uint256 i=0;
        while(bids[_id][i].account != msg.sender) { i++; }
        require(bids[_id][i].account == msg.sender, "No bid exists");
        
        uint256 _amount = bids[_id][i].amount;
        if(_amount > 10**18) {
            bids[_id][i].amount = 0;
            escrow -= _amount;
            (bool success,) = bids[_id][i].account.call{value: _amount}("");
        }
        }
    function updateBid(uint256 _id, uint256 _value) public payable {
        uint256 _stop = history[_id][history[_id].length-1].stop;
        require(_stop == 1 || _stop > history[_id][history[_id].length-1].start, "NFT sale complete");

        uint256 i=0;
        while(bids[_id][i].account != msg.sender) { i++; }
        require(bids[_id][i].account == msg.sender, "No bid exists");
        uint256 value = bids[_id][i].amount;
        require(value != _value);
        if(value < _value * 10**18) {
            require(msg.value >= _value - value, "Insufficent funds");
            escrow += msg.value;
        } else { (bool success,) = msg.sender.call{value: value - _value}(""); }
        bids[_id][i].amount = _value;
        }
    function createBid(uint256 _id, uint256 _value) public payable {
        require(msg.value >= _value);
        uint256 _stop = history[_id][history[_id].length-1].stop;
        require(_stop == 1 || _stop > history[_id][history[_id].length-1].start, "NFT sale complete");

        uint256 i=0;
        while(bids[_id][i].account != msg.sender) { i++; }
        require(bids[_id][i].account != msg.sender, "Bid already exists");
        bids[_id][i].amount = _value;
        escrow += _value;
        }
    function buyTrade(uint256 _id) public payable {
        require(msg.sender != nftContract.ownerOf(_id), "Already NFT owner");
        require(history[_id][history[_id].length-1].stop == 1, "NFT not listed");
        
        uint256 _amount = history[_id][history[_id].length-1].value;
        address _account = history[_id][history[_id].length-1].account;
        require(msg.value >= _amount, "MTV below sell price");
        uint256 _fee = _amount * 5 / 100;
        payable(owner()).send(_fee);
        payable(_account).send(_amount - _fee);

        history[_id][history[_id].length-1].stop = block.timestamp;
        traded[volume++] = listing(_id, _account, _amount, history[_id][history[_id].length-1].start, block.timestamp);
        tradeVolume += _amount;
    }

    function withdrawAll() public payable onlyOwner { require(payable(msg.sender).send(address(this).balance)); }
    // No tokens should be sent into the contract: burn / take them
    function burnRdnmTkn(address _token, address _to, uint256 _amount) external returns(bool success) { 
        bytes memory payload = abi.encodeWithSignature("transfer(address, uint256)", _to, _amount);
        (success,) = _token.call(payload);
        }
}
