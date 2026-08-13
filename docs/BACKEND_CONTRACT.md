# Backend Contract Direction

The commercial layer is optional and dynamic.

Planned endpoints:
- `/v1/auth/login`
- `/v1/me`
- `/v1/catalog/categories`
- `/v1/catalog/products`
- `/v1/services`
- `/v1/services/{id}/connection-profile`
- `/v1/remote-config`
- `/v1/ads`

Catalog entities are not protocol names. A product references one or more server pools and allowed protocols. Prices are resolved by audience/price-list rules (customer, reseller, VIP, corporate, custom override).

The app receives user-scoped connection profiles. It never receives infrastructure administrator credentials.
