// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

/// @title Trustchain - On-chain digital legacy manager
/// @notice Simple decentralized inheritance system with inactivity detection
contract Trustchain {
    /* ========== STATE ========== */

    address public owner;
    uint256 public lastHeartbeat;
    uint256 public inactivityPeriod;
    bool public legacyReleased;

    uint256 public totalShares; // Sum of all heirs’ shares (in basis points)

    struct Heir {
        address addr;
        uint16 share; // e.g. 2500 = 25%
    }

    Heir[] private heirs;
    mapping(address => uint16) public heirShares;

    /* ========== EVENTS ========== */
    event HeirAdded(address indexed heir, uint16 share);
    event HeirRemoved(address indexed heir);
    event HeirUpdated(address indexed heir, uint16 oldShare, uint16 newShare);
    event Heartbeat(address indexed owner, uint256 timestamp);
    event DepositedETH(address indexed from, uint256 amount);
    event LegacyReleased(address indexed triggeredBy, uint256 timestamp);
    event ERC20Released(address indexed token, address indexed to, uint256 amount);

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
    constructor(uint256 _inactivityPeriod) {
        require(_inactivityPeriod > 0, "invalid inactivityPeriod");
        owner = msg.sender;
        inactivityPeriod = _inactivityPeriod;
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
        require(_heir != address(0), "invalid heir");
        require(_share > 0, "share must be > 0");
        require(heirShares[_heir] == 0, "heir exists");
        require(totalShares + _share <= 10000, "total > 100%");

        heirs.push(Heir(_heir, _share));
        heirShares[_heir] = _share;
        totalShares += _share;

        emit HeirAdded(_heir, _share);
    }

    function removeHeir(address _heir) external onlyOwner notReleased {
        require(heirShares[_heir] > 0, "not found");

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

        for (uint256 i = 0; i < heirs.length; i++) {
            Heir memory h = heirs[i];
            uint256 amount = (balance * h.share) / totalShares;
            if (amount > 0) {
                (bool ok, ) = h.addr.call{value: amount}("");
                require(ok, "Transfer failed");
            }
        }

        emit LegacyReleased(msg.sender, block.timestamp);
    }

    /* ========== WITHDRAW BEFORE RELEASE ========== */
    function ownerWithdrawETH(uint256 amount) external onlyOwner notReleased {
        require(amount <= address(this).balance, "Insufficient");
        (bool ok, ) = owner.call{value: amount}("");
        require(ok, "Withdraw failed");
    }
}

/* ========== ERC20 Interface (Optional use later) ========== */
interface IERC20 {
    function balanceOf(address account) external view returns (uint256);
    function transfer(address to, uint256 amount) external returns (bool);
}
