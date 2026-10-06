# SneakerHub - Milestone 1 Defense

## 1. Pitch

Hello, my application is called SneakerHub.

SneakerHub is a mobile marketplace for people who are interested in sneakers.

The problem is that users often need to search different stores to find sneakers they like.

My application provides a simple catalog where users can discover sneakers, search by brand, open product details, choose a size, and save products to favorites.

The target users are young people interested in sneakers, fashion, and streetwear.

In the future, I will add a REST API, database, authentication, and BLoC architecture.

## 2. Live Demo Order

1. Open the Home screen.
2. Show the product cards.
3. Show Search.
4. Change category: Nike / Adidas / Jordan.
5. Press the heart icon.
6. Open Favorites.
7. Open one product.
8. Show the Stack overlay on the image.
9. Show tags.
10. Select a shoe size.
11. Press Add to Cart.
12. Return to Home and show the cart counter.
13. Open Cart.
14. Increase and decrease quantity.
15. Remove an item and show the total price updating.

## 3. Code Review

Show these folders:

- lib/screens
- lib/widgets
- lib/models
- lib/data

Explain:

- Product is a model class.
- products.dart contains temporary local data.
- ProductCard is a reusable widget.
- HomeScreen uses StatefulWidget and setState for search/category filtering.
- ProductDetailScreen uses StatefulWidget and setState for size selection and favorite state.
- LayoutBuilder makes the UI responsive.
- GridView and SingleChildScrollView help avoid RenderFlex overflow.

## 4. Possible Teacher Questions

### Why did you use StatefulWidget?

Because the UI changes when the user selects a category, favorite, or shoe size.

### What does setState() do?

It tells Flutter that state changed and the widget should rebuild.

### Why did you use Stack?

To place the favorite button and brand label on top of the product image.

### Why did you use Expanded?

To give widgets flexible available space and help prevent overflow.

### Why did you use Wrap?

Because tags and size buttons can move to the next line if there is not enough width.

### How is the app responsive?

I use LayoutBuilder and change the number of grid columns depending on screen width. The detail screen also changes from Column to Row on wider screens.

### Why did you separate screens and widgets?

It makes the project easier to read, maintain, and expand in future milestones.

### Where will the REST API be added later?

The static product list in data/products.dart can later be replaced by data from an API.

### Where can BLoC be added?

The favorite, cart, products, and authentication state can later be moved from setState into separate BLoCs.

### What database can be added later?

A database can store users, favorites, cart items, and product information.

### How does the cart work?

The app stores cart items in a list. Each cart item contains a product, selected size, and quantity. setState() rebuilds the UI when quantity changes.

### Why is the cart useful for the final project?

Later, the same cart state can be moved into BLoC and saved using a database or backend API.
