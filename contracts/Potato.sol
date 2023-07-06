// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/utils/Counters.sol";

contract Potato is AccessControl {
    using Counters for Counters.Counter;
    
    struct Product {
        uint256 productID;
        uint256 stock;
        uint256 price;
        string productURI;
    }
    
    Counters.Counter private _counter;
    address payable public middleman;
    uint256[] public productIDs;
    mapping(uint256 => uint256) public stock;
    mapping(uint256 => uint256) public price;
    mapping(uint256 => address) public productSellers;
    mapping(uint256 => string) public productURIs;

    bytes32 public constant SELLER_ROLE = keccak256("SELLER_ROLE");
    uint256 public sellerFee = 0.01 ether;

    event ProductAdded(uint256 productID, uint256 quantity, uint256 pricePerUnit, string productURI);
    event ProductSold(uint256 productID, uint256 quantity, address buyer, uint256 totalPrice);
    event ProductUpdated(uint256 productID, uint256 newPrice, uint256 newQuantity, string newProductURI);
    event ProductRemoved(uint256 productID);
    
    constructor(address payable _middleman) {
        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
        middleman = _middleman;
    }

     function changeMiddleman(address payable newMiddleman) external onlyRole(DEFAULT_ADMIN_ROLE) {
        require(newMiddleman != address(0), "Zero address");
        require(newMiddleman != middleman, "Same middleman");
        middleman = newMiddleman;
    }

    function changeSellerFee(uint256 newFee) external onlyRole(DEFAULT_ADMIN_ROLE) {
        require(newFee > 0, "Zero fee");
        require(newFee != sellerFee, "Same fee");
        sellerFee = newFee;
    }

    function becomeSeller() external payable {
        require(!hasRole(SELLER_ROLE, msg.sender), "Already a seller");
        require(msg.value >= sellerFee, "Subscription fee not met");
        _grantRole(SELLER_ROLE, msg.sender);
    }

    function addProduct( uint256 stockQuantity, uint256 pricePerUnit, string memory productURI) external onlyRole(SELLER_ROLE) {
        require(pricePerUnit > 0, "No free products allowed");
        _counter.increment();
        uint256 newProductID = _counter.current();
        stock[newProductID] = stockQuantity;
        price[newProductID] = pricePerUnit;
        productURIs[newProductID] = productURI;
        productSellers[newProductID] = msg.sender;
        productIDs.push(newProductID);
        emit ProductAdded(newProductID, stockQuantity, pricePerUnit, productURI);
    }

    function updateProduct(uint256 productID, uint256 newPrice, uint256 newQuantity, string calldata newProductURI) external onlyRole(SELLER_ROLE){
        require(bytes(productURIs[productID]).length > 0, "No such product");
        require(productSellers[productID] == msg.sender, "Not your product");
        require(newPrice > 0, "No free products allowed");
        require(bytes(newProductURI).length > 0, "Empty URI");
        require(price[productID] != newPrice || stock[productID] != newQuantity || keccak256(bytes(productURIs[productID]))!=keccak256(bytes(newProductURI)), "Nothing to update");
        if(price[productID] != newPrice)
            price[productID] = newPrice;
        if(stock[productID] != newQuantity)
            stock[productID] = newQuantity;
        if(keccak256(bytes(productURIs[productID]))!=keccak256(bytes(newProductURI)))
            productURIs[productID] = newProductURI;
        emit ProductUpdated(productID, newPrice, newQuantity, newProductURI);

    }

    function removeProduct(uint256 productID) external onlyRole(SELLER_ROLE) {
        require(bytes(productURIs[productID]).length > 0, "No such product");
        require(productSellers[productID] == msg.sender, "Not your product");
        delete stock[productID];
        delete price[productID];
        delete productURIs[productID];
        for (uint256 i = 0; i < productIDs.length; i++) {
            if (productIDs[i] == productID) {
                productIDs[i] = productIDs[productIDs.length - 1];
                productIDs.pop();
                break;
            }
        }
        emit ProductRemoved(productID);
    }

    function purchaseProduct(uint256 productID, uint256 quantity) external payable {
        require(bytes(productURIs[productID]).length > 0, "No such product");
        require(quantity > 0, "Invalid quantity");
        require(msg.sender != productSellers[productID], "Cannot buy your own product");
        require(stock[productID] >= quantity, "Insufficient stock");
        uint256 totalPrice = price[productID] * quantity;
        require(msg.value >= totalPrice, "Insufficient payment");
        
        (bool success1,)= productSellers[productID].call{value:totalPrice * 90 / 100}(""); // Payment is made to the seller
        (bool success2,)= middleman.call{value:totalPrice * 10 / 100}(""); // Commission payment is made to the middleman
        require(success1 && success2, "Payment failed");
        
        stock[productID] -= quantity;
        emit ProductSold(productID, quantity, msg.sender, totalPrice);
    }


    function getProducts() external view returns (uint256[] memory) {
        return productIDs;
    }

    function getProduct(uint256 productID) external view returns (Product memory) {
        return Product(productID, stock[productID], price[productID], productURIs[productID]);
    }

    function getSellerProducts(address seller) external view returns (Product[] memory){
        uint256 counter = 0;
        for (uint256 i = 0; i < productIDs.length; i++) {
            if (productSellers[productIDs[i]] == seller) {
                counter++;
            }
        }
        Product[] memory result = new Product[](counter);
        for (uint256 i = 0; i < counter; i++) {
            if (productSellers[productIDs[i]] == seller) {
                result[i] = Product(productIDs[i], stock[productIDs[i]], price[productIDs[i]], productURIs[productIDs[i]]);
            }
            
        }
        return result;
    }

    function getAvailableProducts(address buyer) external view returns (Product[] memory){
        uint256 counter = 0;
        for (uint256 i = 0; i < productIDs.length; i++) {
            if (productSellers[productIDs[i]] != buyer && stock[productIDs[i]] > 0) 
                counter++;
        }
        
        Product[] memory result = new Product[](counter);
        for (uint256 i = 0; i < counter; i++) {
            if(productSellers[productIDs[i]] != buyer && stock[productIDs[i]] > 0)
                result[i] = Product(productIDs[i], stock[productIDs[i]], price[productIDs[i]], productURIs[productIDs[i]]);
        }
        return result;
    }

    function isSeller(address seller) external view returns (bool) {
        return hasRole(SELLER_ROLE, seller);
    }


}
