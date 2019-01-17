pragma solidity >=0.5.0 <0.6.0;


library SafeMath {
    function add(uint a, uint b) internal pure returns (uint c) {
        c = a + b;
        require(c >= a);
    }
    function sub(uint a, uint b) internal pure returns (uint c) {
        require(b <= a);
        c = a - b;
    }
    function mul(uint a, uint b) internal pure returns (uint c) {
        c = a * b;
        require(a == 0 || c / a == b);
    }
    function div(uint a, uint b) internal pure returns (uint c) {
        require(b > 0);
        c = a / b;
    }
}


contract Owned {
    address public owner;

    constructor() public {
        owner = msg.sender;
    }

    modifier onlyOwner {
        require(msg.sender == owner);
        _;
    }

    function transferOwnership(address newOwner) public onlyOwner {
        owner = newOwner;
    }
}

contract Pausable is Owned {
    bool private _paused = false;
    event Pause();
    event Unpause();

    modifier whenNotPaused() {
        require(!_paused);
        _;
    }

    modifier whenPaused() {
        require(_paused);
        _;
    }

    function pause() public onlyOwner whenNotPaused {
        _paused = true;
        emit Pause();
    }

    function unpause() public onlyOwner whenPaused {
        _paused = false;
        emit Unpause();
    }

    function paused() public view returns (bool) {
        return _paused;
    }
}

interface IERC20 {
    function totalSupply() external view returns (uint256);
    function balanceOf(address who) external view returns (uint256);
    function transfer(address to, uint256 value) external returns (bool);
    function transferFrom(address from, address to, uint256 value) external returns (bool);
    function approve(address spender, uint256 value) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint256);

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}


contract Token is Owned, Pausable, IERC20 {
    using SafeMath for uint;
    uint256 private _totalSupply;
    string private _name;
    string private _symbol;
    uint8 private _decimals;

    mapping (address => uint256) private _balances;
    mapping (address => uint256) private _frozen;
    mapping (address => mapping (address => uint256)) private _allowed;

    event Freeze(address indexed from, uint256 value);
    event Unfreeze(address indexed from, uint256 value);

    constructor() public {
        _name = "Everyday.bet Token";
        _symbol = "EDBU";
        _decimals = 8;
        _totalSupply = 10 ** 8 * 10 ** uint256(_decimals);
        _balances[msg.sender] = _totalSupply;
    }

    function name() public view returns (string memory) {
        return _name;
    }

    function symbol() public view returns (string memory) {
        return _symbol;
    }

    function decimals() public view returns (uint8) {
        return _decimals;
    }

    // erc20 part
    function totalSupply() public view returns (uint256) {
        return _totalSupply;
    }

    function balanceOf(address owner) public view returns (uint256) {
        return _balances[owner];
    }

    function transfer(address to, uint256 value) public whenNotPaused returns (bool) {
        _transfer(msg.sender, to, value);
        return true;
    }

    function transferFrom(address from, address to, uint256 value) public whenNotPaused returns (bool) {
        _allowed[from][msg.sender] = _allowed[from][msg.sender].sub(value);
        _transfer(from, to, value);
        emit Approval(from, msg.sender, _allowed[from][msg.sender]);
        return true;
    }

    function approve(address spender, uint256 value) public whenNotPaused returns (bool) {
        require(spender != address(0));
        require(value > 0);
        _allowed[msg.sender][spender] = value;
        emit Approval(msg.sender, spender, value);
        return true;
    }
    
    function allowance(address owner, address spender) public view returns (uint256) {
        return _allowed[owner][spender];
    }

    /// mint 
    function mint(uint256 value) public onlyOwner returns (bool) {
        require(msg.sender != address(0));
        require(value > 0);
        _totalSupply = _totalSupply.add(value);
        _balances[msg.sender] = _balances[msg.sender].add(value);
        emit Transfer(address(0), msg.sender, value);
        return true;
    }

    /// burn
    function burn(uint256 value) public {
        require(msg.sender != address(0));
        require(value > 0);
        _totalSupply = _totalSupply.sub(value);
        _balances[msg.sender] = _balances[msg.sender].sub(value);
        emit Transfer(msg.sender, address(0), value);
    }

    /// freeze
    function freeze(address who, uint256 value) public onlyOwner returns (bool success) {
        require(_balances[who] >= value);
        require(value > 0);
        _balances[who] = _balances[who].sub(value);
        _frozen[who] = _frozen[who].add(value);
        emit Freeze(who, value);
        return true;
    }

    function unfreeze(address who, uint256 value) public onlyOwner returns (bool success) {
        require(_frozen[who] >= value);
        require(value > 0);
        _frozen[who] = _frozen[who].sub(value);
        _balances[who] = _balances[who].add(value);
        emit Unfreeze(who, value);
        return true;
    }

    function frozenOf(address who) public view returns (uint256 balance) {
        return _frozen[who];
    }    

    /// private method
    function _transfer(address from, address to, uint256 value) internal {
        require(to != address(0));
        require(value > 0);
        _balances[from] = _balances[from].sub(value);
        _balances[to] = _balances[to].add(value);
        emit Transfer(from, to, value);
    }
}
