/// Estados posibles de un pedido en FoodPlease.
enum OrderStatus {
  pending('pending', 'Pendiente'),
  preparing('preparing', 'Preparando'),
  ready('ready', 'Listo'),
  delivered('delivered', 'Entregado'),
  cancelled('cancelled', 'Cancelado');

  const OrderStatus(this.apiValue, this.label);

  final String apiValue;
  final String label;

  bool get isClosed =>
      this == OrderStatus.delivered || this == OrderStatus.cancelled;

  static OrderStatus fromApiValue(String value) {
    for (final OrderStatus status in OrderStatus.values) {
      if (status.apiValue == value) return status;
    }
    throw ArgumentError.value(value, 'value', 'Estado de pedido desconocido.');
  }
}
