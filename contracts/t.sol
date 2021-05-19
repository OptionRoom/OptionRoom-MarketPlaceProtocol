pragma solidity ^0.5.0;



contract aaa{
    function addressToString(address _addr) public pure returns(string memory) 
    {
        bytes32 value = bytes32(uint256(_addr));
        bytes memory alphabet = "0123456789abcdef";

        bytes memory str = new bytes(51);
        str[0] = '0';
        str[1] = 'x';
        for (uint256 i = 0; i < 20; i++) {
            str[2+i*2] = alphabet[uint8(value[i + 12] >> 4)];
            str[3+i*2] = alphabet[uint8(value[i + 12] & 0x0f)];
        }
        return string(str);
    }
    
    
    function append(string memory a, string memory b, string memory c, string memory d, string memory e) internal pure returns (string memory ) {

        return string(abi.encodePacked(a, b, c, d, e));

    }
}