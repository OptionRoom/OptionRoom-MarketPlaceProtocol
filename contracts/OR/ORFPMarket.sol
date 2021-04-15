pragma solidity ^0.5.1;

import "./FixedProductMarketMakerOR.sol";
import "./IORGovernance.sol";

/**
    @title ORFPMarket Extended version of the FixedProductMarketMaker
*/
contract ORFPMarket is FixedProductMarketMaker {

    enum MarketState {
        Invalid,
        Pending, // governance voting for validation
        Rejected,
        Active,
        Inactive,
        Resolving, // governance voting for result
        Resolved  // can redeem
    }

    uint256 public constant votingPeriod = 86400;

    mapping(address => bool) marketVoters;
    mapping(address => bool) resolvingVoters;
    uint256[2] public resolvingVotes;

    address public proposer;
    uint256 public createdTime;
    uint256 public approveVotesCount;
    uint256 public rejectVotesCount;
    uint256 public participationEndTime;
    uint256 public resolvingPeriod;
    bytes32 public questionId;

    bool initializationPhase2;

    string public marketQuestion;

    IORGovernance public ORGovernance;

    function init2(string memory _marketQuestion, address _proposer, uint256 _createdTime,
            uint256 _participationEndTime, uint256 _resolvingPeriod, address _governance, bytes32 _questionId) public {
        require(initializationPhase2 == false, "Initialization already called");
        marketQuestion = _marketQuestion;
        initializationPhase2 = true;
        proposer = _proposer;
        createdTime = _createdTime;
        participationEndTime = _participationEndTime;
        resolvingPeriod = _resolvingPeriod;
        questionId = _questionId;
        ORGovernance = IORGovernance(_governance);
    }

    function state() public view returns (MarketState) {

        uint256 time = getCurrentTime();

        if ((time - createdTime) < votingPeriod) {
            return MarketState.Pending;

        } else if (rejectVotesCount > approveVotesCount) {
            return MarketState.Rejected;

        } else if (time < participationEndTime) {
            return MarketState.Active;

        } else if (time > (participationEndTime + resolvingPeriod)) {
            return MarketState.Resolved;

        } else {
            return MarketState.Resolving;
        }
    }

    function approveMarket(bool approve) public {
        require(state() == MarketState.Pending, "Market is not in pending state");
        require(marketVoters[msg.sender] == false, "user already voted");
        marketVoters[msg.sender] = true;

        if (approve == true) {
            approveVotesCount += ORGovernance.getPowerCount(msg.sender);
        } else {
            rejectVotesCount += ORGovernance.getPowerCount(msg.sender);
        }
    }

    function addLiquidity(uint256 amount) public {
        uint[] memory distributionHint;
        if (totalSupply() > 0) {
            addFunding(amount, distributionHint);
        } else {
            distributionHint = new uint[](2);
            distributionHint[0] = 1;
            distributionHint[1] = 1;
            addFunding(amount, distributionHint);
        }
    }

    function removeLiquidity(uint256 shares) public {
        removeFunding(shares);
        //todo
    }

    function merge() public {
        uint[] memory balances = getBalances(msg.sender);
        uint minBalance = balances[0];
        for (uint256 i = 0; i < balances.length; i++) {
            if (balances[i] < minBalance) {
                minBalance = balances[i];
            }
        }

        uint[] memory sendAmounts = new uint[](balances.length);
        for (uint256 i = 0; i < balances.length; i++) {
            sendAmounts[i] = minBalance;
        }

        conditionalTokens.safeBatchTransferFrom(msg.sender, address(this), positionIds, sendAmounts, "");
        mergePositionsThroughAllConditions(minBalance);

        require(collateralToken.transfer(msg.sender, minBalance), "return transfer failed");
    }

    function resolvingMarket(uint256 outcomeIndex) public {
        require(state() == MarketState.Resolving, "market is not in resolving period");
        require(resolvingVoters[msg.sender] == false, "already voted");
        resolvingVotes[outcomeIndex] += ORGovernance.getPowerCount(msg.sender);
    }

    function getIndexSet() public pure returns (uint256[] memory indexSet) {
        indexSet = new uint256[](2);
        indexSet[0] = 1;
        indexSet[1] = 2;
    }

    function getResolvingOutcome() public view returns (uint256[] memory indexSet) {
        indexSet = new uint256[](2);
        indexSet[0] = 1;
        indexSet[1] = 1;

        if (resolvingVotes[0] > resolvingVotes[1]) {
            indexSet[1] = 0;
        }
        if (resolvingVotes[1] > resolvingVotes[0]) {
            indexSet[1] = 1;
        }
    }

    function getPercentage() public view returns (uint256[] memory percentage) {
        percentage = new uint256[](2);
        uint256[] memory balances = getPoolBalances();
        uint256 totalBalances = balances[0] + balances[1] + 1;

        percentage[0] = balances[1] * 100 / totalBalances;
        percentage[1] = balances[0] * 100 / totalBalances;
    }

    function getPositionIds() public view returns (uint256[] memory) {
        return positionIds;
    }

    function getCurrentTime() public view returns (uint256) {
        //TODO
        //return block.timestamp;
        return crntTime;
    }

    //TODO just for testing remove them
    uint256 crntTime;

    function increaseTime(uint256 t) public {
        crntTime += t;
    }
}
