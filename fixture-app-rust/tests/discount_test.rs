use revi_fixture_app_rust::discount::bulk_discount;

#[test]
fn applies_bulk_discount_at_exactly_ten_units() {
    // 10 units at 100 each should get the 10% bulk discount: 1000 * 0.9 = 900
    assert_eq!(bulk_discount(100, 10), 900);
}

#[test]
fn applies_bulk_discount_above_ten_units() {
    assert_eq!(bulk_discount(100, 11), 990);
}

#[test]
fn no_discount_below_ten_units() {
    assert_eq!(bulk_discount(100, 9), 900);
}
