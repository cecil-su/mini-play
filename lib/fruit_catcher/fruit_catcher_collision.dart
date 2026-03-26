import 'fruit_catcher_models.dart';

class FruitCatcherCollision {
  /// Check if a falling item is caught by the basket (AABB overlap).
  static bool caught(FruitItem item, Basket basket) {
    final ix = item.x - item.radius;
    final iy = item.y - item.radius;
    final iw = item.radius * 2;
    final ih = item.radius * 2;
    final bx = basket.x - basket.width / 2;
    final by = basket.y - basket.height / 2;
    return ix < bx + basket.width &&
        ix + iw > bx &&
        iy < by + basket.height &&
        iy + ih > by;
  }
}
