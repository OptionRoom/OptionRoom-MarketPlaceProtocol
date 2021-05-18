
import "../Demotoken.sol";

contract ERC20DemoToken is DemoToken {

    function deposit() public payable {
        mint(msg.value);
        transfer(msg.sender, msg.value);
    }
    
}
