# SneakerHub

SneakerHub is a Flutter sneaker marketplace created as a university Capstone Project.

**Status:** Milestone 1 complete

## Milestone 1

The goal of Milestone 1 is to build an MVP interface using the Flutter concepts studied in Weeks 1-5.

## Problem

Users often need to browse different stores to discover sneakers, compare models, and save the pairs they like.

## Solution

SneakerHub provides a simple mobile interface where users can:

- Browse sneaker products
- Search by sneaker or brand name
- Filter by brand/category
- Open a detailed product page
- Add or remove products from favorites
- Select a shoe size
- Add products to a working cart with selected size
- Change quantity, remove items, and see the total price

## Target Audience

Young users interested in sneakers, fashion, and streetwear.

## Screens

1. Home / Discovery
2. Product Details
3. Favorites
4. Cart

## Flutter Concepts Used

- StatefulWidget
- setState()
- Stack
- Row
- Column
- Expanded
- Wrap
- Card
- GridView
- LayoutBuilder
- Navigator
- Responsive UI

## Folder Structure

```text
lib/
├── main.dart
├── data/
│   └── products.dart
├── models/
│   ├── product.dart
│   └── cart_item.dart
├── screens/
│   ├── home_screen.dart
│   ├── product_detail_screen.dart
│   ├── favorites_screen.dart
│   └── cart_screen.dart
└── widgets/
    ├── category_chip.dart
    ├── product_card.dart
    └── size_selector.dart
```

## How to Run

```bash
flutter pub get
flutter run
```

For Chrome:

```bash
flutter run -d chrome
```

## Milestone 1 Requirements Covered

### UI/UX Design & Layout

- Stack overlay on product image
- Row and Column layouts
- Expanded widgets
- Responsive GridView
- Wrap for tags and sizes

### Working Interactivity

- Favorite button
- Search
- Category filter
- Size selector
- Add to cart
- Cart quantity + / -
- Remove from cart
- Total price

### Code Cleanliness

- Separate models, data, screens, and widgets
- Reusable product card and size selector
- Clean navigation

### Responsive Layout

- LayoutBuilder changes product grid columns based on width
- Product Detail screen changes from Column to Row on wide screens
- Scrollable content prevents RenderFlex overflow

## Future Development

Later milestones can add:

- REST API
- Authentication
- Database
- Real backend shopping cart
- User profile
- Product reviews
- BLoC architecture
