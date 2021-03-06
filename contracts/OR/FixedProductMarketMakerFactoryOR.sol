pragma solidity ^0.5.16;

import {IERC20} from "openzeppelin-solidity/contracts/token/ERC20/IERC20.sol";
import {ConditionalTokens} from "../../gnosis.pm/conditional-tokens-contracts/contracts/ConditionalTokens.sol";
import {CTHelpers} from "../../gnosis.pm/conditional-tokens-contracts/contracts/CTHelpers.sol";
import {ORFPMarket} from "./ORFPMarket.sol";
import {ERC1155TokenReceiver} from "../../gnosis.pm/conditional-tokens-contracts/contracts/ERC1155/ERC1155TokenReceiver.sol";
import {CloneFactory} from "./CloneFactory.sol";

contract FixedProductMarketMakerFactory is CloneFactory {
    event FixedProductMarketMakerCreation(
        address indexed creator,
        ORFPMarket fixedProductMarketMaker,
        ConditionalTokens indexed conditionalTokens,
        IERC20 indexed collateralToken,
        bytes32[] conditionIds,
        uint fee
    );

    ORFPMarket public implementationMaster;
    address implementationMasterAddr;

    uint public marketsCount;
    ORFPMarket[] public fpMarkets;

    address deployer;
    constructor() public {
        //implementationMaster = new ORFPMarket();
        //implementationMasterAddr = address(implementationMaster);
        
        //implementationMasterAddr = marketTemplateAdd; 
        deployer = msg.sender;
    }
    
    
    /*
        function cloneConstructor(bytes calldata consData) external {
            (
            ConditionalTokens _conditionalTokens,
            IERC20 _collateralToken,
            bytes32[] memory _conditionIds,
            uint _fee
            ) = abi.decode(consData, (ConditionalTokens, IERC20, bytes32[], uint));

            _supportedInterfaces[_INTERFACE_ID_ERC165] = true;
            _supportedInterfaces[
            ERC1155TokenReceiver(0).onERC1155Received.selector ^
            ERC1155TokenReceiver(0).onERC1155BatchReceived.selector
            ] = true;

            conditionalTokens = _conditionalTokens;
            collateralToken = _collateralToken;
            conditionIds = _conditionIds;
            fee = _fee;

            uint atomicOutcomeSlotCount = 1;
            outcomeSlotCounts = new uint[](conditionIds.length);
            for (uint i = 0; i < conditionIds.length; i++) {
                uint outcomeSlotCount = conditionalTokens.getOutcomeSlotCount(conditionIds[i]);
                atomicOutcomeSlotCount *= outcomeSlotCount;
                outcomeSlotCounts[i] = outcomeSlotCount;
            }
            require(atomicOutcomeSlotCount > 1, "conditions must be valid");

            collectionIds = new bytes32[][](conditionIds.length);
            _recordCollectionIDsForAllConditions(conditionIds.length, bytes32(0));
            require(positionIds.length == atomicOutcomeSlotCount, "position IDs construction failed!?");
        }

        function _recordCollectionIDsForAllConditions(uint conditionsLeft, bytes32 parentCollectionId) private {
            if(conditionsLeft == 0) {
                positionIds.push(CTHelpers.getPositionId(collateralToken, parentCollectionId));
                return;
            }

            conditionsLeft--;

            uint outcomeSlotCount = outcomeSlotCounts[conditionsLeft];

            collectionIds[conditionsLeft].push(parentCollectionId);
            for(uint i = 0; i < outcomeSlotCount; i++) {
                _recordCollectionIDsForAllConditions(
                    conditionsLeft,
                    CTHelpers.getCollectionId(
                        parentCollectionId,
                        conditionIds[conditionsLeft],
                        1 << i
                    )
                );
            }
        }
    */
    function createFixedProductMarketMaker(
        ConditionalTokens conditionalTokens,
        IERC20 collateralToken,
        bytes32[] memory conditionIds,
        uint feeLP,
        uint feeProposer,
        address proposer,
        address roomOracle
    )
    internal
    returns (ORFPMarket)
    {
        ORFPMarket fixedProductMarketMaker = ORFPMarket(createClone(implementationMasterAddr));

        fixedProductMarketMaker.init(conditionalTokens, collateralToken, conditionIds, feeLP, feeProposer, proposer, roomOracle);

        emit FixedProductMarketMakerCreation(
            msg.sender,
            fixedProductMarketMaker,
            conditionalTokens,
            collateralToken,
            conditionIds,
            feeLP + feeProposer
        );

        fpMarkets.push(fixedProductMarketMaker);
        marketsCount++;
        return fixedProductMarketMaker;
    }

    function getAllMarkets() public view returns (ORFPMarket[] memory) {
        return fpMarkets;
    }
    
    function getAllMarketsCount() public view returns(uint256){
        return marketsCount; 
    }


}
