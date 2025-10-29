// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

interface IERC20 {
    function balanceOf(address account) external view returns (uint256);
    function transfer(address to, uint256 amount) external returns (bool);
}

contract Trustchain {
    /* ========== STATE ========== */
    address public owner;
    uint256 public lastHeartbeat;
    uint256 public inactivityPeriod;
    bool public legacyReleased;

    uint256 public totalShares;

    struct Heir {
        address addr;
        uint16 share; // in basis points, e.g. 2500 = 25%
    }

    Heir[] private heirs;
    mapping(address => uint16) public heirShares;

    /* ========== EVENTS ========== */
    event HeirAdded(address indexed heir, uint16 share);
    event HeirRemoved(address indexed heir);
    event Heartbeat(address indexed owner, uint256 timestamp);
    event DepositedETH(address indexed from, uint256 amount);
    event LegacyReleased(address indexed triggeredBy, uint256 timestamp);
    event OwnerWithdraw(address indexed owner, uint256 amount);

    /* ========== MODIFIERS ========== */
    modifier onlyOwner() {
        require(msg.sender == owner, "Not owner");
        _;
    }

    modifier notReleased() {
        require(!legacyReleased, "Already released");
        _;
    }

    /* ========== CONSTRUCTOR ========== */
    constructor() {
        owner = msg.sender;
        inactivityPeriod = 365 days; // default 1 year
        lastHeartbeat = block.timestamp;
    }

    /* ========== FALLBACK ========== */
    receive() external payable {
        emit DepositedETH(msg.sender, msg.value);
    }

    /* ========== OWNER FUNCTIONS ========== */
    function heartbeat() external onlyOwner {
        lastHeartbeat = block.timestamp;
        emit Heartbeat(msg.sender, lastHeartbeat);
    }

    function addHeir(address _heir, uint16 _share) external onlyOwner notReleased {
        require(_heir != address(0), "Invalid heir");
        require(_share > 0, "Share must be > 0");
        require(heirShares[_heir] == 0, "Heir exists");
        require(totalShares + _share <= 10000, "Total > 100%");

        heirs.push(Heir(_heir, _share));
        heirShares[_heir] = _share;
        totalShares += _share;

        emit HeirAdded(_heir, _share);
    }

    function removeHeir(address _heir) external onlyOwner notReleased {
        require(heirShares[_heir] > 0, "Not found");

        uint16 share = heirShares[_heir];
        heirShares[_heir] = 0;
        totalShares -= share;

        for (uint256 i = 0; i < heirs.length; i++) {
            if (heirs[i].addr == _heir) {
                heirs[i] = heirs[heirs.length - 1];
                heirs.pop();
                break;
            }
        }

        emit HeirRemoved(_heir);
    }

    function ownerWithdrawETH(uint256 amount) external onlyOwner notReleased {
        require(amount <= address(this).balance, "Insufficient");
        (bool ok, ) = owner.call{value: amount}("");
        require(ok, "Withdraw failed");
        emit OwnerWithdraw(owner, amount);
    }

    /* ========== VIEW FUNCTIONS ========== */
    function heirsCount() external view returns (uint256) {
        return heirs.length;
    }

    function canRelease() public view returns (bool) {
        return !legacyReleased && (block.timestamp > lastHeartbeat + inactivityPeriod);
    }

    /* ========== RELEASE LOGIC ========== */
    function releaseLegacy() external notReleased {
        require(canRelease(), "Owner still active");
        require(totalShares > 0, "No heirs");

        legacyReleased = true;
        uint256 balance = address(this).balance;
        uint256 distributed = 0;

        for (uint256 i = 0; i < heirs.length; i++) {
            Heir memory h = heirs[i];
            uint256 amount = (balance * h.share) / totalShares;
            distributed += amount;
            if (amount > 0) {
                (bool ok, ) = h.addr.call{value: amount}("");
                require(ok, "Transfer failed");
            }
        }

        // Handle leftover wei due to rounding
        uint256 leftover = balance - distributed;
        if (leftover > 0 && heirs.length > 0) {
            (bool ok, ) = heirs[0].addr.call{value: leftover}("");
            require(ok, "Leftover transfer failed");
        }

        emit LegacyReleased(msg.sender, block.timestamp);
    }
}
