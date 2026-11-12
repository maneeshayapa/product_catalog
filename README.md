# Product Catalog

A Flutter shopping catalog app that loads products from the DummyJSON Products
API. Browse and search the catalog, inspect product information and reviews,
and keep a locally persisted shopping cart.

## Project objectives

- Demonstrate a complete product-browsing flow using a public REST API.
- Separate API access, repository logic, application state, and screen
  presentation.
- Provide a responsive catalog experience with search and pagination.
- Manage cart contents across app launches using local persistence.
- Verify core model, cart, and widget behavior with automated tests.

## Features

- Product grid with product images, titles, prices, and average ratings.
- Paginated product loading as you scroll.
- Product search with a 500 ms debounce.
- Product category filtering, including an All categories option.
- Local sorting by default order, price, rating, or product name.
- Product details with an image gallery, description, brand, category, stock,
  warranty, shipping, and return information when available.
- Customer reviews and related products from the product category.
- Add products to the shopping cart, change item quantities, and remove items.
- Automatically calculated cart item count and total.
- Cart contents saved locally using SharedPreferences and restored at startup.
- Loading, network-error, empty-result, and retry states where applicable.

## Technologies and packages

| Technology/package | Use |
| --- | --- |
| Flutter and Dart | Cross-platform application and UI |
| `provider` | `ChangeNotifier` application state |
| DummyJSON Products API | Product catalog and category data |
| `http` | HTTP API requests |
| `shared_preferences` | Local cart persistence |
| `flutter_test` | Unit and widget tests |

## Project structure

```text
lib/
├── main.dart
├── data/
│   ├── models/
│   │   ├── product.dart
│   │   └── product_review.dart
│   ├── repositories/
│   │   └── product_repository.dart
│   └── services/
│       └── product_service.dart
├── providers/
│   ├── cart_provider.dart
│   └── product_provider.dart
└── screens/
    ├── cart/
    │   └── cart_screen.dart
    ├── details/
    │   └── product_details_screen.dart
    └── home/
        └── home_screen.dart

test/
├── cart_provider_test.dart
├── product_model_test.dart
├── product_provider_test.dart
└── widget_test.dart
```

`ProductService` makes HTTP requests and decodes API responses.
`ProductRepository` provides the product data interface used by
`ProductProvider`. The product and review models map API data to Dart objects.
The screens render the catalog, product details, and cart.

## API

The app uses the public [DummyJSON Products API](https://dummyjson.com/docs/products)
at `https://dummyjson.com`.

| Purpose | Endpoint |
| --- | --- |
| List products | `GET /products?limit={limit}&skip={skip}` |
| Search products | `GET /products/search?q={query}&limit={limit}&skip={skip}` |
| List product categories | `GET /products/category-list` |
| Load related products by category | `GET /products/category/{category}?limit={limit}` (the app requests 12) |

Product details, including reviews, are displayed from the product data already
loaded into the app; the app does not make a separate single-product request.
The service uses a 15-second request timeout.

## Requirements

- Flutter SDK with Dart SDK `3.12.1` or later (as specified in `pubspec.yaml`)
- An Android device/emulator or another Flutter-supported target
- Internet access to retrieve catalog data and product images

## Installation and setup

Clone the repository and fetch its packages:

```bash
git clone https://github.com/maneeshayapa/product_catalog.git
cd product_catalog
flutter pub get
```

Run on a connected device or running emulator:

```bash
flutter devices
flutter run
```

To select a specific device, use `flutter run -d <device-id>` with an ID shown
by `flutter devices`.

## Build the Android debug APK

Create a debug APK from the project root:

```bash
flutter build apk --debug
```

The APK is written to
`build/app/outputs/flutter-apk/app-debug.apk`. The `build/` directory is
gitignored, so attach the APK separately (for example, as a GitHub release
asset or a shared download) when submitting; do not commit generated build
files.

## Tests and coverage

Run the test suite from the project root:

```bash
flutter test
```

The four test files contain twenty-one test cases:

- `test/product_model_test.dart` checks parsing, serialization, reviews, and
  optional product fields.
- `test/cart_provider_test.dart` checks cart serialization, quantity changes,
  removal, restoration, totals, and invalid saved JSON.
- `test/product_provider_test.dart` checks category selection, returning to All,
  all four non-default sorting modes, and search/category pagination behavior.
- `test/widget_test.dart` exercises product details, reviews, related products,
  adding a product to the cart, and opening the cart with a fake repository.

The tests cover model parsing/serialization, cart persistence and state
operations, product category/sort state, search and pagination interaction, and
a widget flow through details, related products, add-to-cart, and cart
navigation. They are unit and widget tests; there is no live API integration
test or manual device/UI test in the current test suite.

## State management

The app uses Provider to make `ProductProvider` and `CartProvider` available
above the widget tree. `ProductProvider` manages the loaded products, search
query, category selection, sort option, pagination offsets, loading flags, and
request errors; screens listen to it and rebuild when it notifies listeners.
Category choices are fetched through `ProductService` and `ProductRepository`.
Category filtering works on fetched search results, while sorting is local and
is reapplied whenever another page is loaded. `CartProvider` manages cart
items, quantities, the item count, total price, and persistence operations.
This keeps screen widgets focused on presenting state and forwarding user
actions.

## Cart persistence

At startup, `main()` creates the cart provider asynchronously and restores
serialized cart items from SharedPreferences before showing the app. Add,
increase, decrease, and remove operations update the in-memory cart and save
its JSON representation under the `product_catalog_cart` key. Cart data is
stored locally on the device; it is not synchronized to a server.

## Known limitations

- Catalog data and images require network access; the app has no offline product
  catalog.
- The cart is local to the current app installation and is not synced between
  devices or accounts.
- The cart has no checkout, payment, or order-submission flow.
- Cart quantities are limited to the stock value returned by the API, but stock
  is not revalidated with the server and may become outdated.
- Sorting applies to products loaded so far; it does not reorder the complete
  server-side catalog before every page is fetched.

## Possible future improvements

- Add checkout and order management if a backend is introduced.
- Add tests for product-service request behavior and pagination/search states.
- Surface cart persistence errors directly in the cart UI.

## Author and repository

- Author: [maneeshayapa](https://github.com/maneeshayapa)
- Repository: [maneeshayapa/product_catalog](https://github.com/maneeshayapa/product_catalog)
