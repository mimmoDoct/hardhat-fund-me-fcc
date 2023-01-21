// Get funds from users
// Withdraw funds
// Set a minimum funding value in usd

// SPDX-License-Identifier: MIT
// Pragma
pragma solidity ^0.8.0;

// Imports
import "./PriceConverter.sol";
import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";

//Error Codes
error FundMe__NotOwner();

// Interfaces, Libraries, Contracts

/**
 * @title A contract for crowd funding
 *  @author Milton Valla
 *  @notice This contract is to demo a sample funding contract
 *  @dev This implements price feed as our library
 */
contract FundMe {
    // Type Declarations
    using PriceConverter for uint256;

    // State Variables
    mapping(address => uint256) private s_addressToAmountFunded;
    address[] private s_funders;
    // Could we make this constant?
    address private immutable i_owner; //immutable: save gas, variables set one time but outside of the same line they are declared, naming convention == i_owner
    uint256 public constant MINIMUM_USD = 50 * 1e18; // constant: reduce costs gas if the variable doesn't change, they have a different naming convention (MINIMUM_USD)
    AggregatorV3Interface private s_priceFeed;

    // Events, Modifiers
    modifier onlyOwner() {
        // require(msg.sender == owner, "Sender is not owner!");
        if (msg.sender != i_owner) revert FundMe__NotOwner();
        _; // this means: do the rest of the code
    }

    // Functions Order
    //// constructor
    //// receive
    //// fallback
    //// external
    //// public
    //// internal
    //// private
    //// view / pure

    constructor(address priceFeedAddress) {
        i_owner = msg.sender;
        s_priceFeed = AggregatorV3Interface(priceFeedAddress);
    } // immediately called when you deploy the contract

    receive() external payable {
        fund();
    }

    fallback() external payable {
        fund();
    }

    /**
     * @notice This function funds this contract
     * @dev Thi implements price feeds as our library
     */

    function fund() public payable {
        // Want to be able to set a minimum fund amount in USD
        // 1. How do we send ETH to this contract ?
        require(
            msg.value.getConversionRate(s_priceFeed) >= MINIMUM_USD,
            "You need to spend more ETH!"
        ); // 1 * 10 ** 18 == 1000000000000000000 == 1 ETH
        s_addressToAmountFunded[msg.sender] += msg.value;
        s_funders.push(msg.sender);
    }

    function withdraw() public onlyOwner {
        /*require(msg.sender == owner, "Sender is not owner!");*/ // We delete this, cause we can create a modifiers to reuse everytime we need without copy and paste the code
        /* starting index, ending index, step amount*/
        for (
            uint256 funderIndex = 0;
            funderIndex < s_funders.length;
            funderIndex++ /* or funderIndex++ */
        ) {
            address funder = s_funders[funderIndex];
            s_addressToAmountFunded[funder] = 0;
        }
        // reset the array
        s_funders = new address[](0); // 0 means that it will a new blank array, 1 would mean with one value, etc.
        // withdrawn the funds
        // 3 metods:
        // transfer:
        //      msg.sender = address
        //      payable(msg.sender) = payable address
        //      if the transaction fails it returns an error
        /*payable(msg.sender.transfer(address(this).balance));*/
        // send
        /*bool sendSuccess = payable(msg.sender.send(address(this).balance));*/
        /*require(sendSuccess, "Send Failed");*/
        // call, RECOMMENDED WAY
        (bool callSuccess /*bytes memory dataReturned*/, ) = payable(msg.sender)
            .call{value: address(this).balance}(""); // return two variables
        require(callSuccess, "Call Failed");
    }

    function cheaperWithdraw() public payable onlyOwner {
        address[] memory funders = s_funders;
        // mappings can't be in memory!!
        for (
            uint256 funderIndex = 0;
            funderIndex < funders.length;
            funderIndex++
        ) {
            address funder = funders[funderIndex];
            s_addressToAmountFunded[funder] = 0;
        }
        s_funders = new address[](0);
        (bool success, ) = i_owner.call{value: address(this).balance}("");
        require(success);
    }

    function getOwner() public view returns (address) {
        return i_owner;
    }

    function getFunder(uint256 index) public view returns (address) {
        return s_funders[index];
    }

    function getAddressToAmountFunded(
        address funder
    ) public view returns (uint256) {
        return s_addressToAmountFunded[funder];
    }

    function getPriceFeed() public view returns (AggregatorV3Interface) {
        return s_priceFeed;
    }
}
