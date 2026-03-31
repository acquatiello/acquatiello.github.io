// app.js

// AcquaTiello E-commerce Application

// Product Management Class
class Product {
    constructor(id, name, price) {
        this.id = id;
        this.name = name;
        this.price = price;
    }
}

// Shopping Cart Class
class ShoppingCart {
    constructor() {
        this.cart = [];
    }

    addToCart(product) {
        this.cart.push(product);
    }

    removeFromCart(productId) {
        this.cart = this.cart.filter(product => product.id !== productId);
    }

    getTotal() {
        return this.cart.reduce((total, product) => total + product.price, 0);
    }
}

// Pix Payment Integration
class PixPayment {
    constructor() {
        // Initialize Pix Payment API settings if needed
    }

    processPayment(amount) {
        // Logic to process Pix payment
        console.log(`Processing payment of ${amount} via Pix`);
        // Simulated payment processing... 
        return true; // Return true if payment is successful
    }
}

// Example Usage
const cart = new ShoppingCart();
cart.addToCart(new Product(1, "T-Shirt", 29.99));
cart.addToCart(new Product(2, "Jeans", 49.99));

console.log(`Total amount: ${cart.getTotal()}`);

const payment = new PixPayment();
if(payment.processPayment(cart.getTotal())) {
    console.log("Payment successful!");
} else {
    console.log("Payment failed.");
}
